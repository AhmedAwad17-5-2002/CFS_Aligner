////////////////////////////////////////////////////////////////////////////////
// File:        algn_model.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-06
// Title:       Detailed Description / Design Notes (paste this at the top)
// 
// Description:
//
// Purpose 
// -------
// This file implements `algn_model`, a UVM component that models the register
// layer and the high-level runtime behaviour of the DUT alignment controller.
// It is not RTL — it is a software testbench model used to:
//   1. Mirror and predict the DUT RAL register values (status, IRQs, control).
//   2. Maintain transaction-level RX/TX FIFOs and an intermediate `buffer` of
//      fragments that the align algorithm consumes.
//   3. Validate incoming accesses and predict MD_OKAY / MD_ERR responses.
//   4. Assemble fixed-size TX packets from possibly-split RX fragments.
//   5. Emit expected IRQ events to the rest of the testbench via analysis ports.
//   6. Provide a clear, deterministic reset and background-task lifecycle to
//      match the DUT behaviour for verification and scoreboard checks.
//
// Scope & Responsibilities
// -----------------------
// - The model receives notifications from bus monitors/agents via the
//   write_in_rx() and write_in_tx() APIs. These calls are the external entry
//   points. The model does not directly drive the DUT signals; it observes
//   them via the virtual interface (algn_vif) when synchronising with RTL
//   FIFO push/pop events.
// - The model keeps mirrored copies of RAL fields using the UVM register layer
//   (my_reg_block). It predicts register updates using the RAL predict() API
//   and reads mirrored values with get_mirrored_value().
// - Background tasks (build_buffer, align, tx_ctrl, send_exp_irq) run
//   concurrently as single instances and are controlled by *_nb() starter
//   functions which record process pointers to prevent multiple instances.
// - The model is responsible for safe process kill/restart during reset by
//   using kill_process() and handle_reset().
//
// High-level Architecture & Dataflow
// ---------------------------------
//  RX agent/monitor  -> write_in_rx(item)  -> (validate) -> push_to_rx_fifo_nb()
//       |                             \-> port_out_rx(MD_ERR) on illegal access
//       v
//   rx_fifo (uvm_tlm_fifo)  --pop--> build_buffer() -> buffer (algn_data_item queue)
//       buffer (producer)                          (consumer)
//       <-- align() consumes fragments -- creates tx_item(s) --> push_to_tx_fifo()
//                                                            tx_fifo (uvm_tlm_fifo)
// tx_ctrl() pops tx_fifo -> port_out_tx.write(item) -> waits for tx_complete trigger
// write_in_tx(item) (from TX monitor) -> triggers tx_complete when transaction ends
//
// Key Tasks and Roles
// -------------------
// build_buffer:
//   - Runs forever in background and moves algn_data_item handles from rx_fifo
//     into the local buffer[] while respecting CTRL.SIZE limits.
// align:
//   - Samples CTRL.SIZE and CTRL.OFFSET (mirrored values).
//   - Uses uvm_wait_for_nba_region() to ensure NBA ordering so that any
//     value pushed by build_buffer on the same posedge is visible.
//   - Assembles TX transactions of exactly CTRL.SIZE bytes by concatenating
//     buffer fragments. When a fragment would overflow the target TX item,
//     split() is invoked and fragments are reinserted so ordering and offsets
//     are preserved.
// tx_ctrl:
//   - Pops completed tx_items from tx_fifo, writes them to port_out_tx and
//     then waits on tx_complete (signalled by write_in_tx from the TX monitor).
// send_exp_irq:
//   - Writes exp_irq.irq_value values to port_out_irq on negedge clock when exp_irq.irq_value is set.
//
// Synchronization & RAL Ordering Notes
// ------------------------------------
// - NBA ordering: build_buffer() performs rx_fifo.get() on the positive clock
//   edge; align() calls uvm_wait_for_nba_region() before consuming buffer.
//   This ensures the model observes the same ordering the DUT would present
//   after register mirroring has occurred in the NBA update region.
// - For synchronising with RTL FIFO events, helper tasks (sync_push_to_rx_fifo,
//   sync_pop_from_rx_fifo, sync_push_to_tx_fifo, sync_pop_from_tx_fifo) either
//   wait for the vif signal (e.g., vif.rx_fifo_push) or time out while checking
//   mirrored STATUS fields. Timeouts emit warnings rather than fatals so that
//   simulations can proceed while flagging potential mismatches.
// - All mirrored register reads use get_mirrored_value(); register updates use
//   predict() to keep the model's mirrors consistent without performing actual
//   bus writes (the RAL model and tests are responsible for real register writes).
//
// RAL Registers Referenced (important registers used by code)
// -----------------------------------------------------------
// - my_reg_block.CTRL.SIZE      : Number of bytes per aligned TX packet.
// - my_reg_block.CTRL.OFFSET    : Byte offset inside the aligned word.
// - my_reg_block.CTRL.CLR       : Control clear field used with callback to reset counters.
// - my_reg_block.STATUS.RX_LVL  : Mirrored RX FIFO level used for sync logic.
// - my_reg_block.STATUS.TX_LVL  : Mirrored TX FIFO level used for sync logic.
// - my_reg_block.STATUS.CNT_DROP: Drop counter (incremented on malformed accesses).
// - my_reg_block.IRQEN.*        : IRQ enable mirrors for different IRQ sources.
// - my_reg_block.IRQ.*          : IRQ status mirrors predicted by the model.
//
// Important APIs (public functions)
// --------------------------------
// - write_in_rx(algn_data_item item)
//     Called by RX monitor when an incoming transaction is observed.
//     The model validates and either writes MD_ERR to port_out_rx or enqueues the
//     item via push_to_rx_fifo_nb() which starts a background push_to_rx_fifo().
// - write_in_tx(algn_data_item item)
//     Called by TX monitor when an outgoing transaction completes. If the
//     transaction is inactive (ended) the model triggers tx_complete so tx_ctrl
//     can proceed to the next item.
// - handle_reset(uvm_phase)
//     Hard resets the RAL model, kills background processes, flushes FIFOs, clears
//     buffer[], and restarts background tasks. This function is the canonical
//     reset-entry point and should be registered/used by the environment.
//
// Concurrency & Safety Mechanisms
// ------------------------------
// - Each background activity has a process pointer (process_align, etc.). The
//   *_nb() starter functions check these pointers and `uvm_fatal` if a duplicate
//   start is attempted — protecting against accidental multiple instantiations.
// - kill_process(ref process p) is the safe helper to kill a process and null it.
// - Several helper set_* functions (set_rx_fifo_full, set_tx_fifo_empty, etc.)
//   run in small fork..join_none helper tasks and store their own process pointer
//   so a subsequent set can safely detect / kill previous ones via kill_set_*.
// - The model uses `uvm_info`, `uvm_warning`, and `uvm_fatal` consistently for
//   diagnostics — fatal is used only for unrecoverable invariants.
//
// Fragmentation & Timekeeping
// ---------------------------
// - split(num_bytes, item, ref items[$]) preserves important metadata:
//     * offset, prev_item_delay, length, response
//     * begin_tr()/end_tr() timestamps are copied so latency and ordering checks
//       by the scoreboard remain meaningful.
// - tx_item creation uses factory (algn_data_item::type_id::create) with unique
//   names so traces and factory hooks remain useful.
//
// Integration Requirements / Assumptions
// -------------------------------------
// - uvm_config_db must contain a model_config object under the key "my_model_config"
//   providing:
//     * get_vif() -> returns algn_vif virtual interface with signals:
//         - clk, rx_fifo_push, rx_fifo_pop, tx_fifo_push, tx_fifo_pop
//     * get_algn_data_width() -> data width in bits for CTRL calculations
// - The register block `my_reg_block` must exist and be created as `my_reg_block`
//   with the fields referenced above (CTRL, STATUS, IRQEN, IRQ). The RAL model
//   should be built and locked during build_phase.
// - Default rx_fifo/tx_fifo depths are set to 8 in the model but can be modified
//   by changing their constructors or via a configuration mechanism.
//
// Error Handling & Diagnostic Tips
// -------------------------------
// - Warnings are emitted when model and RTL appear to desynchronize (timeouts).
//   Use these warnings as starting points for RTL vs testbench investigations.
// - Fatal errors indicate invariant violations (e.g., starting two instances of
//   a background task) and should be fixed in the testbench design/flow.
// - Useful debug points: log values of my_reg_block.STATUS.* mirrors and FIFOs
//   sizes when you see sync warnings to understand which side lagged.
//
// Extensibility & Hooks
// ---------------------
// - To extend behaviour (e.g., support more IRQ sources), add new set_*/inc_*/
//   helper functions and update the places that call them (inc_current_rx_lvl, etc.).
// - If the DUT supports multiple data widths or optional features, expand
//   model_config and use it to conditionally enable behavior.
// - All algn_data_item creation uses the factory; users can extend algn_data_item
//   and register with the factory to attach additional fields/behaviours.
//
// Recommended Usage / Startup Sequence
// -----------------------------------
// 1. Configure uvm_config_db with `my_model_config` and ensure `my_reg_block` is
//    available for creation by the model.
// 2. Create `algn_model` in the testbench build_phase (factory or explicit).
// 3. Allow the model to run handle_reset() on reset release (this implementation
//    already restarts background tasks there).
// 4. Ensure monitors call write_in_rx() and write_in_tx() appropriately.
// 5. Scoreboard or monitors should connect to port_out_rx, port_out_tx, port_out_irq.
//
// Test & Verification Suggestions
// ------------------------------
// - Unit test the split() helper with edge cases: splitting 1 byte, splitting
//   at size-1 boundary, and invalid arguments (0 or >= size) to verify fatals.
// - Create scenarios where mirrored STATUS values lag and verify that the
//   sync_* helpers emit warnings rather than hiding failure modes.
// - Test reset flow repeatedly to ensure processes are properly killed and
//   restarted and that no zombie processes remain.
// - Add assertions in the agent/monitors to cross-check that port_out_tx items
//   match the assembled items produced by the model.
//
// Known Limitations & Caveats
// ---------------------------
// - This model does not perform bus-level writes to the DUT RAL to change
//   registers — it predicts mirror values via predict() only. Tests must still
//   perform real register writes if they are intended to affect DUT behavior.
// - The model assumes single-producer single-consumer patterns for buffer[].
//   If multiple concurrent producers are added, additional synchronization
//   mechanisms (events or semaphores) are required.
// - The sync_* tasks rely on specific vif signal names; mismatch will prevent
//   synchronization and cause warnings.
//
// Change Log (short)
// ------------------
// - 2025-09-26 : Full polished algn_model implementation with robust task
//                lifecycle, NBA ordering, RAL predict usage and detailed
//                diagnostics (Author: Ahmed Awad-Allah Mohamed).
//
// End of detailed description header.
////////////////////////////////////////////////////////////////////////////////


