`ifndef UVM_EXT_DRIVER
`define UVM_EXT_DRIVER

//------------------------------------------------------------------------------
// UVM Driver: uvm_ext_driver
//------------------------------------------------------------------------------
// - Extends uvm_driver with transaction type md_drv_item.
// - Drives transactions on the MD interface using the standard MD protocol.
// - Implements reset handling (via md_reset_handler_if).
//------------------------------------------------------------------------------
class uvm_ext_driver #(type ITEM_DRV = uvm_sequence_item, type VIRTUAL_INTF = int) 
    extends uvm_driver #(.REQ(ITEM_DRV)) implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Configuration object containing MD virtual interface and agent settings
    uvm_ext_agent_config #(.VIRTUAL_INTF(VIRTUAL_INTF)) my_agent_config;
    ITEM_DRV my_drv_item;
    bit tr_active = 0;

    // Process handle used to track the transaction-driving process
    // (needed to safely kill/restart when reset is asserted)
    protected process process_drive_transactions;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Register this parameterized driver with the UVM factory
    `uvm_component_param_utils(uvm_ext_driver#(.ITEM_DRV(ITEM_DRV),.VIRTUAL_INTF(VIRTUAL_INTF)))
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - name:   instance name
    // - parent: parent component in the UVM hierarchy
    function new(string name = "uvm_ext_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    // run_phase
    // - Main runtime loop for the driver
    // - Waits for reset deassertion before driving
    // - Restarts transaction driving if reset re-asserts
    task run_phase(uvm_phase phase);
        forever begin
            fork 
                begin
                    wait_reset_end();     // Wait until reset is released
                    drive_transactions(); // Start transaction driving loop
                    disable fork;         // Restart if reset occurs again
                end
            join
        end
    endtask : run_phase

    // drive_transactions
    // - Main driving loop:
    //   * Fetch items from sequencer
    //   * Drive them onto the MD interface
    //   * Perform transaction recording
    //   * Notify sequencer when item is done
    protected virtual task drive_transactions();
        fork
            begin
                process_drive_transactions = process::self(); // Track process for reset handling
                forever begin
                    

                    seq_item_port.get_next_item(my_drv_item);

                        // Enable transaction recording for debug/analysis
                        my_drv_item.enable_recording(get_tr_stream(my_drv_item.get_name()));
                        
                        // Mark transaction start time
                        void'(begin_tr(.tr(my_drv_item), .stream_name(my_drv_item.get_name())));
                        tr_active = 1;
         
                        // Record user-defined fields (visible in waveform viewers)
                        my_drv_item.record();
                        
                        // Protocol-specific driving (to be implemented in derived class)
                        drive_transaction(my_drv_item);            
         
                        // Mark transaction end time
                        end_tr(my_drv_item);
                        tr_active = 0;   
                    
                    seq_item_port.item_done(); // Acknowledge completion
                    my_drv_item = null;
                end
            end
        join
    endtask : drive_transactions

    // drive_transaction
    // - Implements MD protocol handshake for a single transaction.
    // - Must be overridden with protocol-specific driving logic.
    virtual task drive_transaction(ITEM_DRV my_drv_item);
        `uvm_fatal("ALGORITHM_ISSUE", "Implement md_drive_transaction()")
    endtask : drive_transaction

    // handle_reset
    // - Invoked when reset is asserted.
    // - Stops the driving loop and returns interface signals to IDLE state.
    virtual function void handle_reset(uvm_phase phase);
        if (process_drive_transactions != null) begin
            process_drive_transactions.kill(); // Kill driving loop 
            process_drive_transactions = null;

            if (tr_active) begin
                end_tr(my_drv_item);
                tr_active = 0;
            end 

            if (my_drv_item != null) begin
                seq_item_port.item_done();
                my_drv_item = null; // clear reference after done
            end
        end
    endfunction : handle_reset

    // wait_reset_end
    // - Waits until reset is deasserted using agent configuration object.
    protected virtual task wait_reset_end();
        my_agent_config.wait_reset_end();
    endtask : wait_reset_end
    
endclass : uvm_ext_driver

`endif
