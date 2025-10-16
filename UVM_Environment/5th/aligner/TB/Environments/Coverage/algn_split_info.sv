///////////////////////////////////////////////////////////////////////////////
// File:        algn_split_info.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        12/10/2025
// Description: UVM Object - Alignment Split Information
//------------------------------------------------------------------------------
// OVERVIEW:
// This class (`algn_split_info`) is a lightweight data container (extending
// `uvm_object`) used to store and share information related to how an MD
// (Metadata) packet is split and processed inside the Alignment Controller.
//
// In the alignment process, packets received from the RX FIFO might need to
// be divided (split) into smaller aligned segments before being pushed to
// the TX FIFO. This class holds all relevant parameters describing one such
// split operation.
//
// FLOW DESCRIPTION:
// 1. The Alignment Controller or its model identifies a Metadata (MD) packet
//    that requires alignment or splitting.
// 2. For each split operation, an instance of `algn_split_info` is created.
// 3. The fields in this object are populated with computed values:
//      - `ctrl_offset`  → Offset in the control structure indicating start position.
//      - `ctrl_size`    → Size of the control segment.
//      - `md_offset`    → Offset within the Metadata transaction to be split.
//      - `md_size`      → Size of that Metadata portion.
//      - `num_bytes_needed` → Total bytes needed to complete the alignment.
// 4. This object can then be passed between different verification components
//    (e.g., model, scoreboard, monitor) to ensure consistent tracking and
//    comparison of expected vs actual alignment behavior.
//
// In short, `algn_split_info` acts as a *data record* that captures the details
// of one split operation during the MD packet alignment process.
//
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_SPLIT_INFO_SV
`define ALGN_SPLIT_INFO_SV

//------------------------------------------------------------------------------
// Class: algn_split_info
//------------------------------------------------------------------------------
// A UVM object used to hold metadata about a single MD split operation.
// This includes offsets, sizes, and the number of bytes required for alignment.
//------------------------------------------------------------------------------
class algn_split_info extends uvm_object;

  //--------------------------------------------------------------------------
  // Fields
  //--------------------------------------------------------------------------

  // Value of CTRL.OFFSET:
  // Indicates the starting offset (in bytes) within the control structure
  // that corresponds to this split segment.
  int unsigned ctrl_offset;

  // Value of CTRL.SIZE:
  // Indicates the total size (in bytes) of the control structure section
  // associated with this split.
  int unsigned ctrl_size;

  // Value of the MD transaction offset:
  // Marks the starting byte position of the MD packet portion being processed.
  int unsigned md_offset;

  // Value of the MD transaction size:
  // Indicates how many bytes are part of this MD split segment.
  int unsigned md_size;

  // Number of bytes needed during the split:
  // Represents the number of bytes required to complete this partial MD packet
  // before it can be transmitted or processed further.
  int unsigned num_bytes_needed;

  //--------------------------------------------------------------------------
  // UVM Factory registration
  //--------------------------------------------------------------------------
  // Registers this class with the UVM factory for dynamic creation and
  // automation through the UVM configuration database.
  `uvm_object_utils(algn_split_info)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  // Initializes the algn_split_info object with an optional instance name.
  function new(string name = "");
    super.new(name);
  endfunction : new

endclass : algn_split_info

`endif