`ifndef ALGN_MODEL
`define ALGN_MODEL

// ---------------------------------------------------------------------------
// =========== Flow Overview (added explanatory comments) =====================
// This file implements a software model that mirrors DUT behaviour for
// - RX: receives items from the RX agent -> validates -> either reports an
//   expected error or enqueues into a software RX FIFO (rx_fifo).
// - BUFFER: a background builder (build_buffer) moves items from rx_fifo into
//     an intermediate `buffer` queue that the align logic consumes.
// - ALIGN: the align task collects bytes from `buffer` and assembles fixed-size
//     TX packets (CTRL.SIZE). It splits fragments when needed and pushes
//     completed tx items into tx_fifo.
// - TX_CTRL: tx_ctrl pops from tx_fifo, notifies the scoreboard via port_out_tx
//     and waits for tx completion signalled by write_in_tx (tx_complete).
// IRQs are predicted and written to port_out_irq based on mirrored register
// values (IRQEN) and status fields. Process pointers ensure single background
// instances and are killed/restarted safely in handle_reset().
// ============================================================================

// Declare analysis imp macros (suffixes used below: _in_rx, _in_tx)
// (Assumes these macros are provided in your environment as in your other files)
`uvm_analysis_imp_decl(_in_rx)
`uvm_analysis_imp_decl(_in_tx)

