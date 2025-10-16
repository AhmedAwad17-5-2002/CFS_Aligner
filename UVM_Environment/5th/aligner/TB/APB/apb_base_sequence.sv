///////////////////////////////////////////////////////////////////////////////
// File:        apb_base_sequence.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: Base APB sequence class.
//              This sequence provides the foundation for generating APB 
//              transactions (apb_drv_item) that will be executed by the 
//              APB sequencer and driven onto the APB interface by the driver.
//              It can be extended to create specific test scenarios by 
//              overriding or adding sequence body implementations.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_BASE_SEQUENCE
`define APB_BASE_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: apb_base_sequence
//------------------------------------------------------------------------------
// - Extends uvm_sequence parameterized with apb_drv_item.
// - Declares pointer to the parent sequencer (apb_sequencer).
// - Acts as the base class for all APB sequences in the environment.
//------------------------------------------------------------------------------
class apb_base_sequence extends uvm_sequence #(apb_drv_item);

    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Provides handle to the APB sequencer associated with this sequence.
    // This macro declares a typed p_sequencer variable for convenience.
    `uvm_declare_p_sequencer(uvm_ext_sequencer#(.ITEM_DRV(apb_drv_item)))

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this sequence with the UVM factory so that it can be created
    // dynamically using type_id::create() and used in virtual sequences.
    `uvm_object_utils(apb_base_sequence)

    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/

    // Constructor
    // - "name": unique sequence instance name
    function new(string name = "apb_base_sequence");
        super.new(name);
    endfunction : new

endclass : apb_base_sequence

`endif
