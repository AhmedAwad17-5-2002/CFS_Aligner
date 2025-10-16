///////////////////////////////////////////////////////////////////////////////
// File:        apb_simple_sequence.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: Simple APB sequence class.
//              This sequence extends the base APB sequence and demonstrates
//              how to create and send a single APB transaction (apb_drv_item)
//              to the APB driver through the sequencer. It serves as a 
//              reference or starting point for building more complex sequences.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_SIMPLE_SEQ
`define APB_SIMPLE_SEQ

//------------------------------------------------------------------------------
// UVM Sequence: apb_simple_sequence
//------------------------------------------------------------------------------
// - Extends apb_base_sequence.
// - Creates a single APB driver item (apb_drv_item).
// - Randomizes and sends the item to the driver using `uvm_do`.
//------------------------------------------------------------------------------
class apb_simple_sequence extends apb_base_sequence;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // A randomizable APB driver item (transaction)
    rand apb_drv_item my_apb_drv_item;

    // Write data (valid when pwrite == APB_WRITE)
    rand apb_data my_pwdata;

    rand apb_dir  my_pwrite;
        
    // Address of the register being accessed
    rand apb_addr my_paddr;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this sequence with the UVM factory for dynamic creation.
    `uvm_object_utils(apb_simple_sequence)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - "name": unique sequence instance name
    function new(string name = "apb_simple_sequence");
        super.new(name);

        // Create APB transaction object using factory
        my_apb_drv_item = apb_drv_item::type_id::create("my_apb_drv_item");
    endfunction : new

    // body() task
    // - Defines the main sequence flow.
    // - Randomizes and sends the transaction to the driver.
    virtual task body();

        // Example 1: Explicit start/finish
        // start_item(my_apb_drv_item);
        // finish_item(my_apb_drv_item);

        // Example 2: Using UVM macros
        // `uvm_do(my_apb_drv_item)  
        //   -> Creates, randomizes, and sends the item (ignores overridden constraints)
        //
        // `uvm_send(my_apb_drv_item)
        //   -> Similar to uvm_do but considers overridden constraints
        // my_apb_drv_item.constraint_mode(0);
       `uvm_do(my_apb_drv_item)

    endtask : body
	
endclass : apb_simple_sequence

`endif
