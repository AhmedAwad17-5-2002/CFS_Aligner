///////////////////////////////////////////////////////////////////////////////
// File:        apb_base_item.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB base transaction item.
//              This class defines the basic APB sequence item that models a 
//              single transaction on the APB bus. 
//              Fields include:
//                - pwrite : transaction direction (READ or WRITE)
//                - paddr  : target register address
//                - pwdata : data to be written (for WRITE)
//              The item can be randomized and passed between sequencer and driver.
///////////////////////////////////////////////////////////////////////////////

`ifndef BASE_ITEM
`define BASE_ITEM

//------------------------------------------------------------------------------
// UVM Sequence Item: apb_base_item
//------------------------------------------------------------------------------
// - Extends uvm_sequence_item.
// - Defines fields for APB transaction attributes.
// - Provides convert2string() for debug-friendly printing.
//------------------------------------------------------------------------------
class apb_base_item extends uvm_sequence_item;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Write data (valid when pwrite == APB_WRITE)
    rand apb_data pwdata;
		
    // Address of the register being accessed
    rand apb_addr paddr;
		
    // Direction of the transaction: APB_READ or APB_WRITE
    rand apb_dir  pwrite;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this item with the UVM factory for dynamic creation.
    `uvm_object_utils(apb_base_item)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - "name": unique item instance name
    function new(string name = "apb_base_item");
        super.new(name);
    endfunction : new

    // convert2string()
    // - Returns a formatted string representation of the item
    // - Useful for debug logging
    virtual function string convert2string();
        string result;
        result = $sformatf("pwrite: %0s,  paddr: 0x%0h, pwdata: 0x%0h", 
                            pwrite.name(), paddr, pwdata);
        return result;
    endfunction : convert2string
	
endclass : apb_base_item

`endif
