///////////////////////////////////////////////////////////////////////////////
// File:        apb_agent_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Agent Configuration Class.
//              This class encapsulates configuration parameters for the APB
//              agent, including:
//                 - Virtual interface handle (apb_vif)
//                 - Active/passive mode (is_active)
//                 - Whether protocol checks are enabled (has_checks)
//                 - Coverage enable flag (has_coverage)
//                 - Stuck transfer detection threshold (stuck_threshold)
//
//              It provides getter/setter methods to safely control these 
//              parameters, propagates changes to the virtual interface when 
//              necessary, and guards against illegal modifications.
//              The configuration must be set up before simulation starts
//              to ensure correct DUT interaction and reliable verification.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_AGENT_CONFIG
`define APB_AGENT_CONFIG

//------------------------------------------------------------------------------
// UVM Component: apb_agent_config
//------------------------------------------------------------------------------
// - Extends uvm_object so it can live in the UVM hierarchy.
// - Used with uvm_config_db to pass agent settings into objects.
// - Ensures clean and centralized configuration for the APB agent.
//------------------------------------------------------------------------------
class apb_agent_config extends uvm_ext_agent_config #(.VIRTUAL_INTF(apb_vif));

    // Number of clock cycles after which an APB transfer is considered
    // stuck and reported as an error (default: 1000 cycles)
    int unsigned stuck_threshold;

    local time sample_delay_start_tr;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_object_utils(apb_agent_config)
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // Initializes config with default values
    function new(string name = "apb_agent_config");
        super.new(name);

        is_active       = UVM_ACTIVE;
        has_checks      = 1;
        has_coverage    = 1;
        stuck_threshold = 1000;
        sample_delay_start_tr = 1ns;
    endfunction : new

    //-------------------------------------------------------------------------
    // Virtual Interface setter
    //-------------------------------------------------------------------------


    virtual function void set_vif(apb_vif value);
        if (my_vif == null) begin
            super.set_vif(value);
            // Propagate has_checks setting into the interface
            my_vif.has_checks = has_checks;
        end
        else begin
            `uvm_fatal("APB_CONFIG", 
                       "Trying to set the APB virtual interface more than once")
        end
    endfunction : set_vif

    //-------------------------------------------------------------------------
    // has_checks setter
    //-------------------------------------------------------------------------


    virtual function void set_has_checks(bit value);
        super.set_has_checks(value);
        if (get_vif() != null) begin
            my_vif.has_checks = has_checks;
        end
    endfunction : set_has_checks


    //-------------------------------------------------------------------------
    // stuck_threshold getter/setter
    //-------------------------------------------------------------------------

    virtual function int unsigned get_stuck_threshold();
        return stuck_threshold;
    endfunction : get_stuck_threshold

    virtual function void set_stuck_threshold(int unsigned value);
        if (value <= 2) begin
            `uvm_error("APB_CONFIG",
                $sformatf("Invalid stuck_threshold = %0d. Minimum legal APB transfer length is 2 cycles.",
                          value))
        end
        else begin
            stuck_threshold = value;
        end
    endfunction : set_stuck_threshold

    //-------------------------------------------------------------------------
    // Reset synchronization helpers
    //-------------------------------------------------------------------------

    // Wait for reset start (preset_n goes low)
    virtual task wait_reset_start();
        if (my_vif.preset_n !== 0) begin
            @(negedge my_vif.preset_n);
        end
    endtask : wait_reset_start

    // Wait for reset end (preset_n returns high)
    virtual task wait_reset_end();
        while (my_vif.preset_n == 0) begin
            @(posedge my_vif.pclk);
        end
    endtask : wait_reset_end


    virtual function time get_sample_delay_start_tr();
        return sample_delay_start_tr;
    endfunction : get_sample_delay_start_tr

    virtual function void set_sample_delay_start_tr(time value);
        sample_delay_start_tr = value;
    endfunction : set_sample_delay_start_tr


    //-------------------------------------------------------------------------
    // UVM Phase: run_phase
    //-------------------------------------------------------------------------

    // Monitor interface has_checks flag to prevent illegal runtime overrides
    // virtual task run_phase(uvm_phase phase);
    //     forever begin
    //         @(my_vif.has_checks);
            
    //         if (my_vif.has_checks != get_has_checks()) begin
    //             `uvm_error("APB_CONFIG", 
    //                 $sformatf("Illegal modification: \"has_checks\" changed directly on the VIF.Use %0s.set_has_checks() instead.", 
    //                 get_full_name()))
    //         end
    //     end
    // endtask

endclass : apb_agent_config

`endif
