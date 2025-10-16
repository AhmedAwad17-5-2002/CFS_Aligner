///////////////////////////////////////////////////////////////////////////////
// File:        seq_reg_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM Register Sequence
//              This sequence is used to configure and exercise the DUT
//              register model during simulation. It randomizes fields of
//              the CTRL register inside the register block and updates/
//              reads them repeatedly to verify correct register access
//              and behavior.
//              The sequence can be extended or constrained to implement
//              more sophisticated register tests if needed.
///////////////////////////////////////////////////////////////////////////////

`ifndef SEQ_REG_CONFIG
`define SEQ_REG_CONFIG

//------------------------------------------------------------------------------
// UVM Register Sequence: seq_reg_config
//------------------------------------------------------------------------------
// - Extends uvm_reg_sequence to provide register access operations.
// - Works with a user-defined register model (my_reg_block).
// - Randomizes and updates the CTRL register multiple times, checking
//   that writes and reads behave as expected.
//------------------------------------------------------------------------------
class seq_reg_config extends uvm_reg_sequence;

    /*---------------------------------------------------------------------------
    -- Interface, port, fields
    ---------------------------------------------------------------------------*/
    // Handle to the top-level register block model.
    // Must be assigned (e.g., via the test or environment) before starting
    // the sequence.
    reg_block my_reg_block;

    /*---------------------------------------------------------------------------
    -- UVM Factory Registration
    ---------------------------------------------------------------------------*/
    // Registers this sequence with the UVM factory for dynamic creation.
    `uvm_object_utils(seq_reg_config)

    /*---------------------------------------------------------------------------
    -- Constructor
    ---------------------------------------------------------------------------*/
    // Creates a new instance of the sequence.
    function new(string name = "seq_reg_config");
        super.new(name);
    endfunction : new

    /*---------------------------------------------------------------------------
    -- Task: body
    ---------------------------------------------------------------------------*/
    // Main sequence task executed when the sequence starts.
    // Performs the following actions:
    //   1. Randomizes the CTRL register fields.
    //   2. Updates the DUT with new randomized values.
    //   3. Reads back the register to confirm the write.
    // Repeats these steps ten times.
    virtual task body();
        uvm_status_e   status;  // Holds status of each register operation
        uvm_reg_data_t data;    // Holds read-back data value

        // Example of direct writes (commented out):
        // my_reg_block.CTRL.write(status, 32'h00000203);
        // my_reg_block.CTRL.OFFSET.set(2);
        // my_reg_block.CTRL.SIZE.set(3);
        // my_reg_block.CTRL.update(status);

        // Randomized register updates and reads
        repeat (10) begin
            void'(my_reg_block.CTRL.randomize());
            my_reg_block.CTRL.update(status);
            my_reg_block.CTRL.read(status, data);
            // Optionally add checks or uvm_info messages here to verify data.
        end
    endtask : body

endclass : seq_reg_config

`endif // SEQ_REG_CONFIG
