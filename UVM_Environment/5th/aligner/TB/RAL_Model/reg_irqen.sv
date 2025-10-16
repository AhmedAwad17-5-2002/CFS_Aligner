/////////////////////////////////////////////////////////////////////////////// 
// File:        reg_irqen.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-17 
// Description: UVM Register Model for IRQ Enable Register (IRQEN).
//              This register controls interrupt enables for FIFO status flags
//              within the Alignment Controller DUT. 
//              Fields include RX/TX FIFO empty/full flags and MAX_DROP.
//              Each field is modeled as a uvm_reg_field with proper size,
//              position, access type, and reset value.
// 
// Note: This class is part of the UVM Register Abstraction Layer (RAL).
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_IRQEN
`define REG_IRQEN

//------------------------------------------------------------------------------
// Class: reg_irqen
//------------------------------------------------------------------------------
// - Extends uvm_reg
// - Models the IRQ Enable register as part of the DUT register map
// - Provides 5 single-bit fields representing interrupt enable signals
//------------------------------------------------------------------------------
class reg_irqen extends uvm_reg;
    
    //--------------------------------------------------------------------------
    // Register Fields
    //--------------------------------------------------------------------------
    rand uvm_reg_field RX_FIFO_EMPTY; // Interrupt enable: RX FIFO empty
    rand uvm_reg_field RX_FIFO_FULL;  // Interrupt enable: RX FIFO full
    rand uvm_reg_field TX_FIFO_EMPTY; // Interrupt enable: TX FIFO empty
    rand uvm_reg_field TX_FIFO_FULL;  // Interrupt enable: TX FIFO full
    rand uvm_reg_field MAX_DROP;      // Interrupt enable: Max drop condition
    
    //--------------------------------------------------------------------------
    // UVM Factory Registration
    //--------------------------------------------------------------------------
    `uvm_object_utils(reg_irqen)

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    // Creates a 32-bit register with no functional coverage
    function new(string name = "my_reg_irqen");
      super.new(.name(name), .n_bits(32), .has_coverage(UVM_NO_COVERAGE));
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    // Creates and configures all fields in this register.
    // Each field is:
    // - 1 bit wide
    // - Read/Write ("RW")
    // - Non-volatile
    // - Reset to 0
    // - Randomizable
    virtual function void build();

      // Create fields
      RX_FIFO_EMPTY = uvm_reg_field::type_id::create(.name("RX_FIFO_EMPTY"), .parent(null), .contxt(get_full_name()));
      RX_FIFO_FULL  = uvm_reg_field::type_id::create(.name("RX_FIFO_FULL"),  .parent(null), .contxt(get_full_name()));
      TX_FIFO_EMPTY = uvm_reg_field::type_id::create(.name("TX_FIFO_EMPTY"), .parent(null), .contxt(get_full_name()));
      TX_FIFO_FULL  = uvm_reg_field::type_id::create(.name("TX_FIFO_FULL"),  .parent(null), .contxt(get_full_name()));
      MAX_DROP      = uvm_reg_field::type_id::create(.name("MAX_DROP"),      .parent(null), .contxt(get_full_name()));

      // Configure RX_FIFO_EMPTY field
      RX_FIFO_EMPTY.configure(
                      .parent(this),
                      .size(1),
                      .lsb_pos(0),
                      .access("RW"),
                      .volatile(0),
                      .reset(1'b0),
                      .has_reset(1),
                      .is_rand(1),
                      .individually_accessible(0)
                    );

      // Configure RX_FIFO_FULL field
      RX_FIFO_FULL.configure(
                      .parent(this),
                      .size(1),
                      .lsb_pos(1),
                      .access("RW"),
                      .volatile(0),
                      .reset(1'b0),
                      .has_reset(1),
                      .is_rand(1),
                      .individually_accessible(0)
                    );

      // Configure TX_FIFO_EMPTY field
      TX_FIFO_EMPTY.configure(
                      .parent(this),
                      .size(1),
                      .lsb_pos(2),
                      .access("RW"),
                      .volatile(0),
                      .reset(1'b0),
                      .has_reset(1),
                      .is_rand(1),
                      .individually_accessible(0)
                    );

      // Configure TX_FIFO_FULL field
      TX_FIFO_FULL.configure(
                      .parent(this),
                      .size(1),
                      .lsb_pos(3),
                      .access("RW"),
                      .volatile(0),
                      .reset(1'b0),
                      .has_reset(1),
                      .is_rand(1),
                      .individually_accessible(0)
                    );

      // Configure MAX_DROP field
      MAX_DROP.configure(
                      .parent(this),
                      .size(1),
                      .lsb_pos(4),
                      .access("RW"),
                      .volatile(0),
                      .reset(1'b0),
                      .has_reset(1),
                      .is_rand(1),
                      .individually_accessible(0)
                    );
    endfunction : build

endclass : reg_irqen

`endif
