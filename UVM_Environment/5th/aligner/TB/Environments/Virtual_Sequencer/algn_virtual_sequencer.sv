///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequencer.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        12/10/2025
//
// Description: 
// -----------------------------------------------------------------------------
// This file defines the *virtual sequencer* for the Alignment Controller UVM 
// environment.
//
// The purpose of this virtual sequencer is to provide a top-level coordination 
// layer that synchronizes and controls multiple lower-level sequencers operating 
// on different interfaces of the DUT (Design Under Test). 
//
// In this testbench, the DUT is responsible for aligning MD (Metadata) packets 
// received through an RX interface and transmitting the aligned packets through 
// a TX interface, under the control of an APB interface.
//
// The virtual sequencer enables higher-level virtual sequences to:
//   - Start sequences concurrently on APB, RX, and TX sequencers.
//   - Coordinate transactions between these interfaces (e.g., configure DUT via 
//     APB before sending/receiving MD data).
//   - Access the reference model (algn_model) to compare DUT and model behavior.
//
// FLOW OVERVIEW:
// -----------------------------------------------------------------------------
// 1. The UVM test creates the virtual sequencer and the lower-level sequencers 
//    (APB, MD_RX, MD_TX).
// 2. A virtual sequence is started on this virtual sequencer.
// 3. The virtual sequence drives sub-sequences on APB, RX, and TX sequencers
//    through the references defined here.
// 4. The algn_model can be used by the virtual sequence to synchronize expected 
//    behavior with the DUT output or to verify alignment logic correctness.
// -----------------------------------------------------------------------------
//
// This component is a container only; it does not run sequences by itself but 
// provides handles for other sequences to coordinate multi-interface activity.
//
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCER
`define ALGN_VIRTUAL_SEQUENCER

//------------------------------------------------------------------------------
// Class: algn_virtual_sequencer
// Type : UVM virtual sequencer
//------------------------------------------------------------------------------
class algn_virtual_sequencer extends uvm_sequencer;
  
  // Register this component with the UVM factory
  `uvm_component_utils(algn_virtual_sequencer)

  //--------------------------------------------------------------------------
  // References to lower-level sequencers
  //--------------------------------------------------------------------------

  // Reference to the APB sequencer
  // - Drives configuration and control transactions to the DUT
  uvm_sequencer_base apb_sequencer;

  // Reference to the MD RX sequencer
  // - Drives input MD packets into the DUT’s RX FIFO interface
  md_master_sequencer md_rx_sequencer;

  // Reference to the MD TX sequencer
  // - Monitors or coordinates output packets from the DUT’s TX FIFO interface
  md_slave_sequencer md_tx_sequencer;

  //--------------------------------------------------------------------------
  // Reference to the model
  //--------------------------------------------------------------------------

  // Handle to the alignment reference model
  // - Used for prediction and comparison with DUT behavior
  algn_model my_algn_model;

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  // Creates the virtual sequencer instance and registers it under the UVM tree.
  //
  // Parameters:
  //   name   : Instance name for the sequencer
  //   parent : Handle to the parent UVM component (usually env or test)
  //--------------------------------------------------------------------------
  function new(string name = "algn_virtual_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass : algn_virtual_sequencer

`endif // ALGN_VIRTUAL_SEQUENCER
