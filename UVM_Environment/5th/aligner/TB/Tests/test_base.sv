///////////////////////////////////////////////////////////////////////////////
// File:        test_base.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        06/10/2025
// Description: Base UVM test class (detailed).
// 
// Detailed purpose and flow:
//   This file defines the reusable base test class `test_base` which serves
//   as the parent for all specific testcases used to verify the Alignment
//   Controller DUT. The class centralizes creation and configuration of the
//   top-level verification environment (algn_env) and all related
//   configuration objects so child tests can inherit a consistent setup.
//
//   Key responsibilities:
//     1. Create the verification environment instance (my_algn_env) using the
//        UVM factory.
//     2. Create and configure per-agent and per-component configuration
//        objects (APB agent, MD master/slave agents, register/model config,
//        scoreboard config, and the environment config wrapper).
//     3. Retrieve virtual interface handles from the UVM config DB (these
//        are supplied by the top-level testbench module) and attach them to
//        the relevant config objects.
//     4. Push the composed environment configuration object back into the
//        UVM config DB so the environment and its subcomponents can retrieve
//        their configuration during build_phase/connect_phase.
//     5. Provide helper configuration methods (configure_apb, configure_md_*,
//        configure_algn_model, configure_algn_scoreboard, configure_algn_env)
//        so child tests can override specific behaviors without rewriting the
//        entire build flow.
//
//   Typical test execution flow (how this class participates):
//     - Top-level TB instantiates DUT and testbench glue, creates virtual
//       interfaces, then uses uvm_config_db to set those vifs under names
//       like "md_tx_vif", "md_rx_vif", "apb_vif", and "algn_vif" prior to
//       calling run_test().
//     - UVM factory creates an instance of the concrete test (which usually
//       extends test_base). test_base::build_phase() runs:
//         * Creates my_algn_env via the factory.
//         * Creates config objects via the factory.
//         * Retrieves virtual interfaces from uvm_config_db; fatal on missing.
//         * Calls configuration helper methods to populate config objects.
//         * Calls configure_algn_env() to assemble and publish the final
//           algn_env_config object into the uvm_config_db (key: "algn_env_config").
//     - algn_env and other components (created by factory) read the published
//       algn_env_config from uvm_config_db during their build_phase to get
//       their sub-configs and vifs.
//     - The environment and components use connect_phase to wire analysis
//       ports, scoreboard, monitor/checker relationships and the run_phase
//       for stimulus/scoreboard orchestration as needed.
//     - Child tests override or extend run_phase (or other phases) to provide
//       scenario-specific sequences, checks, or runtime configuration changes.
//
//   Notes / best-practices:
//     - Keep virtual interface names in the TB consistent with the names used
//       when retrieving them here (md_tx_vif, md_rx_vif, apb_vif, algn_vif).
//     - Use the helper configure_* functions if you need to change only a
//       small subset of the configuration in child tests; call super.build_phase
//       then tweak the returned config objects.
//     - Fatal errors are used here if required vifs are missing. If you need
//       optional agents, change the checks to warnings and supply default
//       configurations or gating logic in configure_algn_env().
// 
///////////////////////////////////////////////////////////////////////////////

`ifndef TEST_BASE
`define TEST_BASE

