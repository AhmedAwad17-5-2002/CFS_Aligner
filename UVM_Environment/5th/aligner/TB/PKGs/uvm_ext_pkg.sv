///////////////////////////////////////////////////////////////////////////////
// File:        uvm_ext_pkg.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        12/10/2025
// Description: Extended UVM Package for External Interface Verification
//
// ---------------------------------------------------------------------------
// OVERVIEW:
// This package defines the **Extended UVM (uvm_ext)** layer for verifying the
// external interface of the Aligner DUT. It gathers all related UVM components,
// configurations, and interfaces into a single package, ensuring modular,
// reusable, and scalable testbench organization.
//
// The external interface (EXT) is typically responsible for communicating
// between the DUT and its surrounding environment (e.g., PHY, FIFO, or other
// logic). To properly verify this interface, the package provides all the
// required UVM building blocks such as:
//
//   1. Configuration object      → Controls agent behavior (active/passive, etc.)
//   2. Virtual interface handler → Synchronizes resets and interface signals
//   3. Monitor                   → Observes DUT interface activity and collects data
//   4. Coverage collector        → Tracks functional coverage for verification goals
//   5. Sequencer                 → Controls sequence item flow to the driver
//   6. Driver                    → Drives stimuli to the DUT interface
//   7. Agent                     → Wraps driver, monitor, sequencer, and config
//
// ---------------------------------------------------------------------------
// FLOW DESCRIPTION:
// 1. The **agent configuration** is first created and initialized with interface
//    handles, mode settings, and reset behavior.
// 2. The **reset handler interface** is used to manage reset synchronization
//    between UVM components and the DUT.
// 3. The **sequencer** coordinates transaction sequences sent to the **driver**,
//    which then drives these transactions to the DUT via the virtual interface.
// 4. The **monitor** continuously observes the interface signals and reports
//    activity (e.g., transactions or events) through analysis ports.
// 5. The **coverage collector** subscribes to the monitor’s analysis port to
//    accumulate coverage metrics and ensure verification completeness.
// 6. Finally, the **agent** acts as the container managing all the above
//    components, enabling easy instantiation inside a higher-level UVM
//    environment such as `algn_env`.
//
// This modular structure enables easier debugging, improved reuse across
// projects, and better maintainability for the overall UVM testbench.
//
// ---------------------------------------------------------------------------
// FILE ORGANIZATION:
// Each subcomponent is defined in a separate `.sv` file and included here:
//
//   - uvm_ext_agent_config.sv         → Defines configuration object
//   - uvm_ext_reset_handler_if.sv     → Handles reset interface logic
//   - uvm_ext_monitor.sv              → Observes DUT activity
//   - uvm_ext_coverage.sv             → Defines functional coverage collection
//   - uvm_ext_sequencer.sv            → Manages sequence control
//   - uvm_ext_driver.sv               → Drives stimulus to DUT
//   - uvm_ext_agent.sv                → Integrates all EXT components
//
// ---------------------------------------------------------------------------
// USAGE:
//   - Import this package in your testbench files as:
//       `import uvm_ext_pkg::*;`
//
//   - Instantiate the EXT agent inside your environment:
//       my_ext_agent = uvm_ext_agent::type_id::create("my_ext_agent", this);
//
//   - Configure and connect as required during build and connect phases.
//
// ---------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef UVM_EXT_PKG
`define UVM_EXT_PKG

  // Include standard UVM macros
  `include "uvm_macros.svh"

  //--------------------------------------------------------------------------
  // Package: uvm_ext_pkg
  // - Contains all UVM EXT (external interface) verification components.
  // - Provides modular inclusion and reuse across different environments.
  //--------------------------------------------------------------------------
  package uvm_ext_pkg;

    // Import core UVM package symbols and classes
    import uvm_pkg::*;

    //--------------------------------------------------------------------------
    // Include all EXT verification components
    // (Paths preserved exactly as provided by the user)
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_agent_config.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_reset_handler_if.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_monitor.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_coverage.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_sequencer.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_driver.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/EXT/uvm_ext_agent.sv"

  endpackage : uvm_ext_pkg

`endif // UVM_EXT_PKG
