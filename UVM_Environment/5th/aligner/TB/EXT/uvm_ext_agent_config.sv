`ifndef UVM_EXT_AGENT_CONFIG
`define UVM_EXT_AGENT_CONFIG

//------------------------------------------------------------------------------
// UVM Component: uvm_ext_agent_config
//------------------------------------------------------------------------------
// - Extends uvm_object so it can live in the UVM hierarchy.
// - Used with uvm_config_db to pass agent settings into components.
// - Ensures clean and centralized configuration for the APB agent.
//------------------------------------------------------------------------------
class uvm_ext_agent_config #(type VIRTUAL_INTF = int) extends uvm_object;
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Virtual interface to DUT APB signals
    VIRTUAL_INTF my_vif;

    // Active/passive mode (default: ACTIVE)
    uvm_active_passive_enum is_active;

    // Enable/disable protocol checks (default: enabled)
    bit has_checks;

    // Enable/disable coverage collection (default: enabled)
    bit has_coverage;

    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_object_param_utils(uvm_ext_agent_config#(.VIRTUAL_INTF(VIRTUAL_INTF)))
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // Initializes config with default values
    function new(string name = "uvm_ext_agent_config");
        super.new(name);

        is_active       = UVM_ACTIVE;
        has_checks      = 1;
        has_coverage    = 1;
    endfunction : new

    //-------------------------------------------------------------------------
    // Virtual Interface getter/setter
    //-------------------------------------------------------------------------

    virtual function VIRTUAL_INTF get_vif();
        return my_vif;
    endfunction : get_vif

    virtual function void set_vif(VIRTUAL_INTF value);
        if (my_vif == null) begin
            my_vif = value;
        end
        else begin
            `uvm_fatal("EXT_CONFIG", 
                       "Trying to set the virtual interface more than once")
        end
    endfunction : set_vif

    //-------------------------------------------------------------------------
    // has_checks getter/setter
    //-------------------------------------------------------------------------

    virtual function bit get_has_checks();
        return has_checks;
    endfunction : get_has_checks

    virtual function void set_has_checks(bit value);
        has_checks = value;
        // if (get_vif() != null) begin
        //     my_vif.has_checks = has_checks;
        // end
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
    // Reset synchronization helpers
    //-------------------------------------------------------------------------

    // Wait for reset start (preset_n goes low)
    virtual task wait_reset_start();
        `uvm_fatal("ALGORITHM_ISSUE", "One must implement wait_reset_start() task")
    endtask : wait_reset_start

    // Wait for reset end (preset_n returns high)
    virtual task wait_reset_end();
        `uvm_fatal("ALGORITHM_ISSUE", "One must implement wait_reset_end() task")
    endtask : wait_reset_end


endclass : uvm_ext_agent_config

`endif
