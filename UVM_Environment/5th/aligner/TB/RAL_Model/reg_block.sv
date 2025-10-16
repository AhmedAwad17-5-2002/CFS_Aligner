///////////////////////////////////////////////////////////////////////////////
// File:        reg_block.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-17
// Description: UVM register model for the Alignment Controller.
//              This block models the DUT's memory-mapped registers so that
//              sequences can perform register-level stimulus and checking
//              using the UVM Register Abstraction Layer (RAL).
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_BLOCK_SV
`define REG_BLOCK_SV

//------------------------------------------------------------------------------
// Class: reg_block
//------------------------------------------------------------------------------
// - Extends uvm_reg_block to represent the DUT register map.
// - Contains four registers: CTRL, STATUS, IRQEN, and IRQ.
// - Creates a default APB map with little-endian addressing.
// - Enables register access rights and check-on-read for automatic comparison.
//------------------------------------------------------------------------------
class reg_block extends uvm_reg_block;

  //--------------------------------------------------------------------------
  // Register Declarations
  //--------------------------------------------------------------------------
  // Each handle is a UVM register model class (defined elsewhere)
  rand reg_ctrl   CTRL;     // Control register (Read/Write)
  rand reg_status STATUS;   // Status register  (Read-Only)
  rand reg_irqen  IRQEN;    // Interrupt-enable register (Read/Write)
  rand reg_irq    IRQ;      // Interrupt register (Read/Write)

  //--------------------------------------------------------------------------
  // UVM Factory Registration
  //--------------------------------------------------------------------------
  `uvm_object_utils(reg_block)

  //--------------------------------------------------------------------------
  // Constructor
  // - name: Optional instance name (defaults to empty string).
  // - UVM_NO_COVERAGE: disables automatic functional coverage collection.
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  //--------------------------------------------------------------------------
  // build()
  // - Creates the default register map and all register instances.
  // - Sets access rights and enables check-on-read to verify data integrity.
  //--------------------------------------------------------------------------
  virtual function void build();

    // Create the default APB address map:
    //   name       : "apb_map"
    //   base_addr  : 0x0000
    //   n_bytes    : 4-byte word addressing
    //   endian     : Little-endian
    //   byte_addr  : 1 (true = byte-addressable)
    default_map = create_map(
      .name("apb_map"),
      .base_addr('h0000),
      .n_bytes(4),
      .endian(UVM_LITTLE_ENDIAN),
      .byte_addressing(1)
    );

    // Enable automatic read-back checking
    default_map.set_check_on_read(1);

    // Create each register instance and link it to this block
    CTRL   = reg_ctrl  ::type_id::create(.name("CTRL"),   .parent(null), .contxt(get_full_name()));
    STATUS = reg_status::type_id::create(.name("STATUS"), .parent(null), .contxt(get_full_name()));
    IRQEN  = reg_irqen ::type_id::create(.name("IRQEN"),  .parent(null), .contxt(get_full_name()));
    IRQ    = reg_irq   ::type_id::create(.name("IRQ"),    .parent(null), .contxt(get_full_name()));

    // Configure each register to belong to this block
    CTRL  .configure(.blk_parent(this));
    STATUS.configure(.blk_parent(this));
    IRQEN .configure(.blk_parent(this));
    IRQ   .configure(.blk_parent(this));

    // Build the individual field definitions inside each register
    CTRL  .build();
    STATUS.build();
    IRQEN .build();
    IRQ   .build();

    // Add registers to the default map with offsets and access rights
    default_map.add_reg(.rg(CTRL),   .offset('h0000), .rights("RW"));
    default_map.add_reg(.rg(STATUS), .offset('h000C), .rights("RO"));
    default_map.add_reg(.rg(IRQEN),  .offset('h00F0), .rights("RW"));
    default_map.add_reg(.rg(IRQ),    .offset('h00F4), .rights("RW"));

  endfunction : build

endclass : reg_block

`endif // REG_BLOCK_SV