//------------------------------------------------------------------------------
// UVM Component: algn_model
//------------------------------------------------------------------------------
// - Extends uvm_component so it can participate in the UVM testbench hierarchy.
// - Instantiates and builds a my_reg_block (the actual UVM register block).
// - Locks the model to prevent further structural changes after build.
// - Maintains an RX FIFO model and an intermediate buffer queue.
// - Exposes analysis ports for RX/TX responses and IRQ signalling.
// - Implements uvm_ext_reset_handler_if to handle design resets.
//------------------------------------------------------------------------------
class algn_model #(int unsigned DATA_WIDTH = `DATA_WIDTH) extends uvm_component
    implements uvm_ext_reset_handler_if;

    //--------------------------------------------------------------------------
    // Register block instance
    //--------------------------------------------------------------------------
    // Top-level UVM register block that mirrors the DUT’s register map.
    reg_block  my_reg_block;

    // Optional configuration object carrying environment-specific settings.
    model_config my_model_config;

    // Callback object instance used to clear CNT_DROP field when CTRL.CLR is written.
    clr_cnt_drop cbs;

    //--------------------------------------------------------------------------
    // Analysis ports & FIFOs
    //--------------------------------------------------------------------------
    // Input analysis implementation ports for receiving items from monitors/agents.
    uvm_analysis_imp_in_rx#(algn_data_item, algn_model) port_in_rx;
    uvm_analysis_imp_in_tx#(algn_data_item, algn_model) port_in_tx;
    //Port for sending the split information
    uvm_analysis_port#(algn_split_info) port_out_split_info;

    // Output analysis ports: expected RX response, TX item, IRQ flag.
    uvm_analysis_port#(md_response) port_out_rx;
    uvm_analysis_port#(algn_data_item) port_out_tx;
    uvm_analysis_port#(irq) port_out_irq;

    //--------------------------------------------------------------------------
    // Local data structures
    //--------------------------------------------------------------------------

    // Model of the RX FIFO (transaction-level)
    protected uvm_tlm_fifo#(algn_data_item) rx_fifo;
    // Model of the TX FIFO (transaction-level)
    protected uvm_tlm_fifo#(algn_data_item) tx_fifo;

    // Intermediate queue (array of handles) containing items ready for alignment
    protected algn_data_item buffer[$];

    // Pointer to the process of the task build_buffer()
    local process process_build_buffer;
    // Pointer to the process of the task push_to_rx_fifo()
    local process process_push_to_rx_fifo;
    // Pointer to the process of the task align()
    local process process_align;
    // Pointer to the process of the task tx_ctrl()
    local process process_tx_ctrl;

    // Event to synchronize the completion of the TX transaction
    protected uvm_event tx_complete;

    // Buffered value of the expected interrupt request
    protected irq exp_irq;

    // Pointer processes from inside set_xxx helpers
    local process process_set_rx_fifo_empty;
    local process process_set_rx_fifo_full;
    local process process_set_tx_fifo_empty;
    local process process_set_tx_fifo_full;

    // Pointer to the process of the task send_exp_irq()
    local process process_send_exp_irq;

    //--------------------------------------------------------------------------
    // UVM Factory Registration
    //--------------------------------------------------------------------------
    `uvm_component_param_utils(algn_model#(.DATA_WIDTH(DATA_WIDTH)))

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    // name   : unique component name in the UVM hierarchy
    // parent : parent component handle
    function new(string name = "algn_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    // - Creates the top-level register block if it hasn’t been created yet.
    // - Builds the full register hierarchy.
    // - Locks the model to prevent structural changes after build.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (my_reg_block == null) begin
            // Create the register block via the factory
            my_reg_block = reg_block::type_id::create("my_reg_block", this);

            // Build internal register hierarchy
            my_reg_block.build();

            // Lock the model to freeze its structure
            my_reg_block.lock_model();

            // Create callback instance used to clear CNT_DROP on CTRL.CLR writes
            cbs = clr_cnt_drop::type_id::create("cbs", this);
        end

        // Fetch configuration from uvm_config_db (fails fatally if not found)
        if(!uvm_config_db#(model_config #(.DATA_WIDTH(DATA_WIDTH)))::get(this, "","my_model_config", my_model_config)) begin
            `uvm_fatal("DB_FATAL", $sformatf("Couldn't find %0s configuration in db", get_name()))
        end

        // Create analysis imp/ports and fifo
        port_in_rx   = new("port_in_rx", this);
        port_in_tx   = new("port_in_tx", this);
        port_out_rx  = new("port_out_rx", this);
        port_out_tx  = new("port_out_tx", this);
        port_out_irq = new("port_out_irq", this);
        port_out_split_info = new("port_out_split_info", this);

        // Default small FIFO depths (can be changed via config)
        rx_fifo      = new("rx_fifo", this, 8);
        tx_fifo      = new("tx_fifo", this, 8);

        tx_complete = new("tx_complete");
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Connect Phase
    //--------------------------------------------------------------------------
    // - Hooks up callbacks or other connections once components are built.
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect the callback’s field pointer to STATUS.CNT_DROP
        cbs.cnt_drop = my_reg_block.STATUS.CNT_DROP;

        // Register the callback on the CTRL.CLR field so when CLR is written the callback fires
        uvm_callbacks#(uvm_reg_field, clr_cnt_drop)::add(my_reg_block.CTRL.CLR, cbs, UVM_APPEND);
    endfunction

    //--------------------------------------------------------------------------
    // End of Elaboration Phase
    //--------------------------------------------------------------------------
    // - Apply configuration settings after build but before simulation starts.
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);

        // Configure register block (data width) from the model config object
        my_reg_block.CTRL.SET_DATA_WIDTH(my_model_config.get_algn_data_width());
    endfunction

    //--------------------------------------------------------------------------
    // Helper: kill_process
    // - Safely kill a process handle and null it to avoid stale handles.
    //--------------------------------------------------------------------------
    virtual function void kill_process(ref process p);
        if(p != null) begin
            p.kill();
            p = null;
        end
    endfunction


    //Function to determine if the model is empty
    virtual function bit is_empty();
        if(rx_fifo.used() != 0) begin
            return 0;
        end 
      
        if(tx_fifo.used() != 0) begin
            return 0;
        end 
      
        if(buffer.size() != 0) begin
            return 0;
        end 
      
      return 1;
    endfunction

    //--------------------------------------------------------------------------
    // Functions to kill specific setter processes (used internally)
    // Each uses an NBA wait to avoid killing in the middle of UVM NBA-sensitive code.
    //--------------------------------------------------------------------------
    protected virtual function void kill_set_rx_fifo_full();
        fork
            begin
                uvm_wait_for_nba_region();
                // #(1ps);
                kill_process(process_set_rx_fifo_full);
            end
        join_none
    endfunction

    protected virtual function void kill_set_rx_fifo_empty();
        fork
            begin
                uvm_wait_for_nba_region();
                // #(1ps);
                kill_process(process_set_rx_fifo_empty);
            end
        join_none
    endfunction

    protected virtual function void kill_set_tx_fifo_full();
        fork
            begin
                uvm_wait_for_nba_region();
                // #(1ps);
                kill_process(process_set_tx_fifo_full);
            end
        join_none
    endfunction

    protected virtual function void kill_set_tx_fifo_empty();
        fork
            begin
                uvm_wait_for_nba_region();
                // #(1ps);
                kill_process(process_set_tx_fifo_empty);
            end
        join_none
    endfunction

