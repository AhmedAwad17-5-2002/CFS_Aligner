///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_base.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: 
// ---------------------------------------------------------------------------
// UVM Virtual Sequence Base Class for the Alignment Controller Environment
// ---------------------------------------------------------------------------
// This class defines the *base virtual sequence* used to coordinate and 
// control multiple lower-level sequences that run on different sequencers 
// (e.g., APB sequencer, streaming sequencer, etc.) inside the UVM testbench.
//
// In a typical UVM environment, a *virtual sequencer* acts as a coordinator 
// that holds references to multiple interface sequencers. The *virtual 
// sequence* runs on that virtual sequencer and can start other sequences on 
// different interfaces simultaneously or in a controlled order.
//
// ------------------------- Flow Explanation -------------------------------
// 1. The test instantiates and starts a derived virtual sequence that 
//    extends this base class (`algn_virtual_sequence_base`).
// 2. The virtual sequence gets access to the `algn_virtual_sequencer`
//    through the `p_sequencer` handle (declared using the 
//    `uvm_declare_p_sequencer` macro).
// 3. From there, it can control sub-sequences (e.g., APB config sequence,
//    RX/TX stream sequences) to drive complex verification scenarios.
// 4. This base class serves as a generic starting point for all virtual
//    sequences, allowing reusability and consistent structure.
// ---------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_BASE
`define ALGN_VIRTUAL_SEQUENCE_BASE

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_base
//------------------------------------------------------------------------------
// - Base class for all virtual sequences in the Alignment Controller environment.
// - Declares the parent virtual sequencer type using `uvm_declare_p_sequencer`.
// - Provides a standard constructor and UVM factory registration.
//------------------------------------------------------------------------------
class algn_virtual_sequence_base extends uvm_sequence;

    //----------------------------------------------------------------------------
    // Macro: `uvm_declare_p_sequencer`
    // Binds this virtual sequence to the type of the virtual sequencer it runs on.
    // This allows the sequence to access sequencers and resources through
    // `p_sequencer`.
    //----------------------------------------------------------------------------
    `uvm_declare_p_sequencer(algn_virtual_sequencer)

    //----------------------------------------------------------------------------
    // Macro: `uvm_object_utils`
    // Registers this class with the UVM factory for dynamic creation.
    //----------------------------------------------------------------------------
    `uvm_object_utils(algn_virtual_sequence_base)
    
    //----------------------------------------------------------------------------
    // Function: new
    // Constructor for the virtual sequence.
    // - name: optional instance name for debug and reporting.
    //----------------------------------------------------------------------------
    function new(string name = "");
        super.new(name);
    endfunction : new

endclass : algn_virtual_sequence_base

`endif
