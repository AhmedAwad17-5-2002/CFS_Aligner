/////////////////////////////////////////////////////////////////////////////// 
// File:        env_pkg.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        12/10/2025 
// Description: 
// -----------------------------------------------------------------------------
// Environment Package for the Aligner Verification Environment
// -----------------------------------------------------------------------------
// This package defines and includes all files required to build the complete 
// UVM-based verification environment for the **Aligner Controller DUT**. 
//
// The DUT (Aligner Controller) is responsible for aligning MD packets received 
// from the RX FIFO and transmitting the aligned data through the TX FIFO. 
//
// The verification environment ensures the DUT is verified functionally and 
// structurally using a UVM testbench built around the following key components:
//
// -----------------------------------------------------------------------------
// ► 1. PACKAGES IMPORTED
//    - apb_pkg.sv   : Provides APB agent and transaction classes to interface 
//                     with DUT's APB registers.
//    - md_pkg.sv    : Defines MD packet types and transaction items used for 
//                     RX/TX data verification.
//    - RAL_pkg.sv   : Contains Register Abstraction Layer (RAL) for register 
//                     modeling and access prediction.
//    - uvm_ext_pkg.sv : Contains UVM extensions or helper macros used globally.
//
// ► 2. INTERFACE INCLUDED
//    - algn_if.sv : Defines the DUT interface connecting the testbench to the 
//                   DUT (signals, clocking, modports).
//
// ► 3. ENVIRONMENT COMPONENTS INCLUDED
//    - algn_data_item.sv       : Basic transaction class representing Aligner data.
//    - algn_md_adapter.sv      : Adapter class for converting MD transactions 
//                                between the UVM model and the DUT signals.
//
// ► 4. COVERAGE COMPONENTS
//    - algn_split_info.sv, algn_coverage.sv : Coverage models to measure functional
//      verification completeness for packet alignment, control, and status events.
//
// ► 5. MODEL COMPONENTS
//    - model_config.sv         : Configuration class for the Aligner model.
//    - reg_predictor.sv        : Mirrors the DUT’s register state by monitoring APB 
//                                accesses, keeping the RAL model synchronized.
//    - algn_model.sv           : High-level behavioral model of the DUT, used for
//                                reference checking against DUT output.
//
// ► 6. SCOREBOARD COMPONENTS
//    - algn_scoreboard_config.sv : Configuration class for the scoreboard.
//    - algn_scoreboard.sv        : Compares DUT output transactions with expected
//                                  model outputs to ensure data correctness.
//
// ► 7. ENVIRONMENT CONFIGURATION
//    - algn_types.sv           : Defines enumerations, constants, and shared types.
//    - algn_env_config.sv      : Central configuration class connecting all 
//                                environment components and resources.
//
// ► 8. VIRTUAL SEQUENCER & SEQUENCES
//    - algn_virtual_sequencer.sv : Coordinates sequence execution across agents.
//    - algn_virtual_sequence_*.sv : Define various traffic and scenario sequences,
//                                   including register access, error injection,
//                                   slow pacing, and RX/TX behavior.
//
// ► 9. TOP-LEVEL ENVIRONMENT
//    - algn_env.sv : Assembles all agents, models, coverage, and scoreboard into 
//                    a unified UVM environment.
//
// -----------------------------------------------------------------------------
// FLOW SUMMARY:
// -----------------------------------------------------------------------------
// 1. The testbench imports this package (env_pkg).
// 2. The environment (`algn_env`) is instantiated by the top-level test.
// 3. APB agent drives register accesses → DUT.
// 4. MD packet stimuli are generated and sent → DUT RX FIFO.
// 5. DUT processes & aligns packets → outputs to TX FIFO.
// 6. The reference model predicts expected results.
// 7. The scoreboard compares DUT vs. model outputs.
// 8. Coverage monitors track verification progress.
// -----------------------------------------------------------------------------
//
// Notes:
// - File paths are kept absolute for clarity during development.
// - To improve portability, relative paths may later be used.
// ----------------------------------------------------------------------------- 
///////////////////////////////////////////////////////////////////////////////

`ifndef ENV_PKG
`define ENV_PKG

  // Include UVM macros and dependent packages
  `include "uvm_macros.svh"

  // ---------------------------------------------------------------------------
  // Import dependent packages and interface definitions
  // ---------------------------------------------------------------------------
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/apb_pkg.sv"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/md_pkg.sv"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/RAL_pkg.sv"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/uvm_ext_pkg.sv"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Interfaces/algn_if.sv"

  // ---------------------------------------------------------------------------
  // Package Definition
  // ---------------------------------------------------------------------------
  package env_pkg;

    // Import essential packages
    import uvm_pkg::*;
    import uvm_ext_pkg::*;
    import apb_pkg::*;
    import md_pkg::*;
    import RAL_pkg::*;

    // -------------------------------------------------------------------------
    // Aligner Adapter & Data Definitions
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Algn_Adapter/algn_data_item.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Algn_Adapter/algn_md_adapter.sv"

    // -------------------------------------------------------------------------
    // Coverage Definitions
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Coverage/algn_split_info.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Coverage/algn_coverage.sv"

    // -------------------------------------------------------------------------
    // Environment Types and Configuration
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/algn_types.sv"      
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Algner_Model/model_config.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Scoreboard/algn_scoreboard_config.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/algn_env_config.sv"

    // -------------------------------------------------------------------------
    // Reference Model and Scoreboard
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Algner_Model/reg_predictor.sv" // Register state mirroring
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Algner_Model/algn_model.sv"    // DUT reference model
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Scoreboard/algn_scoreboard.sv" // Data comparison logic

    // -------------------------------------------------------------------------
    // Virtual Sequencer & Sequences
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequencer/algn_virtual_sequencer.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_base.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_slow_pace.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_reg_access_random.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_reg_access_unmapped.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_reg_config.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_reg_status.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_rx.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/Virtual_Sequences/algn_virtual_sequence_rx_err.sv"

    // -------------------------------------------------------------------------
    // Top-Level Environment
    // -------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Environments/algn_env.sv"

  endpackage : env_pkg

`endif
