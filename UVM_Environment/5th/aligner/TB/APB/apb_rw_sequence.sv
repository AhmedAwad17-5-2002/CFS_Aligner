///////////////////////////////////////////////////////////////////////////////
// File:        apb_rw_sequence.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Read/Write sequence.
//              This sequence extends apb_base_sequence and demonstrates how 
//              to create and send a constrained APB transaction. 
//              It specifically randomizes an address and optionally data, 
//              then forces the transaction to perform a READ operation.
//              Can be easily extended or modified to support WRITE as well.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_RW_SEQUENCE
`define APB_RW_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: apb_rw_sequence
//------------------------------------------------------------------------------
// - Extends apb_base_sequence.
// - Declares randomizable APB address and data fields.
// - Generates a read transaction (pwrite == APB_READ).
//------------------------------------------------------------------------------
class apb_rw_sequence extends apb_base_sequence;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Randomizable APB address for the transaction
    rand apb_addr my_apb_addr;

    // Randomizable APB data (useful for WRITE extension or checking return data)
    rand apb_data my_apb_data;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this sequence with the UVM factory for dynamic creation.
    `uvm_object_utils(apb_rw_sequence)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - "name": unique sequence instance name
    function new(string name = "apb_rw_sequence");
        super.new(name);
    endfunction : new

    // body() task
    // - Defines the sequence flow.
    // - Randomizes and sends a READ transaction using the provided address.
    virtual task body();
        apb_drv_item my_apb_drv_item; // APB transaction to be sent

        //----------------------------------------------------------------------
        // Option 1: Explicit randomization and send (commented for reference)
        //----------------------------------------------------------------------
        // my_apb_drv_item = apb_drv_item::type_id::create("my_apb_drv_item");
        // void'(my_apb_drv_item.randomize() with {
        //     pwrite == APB_READ;
        //     paddr  == my_apb_addr;
        // });
        // start_item(my_apb_drv_item);
        // finish_item(my_apb_drv_item);

        //----------------------------------------------------------------------
        // Option 2: Using UVM macro (preferred)
        //   - Creates, randomizes, and sends the item in one step.
        //   - `uvm_do_with applies inline constraints (here forcing READ + address).
        //----------------------------------------------------------------------
        `uvm_do_with(my_apb_drv_item, {
            pwrite == APB_READ;
            paddr  == my_apb_addr;
        })
    endtask : body
	
endclass : apb_rw_sequence

`endif
