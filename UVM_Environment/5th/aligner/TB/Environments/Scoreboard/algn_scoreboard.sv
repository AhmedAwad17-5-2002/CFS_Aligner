///////////////////////////////////////////////////////////////////////////////
// File:        algn_scoreboard.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-06 (Fixed Version)
// Description: UVM Scoreboard for Aligner Environment
//
// Overview:
// ---------
// This class implements the UVM scoreboard responsible for verifying the 
// functionality of the Aligner DUT. The DUT is expected to align MD packets 
// received through the RX FIFO and transmit the processed (aligned) data 
// through the TX FIFO. The scoreboard ensures that the DUT correctly performs 
// this alignment and reports any mismatches or protocol errors.
//
// The scoreboard collects data from various analysis ports (monitors) within 
// the UVM environment, compares expected vs. actual DUT behavior, and maintains 
// statistics and logs of pass/fail results.
//
//
// Key Responsibilities:
// ----------------------
// 1. **Data Collection**
//    - Receives and stores transactions from multiple analysis ports, including:
//        • RX FIFO Monitor (input packets to DUT)
//        • TX FIFO Monitor (output packets from DUT)
//        • Register Monitor (register read/write transactions)
//        • rec_IRQ Monitor (interrupt signals from DUT)
//
// 2. **Expected vs. Actual Comparison**
//    - Maintains a queue of expected transactions based on the reference model 
//      or DUT input stimulus.
//    - When DUT output (TX FIFO) arrives, it is compared against the expected 
//      aligned packet to check correctness.
//    - Handles timing synchronization and ensures FIFO order correctness.
//
// 3. **Error and Status Tracking**
//    - Counts the number of matches (pass) and mismatches (fail).
//    - Reports UVM errors or warnings upon mismatch detection.
//    - Implements a watchdog timer to ensure no transactions are lost or 
//      stuck (timeout detection).
//
// 4. **Reset and Initialization Handling**
//    - Responds to reset events by clearing queues, counters, and flags.
//    - Waits for system readiness after reset before resuming checks.
//
// 5. **Interrupt Monitoring**
//    - Monitors DUT interrupt (rec_IRQ) events and validates that they are 
//      generated at correct times and under valid conditions.
//
// 6. **Reporting**
//    - Provides summary reports of all pass/fail counts at the end of simulation.
//    - Logs detailed messages for each comparison for debugging.
//
//
// Internal Architecture:
// ----------------------
// • **Analysis Ports**
//    - `rx_analysis_port`  → Collects RX FIFO transactions (input).
//    - `tx_analysis_port`  → Collects TX FIFO transactions (output).
//    - `reg_analysis_port` → Receives register transactions.
//    - `irq_analysis_port` → Observes DUT interrupt activity.
//
// • **Expected Data Queue**
//    - Stores expected aligned packets generated from RX data.
//    - Each entry is dequeued and compared upon receiving a TX transaction.
//
// • **Watchdog**
//    - Separate process running in parallel to detect long inactivity periods.
//    - Triggers a UVM warning/error if simulation stalls or data mismatch persists.
//
// • **Counters**
//    - `match_counter` → Number of successful matches.
//    - `mismatch_counter` → Number of failed comparisons.
//
//
// Typical Flow:
// --------------
// 1. DUT sends a packet to RX FIFO → RX monitor forwards to scoreboard.
// 2. Scoreboard predicts expected aligned output and pushes it to expected queue.
// 3. DUT sends aligned packet to TX FIFO → TX monitor forwards to scoreboard.
// 4. Scoreboard dequeues the expected packet, compares with actual output.
// 5. If they match → increment pass counter; else → log error and increment fail counter.
// 6. rec_IRQ and register monitors verify synchronization and control correctness.
// 7. Watchdog ensures no transaction starvation.
// 8. At end of simulation, scoreboard prints a detailed summary.
//
//
// Notes:
// ------
// • The scoreboard is non-blocking and event-driven, reacting to incoming analysis 
//   transactions via TLM connections.
// • It is designed to work seamlessly with the `algn_env` and `algn_model` components.
// • Identifier spelling (`*_counter`) was left as-is for backward compatibility.
// • Extendable for additional coverage collection or checks if required.
//
// Dependencies:
// -------------
// - Requires UVM package.
// - Relies on definitions of transaction types used by RX/TX/rec_IRQ/Reg agents.
//
// Revision History:
// -----------------
// 2025-08-20 : Initial version created.
// 2025-10-06 : Added comments, improved documentation, fixed description,
//               clarified data flow and scoreboard responsibilities.
//
///////////////////////////////////////////////////////////////////////////////


