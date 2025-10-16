///////////////////////////////////////////////////////////////////////////////
// File:        algn_env_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM configuration object for the Alignment Controller
//              verification environment.  This class centralizes all run-time
//              configuration parameters (enable/disable agents, provide agent
//              configs, etc.) and is typically placed into the uvm_config_db
//              for retrieval by the top-level environment (algn_env).
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_ENV_CONFIG
`define ALGN_ENV_CONFIG

//------------------------------------------------------------------------------
// UVM Component: algn_env_config
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH to match the MD bus width.
// - Extends uvm_object so it can be stored in the UVM configuration database.
// - Provides getters/setters for enabling/disabling agents and supplying
//   their individual configuration objects.
//------------------------------------------------------------------------------
class algn_env_config #(int unsigned DATA_WIDTH = `DATA_WIDTH) extends uvm_object;

    //--------------------------------------------------------------------------
    // Enable flags for optional sub-components
    //--------------------------------------------------------------------------
    local bit has_apb_agent;        // Include APB agent if 1
    local bit has_md_master_agent;  // Include MD master agent if 1
    local bit has_md_slave_agent;   // Include MD slave agent if 1
    local bit has_algn_model;        // Include UVM register model if 1
    local bit has_algn_scoreboard;
    local bit has_coverage;        

    //Virtual interface
    protected algn_vif my_algn_vif;

    //--------------------------------------------------------------------------
    // Sub-agent configuration handles
    //--------------------------------------------------------------------------
    local apb_agent_config                                      my_apb_agent_config;
    local md_slave_agent_config  #(.DATA_WIDTH(DATA_WIDTH))     my_md_slave_agent_config;
    local md_master_agent_config #(.DATA_WIDTH(DATA_WIDTH))     my_md_master_agent_config;
    local model_config           #(.DATA_WIDTH(DATA_WIDTH))     my_model_config;
    local algn_scoreboard_config #(.DATA_WIDTH(DATA_WIDTH))     my_algn_scoreboard_config;

    //--------------------------------------------------------------------------
    // UVM Factory Registration
    //--------------------------------------------------------------------------
    `uvm_object_param_utils(algn_env_config#(.DATA_WIDTH(DATA_WIDTH)))

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    // Initializes default settings (all agents enabled unless changed later).
    function new(string name = "algn_env_config");
        super.new(name);
        has_apb_agent       = 0;
        has_md_master_agent = 0;
        has_md_slave_agent  = 0;
        has_algn_model      = 0; // default off unless specifically required
        has_algn_scoreboard = 0;
        has_coverage        = 0;
    endfunction : new

    //--------------------------------------------------------------------------
    // Enable/Disable Flags
    //--------------------------------------------------------------------------
    virtual function void set_vif(algn_vif value);
        my_algn_vif = value;
    endfunction
    virtual function algn_vif get_vif();
        return my_algn_vif;
    endfunction

    virtual function void set_has_apb_agent(bit value);
        has_apb_agent = value;
    endfunction
    virtual function bit unsigned get_has_apb_agent();
        return has_apb_agent;
    endfunction

    virtual function void set_has_md_master_agent(bit value);
        has_md_master_agent = value;
    endfunction
    virtual function bit unsigned get_has_md_master_agent();
        return has_md_master_agent;
    endfunction

    virtual function void set_has_md_slave_agent(bit value);
        has_md_slave_agent = value;
    endfunction
    virtual function bit unsigned get_has_md_slave_agent();
        return has_md_slave_agent;
    endfunction

    virtual function void set_has_algn_model(bit value);
        has_algn_model = value;
    endfunction
    virtual function bit unsigned get_has_algn_model();
        return has_algn_model;
    endfunction

    virtual function void set_has_algn_scoreboard(bit value);
        has_algn_scoreboard = value;
    endfunction
    virtual function bit unsigned get_has_algn_scoreboard();
        return has_algn_scoreboard;
    endfunction

    virtual function void set_has_coverage(bit value);
        has_coverage = value;
    endfunction
    virtual function bit unsigned get_has_coverage();
        return has_coverage;
    endfunction


    

    //--------------------------------------------------------------------------
    // Sub-Agent Config Accessors
    //--------------------------------------------------------------------------
    virtual function void set_apb_agent_config(apb_agent_config value);
        my_apb_agent_config = value;
    endfunction
    virtual function apb_agent_config get_apb_agent_config();
        return my_apb_agent_config;
    endfunction

    virtual function void set_md_slave_agent_config(md_slave_agent_config value);
        my_md_slave_agent_config = value;
    endfunction
    virtual function md_slave_agent_config get_md_slave_agent_config();
        return my_md_slave_agent_config;
    endfunction

    virtual function void set_md_master_agent_config(md_master_agent_config value);
        my_md_master_agent_config = value;
    endfunction
    virtual function md_master_agent_config get_md_master_agent_config();
        return my_md_master_agent_config;
    endfunction

    virtual function void set_model_config(model_config value);
        my_model_config = value;
    endfunction
    virtual function model_config get_model_config();
        return my_model_config;
    endfunction

    virtual function void set_algn_scoreboard_config(algn_scoreboard_config value);
        my_algn_scoreboard_config = value;
    endfunction
    virtual function algn_scoreboard_config get_algn_scoreboard_config();
        return my_algn_scoreboard_config;
    endfunction

endclass : algn_env_config

`endif
