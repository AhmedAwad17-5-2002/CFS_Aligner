///////////////////////////////////////////////////////////////////////////////
// File:        apb_monitor.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Monitor
//              Passive verification component that observes APB bus activity 
//              via a virtual interface. The monitor:
//                - Collects APB bus-level signals into apb_mon_item transactions
//                - Measures timing (number of cycles per transfer)
//                - Performs optional protocol checks (e.g., stuck transfers)
//                - Broadcasts observed transactions via analysis_port to 
//                  subscribers such as scoreboard or coverage collectors
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_MONITOR
`define APB_MONITOR

//------------------------------------------------------------------------------
// UVM Monitor: apb_monitor
//------------------------------------------------------------------------------
// - Extends uvm_monitor (passive component).
// - Implements reset handler interface (apb_reset_handler_if).
// - Continuously samples APB signals from the virtual interface (apb_vif).
// - Publishes observed transactions to subscribers through analysis_port.
//------------------------------------------------------------------------------
class apb_monitor extends uvm_ext_monitor #(.VIRTUAL_INTF(apb_vif),.ITEM_MON(apb_mon_item));

    //--------------------------------------------------------------------------
    // Interface, ports, fields
    //--------------------------------------------------------------------------
    apb_agent_config  my_agent_config;   // Provides vif & settings
    //--------------------------------------------------------------------------
    // UVM Factory registration
    //--------------------------------------------------------------------------
    `uvm_component_utils(apb_monitor)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new


    // end_of_elaboration_phase
    // - Verifies correct agent config type
    // - Ensures pointer is valid before simulation run
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // super.my_agent_config = my_agent_config;
        if(super.my_agent_config == null) begin
          `uvm_fatal("ALGORITHM_ISSUE", 
              $sformatf("Agent config pointer from %0s is null", get_full_name()))
        end
      
        if($cast(my_agent_config, super.my_agent_config) == 0) begin
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Failed cast: %0s to %0s", 
                    super.my_agent_config.get_full_name(), 
                    apb_agent_config::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase


    //--------------------------------------------------------------------------
    // Collect a single APB transaction
    //--------------------------------------------------------------------------
    protected virtual task collect_transaction();
        apb_vif       my_mon_vif      = my_agent_config.get_vif();
        // Create a fresh transaction object
        // my_mon_item = apb_mon_item::type_id::create("my_mon_item");
        
        //----------------------------------------------------------------------
        // Wait for transaction setup (PSEL asserted)
        //----------------------------------------------------------------------
        while (my_mon_vif.psel !== 1) begin
            @(posedge my_mon_vif.pclk);
            // #(my_agent_config.get_sample_delay_start_tr());
            my_mon_item.prev_item_delay++; // Count idle cycles
        end

        //----------------------------------------------------------------------
        // Capture setup phase info
        //----------------------------------------------------------------------
        my_mon_item.paddr  = my_mon_vif.paddr;            // Address
        my_mon_item.pwrite = apb_dir'(my_mon_vif.pwrite); // Direction
        my_mon_item.length = 1;                           // Start cycle count at 1

        // Capture write data (if WRITE transaction)
        if (my_mon_item.pwrite === APB_WRITE) begin
            my_mon_item.pwdata = my_mon_vif.pwdata;
        end

        //----------------------------------------------------------------------
        // Enable phase: advance one cycle, then wait until PREADY asserted
        //----------------------------------------------------------------------
        @(posedge my_mon_vif.pclk);
        my_mon_item.length++;

        while (my_mon_vif.pready !== 1) begin
            @(posedge my_mon_vif.pclk);
            // #(my_agent_config.get_sample_delay_start_tr());
            my_mon_item.length++;

            // Optional protocol check: detect stuck transfers
            if (my_agent_config.get_has_checks()) begin
                if (my_mon_item.length >= my_agent_config.get_stuck_threshold()) begin
                    `uvm_error("PROTOCOL_ERROR", 
                               $sformatf("APB transfer stuck: exceeded threshold of %0d cycles", 
                               my_mon_item.length))
                end
            end
        end

        //----------------------------------------------------------------------
        // Capture completion info
        //----------------------------------------------------------------------
        my_mon_item.response = apb_response'(my_mon_vif.pslverr); // Response: OK/ERR
        if (my_mon_item.pwrite === APB_READ) begin
            my_mon_item.prdata = my_mon_vif.prdata;    // Read data
        end

        
        
         `uvm_info("ITEM_END", 
                  $sformatf("\nMonitored item: %0s", my_mon_item.convert2string()), 
                  UVM_LOW)
        

        //----------------------------------------------------------------------
        // Publish monitored transaction to analysis port
        //----------------------------------------------------------------------
        // #(my_agent_config.get_sample_delay_start_tr());
        monitor_aport.write(my_mon_item);

        

        //----------------------------------------------------------------------
        // Debug log
        //----------------------------------------------------------------------
        

        // Wait one cycle before monitoring the next transaction
        @(posedge my_mon_vif.pclk);
    endtask : collect_transaction


endclass : apb_monitor

`endif // APB_MONITOR
