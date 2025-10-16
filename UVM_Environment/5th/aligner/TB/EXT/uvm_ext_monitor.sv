`ifndef UVM_EXT_MONITOR
`define UVM_EXT_MONITOR

//------------------------------------------------------------------------------
// UVM Monitor: uvm_ext_monitor
//------------------------------------------------------------------------------
// - Extends uvm_monitor (passive component).
// - Implements reset handler interface (reset_handler_if).
// - Continuously samples MD signals from the virtual interface (VIRTUAL_INTF).
// - Publishes observed transactions to subscribers through analysis_port.
//------------------------------------------------------------------------------
class uvm_ext_monitor #(type VIRTUAL_INTF = int, type ITEM_MON = uvm_sequence_item) 
    extends uvm_monitor 
    implements uvm_ext_reset_handler_if;

    //--------------------------------------------------------------------------
    // Interface, ports, fields
    //--------------------------------------------------------------------------
    uvm_ext_agent_config #(.VIRTUAL_INTF(VIRTUAL_INTF))  my_agent_config;   // Provides vif & settings
    uvm_analysis_port #(ITEM_MON) monitor_aport;                            // Publishes observed items
    ITEM_MON  my_mon_item;                                                  // Stores a collected item
    bit tr_active = 0;
    protected process process_collect_transactions;                         // Tracks collection loop

    //--------------------------------------------------------------------------
    // UVM Factory registration
    //--------------------------------------------------------------------------
    `uvm_component_param_utils(uvm_ext_monitor#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON)))

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "uvm_ext_monitor", uvm_component parent = null);
        super.new(name, parent);

        // Create analysis port for publishing monitored transactions
        monitor_aport = new("monitor_aport", this);
    endfunction : new

    //--------------------------------------------------------------------------
    // Run Phase
    //--------------------------------------------------------------------------
    // Loop forever:
    //   - Wait for reset deassertion
    //   - Start collecting transactions
    //   - Restart collection if reset reasserts
    //--------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        forever begin
            fork
                begin
                    wait_reset_end();       // Block until reset finishes
                    collect_transactions(); // Begin continuous monitoring
                    disable fork;           // If reset asserts, restart
                end
            join
        end   
    endtask : run_phase

    //--------------------------------------------------------------------------
    // Collect multiple transactions continuously
    //--------------------------------------------------------------------------
    protected virtual task collect_transactions();
        fork
            begin
                process_collect_transactions = process::self();
                forever begin
                    // Create a fresh transaction object
                    my_mon_item = ITEM_MON::type_id::create("my_mon_item");

                    // my_mon_item.enable_recording(get_tr_stream("MON_ITEM"));
                    // void'(begin_tr(.tr(my_mon_item), .stream_name("MON_ITEM")));
                    // tr_active = 1;
                    // my_mon_item.record();

                    collect_transaction(); // Collect one transaction
                    
                    // end_tr(my_mon_item);   // Block until sequence sends item
                    // tr_active = 0;
                end
            end
        join
    endtask : collect_transactions

    //--------------------------------------------------------------------------
    // Collect a single MD transaction
    //--------------------------------------------------------------------------
    protected virtual task collect_transaction();
        `uvm_fatal("ALGORITHM_ISSUE", "One must implement collect_transaction task in uvm_ext_monitor")
    endtask : collect_transaction

    //--------------------------------------------------------------------------
    // Reset Handling
    //--------------------------------------------------------------------------
    // Kills ongoing collection loop when reset asserts
    virtual function void handle_reset(uvm_phase phase);
        if (process_collect_transactions != null) begin
            process_collect_transactions.kill();
            process_collect_transactions = null;

            if (tr_active) begin
                void'(end_tr(my_mon_item));
                tr_active = 0;
            end 
            
        end
    endfunction

    // Wait until reset is deasserted (delegated to config object)
    protected virtual task wait_reset_end();
        my_agent_config.wait_reset_end();
    endtask

endclass : uvm_ext_monitor

`endif // UVM_EXT_MONITOR
