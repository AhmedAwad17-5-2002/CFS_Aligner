///////////////////////////////////////////////////////////////////////////////
// File:        RAL_pkg.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM Register Abstraction Layer (RAL) package for the
//              Alignment Controller verification environment.
//              This package imports the UVM library and includes all the
//              register description files (reg_ctrl, reg_status, reg_irqen,
//              reg_irq, reg_block, reg_model). These describe the DUT’s
//              registers and provide a standard UVM RAL model to access them
//              for read/write operations during testbench simulations.
///////////////////////////////////////////////////////////////////////////////

`ifndef RAL_PKG
`define RAL_PKG

  //------------------------------------------------------------------------------
  // UVM Macros
  //------------------------------------------------------------------------------
  // Includes standard UVM macros (factory registration, reporting, etc.)
  // and any project-specific UVM extensions.
  `include "uvm_macros.svh"
  `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/uvm_ext_pkg.sv"

  //------------------------------------------------------------------------------
  // Package: RAL_pkg
  //------------------------------------------------------------------------------
  // - Collects all register definition files for the DUT’s RAL model.
  // - Provides a single point of import for the entire register model.
  //------------------------------------------------------------------------------
  package RAL_pkg;

    // Import the base UVM package and project extensions to access UVM RAL classes
    import uvm_pkg::*;
    import uvm_ext_pkg::*;

    //--------------------------------------------------------------------------
    // Individual Register Description Files
    //--------------------------------------------------------------------------
    // Each of these files defines a specific register or block used in the DUT.
    // Paths are absolute here; they can be switched to relative paths if preferred.
    
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_access_status_info.sv"
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/clr_cnt_drop.sv"

    // Core register definitions
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_ctrl.sv"     // Control register
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_status.sv"   // Status register
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_irqen.sv"    // Interrupt enable register
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_irq.sv"      // Interrupt status register

    // Register block and top-level RAL model
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/reg_block.sv"    // Register block aggregation
    

    // Optional sequences for RAL configuration
    `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/RAL_Model/seq_reg_config.sv"

  endpackage : RAL_pkg

`endif // RAL_PKG
