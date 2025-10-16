/////////////////////////////////////////////////////////////////////////////// 
// File:        md_agent_config.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM Configuration Class for MD Agent. 
//              ---------------------------------------------------------------
//              This configuration component is used to control the behavior of 
//              the MD Agent in a UVM testbench. It stores and manages runtime 
//              options such as:
//                - Active or passive mode
//                - Protocol checking enable/disable
//                - Coverage collection enable/disable
//                - Reset synchronization
//                - Transaction sampling delay
//                - Stuck transfer threshold (optional)
//
//              It also provides getter/setter methods to safely access/modify 
//              these fields. The virtual interface must be assigned once before 
//              simulation, and illegal runtime overrides are reported as errors.
//
//              Purpose:
//              --------
//              This class ensures consistent and controlled configuration of 
//              the MD Agent, avoiding accidental misconfiguration and enforcing 
//              proper testbench setup before simulation begins. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_AGENT_CONFIG
`define MD_AGENT_CONFIG

//------------------------------------------------------------------------------
// md_agent_config
//------------------------------------------------------------------------------
// - Extends uvm_component
// - Holds agent configuration fields (is_active, has_checks, has_coverage, etc.)
// - Provides getter/setter methods to control runtime options
// - Ensures reset synchronization for DUT
// - Verifies that the virtual interface (md_vif) is set before simulation
//------------------------------------------------------------------------------
class md_agent_config #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
    extends uvm_ext_agent_config #(.VIRTUAL_INTF(md_vif));;
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/

    // Delay between sampling start of transaction (default: 1ns)
    local time sample_delay_start_tr;

    // Number of cycles after which transfer is considered stuck (default: 1000)
    local int unsigned stuck_threshold;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Register with UVM factory (supports parameterized DATA_WIDTH)
    `uvm_object_param_utils(md_agent_config #(.DATA_WIDTH(DATA_WIDTH)))
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/

    // Constructor
    // - Initializes configuration fields with default values
    function new(string name = "md_agent_config");
        super.new(name);

        is_active       = UVM_ACTIVE;
        has_checks      = 1;
        has_coverage    = 1;
        sample_delay_start_tr = 1ns;
        stuck_threshold = 1000;
    endfunction : new

    //-------------------------------------------------------------------------
    // Virtual Interface Accessors
    //-------------------------------------------------------------------------
    virtual function void set_vif(md_vif value);
        super.set_vif(value);
        // if (my_vif != null) begin
            // Propagate has_checks setting into the interface
            my_vif.has_checks = has_checks;
        // end
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
    // has_coverage getter/setter
    //-------------------------------------------------------------------------

    virtual function bit get_has_coverage();
        return has_coverage;
    endfunction : get_has_coverage

    virtual function void set_has_coverage(bit value);
        has_coverage = value;
    endfunction : set_has_coverage

    //-------------------------------------------------------------------------
    // is_active getter/setter
    //-------------------------------------------------------------------------

    virtual function uvm_active_passive_enum get_is_active();
        return is_active;
    endfunction : get_is_active

    virtual function void set_is_active(uvm_active_passive_enum value);
        is_active = value;
    endfunction : set_is_active

    //-------------------------------------------------------------------------
    // Stuck threshold getter/setter
    //-------------------------------------------------------------------------

    virtual function int unsigned get_stuck_threshold();
        return stuck_threshold;
    endfunction : get_stuck_threshold

    virtual function void set_stuck_threshold(int unsigned value);
        stuck_threshold = value;
    endfunction : set_stuck_threshold

    //-------------------------------------------------------------------------
    // Reset synchronization helpers
    //-------------------------------------------------------------------------

    // Wait for reset start (reset_n goes low)
    virtual task wait_reset_start();
        if (my_vif.reset_n !== 0) begin
            @(negedge my_vif.reset_n);
        end
    endtask : wait_reset_start

    // Wait for reset end (reset_n goes high again)
    virtual task wait_reset_end();
        while (my_vif.reset_n == 0) begin
            @(posedge my_vif.clk);
        end
    endtask : wait_reset_end

    //-------------------------------------------------------------------------
    // Sample delay getter/setter
    //-------------------------------------------------------------------------

    virtual function time get_sample_delay_start_tr();
        return sample_delay_start_tr;
    endfunction : get_sample_delay_start_tr

    virtual function void set_sample_delay_start_tr(time value);
        sample_delay_start_tr = value;
    endfunction : set_sample_delay_start_tr
    
endclass : md_agent_config

`endif
