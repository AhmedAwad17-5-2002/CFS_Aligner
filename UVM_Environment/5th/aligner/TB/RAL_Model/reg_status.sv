///////////////////////////////////////////////////////////////////////////////
// File:        reg_status.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-17
// Description: UVM Register Model for the STATUS register of the Alignment
//              Controller. This register provides read-only status fields:
//                * TX_LVL  : 8-bit transmit FIFO level
//                * RX_LVL  : 4-bit receive FIFO level
//                * CNT_DROP: 4-bit counter of dropped packets
//              The remaining upper bits (31:20) are reserved.
//              Used inside the UVM RAL to mirror and check DUT register values.
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_STATUS
`define REG_STATUS

//------------------------------------------------------------------------------
// UVM Register: reg_status
//------------------------------------------------------------------------------
// - Extends uvm_reg to model a 32-bit STATUS register.
// - Contains three read-only fields (TX_LVL, RX_LVL, CNT_DROP).
//------------------------------------------------------------------------------
class reg_status extends uvm_reg;

  //-------------------------------------------------------------------------
  // Register Fields
  //-------------------------------------------------------------------------
  rand uvm_reg_field TX_LVL;    // Transmit FIFO level (bits [19:16])
  rand uvm_reg_field RX_LVL;    // Receive  FIFO level (bits [11:8])
  rand uvm_reg_field CNT_DROP;  // Dropped packet count (bits [7:0])

  //-------------------------------------------------------------------------
  // UVM Factory registration
  //-------------------------------------------------------------------------
  `uvm_object_utils(reg_status)

  //-------------------------------------------------------------------------
  // Constructor
  //-------------------------------------------------------------------------
  // name        : instance name of this register
  // n_bits      : 32-bit register width
  // has_coverage: no built-in coverage (UVM_NO_COVERAGE)
  function new(string name = "my_reg_status");
    super.new(.name(name), .n_bits(32), .has_coverage(UVM_NO_COVERAGE));
  endfunction : new

  //-------------------------------------------------------------------------
  // Build Method
  //-------------------------------------------------------------------------
  // Creates and configures each field of the STATUS register.
  virtual function void build();
    // Create fields
    TX_LVL   = uvm_reg_field::type_id::create(.name("TX_LVL"),   .parent(null), .contxt(get_full_name()));
    RX_LVL   = uvm_reg_field::type_id::create(.name("RX_LVL"),   .parent(null), .contxt(get_full_name()));
    CNT_DROP = uvm_reg_field::type_id::create(.name("CNT_DROP"), .parent(null), .contxt(get_full_name()));

    // Configure CNT_DROP: bits [7:0], Read-Only, reset 0x00
    CNT_DROP.configure(
      .parent(this),
      .size(8),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(8'h00),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );

    // Configure RX_LVL: bits [11:8], Read-Only, reset 0x0
    RX_LVL.configure(
      .parent(this),
      .size(4),
      .lsb_pos(8),
      .access("RO"),
      .volatile(0),
      .reset(4'h0),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );

    // Configure TX_LVL: bits [19:16], Read-Only, reset 0x0
    TX_LVL.configure(
      .parent(this),
      .size(4),
      .lsb_pos(16),
      .access("RO"),
      .volatile(0),
      .reset(4'h0),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );
  endfunction : build

endclass : reg_status

`endif
