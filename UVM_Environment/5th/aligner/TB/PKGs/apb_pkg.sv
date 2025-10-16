///////////////////////////////////////////////////////////////////////////////
// File:        apb_pkg.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB package.
//              This package contains all APB-related UVM components including
//              configuration objects, sequence items, sequences, driver,
//              sequencer, monitor, and agent. 
//              It serves as a single entry point for importing the entire APB
//              verification infrastructure into the testbench.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_PKG
`define APB_PKG

  //------------------------------------------------------------------------------
  // UVM + Interface includes
  //------------------------------------------------------------------------------
  `include "uvm_macros.svh"   // Required UVM macros
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Interfaces/apb_if.sv"        // APB interface definition
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/uvm_ext_pkg.sv"
  //------------------------------------------------------------------------------
  // Package definition
  //------------------------------------------------------------------------------
  package apb_pkg;
    import uvm_pkg::*;        // Import UVM base classes
    import uvm_ext_pkg::*;

    // `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_reset_handler_if.sv" // interface class
    //--------------------------------------------------------------------------
    // APB Types and Config
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_types.sv"          // APB typedefs, enums, constants
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_agent_config.sv"   // Configuration object for APB agent
    
    //--------------------------------------------------------------------------
    // APB Transaction-Level Items
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_base_item.sv"      // Base transaction item
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_drv_item.sv"       // Driver transaction item
    
    //--------------------------------------------------------------------------
    // APB Agent Components
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_driver.sv"         // APB driver (drives DUT signals)
    // `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_sequencer.sv"      // APB sequencer (coordinates sequences)
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_mon_item.sv"       // Monitor transaction item
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_monitor.sv"        // APB monitor (observes DUT activity)


    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_coverage.sv"
    
    //--------------------------------------------------------------------------
    // APB Sequences
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_base_sequence.sv"  // Base sequence
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_simple_sequence.sv"// Simple APB sequence
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_rw_sequence.sv"    // Read/Write sequence
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_random_sequence.sv"// Random transaction sequence
    

    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_reg_adapter.sv"
    //--------------------------------------------------------------------------
    // APB Agent (container for driver, sequencer, monitor)
    //--------------------------------------------------------------------------
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/APB/apb_agent.sv"
    
  endpackage : apb_pkg

`endif
