///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_rx.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: 
//   This file defines the "algn_virtual_sequence_rx" class, which extends the
//   base virtual sequence "algn_virtual_sequence_base". Its main purpose is to
//   coordinate and trigger the RX path sequence for the Alignment Controller DUT.
//
//   -------------------------------
//   OVERVIEW AND FLOW DESCRIPTION:
//   -------------------------------
//   1. The virtual sequence serves as a high-level controller that can start
//      lower-level sequences running on different sequencers within the
//      UVM environment.
//
//   2. In this specific sequence, "algn_virtual_sequence_rx" manages the
//      transmission of one "MD" packet transaction through the RX path.
//
//   3. The process flow is as follows:
//      - A `md_master_simple_sequence` is created.
//      - Before randomization, the sequence is linked to the appropriate 
//        sequencer (`md_rx_sequencer`) using `set_sequencer()`.
//      - During execution (inside `body()`), the sequence is started on the 
//        RX sequencer, which drives the MD transaction toward the DUT.
//
//   4. This structure provides flexibility to later extend the sequence to 
//      include coordination with TX paths or APB sequences if needed.
//
//   The class is registered with the UVM factory to allow dynamic creation
//   and to support randomization in more complex virtual sequences.
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_RX_SV
`define ALGN_VIRTUAL_SEQUENCE_RX_SV

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_rx
//------------------------------------------------------------------------------
// - Extends: algn_virtual_sequence_base
// - Role   : Runs a simple RX MD transaction sequence through the RX sequencer.
//------------------------------------------------------------------------------
class algn_virtual_sequence_rx extends algn_virtual_sequence_base;

  //--------------------------------------------------------------------------
  // Data Members
  //--------------------------------------------------------------------------
  // Sequence handle for sending one MD RX transaction.
  rand md_master_simple_sequence seq;

  //--------------------------------------------------------------------------
  // UVM Factory Registration
  //--------------------------------------------------------------------------
  // Allows the sequence to be created dynamically via the UVM factory.
  `uvm_object_utils(algn_virtual_sequence_rx)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  // - Initializes the base class and creates the sub-sequence instance.
  function new(string name = "");
    super.new(name);
    // Create the MD RX sequence instance using UVM factory
    seq = md_master_simple_sequence::type_id::create("seq");
  endfunction : new

  //--------------------------------------------------------------------------
  // pre_randomize()
  //--------------------------------------------------------------------------
  // - Called automatically before randomization.
  // - Assigns the correct sequencer handle to the sub-sequence.
  function void pre_randomize();
    super.pre_randomize();
    // Connect the MD sequence to the RX sequencer in the virtual sequencer
    seq.set_sequencer(p_sequencer.md_rx_sequencer);
  endfunction : pre_randomize

  //--------------------------------------------------------------------------
  // body()
  //--------------------------------------------------------------------------
  // - Main execution task of the virtual sequence.
  // - Starts the MD RX sequence on the corresponding sequencer.
  virtual task body();
    // Start the RX transaction sequence on the RX sequencer
    seq.start(p_sequencer.md_rx_sequencer);
  endtask : body

endclass : algn_virtual_sequence_rx

`endif
