///////////////////////////////////////////////////////////////////////////////
// File:        apb_reg_adapter.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM Register Adapter for the APB interface.
//              ---------------------------------------------------------------
//              Bridges the UVM Register Layer and the APB bus agent.
//              - Converts APB monitor/driver items (bus transactions) to
//                uvm_reg_bus_op objects (bus2reg).
//              - Converts uvm_reg_bus_op objects back to APB driver items
//                (reg2bus).
//              This enables the UVM register model to perform read/write
//              operations through the APB agent transparently.
//              ---------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_REG_ADAPTER
`define APB_REG_ADAPTER

//------------------------------------------------------------------------------
// Class: apb_reg_adapter
// Extends: uvm_reg_adapter
//------------------------------------------------------------------------------
// * Responsible for translating between APB sequence items and the generic
//   UVM register bus operations.
// * Supports both monitor items (from APB monitor) and driver items
//   (from APB driver).
//------------------------------------------------------------------------------
class apb_reg_adapter extends uvm_reg_adapter;
    
  // Factory registration so the adapter can be created dynamically
  `uvm_object_utils(apb_reg_adapter)
    
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction
    
  //--------------------------------------------------------------------------
  // Function: bus2reg
  // Purpose : Converts a generic APB sequence item (monitor or driver) into a
  //           uvm_reg_bus_op for the UVM register model.
  //--------------------------------------------------------------------------
  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    apb_mon_item item_mon;
    apb_drv_item item_drv;
      
    // --- Case 1: Item came from the monitor -------------------------------
    if ($cast(item_mon, bus_item)) begin
      // Determine read/write type
      rw.kind = (item_mon.pwrite == APB_WRITE) ? UVM_WRITE : UVM_READ;

      // Capture address and data
      // rw.addr = item_mon.paddr;
      rw.addr = (item_mon.paddr & 32'hFFFFFFFC);

      rw.data = (item_mon.pwrite == APB_WRITE) ? item_mon.pwdata
                                               : item_mon.prdata;

      // Capture status
      rw.status = (item_mon.response == APB_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
    end
    // --- Case 2: Item came from the driver -------------------------------
    /*We also have to copy the fields from the item drive just like we did for the item mon. 
      And this is because in the background the register block will call this function bus2reg() 
      also for this item apb_drv_item. 
      So let's implement here a similar code like this one.*/
    else if ($cast(item_drv, bus_item)) begin
      rw.kind   = (item_drv.pwrite == APB_WRITE) ? UVM_WRITE : UVM_READ;
      rw.addr   = item_drv.paddr;
      rw.data   = item_drv.pwdata;       // Driver always has write data
      rw.status = UVM_IS_OK;             // Assume OK unless monitor says otherwise

    // --- Unsupported item type ------------------------------------------
    end
    else begin
      `uvm_fatal("ALGORITHM_ISSUE",
                 $sformatf("Class not supported: %0s",
                           bus_item.get_type_name()))
    end
  endfunction : bus2reg
    
  //--------------------------------------------------------------------------
  // Function: reg2bus
  // Purpose : Converts a uvm_reg_bus_op into an APB driver item for execution
  //           on the bus.
  //--------------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    // Create a driver item using the UVM factory
    apb_drv_item my_apb_drv_item = apb_drv_item::type_id::create("my_apb_drv_item");
      
    // Constrain fields to match the register operation
    void'(my_apb_drv_item.randomize() with {
      my_apb_drv_item.pwrite == (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
      my_apb_drv_item.pwdata == rw.data;
      my_apb_drv_item.paddr  == rw.addr;
    });
      
    return my_apb_drv_item;
  endfunction : reg2bus
    
endclass : apb_reg_adapter

`endif // APB_REG_ADAPTER