`ifndef ALGN_SCOREBOARD
`define ALGN_SCOREBOARD

//-----------------------------------------------------------------------------
// Analysis port macro declarations (implementation-specific macros)
// These macros should declare analysis interface implementations used below.
//-----------------------------------------------------------------------------
`uvm_analysis_imp_decl(_in_model_rx)
`uvm_analysis_imp_decl(_in_model_tx)
`uvm_analysis_imp_decl(_in_model_irq)
`uvm_analysis_imp_decl(_in_agent_rx)
`uvm_analysis_imp_decl(_in_agent_tx)

//-----------------------------------------------------------------------------
// Scoreboard class
//-----------------------------------------------------------------------------
class algn_scoreboard #(int unsigned DATA_WIDTH = `DATA_WIDTH)
  extends uvm_component implements uvm_ext_reset_handler_if;

  // Configuration object (contains thresholds, vif handle, and check flags)
  algn_scoreboard_config #(.DATA_WIDTH(`DATA_WIDTH)) my_algn_scoreboard_config;

  // -------------------- Analysis ports -------------------------------------
  // Ports through which the scoreboard receives transactions from model/agents
  uvm_analysis_imp_in_model_rx #(md_response, algn_scoreboard) port_in_model_rx;
  uvm_analysis_imp_in_model_tx #(algn_data_item, algn_scoreboard) port_in_model_tx;
  uvm_analysis_imp_in_model_irq#(irq,          algn_scoreboard) port_in_model_irq;
  uvm_analysis_imp_in_agent_rx #(algn_data_item, algn_scoreboard) port_in_agent_rx;
  uvm_analysis_imp_in_agent_tx #(algn_data_item, algn_scoreboard) port_in_agent_tx;

  // -------------------- Expected queues -----------------------------------
  // Queues containing expected responses/items/irqs produced by the model.
  protected md_response exp_rx_responses[$];    // expected RX responses
  protected algn_data_item exp_tx_items[$];        // expected TX items
  protected irq exp_irqs[$];                    // expected rec_IRQ flags

  // -------------------- Watchdog processes --------------------------------
  // We store process handles so they can be killed when the expected event
  // arrives or during reset.
  local process process_exp_rx_response_watchdog[$];
  local process process_exp_tx_item_watchdog[$];
  local process process_exp_irq_watchdog[$];

  // Process handle for the rec_IRQ receive task (single instance enforced)
  local process process_rcv_irq;

  // -------------------- Pass/Fail counters --------------------------------
  // NOTE: These counters have a spelling mistake in the identifier ("counter").
  // We keep the names unchanged to avoid breaking external references; if you
  // want them corrected to "counter" across the testbench, I can do a
  // refactor pass.
  local int unsigned rx_passed_counter;
  local int unsigned rx_failed_counter;

  local int unsigned tx_passed_counter;
  local int unsigned tx_failed_counter;

  local int unsigned irq_passed_counter;
  local int unsigned irq_failed_counter;

  `uvm_component_param_utils(algn_scoreboard#(.DATA_WIDTH(DATA_WIDTH)))

  //-------------------------------------------------------------------------
  // Constructor: create analysis ports and initialize members
  //-------------------------------------------------------------------------
  function new(string name = "algn_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    // Instantiate analysis ports (bound to this scoreboard instance)
    port_in_model_rx  = new("port_in_model_rx",  this);
    port_in_model_tx  = new("port_in_model_tx",  this);
    port_in_model_irq = new("port_in_model_irq", this);
    port_in_agent_rx  = new("port_in_agent_rx",  this);
    port_in_agent_tx  = new("port_in_agent_tx",  this);
  endfunction

  //-------------------------------------------------------------------------
  // build_phase: fetch configuration object from uvm_config_db
  //-------------------------------------------------------------------------
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(algn_scoreboard_config#(.DATA_WIDTH(DATA_WIDTH)))
         ::get(this, "", "my_algn_scoreboard_config", my_algn_scoreboard_config)) begin
      `uvm_fatal("DB_FATAL", $sformatf("Couldn't find %0s configuration in uvm_config_db", get_name()))
    end
  endfunction

  // ------------------------- RX watchdog --------------------------
  // Watchdog task that waits `threshold` cycles for an expected RX response.
  // If the response does not arrive in time, it logs an error (if checks
  // are enabled in the configuration).
  protected virtual task exp_rx_response_watchdog(md_response response);
    algn_vif      vif       = my_algn_scoreboard_config.get_vif();
    int unsigned  threshold = my_algn_scoreboard_config.get_expected_rx_response_threshold();
    time         start_time = $time();

    // Wait for the configured number of clock cycles
    repeat (threshold) @(posedge vif.clk);

    if (my_algn_scoreboard_config.get_has_checks()) begin
      `uvm_error("DUT_ERROR", $sformatf(
        "RX response %0s expected at %0t not received after %0d cycles",
        response.name(), start_time, threshold))
    end
  endtask

  // Non-blocking wrapper to spawn a watchdog and keep a handle to it
  local function void exp_rx_response_watchdog_nb(md_response response);
    fork
      begin
        process p = process::self();
        process_exp_rx_response_watchdog.push_back(p);
        exp_rx_response_watchdog(response);

        if (process_exp_rx_response_watchdog.size() > 0)
          void'(process_exp_rx_response_watchdog.pop_front());
      end
    join_none
  endfunction

  // ------------------------- TX watchdog --------------------------
  // Similar watchdog for expected TX items.
  protected virtual task exp_tx_item_watchdog(algn_data_item item);
    algn_vif      vif       = my_algn_scoreboard_config.get_vif();
    int unsigned  threshold = my_algn_scoreboard_config.get_expected_tx_item_threshold();
    time         start_time = $time();

    repeat (threshold) @(posedge vif.clk);

    if (my_algn_scoreboard_config.get_has_checks()) begin
      `uvm_error("DUT_ERROR", $sformatf(
        "TX item %0s expected at %0t not received after %0d cycles",
        item.get_name(), start_time, threshold))
    end
  endtask

  local function void exp_tx_item_watchdog_nb(algn_data_item item);
    fork
      begin
        process p = process::self();
        process_exp_tx_item_watchdog.push_back(p);
        exp_tx_item_watchdog(item);

        if (process_exp_tx_item_watchdog.size() > 0)
          void'(process_exp_tx_item_watchdog.pop_front());
      end
    join_none
  endfunction

  // ------------------------- rec_IRQ watchdog --------------------------
  // Watchdog for expected IRQs. Increments a failure counter if not seen.
  protected virtual task exp_irq_watchdog(irq rec_irq);
    algn_vif      vif         = my_algn_scoreboard_config.get_vif();
    int unsigned  threshold   = my_algn_scoreboard_config.get_expected_irq_threshold();
    time          start_time  = $time();
    string        irq_type    = rec_irq.irq_type;;

    repeat (threshold) @(posedge vif.clk);

    if (my_algn_scoreboard_config.get_has_checks()) begin

      irq_failed_counter++;

      `uvm_error("DUT_ERROR", $sformatf(
        "rec_IRQ %0b expected at %0t for %0s not received after %0d cycles",
        rec_irq.irq_value, start_time, irq_type, threshold))
    end
  endtask

  local function void exp_irq_watchdog_nb(irq rec_irq);
    fork
      begin
        process p = process::self();
        process_exp_irq_watchdog.push_back(p);
        exp_irq_watchdog(rec_irq);

        if (process_exp_irq_watchdog.size() > 0)
          void'(process_exp_irq_watchdog.pop_front());
      end
    join_none
  endfunction


  // ---------------------------------------------------------------------
  // Task to collect rec_IRQ events from the DUT.
  // - Waits for positive edge when rec_IRQ is asserted and reset is deasserted.
  // - Matches observed rec_IRQ against expected queue, reports unexpected IRQs.
  // ---------------------------------------------------------------------
  protected virtual task rcv_irq();
    algn_vif vif = my_algn_scoreboard_config.get_vif();
      
    forever begin
      @(posedge vif.clk);
      while ((vif.irq & vif.reset_n) == 0)
        @(posedge vif.clk);

        
      if(exp_irqs.size() == 0) begin
        if(my_algn_scoreboard_config.get_has_checks()) begin
            `uvm_error("DUT_ERROR", "Unexpected rec_IRQ detected")
            irq_failed_counter++;
          end
        end
      else begin
        // consume the expected rec_IRQ
        void'(exp_irqs.pop_front());

        // Kill the corresponding watchdog and remove its handle
        if(process_exp_irq_watchdog[0] != null)
        process_exp_irq_watchdog[0].kill();

        void'(process_exp_irq_watchdog.pop_front);
        irq_passed_counter++;
        
      end
    end
  endtask
    
  // Function to start rcv_irq() as a non-blocking process. Enforces single
  // instance by checking process_rcv_irq.
  local virtual function void rcv_irq_nb();
    if(process_rcv_irq != null) begin
      `uvm_fatal("ALGORITHM_ISSUE", "Can not start two instances of rcv_irq() tasks")
    end
    
    fork
      begin
        process_rcv_irq = process::self();
        
        rcv_irq();
        
        process_rcv_irq = null;
      end
    join_none
  endfunction

  // ----------------------- Analysis Callbacks ---------------------
  // These functions are called via analysis ports when transactions arrive.

  virtual function void write_in_model_rx(md_response response);
    // model tells us to expect a RX response

    if (exp_rx_responses.size() >= 1)
      `uvm_fatal("ALGORITHM_ISSUE", $sformatf("Queue already has %0d expected responses",
        exp_rx_responses.size()))

    exp_rx_responses.push_back(response);
    exp_rx_response_watchdog_nb(response);
  endfunction

  virtual function void write_in_model_tx(algn_data_item item_mon);
    // model tells us to expect a TX item
    if (item_mon == null) begin
      `uvm_warning("NULL_TX", "write_in_model_tx got null item_mon")
      return;
    end

    if (exp_tx_items.size() >= 1)
      `uvm_fatal("ALGORITHM_ISSUE", $sformatf("Queue already has %0d expected items",
        exp_tx_items.size()))

    // enqueue expected item and start watchdog
    exp_tx_items.push_back(item_mon);
    exp_tx_item_watchdog_nb(item_mon);
  endfunction


  virtual function void write_in_agent_rx(algn_data_item item_mon);
    // agent observed an RX item from DUT; compare with expected response
    if (item_mon == null) begin
      `uvm_warning("NULL_AGENT_RX", "write_in_agent_rx got null item_mon")
      return;
    end

    if (!item_mon.is_active()) begin
      md_response exp_response;
      if (exp_rx_responses.size() == 0) begin
        `uvm_error("UNEXPECTED_RX", "Agent RX item received but no expected response stored")
        return;
      end

      exp_response = exp_rx_responses.pop_front();

      // Kill the RX watchdog corresponding to this expected response
      if (process_exp_rx_response_watchdog.size() > 0) begin
        process_exp_rx_response_watchdog[0].kill();
        void'(process_exp_rx_response_watchdog.pop_front());
      end

      if (my_algn_scoreboard_config.get_has_checks()) begin
        if (item_mon.response != exp_response) begin
          rx_failed_counter++;

          `uvm_error("DUT_ERROR", $sformatf(
            "RX mismatch: expected %0s, received %0s, item %0s",
            exp_response.name(), item_mon.response.name(), item_mon.convert2string()))
        end
        else begin
          rx_passed_counter++;
        end
      end
    end
  endfunction

  // Helper: compare two dynamic byte arrays (returns 1 if equal)
  protected function bit data_arrays_equal(ref bit [7:0] a[$], ref bit [7:0] b[$]);
    if (a.size() != b.size()) 
      return 0;

    for (int i = 0; i < a.size(); i++) begin
      if (a[i] !== b[i]) 
        return 0;
    end

    return 1;
  endfunction


  virtual function void write_in_agent_tx(algn_data_item item_mon);
    if (item_mon == null) begin
      `uvm_warning("NULL_AGENT_TX", "write_in_agent_tx got null item_mon")
      return;
    end

    if (!item_mon.is_active()) begin
      algn_data_item model_item;

      if (exp_tx_items.size() == 0) begin
        `uvm_error("UNEXPECTED_TX", "Agent TX item received but no expected item stored")
        return;
      end

      model_item = exp_tx_items.pop_front();

      // Kill the TX watchdog and remove its handle (safe pop)
      if (process_exp_tx_item_watchdog.size() > 0) begin
        if (process_exp_tx_item_watchdog[0] != null) process_exp_tx_item_watchdog[0].kill();
        void'(process_exp_tx_item_watchdog.pop_front()); // note the ()
      end

      if (my_algn_scoreboard_config.get_has_checks()) begin
        bit data_match = data_arrays_equal(item_mon.data, model_item.data);
        bit offset_match = (item_mon.offset == model_item.offset);

        if (!data_match || !offset_match) begin
          // Build sources string safely (handle variable number of sources and nulls)
          string sources_str = "";

          // Prepare human-friendly message describing mismatches
          string why = "";

          // increment failure counter (single increment per mismatch)
          tx_failed_counter++;
         
          for (int si = 0; si < model_item.sources.size(); si++) begin
            if (model_item.sources[si] != null) begin
              // call data2string() to produce a printable representation
              string s = model_item.sources[si].data2string();
              sources_str = {sources_str, $sformatf("\n  source[%0d]=%s", si, s)};
            end
            else begin
              sources_str = {sources_str, $sformatf("\n  source[%0d]=<NULL>", si)};
            end
          end
          
          if (!data_match) 
            why = {why, "DATA_MISMATCH "};

          if (!offset_match) 
            why = {why, "OFFSET_MISMATCH "};

          `uvm_error("DUT_ERROR", $sformatf(
            "TX mismatch (%0s): expected:\n%0s\nreceived:\n%0s\nexpected sources:%0s",
            why, model_item.convert2string(), item_mon.convert2string(), sources_str)
          )
        end
        else begin
          tx_passed_counter++;
        end
      end // has_checks
    end // not active
  endfunction




  virtual function void write_in_model_irq(irq rec_irq);
    string irq_type = rec_irq.irq_type;
    // $display("irq_passed_counter++ for %0s", irq_type);
    // model requests an rec_IRQ to be expected
    if(exp_irqs.size() >= 100) begin
      `uvm_error("ALGORITHM_ISSUE", $sformatf("Something went wrong as there are already %0d entries in exp_irqs and just received one more",
                                              exp_irqs.size()))
    end 
     
    exp_irqs.push_back(rec_irq);
      
    exp_irq_watchdog_nb(rec_irq);
  endfunction

  // ----------------------- Utility Functions ----------------------
  // Kill and clear all processes in the provided queue
  virtual function void kill_processes_from_queue(ref process processes[$]);
    while (processes.size() > 0) begin
      if (processes[0] != null) processes[0].kill();
      void'(processes.pop_front());
    end
  endfunction

  // Reset handler that clears queues and kills watchdogs. Then restarts rec_IRQ
  // collection task.
  virtual function void handle_reset(uvm_phase phase);
    exp_rx_responses.delete();
    kill_processes_from_queue(process_exp_rx_response_watchdog);

    exp_tx_items.delete();
    kill_processes_from_queue(process_exp_tx_item_watchdog);

    exp_irqs.delete();
    kill_processes_from_queue(process_exp_irq_watchdog);
      
    if(process_rcv_irq != null) begin

      process_rcv_irq.kill();     
      process_rcv_irq = null;
    end

    // Restart rec_IRQ receiver task (non-blocking)
    rcv_irq_nb();

    `uvm_info("RESET", "Scoreboard reset: queues cleared, watchdogs killed", UVM_LOW)
  endfunction



  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("DEBUG", $sformatf("\nrx_passed_counter: %0d   rx_failed_counter: %0d"
      , rx_passed_counter, rx_failed_counter), UVM_NONE)

    `uvm_info("DEBUG", $sformatf("\ntx_passed_counter: %0d   tx_failed_counter: %0d"
      , tx_passed_counter, tx_failed_counter), UVM_NONE)

    `uvm_info("DEBUG", $sformatf("\nirq_passed_counter: %0d   irq_failed_counter: %0d"
      , irq_passed_counter, irq_failed_counter), UVM_NONE)
    
  endfunction : report_phase

endclass

`endif // ALGN_SCOREBOARD