//------------------------------------------------------------------------------
// UVM Test: test_base
//------------------------------------------------------------------------------
// - Extends uvm_test (root of the UVM test hierarchy).
// - Creates and configures the algn_env verification environment.
// - Provides reusable configuration functions for APB, MD slave/master,
//   register model, and environment configuration objects.
//------------------------------------------------------------------------------
class test_base extends uvm_test;

    // Environment instance (contains APB agent and other verification components)
    algn_env #(.DATA_WIDTH(`DATA_WIDTH)) my_algn_env;

    // Configuration objects for agents and register model
    apb_agent_config                                    my_apb_agent_config;
    md_slave_agent_config   #(.DATA_WIDTH(`DATA_WIDTH)) my_md_slave_agent_config;
    md_master_agent_config  #(.DATA_WIDTH(`DATA_WIDTH)) my_md_master_agent_config;
    model_config            #(.DATA_WIDTH(`DATA_WIDTH)) my_model_config;
    algn_env_config         #(.DATA_WIDTH(`DATA_WIDTH)) my_algn_env_config;
    algn_scoreboard_config  #(.DATA_WIDTH(`DATA_WIDTH)) my_algn_scoreboard_config;

    // Virtual interfaces (provided from the testbench top)
    apb_vif my_apb_vif;
    md_vif  my_md_rx_vif, my_md_tx_vif;
    algn_vif my_algn_vif;

    string apb_agent_configration_message;
    string md_master_agent_configration_message;
    string md_slave_agent_configration_message;

    /*---------------------------------------------------------------------------
    -- UVM Factory registration
    ---------------------------------------------------------------------------*/
    // Registers this test with the UVM factory for dynamic creation.
    `uvm_component_utils(test_base)

    /*---------------------------------------------------------------------------
    -- Constructor
    ---------------------------------------------------------------------------*/
    // - "name": unique test instance name
    // - "parent": parent component in the UVM hierarchy
    function new(string name = "test_base", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    /*---------------------------------------------------------------------------
    -- build_phase
    ---------------------------------------------------------------------------*/
    // - Creates the environment and all configuration objects.
    // - Retrieves virtual interfaces from the config DB.
    // - Calls helper functions to populate configuration objects.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create environment via factory so it can be overridden by child tests
        my_algn_env = algn_env#(.DATA_WIDTH(`DATA_WIDTH))::type_id::create("my_algn_env", this);

        // Create configuration objects (factory-created to allow overrides)
        my_algn_env_config   = algn_env_config#(.DATA_WIDTH(`DATA_WIDTH))::type_id::create("my_algn_env_config");
        my_apb_agent_config  = apb_agent_config::type_id::create("my_apb_agent_config");
        my_md_slave_agent_config  = md_slave_agent_config#(.DATA_WIDTH(`DATA_WIDTH))::type_id::create("my_md_slave_agent_config");
        my_md_master_agent_config = md_master_agent_config#(.DATA_WIDTH(`DATA_WIDTH))::type_id::create("my_md_master_agent_config");
        my_model_config        = model_config#(.DATA_WIDTH(`DATA_WIDTH))::type_id::create("my_model_config");
        my_algn_scoreboard_config = algn_scoreboard_config#(.DATA_WIDTH(`DATA_WIDTH)) :: type_id :: create("my_algn_scoreboard_config");

        // ---------------------------------------------------------------------
        // Get virtual interfaces from the configuration database (set by TB top).
        // Fatal on missing critical vifs so missing testbench hookup is obvious.
        // ---------------------------------------------------------------------
        if(!uvm_config_db #(md_vif)::get(this,"","md_tx_vif",my_md_tx_vif))
            `uvm_fatal("base_test","couldn't find md_tx_vif in base_test build phase")
        else
            `uvm_info("CONFIG",$sformatf("md_tx_vif is set successfully"), UVM_FULL)

        if(!uvm_config_db #(md_vif)::get(this,"","md_rx_vif",my_md_rx_vif))
            `uvm_fatal("base_test","couldn't find md_rx_vif in base_test build phase")
        else
            `uvm_info("CONFIG",$sformatf("md_rx_vif is set successfully"), UVM_FULL)

        if(!uvm_config_db #(apb_vif)::get(this,"","apb_vif",my_apb_vif))
            `uvm_fatal("base_test","couldn't find apb_vif in base_test build phase")
        else
            `uvm_info("CONFIG",$sformatf("apb_vif is set successfully"), UVM_FULL)

        if(!uvm_config_db #(algn_vif)::get(this,"","algn_vif",my_algn_vif))
            `uvm_fatal("base_test","couldn't find algn_vif in base_test build phase")
        else
            `uvm_info("CONFIG",$sformatf("algn_vif is set successfully"), UVM_FULL)

        // ---------------------------------------------------------------------
        // Configure agents and register model using helper functions below.
        // These helper functions set the vifs and per-agent runtime options.
        // Child tests may override these helpers to change modes or options.
        // ---------------------------------------------------------------------
        configure_apb(my_apb_agent_config, UVM_ACTIVE);
        configure_md_slave(my_md_slave_agent_config, UVM_ACTIVE);
        configure_md_master(my_md_master_agent_config, UVM_ACTIVE);
        configure_algn_model(my_model_config);
        configure_algn_scoreboard(my_algn_scoreboard_config);

        // Pass all configuration objects to the environment (pack them into the env config)
        configure_algn_env();
    endfunction : build_phase

    //-------------------------------------------------------------------------
    // Individual configuration helper functions
    //-------------------------------------------------------------------------
    // Each helper fills its config object with sensible defaults and attaches
    // the corresponding virtual interface. Override these in a derived test
    // to customize behavior (e.g., passive agents, different thresholds).
    //-------------------------------------------------------------------------

    virtual function void configure_apb(ref apb_agent_config my_apb_agent_config,
                                        input uvm_active_passive_enum agent_mode);
        // attach the virtual interface used by the APB agent
        my_apb_agent_config.set_vif(my_apb_vif);
        // enable checks and coverage by default
        my_apb_agent_config.set_has_checks(1);
        my_apb_agent_config.set_stuck_threshold(100);
        my_apb_agent_config.set_sample_delay_start_tr(1ns);
        my_apb_agent_config.set_has_coverage(1);
        // set active/passive according to requested mode
        my_apb_agent_config.set_is_active(agent_mode);
    endfunction

    virtual function void configure_md_slave(ref md_slave_agent_config my_md_slave_agent_config,
                                             input uvm_active_passive_enum agent_mode);
        // The MD slave agent drives TX-side of DUT (transmit to DUT RX FIFO)
        my_md_slave_agent_config.set_vif(my_md_tx_vif);
        my_md_slave_agent_config.set_has_checks(1);
        my_md_slave_agent_config.set_stuck_threshold(100);
        my_md_slave_agent_config.set_sample_delay_start_tr(1ns);
        my_md_slave_agent_config.set_has_coverage(1);
        my_md_slave_agent_config.set_is_active(agent_mode);
    endfunction

    virtual function void configure_md_master(ref md_master_agent_config my_md_master_agent_config,
                                              input uvm_active_passive_enum agent_mode);
        // The MD master agent drives RX-side stimuli (responds/reads DUT TX FIFO).
        my_md_master_agent_config.set_vif(my_md_rx_vif);
        my_md_master_agent_config.set_has_checks(1);
        my_md_master_agent_config.set_stuck_threshold(100);
        my_md_master_agent_config.set_sample_delay_start_tr(1ns);
        my_md_master_agent_config.set_has_coverage(1);
        my_md_master_agent_config.set_is_active(agent_mode);
    endfunction

    virtual function void configure_algn_model(ref model_config my_model_config);
        // Register model / reference model configuration
        my_model_config.set_has_checks(1);
        my_model_config.set_algn_data_width(`DATA_WIDTH);
        my_model_config.set_vif(my_algn_vif);
    endfunction

    virtual function void configure_algn_scoreboard(ref algn_scoreboard_config my_algn_scoreboard_config);

        // Scoreboard config: attach the alignment vif, thresholds and data width
        my_algn_scoreboard_config.set_vif(my_algn_vif);
        my_algn_scoreboard_config.set_has_checks(1);
        my_algn_scoreboard_config.set_expected_rx_response_threshold(10);
        my_algn_scoreboard_config.set_expected_tx_item_threshold(10);
        my_algn_scoreboard_config.set_expected_irq_threshold(20);
        my_algn_scoreboard_config.set_algn_data_width(`DATA_WIDTH);
    endfunction

    virtual function void configure_algn_env();
    
        // Declare which subcomponents the algn_env should create and enable
        my_algn_env_config.set_vif(my_algn_vif);
        my_algn_env_config.set_has_apb_agent(1);
        my_algn_env_config.set_has_md_slave_agent(1);
        my_algn_env_config.set_has_md_master_agent(1);
        my_algn_env_config.set_has_algn_model(1);
        my_algn_env_config.set_has_algn_scoreboard(1);
        my_algn_env_config.set_has_coverage(1);

        // Attach per-component config objects to the env config
        my_algn_env_config.set_apb_agent_config(my_apb_agent_config);
        my_algn_env_config.set_md_slave_agent_config(my_md_slave_agent_config);
        my_algn_env_config.set_md_master_agent_config(my_md_master_agent_config);
        my_algn_env_config.set_model_config(my_model_config);
        my_algn_env_config.set_algn_scoreboard_config(my_algn_scoreboard_config);
        
        // Push the environment config object into the UVM configuration database
        // so algn_env and its subcomponents can retrieve it in their build_phase.
        uvm_config_db#(algn_env_config)::set(null, "*", "algn_env_config", my_algn_env_config);
    endfunction


    virtual function void display_configurations();
        apb_agent_configration_message = {
                    $sformatf("configure_apb_agent is done with\n"),
                    $sformatf("         has_checks   = %0b\n",my_apb_agent_config.get_has_checks()),
                    $sformatf("         has_coverage = %0b\n",my_apb_agent_config.get_has_coverage()),
                    $sformatf("         is_active    = %0b\n",my_apb_agent_config.get_is_active()),
                    $sformatf("         stuck_threshold = %0dcycles\n",my_apb_agent_config.get_stuck_threshold()),
                    $sformatf("         sample_delay_start_tr = %0tns\n",my_apb_agent_config.get_sample_delay_start_tr())
                };

        md_master_agent_configration_message = {
                    $sformatf("configure_md_master_agent is done with\n"),
                    $sformatf("         has_checks   = %0b\n",my_md_master_agent_config.get_has_checks()),
                    $sformatf("         has_coverage = %0b\n",my_md_master_agent_config.get_has_coverage()),
                    $sformatf("         is_active    = %0b\n",my_md_master_agent_config.get_is_active()),
                    $sformatf("         stuck_threshold = %0dcycles\n",my_md_master_agent_config.get_stuck_threshold()),
                    $sformatf("         sample_delay_start_tr = %0tns\n",my_md_master_agent_config.get_sample_delay_start_tr())
                };

        md_slave_agent_configration_message = {
                    $sformatf("configure_md_slave_agent is done with\n"),
                    $sformatf("         has_checks   = %0b\n",my_md_slave_agent_config.get_has_checks()),
                    $sformatf("         has_coverage = %0b\n",my_md_slave_agent_config.get_has_coverage()),
                    $sformatf("         is_active    = %0b\n",my_md_slave_agent_config.get_is_active()),
                    $sformatf("         stuck_threshold = %0dcycles\n",my_md_slave_agent_config.get_stuck_threshold()),
                    $sformatf("         sample_delay_start_tr = %0tns\n",my_md_slave_agent_config.get_sample_delay_start_tr())
                };


        `uvm_info("CONFIG",apb_agent_configration_message, UVM_FULL)
        `uvm_info("CONFIG",md_master_agent_configration_message, UVM_FULL)
        `uvm_info("CONFIG",md_slave_agent_configration_message, UVM_FULL)
    endfunction : display_configurations

endclass : test_base

`endif
