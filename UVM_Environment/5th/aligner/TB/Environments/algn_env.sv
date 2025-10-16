///////////////////////////////////////////////////////////////////////////////
// File:        algn_env.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        12/10/2025
// Description: UVM Environment for Alignment Controller Verification
// ---------------------------------------------------------------------------
// Detailed Description & Flow:
// This file defines the `algn_env` UVM environment — the top-level verification
// container for the Alignment Controller DUT. It is responsible for creating,
// configuring, connecting, and synchronizing all verification components used
// to stimulate, observe, and check the DUT behavior.
//
// The environment is parameterized by DATA_WIDTH to allow reuse across
// different interface widths and supports flexible configuration via
// `algn_env_config`.
//
// ---------------------------------------------------------------------------
// High-Level Verification Flow
// ---------------------------------------------------------------------------
//
// 1. Test / Env Construction
//    - The UVM testbench or top-level test creates `algn_env` using the UVM factory.
//    - Configuration objects (e.g., algn_env_config, agent configs, model config,
//      scoreboard config) are placed into the uvm_config_db by the testbench.
//
// 2. build_phase
//    - The environment retrieves its configuration object (`algn_env_config`).
//    - Depending on flags in the config, it conditionally builds:
//         • APB agent (bus interface to DUT)
//         • MD master/slave agents (data traffic generators/monitors)
//         • Register model (algn_model) and predictor
//         • Scoreboard and coverage collector
//    - Configuration handles for model, agents, and scoreboard are propagated
//      into the config_db for subcomponents.
//
// 3. connect_phase
//    - Instantiates APB-to-register adapter and connects APB monitor outputs
//      to the register predictor (keeps model in sync).
//    - Connects MD agents’ monitor ports to the model and scoreboard.
//    - Maps the register model’s default_map to the APB sequencer so that
//      register sequences can be issued through APB.
//    - Sets up virtual sequencer references for coordinated sequencing.
//
// 4. run_phase / Reset Handling
//    - The environment continuously monitors DUT reset.
//    - When reset is asserted, it triggers handle_reset() in model,
//      scoreboard, and coverage components.
//    - After reset deassertion, normal operation resumes automatically.
//
// 5. Scoreboarding & Coverage
//    - The scoreboard compares model-predicted transactions against DUT output.
//    - The coverage collector tracks functional events for regression metrics.
//
// 6. Extensibility
//    - The environment supports adding new agents, monitors, or analysis
//      components through configuration without structural changes.
// ---------------------------------------------------------------------------
// Notes:
//  - The testbench must populate the uvm_config_db with appropriate configs.
//  - All subcomponent creation and connections are conditional, allowing
//    scalable verification (e.g., smoke vs. full regressions).
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_ENV
`define ALGN_ENV
// import uvm_ext_pkg::*;   // Uncomment if using UVM extensions beyond base UVM

//------------------------------------------------------------------------------
// Class: algn_env
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH for flexible bus sizing.
// - Extends uvm_env (base class for all UVM environments).
// - Implements uvm_ext_reset_handler_if for asynchronous reset handling.
// - Builds all UVM components (agents, model, predictor, scoreboard, etc.).
//------------------------------------------------------------------------------
class algn_env #(int unsigned DATA_WIDTH = `DATA_WIDTH)
  extends uvm_env
  implements uvm_ext_reset_handler_if;

  //--------------------------------------------------------------------------
  // Interface, Port, and Field Declarations
  //--------------------------------------------------------------------------

  // Core agents and components
  apb_agent                                         my_apb_agent;          // APB agent (control interface)
  md_master_agent #(.DATA_WIDTH(DATA_WIDTH))        my_md_master_agent;    // MD Master agent (RX direction)
  md_slave_agent  #(.DATA_WIDTH(DATA_WIDTH))        my_md_slave_agent;     // MD Slave agent (TX direction)
  algn_env_config #(.DATA_WIDTH(DATA_WIDTH))        my_algn_env_config;    // Environment configuration

  // Register model & predictor
  algn_model #(.DATA_WIDTH(DATA_WIDTH))             my_algn_model;         // DUT behavioral register model
  reg_predictor#(.BUSTYPE(apb_mon_item),
                 .DATA_WIDTH(DATA_WIDTH))           my_reg_predictor;      // Register predictor
  apb_reg_adapter                                   my_apb_reg_adapter;    // Adapter: APB <-> Register model

  // Scoreboard & Coverage
  algn_scoreboard                                   my_algn_scoreboard;    // Functional checker
  algn_scoreboard_config #(.DATA_WIDTH(DATA_WIDTH)) my_algn_scoreboard_config;
  algn_coverage                                     my_algn_coverage;      // Coverage collector

  // Virtual sequencer (coordinates multiple sequencers)
  algn_virtual_sequencer                            my_algn_virtual_sequencer;

  // MD data adapters (bridge MD monitors to model/scoreboard)
  algn_md_adapter                                   algn_md_master_adapter;
  algn_md_adapter                                   algn_md_slave_adapter;

  //--------------------------------------------------------------------------
  // UVM Factory Registration
  //--------------------------------------------------------------------------
  `uvm_component_param_utils(algn_env #(.DATA_WIDTH(DATA_WIDTH)))

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "algn_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  //--------------------------------------------------------------------------
  // build_phase
  // - Retrieves the environment configuration.
  // - Conditionally creates all UVM subcomponents.
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve configuration object from config_db
    if (!uvm_config_db#(algn_env_config)::get(this, "*", "algn_env_config", my_algn_env_config)) begin
      `uvm_fatal("CFG", "algn_env_config not found in configuration database")
    end
    else begin
      // Register model & predictor
      if (my_algn_env_config.get_has_algn_model()) begin
        my_algn_model = algn_model#(.DATA_WIDTH(DATA_WIDTH))::type_id::create("my_algn_model", this);
        my_reg_predictor = reg_predictor#(apb_mon_item)::type_id::create("my_reg_predictor", this);

        // Propagate model configuration to subcomponents
        uvm_config_db#(model_config#(.DATA_WIDTH(DATA_WIDTH)))::set(
          this, "*", "my_model_config", my_algn_env_config.get_model_config());
      end

      // Create MD Master agent
      if (my_algn_env_config.get_has_md_master_agent()) begin
        my_md_master_agent = md_master_agent#(.DATA_WIDTH(DATA_WIDTH))::type_id::create("my_md_master_agent", this);
        uvm_config_db#(uvm_ext_pkg::uvm_ext_agent_config#(md_vif))::set(
          this, "my_md_master_agent", "my_agent_config", my_algn_env_config.get_md_master_agent_config());
      end

      // Create APB agent
      if (my_algn_env_config.get_has_apb_agent()) begin
        my_apb_agent = apb_agent::type_id::create("my_apb_agent", this);
        uvm_config_db#(uvm_ext_pkg::uvm_ext_agent_config#(apb_vif))::set(
          this, "my_apb_agent", "my_agent_config", my_algn_env_config.get_apb_agent_config());
      end

      // Create MD Slave agent
      if (my_algn_env_config.get_has_md_slave_agent()) begin
        my_md_slave_agent = md_slave_agent#(.DATA_WIDTH(DATA_WIDTH))::type_id::create("my_md_slave_agent", this);
        uvm_config_db#(uvm_ext_pkg::uvm_ext_agent_config#(md_vif))::set(
          this, "my_md_slave_agent", "my_agent_config", my_algn_env_config.get_md_slave_agent_config());
      end

      // Create Coverage collector
      if (my_algn_env_config.get_has_coverage()) begin
        my_algn_coverage = algn_coverage::type_id::create("my_algn_coverage", this);
      end
    end

    // Create Scoreboard if enabled
    if (my_algn_env_config.get_has_algn_scoreboard()) begin
      my_algn_scoreboard = algn_scoreboard#(.DATA_WIDTH(DATA_WIDTH))::type_id::create("my_algn_scoreboard", this);
      uvm_config_db#(algn_scoreboard_config#(.DATA_WIDTH(DATA_WIDTH)))::set(
        this, "my_algn_scoreboard", "my_algn_scoreboard_config", my_algn_env_config.get_algn_scoreboard_config());
    end

    // Create virtual sequencer and MD adapters
    my_algn_virtual_sequencer = algn_virtual_sequencer::type_id::create("my_algn_virtual_sequencer", this);
    algn_md_master_adapter = algn_md_adapter::type_id::create("algn_md_master_adapter", this);
    algn_md_slave_adapter  = algn_md_adapter::type_id::create("algn_md_slave_adapter", this);

  endfunction : build_phase

  //--------------------------------------------------------------------------
  // connect_phase
  // - Establishes all connections between agents, adapters, model, and scoreboard.
  //--------------------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    my_apb_reg_adapter = apb_reg_adapter::type_id::create("my_apb_reg_adapter", this);
    super.connect_phase(phase);

    if (my_algn_env_config.get_has_algn_model()) begin
      // Register model <-> predictor connections
      my_reg_predictor.adapter = my_apb_reg_adapter;
      my_reg_predictor.map     = my_algn_model.my_reg_block.default_map;
      my_algn_model.my_reg_block.default_map.set_sequencer(
        my_apb_agent.my_sequencer, my_apb_reg_adapter);
      my_apb_agent.my_monitor.monitor_aport.connect(my_reg_predictor.bus_in);

      // Connect MD adapters to model ports
      algn_md_master_adapter.algn_md_adapter_aport.connect(my_algn_model.port_in_rx);
      algn_md_slave_adapter.algn_md_adapter_aport.connect(my_algn_model.port_in_tx);

      // Connect model handle to virtual sequencer
      my_algn_virtual_sequencer.my_algn_model = my_algn_model;
    end

    // Connect model and agents to the scoreboard
    if (my_algn_env_config.get_has_algn_scoreboard()) begin
      my_algn_model.port_out_rx.connect(my_algn_scoreboard.port_in_model_rx);
      my_algn_model.port_out_tx.connect(my_algn_scoreboard.port_in_model_tx);
      my_algn_model.port_out_irq.connect(my_algn_scoreboard.port_in_model_irq);

      algn_md_master_adapter.algn_md_adapter_aport.connect(my_algn_scoreboard.port_in_agent_rx);
      algn_md_slave_adapter.algn_md_adapter_aport.connect(my_algn_scoreboard.port_in_agent_tx);
    end

    // Connect coverage if enabled
    if (my_algn_env_config.get_has_coverage() && my_algn_env_config.get_has_algn_model()) begin
      my_algn_model.port_out_split_info.connect(my_algn_coverage.port_in_split_info);
    end

    // Virtual sequencer channel setup
    if (my_algn_env_config.get_has_apb_agent())
      my_algn_virtual_sequencer.apb_sequencer = my_apb_agent.my_sequencer;

    if (my_algn_env_config.get_has_md_master_agent())
      my_algn_virtual_sequencer.md_rx_sequencer = md_master_sequencer'(my_md_master_agent.my_sequencer);

    if (my_algn_env_config.get_has_md_slave_agent())
      my_algn_virtual_sequencer.md_tx_sequencer = md_slave_sequencer'(my_md_slave_agent.my_sequencer);

    // Connect monitor analysis ports to adapters
    my_md_master_agent.my_monitor.monitor_aport.connect(algn_md_master_adapter.port_in_md_adapter);
    my_md_slave_agent.my_monitor.monitor_aport.connect(algn_md_slave_adapter.port_in_md_adapter);
  endfunction : connect_phase

  //--------------------------------------------------------------------------
  // Reset Handling
  //--------------------------------------------------------------------------

  // Handles component resets when triggered
  virtual function void handle_reset(uvm_phase phase);
    if (my_algn_env_config.get_has_algn_model())
      my_algn_model.handle_reset(phase);

    if (my_algn_env_config.get_has_algn_scoreboard())
      my_algn_scoreboard.handle_reset(phase);

    if (my_algn_env_config.get_has_coverage())
      my_algn_coverage.handle_reset(phase);
  endfunction

  // Wait for reset start/end signals through agent configs
  protected virtual task wait_reset_start();
    my_apb_agent.my_agent_config.wait_reset_start();
  endtask

  protected virtual task wait_reset_end();
    my_apb_agent.my_agent_config.wait_reset_end();
  endtask

  // Continuously monitor reset cycles and reinitialize components
  virtual task run_phase(uvm_phase phase);
    forever begin
      wait_reset_start();
      handle_reset(phase);
      wait_reset_end();
    end
  endtask

endclass : algn_env

`endif
