///////////////////////////////////////////////////////////////////////////////
// File:        md_monitor.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-07
// Description: MD Monitor
//              Passive UVM verification component that observes the MD bus 
//              via a virtual interface. 
//              Responsibilities include:
//                - Sampling MD bus-level signals into md_mon_item transactions
//                - Measuring timing (number of cycles per transfer)
//                - Performing optional protocol checks (e.g., detecting stuck 
//                  transfers if valid/ready handshake stalls)
//                - Broadcasting observed transactions via analysis_port to 
//                  subscribers (e.g., scoreboard, coverage collectors, etc.)
//              This component does not drive the bus — it is passive only.
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_MONITOR
`define MD_MONITOR

//------------------------------------------------------------------------------
// UVM Monitor: md_monitor
//------------------------------------------------------------------------------
// - Extends uvm_monitor (passive component).
// - Implements reset handler interface (md_reset_handler_if).
// - Continuously samples MD signals from the virtual interface (md_vif).
// - Publishes observed transactions to subscribers through analysis_port.
//------------------------------------------------------------------------------
class md_monitor #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
    extends uvm_ext_monitor #(.VIRTUAL_INTF(md_vif),.ITEM_MON(md_mon_item));

    //--------------------------------------------------------------------------
    // Interface, ports, fields
    //--------------------------------------------------------------------------
    md_agent_config #(.DATA_WIDTH(DATA_WIDTH))  my_agent_config;                // Provides vif & settings

    //--------------------------------------------------------------------------
    // UVM Factory registration
    //--------------------------------------------------------------------------
    `uvm_component_param_utils(md_monitor#(.DATA_WIDTH(DATA_WIDTH)))

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "md_monitor", uvm_component parent = null);
        super.new(name, parent);

        // Create analysis port for publishing monitored transactions
        // monitor_aport = new("monitor_aport", this);
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
                    md_agent_config#(.DATA_WIDTH(DATA_WIDTH))::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase


    //--------------------------------------------------------------------------
    // Collect a single MD transaction
    //--------------------------------------------------------------------------
    protected virtual task collect_transaction();
        // Get virtual interface from agent config
        md_vif my_mon_vif = my_agent_config.get_vif();

        // Transaction setup
        int unsigned data_width_in_bytes = DATA_WIDTH/8;
        my_mon_item.enable_recording(get_tr_stream("MD_MON_ITEM"));



        // Wait until valid goes high
        #(my_agent_config.get_sample_delay_start_tr());
        while(my_mon_vif.valid !== 1) begin
            @(posedge my_mon_vif.clk);
            my_mon_item.prev_item_delay++;
            #(my_agent_config.get_sample_delay_start_tr());
        end
        
        // Start transaction recording
        void'(begin_tr(.tr(my_mon_item), .stream_name("MD_MON_ITEM")));

        // Capture transaction fields
        my_mon_item.offset = my_mon_vif.offset;

        for (int i = 0; i < my_mon_vif.size; i++) begin
            my_mon_item.data.push_back(
                (my_mon_vif.data >> ((my_mon_item.offset + i) * 8)) & 8'hFF
            );
        end

        my_mon_item.length = 1;

        
        tr_active = 1;
        `uvm_info("ITEM_START", 
                  $sformatf("\nMonitor started collecting item: %0s", 
                            my_mon_item.convert2string()), 
                  UVM_LOW)

        // Record & publish transaction start
        my_mon_item.record();
        monitor_aport.write(my_mon_item);

        // Wait until ready or detect stuck transfer
        @(posedge my_mon_vif.clk);
        while (my_mon_vif.ready !== 1) begin
            @(posedge my_mon_vif.clk);
            my_mon_item.length++;

            // Optional stuck-transfer protocol check
            if (my_agent_config.get_has_checks()) begin
                if (my_mon_item.length >= my_agent_config.get_stuck_threshold()) begin
                    `uvm_info("PROTOCOL_ERROR", super.my_agent_config.get_full_name(),UVM_NONE)
                    `uvm_error("PROTOCOL_ERROR", 
                               $sformatf("MD transfer stuck: exceeded threshold of %0d cycles", 
                                         my_agent_config.get_stuck_threshold()))
                    
                end
            end
        end

        // Capture response
        my_mon_item.response = md_response'(my_mon_vif.err);
      
        // End transaction recording
        void'(end_tr(my_mon_item));
        tr_active = 0;

        // Publish monitored transaction to subscribers
        monitor_aport.write(my_mon_item);
        
        // Debug log
        `uvm_info("ITEM_END", 
                  $sformatf("\nMonitored item: %0s", my_mon_item.convert2string()), 
                  UVM_LOW)

    endtask : collect_transaction



endclass : md_monitor

`endif // MD_MONITOR
