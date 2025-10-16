///////////////////////////////////////////////////////////////////////////////
// File:        reg_irq.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-17
// Description: UVM register model for the IRQ (Interrupt Request) register
//              of the Alignment Controller DUT.  
//              This register contains status bits that reflect the FIFO
//              conditions of the DUT. Each bit is configured as W1C
//              (Write-1-to-Clear) so that writing a logic ‘1’ clears the flag.
//
//   Bit mapping (LSB → MSB):
//     [0] RX_FIFO_EMPTY : RX FIFO is empty interrupt
//     [1] RX_FIFO_FULL  : RX FIFO is full interrupt
//     [2] TX_FIFO_EMPTY : TX FIFO is empty interrupt
//     [3] TX_FIFO_FULL  : TX FIFO is full interrupt
//     [4] MAX_DROP      : Max-drop event interrupt
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_IRQ
`define REG_IRQ

//------------------------------------------------------------------------------
// Class: reg_irq
//------------------------------------------------------------------------------
// - Extends uvm_reg to represent a 32-bit hardware IRQ register.
// - Each field is 1 bit wide and configured as W1C.
// - Used in the UVM Register Model to access and predict DUT IRQ behavior.
//------------------------------------------------------------------------------
class reg_irq extends uvm_reg;

  //--------------------------------------------------------------------------
  // Register Fields
  //--------------------------------------------------------------------------
  rand uvm_reg_field RX_FIFO_EMPTY; // Interrupt when RX FIFO becomes empty
  rand uvm_reg_field RX_FIFO_FULL;  // Interrupt when RX FIFO becomes full
  rand uvm_reg_field TX_FIFO_EMPTY; // Interrupt when TX FIFO becomes empty
  rand uvm_reg_field TX_FIFO_FULL;  // Interrupt when TX FIFO becomes full
  rand uvm_reg_field MAX_DROP;      // Interrupt when maximum drop event occurs
  rand uvm_reg_field RESERVED;      // Interrupt when maximum drop event occurs

  // Register this class with the UVM factory
  `uvm_object_utils(reg_irq)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  // name       : Optional instance name
  // Initializes a 32-bit register with no functional coverage
  function new(string name = "my_reg_irq");
    super.new(.name(name), .n_bits(32), .has_coverage(UVM_NO_COVERAGE));
  endfunction : new

  //--------------------------------------------------------------------------
  // Build Method
  //--------------------------------------------------------------------------
  // Creates and configures each field with:
  //   - size          : 1 bit
  //   - lsb_pos       : unique bit position
  //   - access        : W1C (Write-1-to-Clear)
  //   - reset         : 0
  //   - has_reset     : 1 (reset is defined)
  //   - is_rand       : 1 (field can be randomized for testing)
  //   - individually_accessible : 0 (no standalone access)
  virtual function void build();

    // Create field objects
    RX_FIFO_EMPTY = uvm_reg_field::type_id::create(
                      .name("RX_FIFO_EMPTY"), .parent(null), .contxt(get_full_name()));
    RX_FIFO_FULL  = uvm_reg_field::type_id::create(
                      .name("RX_FIFO_FULL"),  .parent(null), .contxt(get_full_name()));
    TX_FIFO_EMPTY = uvm_reg_field::type_id::create(
                      .name("TX_FIFO_EMPTY"), .parent(null), .contxt(get_full_name()));
    TX_FIFO_FULL  = uvm_reg_field::type_id::create(
                      .name("TX_FIFO_FULL"),  .parent(null), .contxt(get_full_name()));
    MAX_DROP      = uvm_reg_field::type_id::create(
                      .name("MAX_DROP"),      .parent(null), .contxt(get_full_name()));
    RESERVED      = uvm_reg_field::type_id::create(
                      .name("RESERVED"),      .parent(null), .contxt(get_full_name()));

    // Configure each field
    RX_FIFO_EMPTY.configure(
      .parent(this), 
      .size(1), 
      .lsb_pos(0), 
      .access("W1C"),
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    RX_FIFO_FULL.configure (
      .parent(this), 
      .size(1), 
      .lsb_pos(1), 
      .access("W1C"),             
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    TX_FIFO_EMPTY.configure(
      .parent(this), 
      .size(1), 
      .lsb_pos(2), 
      .access("W1C"),
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    TX_FIFO_FULL.configure (
      .parent(this), 
      .size(1), 
      .lsb_pos(3), 
      .access("W1C"),
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    MAX_DROP.configure    (
      .parent(this), 
      .size(1), 
      .lsb_pos(4), 
      .access("W1C"),
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    RESERVED.configure    (
      .parent(this), 
      .size(27), 
      .lsb_pos(5), 
      .access("RO"),
      .volatile(0), 
      .reset(1'b0), 
      .has_reset(1),
      .is_rand(1), 
      .individually_accessible(0)
      );

    RX_FIFO_EMPTY.value.rand_mode(1);
    RX_FIFO_FULL.value.rand_mode(1);
    TX_FIFO_EMPTY.value.rand_mode(1);
    TX_FIFO_FULL.value.rand_mode(1);
    MAX_DROP.value.rand_mode(1);

  endfunction : build

endclass : reg_irq

`endif