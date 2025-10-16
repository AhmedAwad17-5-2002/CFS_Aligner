///////////////////////////////////////////////////////////////////////////////
// File:        apb_random_sequence.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: Random APB sequence.
//              This sequence extends apb_base_sequence and repeatedly generates
//              multiple simple APB transactions (apb_simple_sequence).
//              The number of items is randomizable (default range: 1–10).
//              Useful for stress testing and generating random traffic on the
//              APB interface.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_RANDOM_SEQUENCE
`define APB_RANDOM_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: apb_random_sequence
//------------------------------------------------------------------------------
// - Extends apb_base_sequence.
// - Randomizable num_items field defines how many transactions to run.
// - Repeatedly launches apb_simple_sequence inside body().
//------------------------------------------------------------------------------
class apb_random_sequence extends apb_base_sequence;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Number of items (transactions) to generate
    rand int unsigned num_items;

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this sequence with the UVM factory for dynamic creation.
    `uvm_object_utils(apb_random_sequence)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - "name": unique sequence instance name
    function new(string name = "apb_random_sequence");
        super.new(name);
    endfunction : new

    // body() task
    // - Defines the sequence flow.
    // - Runs num_items iterations, each generating a new apb_simple_sequence.
    task body();
        for (int i = 0; i < num_items; i++) begin
            apb_simple_sequence my_apb_simple_sequence;

            //------------------------------------------------------------------
            // Option 1: Explicit create + randomize + start (commented example)
            //------------------------------------------------------------------
            // my_apb_simple_sequence = apb_simple_sequence::type_id::create("my_apb_simple_sequence");
            // void'(my_apb_simple_sequence.randomize());
            // my_apb_simple_sequence.start(p_sequencer);

            //------------------------------------------------------------------
            // Option 2: Using UVM macro (preferred)
            //   - Creates, randomizes, and sends in one line.
            //------------------------------------------------------------------
            `uvm_do(my_apb_simple_sequence)
        end
    endtask : body

    /*-------------------------------------------------------------------------------
    -- Constraints
    -------------------------------------------------------------------------------*/
    // Default constraint: num_items should be between 1 and 10
    constraint num_items_default {
        soft num_items inside {[1:10]};
    }
	
endclass : apb_random_sequence

`endif
