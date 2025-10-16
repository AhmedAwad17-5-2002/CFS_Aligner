///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_rx_err.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: 
// -----------------------------------------------------------------------------
// This file defines the "algn_virtual_sequence_rx_err" class, which is a
// specialized virtual sequence extending the base "algn_virtual_sequence_rx".
// Its primary purpose is to generate *erroneous RX sequences* for negative
// testing of the Aligner DUT.
//
// -----------------------------
// Functional Overview:
// -----------------------------
// The Aligner DUT is designed to process MD packets from the RX FIFO,
// realign them, and push aligned data into the TX FIFO. However, to ensure
// robust error handling, verification must inject *invalid or misaligned*
// RX transactions.
//
// This virtual sequence ensures that by applying randomized constraints that
// deliberately create RX data patterns violating alignment or packet structure.
//
// -----------------------------
// Flow Summary:
// -----------------------------
// 1. **Parent Relation**: Inherits from `algn_virtual_sequence_rx`, meaning it
//    reuses all the standard RX traffic generation features.
// 2. **Illegal Constraint** (`illegal_rx_hard`):
//    - Ensures generated packets have invalid alignment or overflow relative
//      to the aligner data width.
//    - Two main checks:
//        a) Misalignment: data size + offset doesn’t align to the data bus width.
//        b) Overflow: combined offset and packet size exceed the legal data width.
// 3. **Configuration Access**:
//    - Before randomization, it retrieves the aligner’s data width from the
//      environment configuration through the virtual sequencer.
// 4. **Result**:
//    - Produces randomized, invalid RX data scenarios to trigger DUT error paths,
//      essential for coverage and robustness testing.
//
// -----------------------------
// Hierarchy Context:
// -----------------------------
// uvm_test_top
//   └── algn_env
//        └── algn_virtual_sequencer
//              ├── algn_virtual_sequence_rx
//              └── algn_virtual_sequence_rx_err  <-- (This file)
// -----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_RX_ERR_SV
`define ALGN_VIRTUAL_SEQUENCE_RX_ERR_SV

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_rx_err
//------------------------------------------------------------------------------
// - Extends: algn_virtual_sequence_rx
// - Purpose: Generates randomized RX transactions with illegal configurations
//            (misaligned or overflowing packet sizes).
// - Usage:   Used in negative testing scenarios to verify DUT error handling.
//------------------------------------------------------------------------------
class algn_virtual_sequence_rx_err extends algn_virtual_sequence_rx;
  
  //--------------------------------------------------------------------------
  // Local Variables
  //--------------------------------------------------------------------------
  // Aligner data width retrieved from model configuration
  local int unsigned algn_data_width;
  
  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  // illegal_rx_hard:
  // - Enforces that generated RX packets are misaligned or exceed valid limits.
  // - Ensures coverage for DUT’s error-handling logic.
  constraint illegal_rx_hard {
    (
      // Case 1: Misalignment — packet size + offset not bus-aligned
      (((algn_data_width / 8) + seq.my_md_drv_master_item.offset) 
        % seq.my_md_drv_master_item.data.size() != 0)
    )
    ||
    (
      // Case 2: Overflow — total bytes exceed data bus width
      ((seq.my_md_drv_master_item.data.size() 
        + seq.my_md_drv_master_item.offset) > (algn_data_width / 8))
    );
  }

  //--------------------------------------------------------------------------
  // UVM Factory Registration
  //--------------------------------------------------------------------------
  `uvm_object_utils(algn_virtual_sequence_rx_err)
  
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction
  
  //--------------------------------------------------------------------------
  // pre_randomize()
  //--------------------------------------------------------------------------
  // - Called before randomization begins.
  // - Retrieves the aligner data width from the configuration database
  //   through the virtual sequencer’s model handle.
  //--------------------------------------------------------------------------
  function void pre_randomize();
    super.pre_randomize();
    
    // Access configuration from the model (dynamic width retrieval)
    algn_data_width = p_sequencer.my_algn_model.my_model_config.get_algn_data_width();
  endfunction
  
endclass : algn_virtual_sequence_rx_err

`endif