//Task for trying to synchronize a push to RX FIFO with RTL
    protected virtual task sync_push_to_rx_fifo();
      algn_vif vif = my_model_config.get_vif();
      
      fork
        begin
          fork
            begin
              @(posedge vif.clk iff(vif.rx_fifo_push)); 
            end
            begin
              int rx_level;
              repeat(10) begin
                    rx_level = my_reg_block.STATUS.RX_LVL.get_mirrored_value();
                    @(posedge vif.clk iff(rx_level < rx_fifo.size())); 
              end
              
              `uvm_warning("DUT_WARNING", "RX FIFO push did NOT synchronize with RTL")
            end
          join_any
          
          disable fork;
        end
      join
    endtask
    
    //Task for trying to synchronize a pop from RX FIFO with RTL
    protected virtual task sync_pop_from_rx_fifo();
      algn_vif vif = my_model_config.get_vif();
      
      fork
        begin
          fork
            begin
              @(posedge vif.clk iff(vif.rx_fifo_pop)); 
            end
            begin
                int rx_level;
                int tx_level;
                repeat(10) begin
                    rx_level = my_reg_block.STATUS.RX_LVL.get_mirrored_value();
                    tx_level = my_reg_block.STATUS.TX_LVL.get_mirrored_value();
                    @(posedge vif.clk iff((rx_level > 0) && (tx_level < tx_fifo.size()))); 
                end
              
              `uvm_warning("DUT_WARNING", "RX FIFO pop did NOT synchronize with RTL")
            end
          join_any
          
          disable fork;
        end
      join
    endtask
    
    //Task for trying to synchronize a push to TX FIFO with RTL
    protected virtual task sync_push_to_tx_fifo();
      algn_vif vif = my_model_config.get_vif();
      
      fork
        begin
          fork
            begin
              @(posedge vif.clk iff(vif.tx_fifo_push)); 
            end
            begin
                int tx_level;
                repeat(10) begin
                    tx_level = my_reg_block.STATUS.TX_LVL.get_mirrored_value();
                    @(posedge vif.clk iff(tx_level < tx_fifo.size())); 
                end
              
              `uvm_warning("DUT_WARNING", "TX FIFO push did NOT synchronize with RTL")
            end
          join_any
          
          disable fork;
        end
      join
    endtask
    
    //Task for trying to synchronize a pop from TX FIFO with RTL
    protected virtual task sync_pop_from_tx_fifo();
      algn_vif vif = my_model_config.get_vif();
      
      fork
        begin
          fork
            begin
             @(posedge vif.clk iff(vif.tx_fifo_pop)); 
            end
            begin
                int tx_level;
                repeat(200) begin
                    tx_level = my_reg_block.STATUS.TX_LVL.get_mirrored_value();
                    @(posedge vif.clk iff(tx_level > 0)); 
                end
              
              `uvm_warning("DUT_WARNING", "TX FIFO pop did NOT synchronize with RTL")
            end
          join_any
          
          disable fork;
        end
      join
    endtask



    // //Task for trying to synchronize a pop from TX FIFO with RTL
    // protected virtual task sync_max_drop();
    //   algn_vif vif = my_model_config.get_vif();
      
    //   fork
    //     begin
    //       fork
    //         begin
    //          @(posedge vif.clk iff(vif.tx_fifo_pop)); 
    //         end
    //         begin
    //             int tx_level;
    //             repeat(200) begin
    //                 tx_level = my_reg_block.STATUS.TX_LVL.get_mirrored_value();
    //                 @(posedge vif.clk iff(tx_level > 0)); 
    //             end
              
    //           `uvm_warning("DUT_WARNING", "TX FIFO pop did NOT synchronize with RTL")
    //         end
    //       join_any
          
    //       disable fork;
    //     end
    //   join
    // endtask
    



    //--------------------------------------------------------------------------
    // Task: send_exp_irq
    // - Background task that writes exp_irq.irq_value values into port_out_irq on negedge clk.
    // - use send_exp_irq_nb() to start as background process.
    //--------------------------------------------------------------------------
    protected virtual task send_exp_irq();
        algn_vif vif = my_model_config.get_vif();

        forever begin
            @(negedge vif.clk);

            if (exp_irq.irq_value == 1) begin
                port_out_irq.write(exp_irq);
                exp_irq.irq_value = 0;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Function: send_exp_irq_nb
    // - Non-blocking starter for send_exp_irq()
    //--------------------------------------------------------------------------
    local virtual function void send_exp_irq_nb();
        if (process_send_exp_irq != null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "Can not start two instances of send_exp_irq() tasks")
        end

        fork
            begin
                process_send_exp_irq = process::self();
                send_exp_irq();
                process_send_exp_irq = null;
            end
        join_none
    endfunction

    //--------------------------------------------------------------------------
    // Function: get_exp_response
    // Determine expected response for an incoming algn_data_item according to
    // the current configuration and register values.
    // Returns MD_OKAY or MD_ERR.
    //--------------------------------------------------------------------------
    protected virtual function md_response get_exp_response(algn_data_item item);
        // Size of the access is 0 -> invalid
        if (item.data.size() == 0) begin
            return MD_ERR;
        end

        // Illegal combination between size and offset:
        // (aligner data width + offset) % size != 0
        if (((my_model_config.get_algn_data_width() / 8) + item.offset) % item.data.size() != 0) begin
            return MD_ERR;
        end

        // Illegal combination between size and offset:
        // size + offset > aligner data width
        if (item.offset + item.data.size() > (my_model_config.get_algn_data_width() / 8)) begin
            return MD_ERR;
        end

        return MD_OKAY;
    endfunction

    //--------------------------------------------------------------------------
    // Function: set_max_drop
    // - Predicts IRQ.MAX_DROP bit and writes an IRQ event if enabled.
    //--------------------------------------------------------------------------
    protected virtual function void set_max_drop();
        void'(my_reg_block.IRQ.MAX_DROP.predict(1));

        `uvm_info("CNT_DROP", $sformatf("Drop counter reached max value - %0s: %0d",
                                   my_reg_block.IRQEN.MAX_DROP.get_full_name(),
                                   my_reg_block.IRQEN.MAX_DROP.get_mirrored_value()), UVM_MEDIUM)

        if (my_reg_block.IRQEN.MAX_DROP.get_mirrored_value() == 1) begin
            // port_out_irq.write(1);
            exp_irq.irq_value = 1;
            $display("IRQ = %0b",exp_irq.irq_value);
            exp_irq.irq_type = "max_drop";
        end
    endfunction

    //--------------------------------------------------------------------------
    // Function: inc_cnt_drop
    // - Increment STATUS.CNT_DROP when an error is detected and handle max case.
    //--------------------------------------------------------------------------
    protected virtual function void inc_cnt_drop(md_response response);
        uvm_reg_data_t max_value = ('h1 << my_reg_block.STATUS.CNT_DROP.get_n_bits()) - 1;

        if (my_reg_block.STATUS.CNT_DROP.get_mirrored_value() < max_value) begin
            
            void'(my_reg_block.STATUS.CNT_DROP.predict(my_reg_block.STATUS.CNT_DROP.get_mirrored_value() + 1));

            if (my_reg_block.STATUS.CNT_DROP.get_mirrored_value() == max_value) begin
                set_max_drop();
            end

            `uvm_info("DEBUG", $sformatf("Increment %9s: %0d due to: %0s",
                                     my_reg_block.STATUS.CNT_DROP.get_full_name(),
                                     my_reg_block.STATUS.CNT_DROP.get_mirrored_value,
                                     response.name()), UVM_NONE)
        end
        
    endfunction

    //--------------------------------------------------------------------------
    // Functions: set_rx_fifo_full / set_tx_fifo_full / set_rx_fifo_empty / set_tx_fifo_empty
    // - Predict IRQ fields and set exp_irq.irq_value if IRQEN mirrors indicate so.
    // - Run in background for a couple NBA region waits to avoid races.
    //--------------------------------------------------------------------------
    protected virtual function void set_rx_fifo_full();
        fork
            begin
                process_set_rx_fifo_full = process::self();
                repeat(2) begin
                    uvm_wait_for_nba_region();
                    // #(1ps);
                end

                void'(my_reg_block.IRQ.RX_FIFO_FULL.predict(1));

                `uvm_info("RX_FIFO", $sformatf("RX FIFO became full - %0s: %0d",
                                   my_reg_block.IRQEN.RX_FIFO_FULL.get_full_name(),
                                   my_reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value()), UVM_MEDIUM)

                if (my_reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value() === 1) begin
                    exp_irq.irq_value = 1;
                    exp_irq.irq_type = "rx_fifo_full";
                end

                process_set_rx_fifo_full = null;
            end
        join_none
    endfunction : set_rx_fifo_full

    protected virtual function void set_tx_fifo_full();
        fork
            begin
                process_set_tx_fifo_full = process::self();
                repeat(2) begin
                    uvm_wait_for_nba_region();
                    // #(1ps);
                end

                void'(my_reg_block.IRQ.TX_FIFO_FULL.predict(1));

                `uvm_info("TX_FIFO", $sformatf("TX FIFO became full - %0s: %0d",
                                   my_reg_block.IRQEN.TX_FIFO_FULL.get_full_name(),
                                   my_reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value()), UVM_MEDIUM)

                if (my_reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value() === 1) begin
                    exp_irq.irq_value = 1;
                    exp_irq.irq_type = "tx_fifo_full";
                end

                process_set_tx_fifo_full = null;
            end
        join_none
    endfunction : set_tx_fifo_full

    protected virtual function void set_rx_fifo_empty();
        fork
            begin
                process_set_rx_fifo_empty = process::self();
                repeat(2) begin
                    uvm_wait_for_nba_region();
                    // #(1ps);
                end

                void'(my_reg_block.IRQ.RX_FIFO_EMPTY.predict(1));

                `uvm_info("RX_FIFO", $sformatf("RX FIFO became empty - %0s: %0d",
                                   my_reg_block.IRQEN.RX_FIFO_EMPTY.get_full_name(),
                                   my_reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value()), UVM_MEDIUM)

                if (my_reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value() === 1) begin
                    exp_irq.irq_value = 1;
                    exp_irq.irq_type = "rx_fifo_empty";
                end

                process_set_rx_fifo_empty = null;
            end
        join_none
    endfunction : set_rx_fifo_empty

    protected virtual function void set_tx_fifo_empty();
        fork
            begin
                process_set_tx_fifo_empty = process::self();
                repeat(2) begin
                    uvm_wait_for_nba_region();
                    // #(1ps);
                end

                void'(my_reg_block.IRQ.TX_FIFO_EMPTY.predict(1));

                `uvm_info("TX_FIFO", $sformatf("TX FIFO became empty - %0s: %0d",
                                   my_reg_block.IRQEN.TX_FIFO_EMPTY.get_full_name(),
                                   my_reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value()), UVM_MEDIUM)

                if (my_reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value() === 1) begin
                    exp_irq.irq_value = 1;
                    exp_irq.irq_type = "tx_fifo_empty";
                end

                process_set_tx_fifo_empty = null;
            end
        join_none
    endfunction : set_tx_fifo_empty

    //--------------------------------------------------------------------------
    // Functions: inc_current_rx_lvl / inc_current_tx_lvl / dec_current_rx_lvl / dec_current_tx_lvl
    // - Maintain mirrored STATUS levels and trigger FIFO full/empty handlers.
    //--------------------------------------------------------------------------
    protected virtual function void inc_current_rx_lvl();
        void'(my_reg_block.STATUS.RX_LVL.predict(my_reg_block.STATUS.RX_LVL.get_mirrored_value() + 1));

        if (my_reg_block.STATUS.RX_LVL.get_mirrored_value() === rx_fifo.size()) begin
            set_rx_fifo_full();
            // $monitor("rx_fifo is full");
        end
    endfunction

    protected virtual function void inc_current_tx_lvl();
        void'(my_reg_block.STATUS.TX_LVL.predict(my_reg_block.STATUS.TX_LVL.get_mirrored_value() + 1));

        if (my_reg_block.STATUS.TX_LVL.get_mirrored_value() === tx_fifo.size()) begin
            set_tx_fifo_full();
            // $monitor("tx_fifo is full");
        end
    endfunction

    protected virtual function void dec_current_rx_lvl();
        void'(my_reg_block.STATUS.RX_LVL.predict(my_reg_block.STATUS.RX_LVL.get_mirrored_value() - 1));

        if (my_reg_block.STATUS.RX_LVL.get_mirrored_value() === 0) begin
            set_rx_fifo_empty();
            // $monitor("rx_fifo is empty");
        end
    endfunction

    protected virtual function void dec_current_tx_lvl();
        void'(my_reg_block.STATUS.TX_LVL.predict(my_reg_block.STATUS.TX_LVL.get_mirrored_value() - 1));

        if (my_reg_block.STATUS.TX_LVL.get_mirrored_value() === 0) begin
            set_tx_fifo_empty();
            // $monitor("tx_fifo is empty");
        end
    endfunction

    //--------------------------------------------------------------------------
    // Task: push_to_rx_fifo
    // - Blocking task: put item into rx_fifo, update counters, and signal expected RX response.
    // - Typically called from non-blocking wrapper push_to_rx_fifo_nb().
    //--------------------------------------------------------------------------
    protected virtual task push_to_rx_fifo(algn_data_item item);
        // $monitor("\n1- Before sync_push_to_rx_fifo @%0t", $time());
        sync_push_to_rx_fifo();

        // $monitor("\n4- After sync_push_to_rx_fifo @%0t", $time());
        if(item != null)
            rx_fifo.put(item);
        else 
            return;

        kill_set_rx_fifo_empty();

        inc_current_rx_lvl();

        `uvm_info("RX_FIFO", $sformatf("RX FIFO push - new level: %0d, pushed entry: %0s",
                                    my_reg_block.STATUS.RX_LVL.get_mirrored_value(),
                                    item.convert2string()), UVM_LOW)

        port_out_rx.write(MD_OKAY);
    endtask

    //--------------------------------------------------------------------------
    // Task: push_to_tx_fifo
    // - Blocking task: put item into tx_fifo, update counters.
    // - Typically called by align() when a tx_item completes.
    //--------------------------------------------------------------------------
    protected virtual task push_to_tx_fifo(algn_data_item item);
        // $monitor("\n1- Before sync_push_to_tx_fifo @%0t", $time());

        sync_push_to_tx_fifo();

        // $monitor("\n4- After sync_push_to_tx_fifo @%0t", $time());
        if(item != null)
            tx_fifo.put(item);
        else 
            return;

        kill_set_tx_fifo_empty();

        inc_current_tx_lvl();

        `uvm_info("TX_FIFO", $sformatf("TX FIFO push - new level: %0d, pushed entry: %0s",
                                    my_reg_block.STATUS.TX_LVL.get_mirrored_value(),
                                    item.convert2string()), UVM_LOW)
    endtask

    //--------------------------------------------------------------------------
    // Task: pop_from_rx_fifo
    // - Blocking task: get item from rx_fifo, update counters.
    //--------------------------------------------------------------------------
    protected virtual task pop_from_rx_fifo(ref algn_data_item item);
        // $monitor("\n1- Before sync_pop_from_rx_fifo @%0t", $time());
        sync_pop_from_rx_fifo();

        // initialize to null to be explicit
        // item = null;

        // $monitor("\nAfter sync_pop_from_rx_fifo @%0t", $time());
        rx_fifo.get(item); // fifo will write the handle into 'item'

        kill_set_rx_fifo_full();

        if (item == null) begin
            `uvm_error("FIFO_GET", "rx_fifo.get returned null item")
            disable fork; // or handle gracefully
        end
        dec_current_rx_lvl();
        `uvm_info("RX_FIFO", $sformatf("RX FIFO pop - new level: %0d, poped entry: %0s",
                                    my_reg_block.STATUS.RX_LVL.get_mirrored_value(),
                                    item.convert2string()), UVM_LOW)
    endtask

    //--------------------------------------------------------------------------
    // Task: pop_from_tx_fifo
    // - Blocking task: get item from tx_fifo, update counters.
    //--------------------------------------------------------------------------
    protected virtual task pop_from_tx_fifo(ref algn_data_item item);
        // $monitor("\n1- Before sync_pop_from_tx_fifo @%0t", $time());
        sync_pop_from_tx_fifo();

        // initialize to null to be explicit
        // item = null;
        // $monitor("\nAfter sync_pop_from_tx_fifo @%0t", $time());
        tx_fifo.get(item); // fifo will write the handle into 'item'

        kill_set_tx_fifo_full();

        if (item == null) begin
            `uvm_error("FIFO_GET", "tx_fifo.get returned null item")
            disable fork; // or handle gracefully
        end
        dec_current_tx_lvl();
        `uvm_info("TX_FIFO", $sformatf("TX FIFO pop - new level: %0d, poped entry: %0s",
                                    my_reg_block.STATUS.TX_LVL.get_mirrored_value(),
                                    item.convert2string()), UVM_LOW)
    endtask

    //--------------------------------------------------------------------------
    // Task: build_buffer
    // - Continuously moves items from the RX FIFO into local queue `buffer`
    //   while respecting a size limit stored in control register (CTRL.SIZE).
    //--------------------------------------------------------------------------
    protected virtual task build_buffer();
        algn_vif vif = my_model_config.get_vif();

        forever begin
            int unsigned ctrl_size      = my_reg_block.CTRL.SIZE.get_mirrored_value();
            // int unsigned ctrl_offset    = my_reg_block.CTRL.OFFSET.get_mirrored_value();
            // int unsigned rx_fifo_level  = my_reg_block.STATUS.RX_LVL.get_mirrored_value();

            int unsigned tot_bytes = 0;

            foreach (buffer[i]) begin
                if (buffer[i] != null) begin
                    tot_bytes += buffer[i].data.size();
                end
            end

            if (tot_bytes <= ctrl_size) begin
                algn_data_item rx_item;
                pop_from_rx_fifo(rx_item);
                // $monitor("\n\npop_from_rx_fifo Finished @%0t with item %0s\n\n",$time(),(rx_item!=null)?rx_item.convert2string():"null");

                if (rx_item != null) begin
                    buffer.push_back(rx_item);
                end
                else begin
                    `uvm_warning("NULL_ITEM", "pop_from_rx_fifo returned null rx_item")
                end
            end
            else begin
                @(posedge vif.clk);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Non-blocking wrappers to start background tasks safely
    //--------------------------------------------------------------------------
    local virtual function void push_to_rx_fifo_nb(algn_data_item item);
        if (process_push_to_rx_fifo != null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "Can not start two instances of push_to_rx_fifo() tasks")
        end

        fork
            begin
                process_push_to_rx_fifo = process::self();
                // if(item != null)
                    push_to_rx_fifo(item);
                // else 
                    process_push_to_rx_fifo = null;
            end
        join_none
    endfunction

    local virtual function void build_buffer_nb();
        if (process_build_buffer != null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "Can not start two instances of build_buffer() tasks")
        end

        fork
            begin
                process_build_buffer = process::self();
                build_buffer();
                process_build_buffer = null;
            end
        join_none
    endfunction

    //--------------------------------------------------------------------------
    // split: split an algn_data_item into two fragments
    //--------------------------------------------------------------------------
    protected virtual function void split(int unsigned num_bytes, algn_data_item item, ref algn_data_item items[$]);
        int original_size = item.data.size();
        if (item == null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "split() called with a null item handle")
        end
        else if (num_bytes == 0 || num_bytes >= original_size) begin
            `uvm_fatal("ALGORITHM_ISSUE",
                $sformatf("Can not split an item using num_bytes=%0d. Item data size=%0d",
                          num_bytes, original_size));
        end
        else begin
            for (int i = 0; i < 2; i++) begin
                string name = $sformatf("%s_splitted_%0d_%0d", get_name(), $urandom, i);
                algn_data_item splitted_item = algn_data_item::type_id::create(name, this);

                if (i == 0) begin
                    splitted_item.offset = item.offset;
                    for (int j = 0; j < num_bytes; j++) begin
                        splitted_item.data.push_back(item.data[j]);
                    end
                end
                else begin
                    splitted_item.offset = item.offset + num_bytes;
                    for (int j = num_bytes; j < original_size; j++) begin
                        splitted_item.data.push_back(item.data[j]);
                    end
                end

                // Copy useful metadata fields
                splitted_item.prev_item_delay = item.prev_item_delay;
                splitted_item.length          = item.length;
                splitted_item.response        = item.response;

                // Preserve transaction timestamps
                void'(splitted_item.begin_tr(item.get_begin_time()));
                if (!item.is_active()) begin
                    // original already ended -> close this fragment as well
                    splitted_item.end_tr(item.get_end_time());
                end
                items.push_back(splitted_item);
            end
        end
    endfunction : split

    //------------------------------------------------------------------------------
