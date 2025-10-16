///////////////////////////////////////////////////////////////////////////////
// File:        reg_ctrl.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM register model for the Control Register (reg_ctrl).
//              This 32-bit register contains three fields:
//                • SIZE   : 3-bit read/write field at bit positions [2:0].
//                • OFFSET : 2-bit read/write field at bit positions [9:8].
//                • CLR    : 1-bit write-only field at bit position [16].
//              Used in the UVM RAL (Register Abstraction Layer) to mirror and
//              control the DUT register during verification.
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_CTRL
`define REG_CTRL

//------------------------------------------------------------------------------
// UVM Register: reg_ctrl
//------------------------------------------------------------------------------
// - Extends uvm_reg to model a 32-bit DUT control register.
// - Provides three configurable uvm_reg_field objects (SIZE, OFFSET, CLR).
// - Includes constraints to keep SIZE and OFFSET legal with respect to DATA_WIDTH.
//------------------------------------------------------------------------------
class reg_ctrl extends uvm_reg;

  //--------------------------------------------------------------------------
  // Register field handles
  //--------------------------------------------------------------------------
  rand uvm_reg_field SIZE;    // 3-bit RW field (bits [2:0])
  rand uvm_reg_field OFFSET;  // 2-bit RW field (bits [9:8])
  rand uvm_reg_field CLR;     // 1-bit WO field (bit [16])

  // Local parameter to track current data bus width (default = 8 bits)
  local int unsigned DATA_WIDTH;

  //--------------------------------------------------------------------------
  // Constraints to ensure valid SIZE/OFFSET values
  //--------------------------------------------------------------------------
  constraint legal_size {
    SIZE.value != 0;
  }

  constraint legal_size_offset {
    ((DATA_WIDTH / 8) + OFFSET.value) % SIZE.value == 0;
    OFFSET.value + SIZE.value <= (DATA_WIDTH / 8);
  }

  //--------------------------------------------------------------------------
  // UVM factory registration for dynamic creation
  //--------------------------------------------------------------------------
  `uvm_object_utils(reg_ctrl)

  //--------------------------------------------------------------------------
  // Constructor
  // - name : optional instance name (defaults to "my_reg_ctrl")
  // - 32-bit register width, coverage disabled (UVM_NO_COVERAGE)
  //--------------------------------------------------------------------------
  function new(string name = "my_reg_ctrl");
    super.new(.name(name), .n_bits(32), .has_coverage(UVM_NO_COVERAGE));
    DATA_WIDTH = 8;
  endfunction : new

  //--------------------------------------------------------------------------
  // Build
  // - Creates and configures the three register fields with reset values,
  //   bit positions, and access types.
  //--------------------------------------------------------------------------
  virtual function void build();

    // Create field objects
    SIZE   = uvm_reg_field::type_id::create(.name("SIZE"),   .parent(null), .contxt(get_full_name()));
    OFFSET = uvm_reg_field::type_id::create(.name("OFFSET"), .parent(null), .contxt(get_full_name()));
    CLR    = uvm_reg_field::type_id::create(.name("CLR"),    .parent(null), .contxt(get_full_name()));

    // Configure SIZE field: 3 bits, RW, reset = 3'b001
    SIZE.configure(
      .parent(this),
      .size(3),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset(3'b001),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );

    // Configure OFFSET field: 2 bits, RW, reset = 2'b00
    OFFSET.configure(
      .parent(this),
      .size(2),
      .lsb_pos(8),
      .access("RW"),
      .volatile(0),
      .reset(2'b00),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );

    // Configure CLR field: 1 bit, WO, reset = 1'b0
    CLR.configure(
      .parent(this),
      .size(1),
      .lsb_pos(16),
      .access("WO"),
      .volatile(0),
      .reset(1'b0),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(0)
    );
  endfunction : build

  //--------------------------------------------------------------------------
  // Accessor/Mutator for DATA_WIDTH
  //--------------------------------------------------------------------------

  // Sets DATA_WIDTH ensuring it is >= 8 and a power of two
  virtual function void SET_DATA_WIDTH(int unsigned value);
    if (value < 8) begin
      `uvm_fatal("ALGORITHM_ISSUE",
                 $sformatf("The minimum legal value for DATA_WIDTH is 8 but user tried to set %0d", value))
    end
    if ($countones(value) != 1) begin
      `uvm_fatal("ALGORITHM_ISSUE",
                 $sformatf("The value for DATA_WIDTH must be a power of 2 but user tried to set %0d", value))
    end
    DATA_WIDTH = value;
  endfunction

  // Returns the current DATA_WIDTH setting
  virtual function int unsigned GET_DATA_WIDTH();
    return DATA_WIDTH;
  endfunction

endclass : reg_ctrl

`endif
