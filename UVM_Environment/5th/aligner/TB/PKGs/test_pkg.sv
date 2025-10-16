///////////////////////////////////////////////////////////////////////////////
// File:        test_pkg.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: UVM Test Package for Aligner Verification Environment
//
// -----------------------------------------------------------------------------
// Overview:
// This package defines and includes all the components, tests, and dependencies
// required to verify the Aligner DUT functionality under different conditions.
//
// The Aligner DUT is responsible for aligning MD (Metadata) packets found in
// the RX FIFO and pushing the aligned data into the TX FIFO. To verify this,
// the UVM testbench uses an environment composed of multiple agents, sequences,
// and configuration classes. The test_pkg serves as the central container that
// collects all required files for building and running UVM tests.
//
// -----------------------------------------------------------------------------
// Verification Flow:
//
// 1. **Compilation Phase**
//    - This package imports all dependent packages (APB, MD, RAL, ENV).
//    - Includes base and derived test classes that define the simulation flow.
//
// 2. **Build Phase**
//    - Each test (e.g., `test_reg_access`, `md_random_test`) creates the
//      verification environment (`algn_env`) and configures its agents.
//
// 3. **Run Phase**
//    - Tests execute sequences that drive stimuli via agents and check DUT
//      responses using scoreboards and monitors.
//
// 4. **Reporting Phase**
//    - UVM phases conclude with reporting and coverage collection.
//
// -----------------------------------------------------------------------------
// Included Files:
//
//   - env_pkg.sv           : Environment and related components
//   - test_base.sv         : Base test class with common setup
//   - test_reg_access.sv   : Register access test (APB configuration)
//   - md_random_test.sv    : Randomized MD packet stimulus test
//   - algn_test_random_rx_err.sv : Randomized RX error injection test
//
// -----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef TEST_PKG
  `define TEST_PKG

  // Include UVM macros and environment package
  `include "uvm_macros.svh"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/env_pkg.sv"

  //----------------------------------------------------------------------------
  // Package Declaration
  //----------------------------------------------------------------------------
  package test_pkg;

    // ---------------------------------------------------------
    // Import required packages
    // ---------------------------------------------------------
    import uvm_pkg::*;       // UVM base classes
    import md_pkg::*;        // Metadata (MD) protocol definitions
    import apb_pkg::*;       // APB agent and transaction types
    import RAL_pkg::*;       // Register Abstraction Layer package
    import env_pkg::*;       // Environment definitions (algn_env, config, etc.)

    // ---------------------------------------------------------
    // Include all UVM test classes
    // ---------------------------------------------------------

    // Base test: sets up common environment configuration
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Tests/test_base.sv"

    // Functional tests for DUT verification
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Tests/test_reg_access.sv"       // APB register access test
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Tests/md_random_test.sv"        // Random metadata alignment test
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Tests/algn_test_random_rx_err.sv" // RX error stress test

  endpackage : test_pkg

`endif