// align: background task that assembles tx_item sized exactly CTRL.SIZE from buffer
//------------------------------------------------------------------------------
protected virtual task align();
    algn_vif my_algn_vif = my_model_config.get_vif();
    int unsigned ctrl_size;
    int unsigned ctrl_offset;
    int unsigned total_bytes;

    forever begin
        // sample mirrored control registers
        ctrl_size   = my_reg_block.CTRL.SIZE.get_mirrored_value();
        ctrl_offset = my_reg_block.CTRL.OFFSET.get_mirrored_value();

        // wait for NBA so build_buffer can push on same posedge first
        uvm_wait_for_nba_region();

        total_bytes = 0;
        foreach (buffer[k]) begin
            if (buffer[k] != null) begin
                total_bytes += buffer[k].data.size();
            end
            else begin
                break;
            end
        end

        if (total_bytes >= ctrl_size) begin
            while (total_bytes >= ctrl_size) begin
                string tx_name = $sformatf("%s_tx_item_%0d", get_name(), $urandom);
                algn_data_item tx_item = algn_data_item::type_id::create(tx_name, this);
                tx_item.offset = ctrl_offset;

                // begin_tr from the first contributing fragment (best-effort)
                // If buffer[0] is valid at this moment, use its begin time.
                if (buffer.size() > 0 && buffer[0] != null) begin
                    void'(tx_item.begin_tr(buffer[0].get_begin_time()));
                end
                else begin
                    void'(tx_item.begin_tr());
                end

                // Fill until tx_item reaches ctrl_size
                while (tx_item.data.size() != ctrl_size) begin
                    algn_data_item buffer_item;
                    // wait until there is a buffer item available
                    while (buffer.size() == 0 || buffer[0] == null) begin
                        @(posedge my_algn_vif.clk);
                    end

                    // consume the leading buffer fragment
                    buffer_item = buffer.pop_front();

                    if (buffer_item == null) begin
                        `uvm_warning("ALIGN_NULL", "pop_front() returned null buffer_item — skipping")
                        continue;
                    end
                    else begin
                        // Case A: consume the whole buffer_item into tx_item
                        if (tx_item.data.size() + buffer_item.data.size() <= ctrl_size) begin
                            foreach (buffer_item.data[idx]) begin
                                tx_item.data.push_back(buffer_item.data[idx]);
                            end

                            // RECORD: the fragment we just consumed is a source
                            tx_item.sources.push_back(buffer_item);

                            // If this fill completed the tx_item, set end time and push
                            if (tx_item.data.size() == ctrl_size) begin
                                tx_item.end_tr(buffer_item.get_end_time());
                                push_to_tx_fifo(tx_item);
                            end
                            // continue filling if not yet full
                        end
                        // Case B: need only part of buffer_item -> split
                        else begin
                            int unsigned num_bytes_needed = ctrl_size - tx_item.data.size();
                            algn_data_item splitted_items[$];

                            // split into [0]=needed, [1]=remainder
                            split(num_bytes_needed, buffer_item, splitted_items);

                            // push the remainder back to the front of buffer for later consumption
                            buffer.push_front(splitted_items[1]);

                            // consume the needed fragment now (splitted_items[0])
                            foreach (splitted_items[0].data[idx]) begin
                                tx_item.data.push_back(splitted_items[0].data[idx]);
                            end

                            // RECORD: the consumed fragment is a source
                            tx_item.sources.push_back(splitted_items[0]);

                            // publish split info as before
                            begin
                                algn_split_info info = algn_split_info::type_id::create("info", this);

                                info.ctrl_offset         = ctrl_offset;
                                info.ctrl_size           = ctrl_size;
                                info.md_offset           = buffer_item.offset;
                                info.md_size             = buffer_item.data.size();
                                info.num_bytes_needed    = num_bytes_needed;

                                port_out_split_info.write(info);
                            end

                            // if this filled the tx_item, finish it
                            if (tx_item.data.size() == ctrl_size) begin
                                tx_item.end_tr(splitted_items[0].get_end_time());
                                push_to_tx_fifo(tx_item);
                            end
                        end
                    end
                end // while filling tx_item

                // recompute total_bytes from remaining buffer contents
                total_bytes = 0;
                foreach (buffer[k]) begin
                    total_bytes += buffer[k].data.size();
                end
            end // while total_bytes >= ctrl_size
        end
        else begin
            // not enough bytes — wait a clock edge then retry
            @(posedge my_algn_vif.clk);
        end
    end // forever
endtask : align


    //--------------------------------------------------------------------------
    // align_nb: start align() as a single background process (safe starter)
    //--------------------------------------------------------------------------
    local virtual function void align_nb();
        if (process_align != null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "Cannot start two instances of align() task")
        end

        fork
            begin
                process_align = process::self();
                align();
                process_align = null;
            end
        join_none
    endfunction

    //--------------------------------------------------------------------------
    // tx_ctrl: background task that consumes tx_fifo and forwards items out
    //--------------------------------------------------------------------------
    protected virtual task tx_ctrl();
        algn_data_item item;
        algn_vif my_algn_vif = my_model_config.get_vif();
        forever begin
            if (my_reg_block.STATUS.TX_LVL.get_mirrored_value() > 0) begin
                pop_from_tx_fifo(item);
                // item.data[0]=item.data[0]+1;
                port_out_tx.write(item);
                tx_complete.wait_trigger();
            end
            else begin
                @(posedge my_algn_vif.clk);
            end
        end
    endtask

    local virtual function void tx_ctrl_nb();
        if (process_tx_ctrl != null) begin
            `uvm_fatal("ALGORITHM_ISSUE", "Can not start two instances of tx_ctrl() tasks")
        end
        else begin
            fork
                begin
                    process_tx_ctrl = process::self();
                    tx_ctrl();
                    process_tx_ctrl = null;
                end
            join_none
        end
    endfunction

    //--------------------------------------------------------------------------
    // API: write_in_rx
    // - Called when an RX monitor/agent informs the model of a new incoming item.
    //--------------------------------------------------------------------------
    virtual function void write_in_rx(algn_data_item item_mon);
        if (item_mon != null && item_mon.is_active()) begin
            md_response exp_response = get_exp_response(item_mon);

            case (exp_response)
                MD_ERR: begin
                    inc_cnt_drop(exp_response);
                    port_out_rx.write(exp_response);
                end
                MD_OKAY: begin
                    push_to_rx_fifo_nb(item_mon);
                end
                default: begin
                    `uvm_fatal("ALGORITHM_ISSUE", $sformatf("Un-supported value for response: %0s", exp_response.name()))
                end
            endcase
        end
    endfunction

    //--------------------------------------------------------------------------
    // API: write_in_tx
    // - Called when a TX monitor/agent informs the model of a transmitted item.
    // - If the transaction ended (is_active() == 0), signal tx_complete.
    //--------------------------------------------------------------------------
    virtual function void write_in_tx(algn_data_item item_mon);
        if (item_mon == null) begin
            `uvm_warning("WRITE_TX_NULL", "write_in_tx called with null item_mon — ignoring")
            return;
        end
        if (!item_mon.is_active()) begin
            tx_complete.trigger();
        end
    endfunction

    //--------------------------------------------------------------------------
    // Reset Handler (uvm_ext_reset_handler_if)
    // - Resets the register model and restarts background tasks as needed.
    //--------------------------------------------------------------------------
    virtual function void handle_reset(uvm_phase phase);
        // Reset RAL model to a hard-reset state
        my_reg_block.reset("HARD");

        // Kill any running background processes and clear internal data structures
        kill_process(process_push_to_rx_fifo);
        kill_process(process_build_buffer);
        kill_process(process_align);
        kill_process(process_tx_ctrl);

        kill_process(process_set_rx_fifo_empty);
        kill_process(process_set_rx_fifo_full);
        kill_process(process_set_tx_fifo_empty);
        kill_process(process_set_tx_fifo_full);
        kill_process(process_send_exp_irq);

        tx_complete.reset();

        buffer.delete();

        rx_fifo.flush();
        tx_fifo.flush();

        // Restart background tasks
        build_buffer_nb();
        align_nb();
        tx_ctrl_nb();

        // Prime IRQ sender and set exp_irq.irq_value so an IRQ may be emitted after reset
        exp_irq.irq_value = 0;
        send_exp_irq_nb();
    endfunction

endclass : algn_model

`endif // ALGN_MODEL