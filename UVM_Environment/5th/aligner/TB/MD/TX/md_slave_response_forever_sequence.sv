/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_response_forever_sequence.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM sequence for generating a response MD slave transaction. 
//              This sequence creates a randomized md_drv_slave_item with 
//              size and offset constraints that ensure alignment within 
//              the sequencer’s data width. The sequence then sends the item 
//              to the driver via the sequencer. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_SLAVE_RESPONSE_FOREVER_SEQUENCE
`define MD_SLAVE_RESPONSE_FOREVER_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: md_slave_response_forever_sequence
//------------------------------------------------------------------------------
// - Extends md_base_sequence parameterized with md_drv_slave_item.
// - Generates a randomized transaction item (md_drv_slave_item).
// - Applies constraints to guarantee data size + offset fit in the sequencer’s
//   data width.
// - Sends the item to the driver using `uvm_send`.
//------------------------------------------------------------------------------
class md_slave_response_forever_sequence extends md_slave_base_sequence;
	
	/*-------------------------------------------------------------------------------
	-- Fields
	-------------------------------------------------------------------------------*/
	// Randomized slave driver item (transaction to send to DUT)
	rand md_drv_slave_item my_md_drv_slave_item;

	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers sequence with UVM factory for dynamic creation
	`uvm_object_utils(md_slave_response_forever_sequence)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique sequence instance name
	function new(string name = "md_slave_response_forever_sequence");
		super.new(name);

		// Create transaction item using UVM factory
		my_md_drv_slave_item = md_drv_slave_item::type_id::create("my_md_drv_slave_item");

	endfunction : new

	virtual task body();
      forever begin
        md_slave_response_sequence seq = md_slave_response_sequence::type_id::create("seq");
        
        `uvm_do_on(seq, p_sequencer)
      end
    endtask
	
endclass : md_slave_response_forever_sequence

`endif
