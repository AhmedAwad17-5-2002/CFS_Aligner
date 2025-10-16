/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_base_sequence.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM sequence for generating a basic MD slave transaction. 
//              This sequence creates a randomized md_drv_slave_item with 
//              size and offset constraints to ensure alignment within 
//              the sequencer’s data width. 
//              The randomized item is then sent to the driver through 
//              the slave sequencer, enabling controlled stimulus 
//              for DUT verification. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_SLAVE_BASE_SEQUENCE
`define MD_SLAVE_BASE_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: md_slave_base_sequence
//------------------------------------------------------------------------------
// - Extends md_base_sequence parameterized with md_drv_slave_item.
// - Randomizes an md_drv_slave_item transaction.
// - Applies constraints (defined in the item) to ensure data size/offset fit.
// - Drives the transaction to the slave driver via its sequencer.
//------------------------------------------------------------------------------
class md_slave_base_sequence 
	extends md_base_sequence #(.ITEM_DRV(md_drv_slave_item));
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers this sequence with the UVM factory 
	// → Allows creation via type_id::create()
	`uvm_object_utils(md_slave_base_sequence)

	// Declares handle to the parent sequencer (md_slave_base_sequencer)
	// → Provides access to sequencer fields and configuration if needed
	`uvm_declare_p_sequencer(md_slave_base_sequencer)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique sequence instance name
	function new(string name = "md_slave_base_sequence");
		super.new(name);
	endfunction : new

	/*-------------------------------------------------------------------------------
	-- Sequence Body
	-------------------------------------------------------------------------------*/
	// body task
	// - Entry point of the sequence
	// - Randomizes and sends a transaction item (md_drv_slave_item) 
	//   to the driver via the sequencer
	// virtual task body();
	// 	md_drv_slave_item req;

	// 	// Create new transaction item
	// 	req = md_drv_slave_item::type_id::create("req");

	// 	// Randomize with default constraints
	// 	if (!req.randomize()) begin
	// 		`uvm_error("RANDOMIZE_FAIL", "Failed to randomize md_drv_slave_item")
	// 	end

	// 	// Start and send the transaction to the driver
	// 	start_item(req);
	// 	finish_item(req);
	// endtask : body
	
endclass : md_slave_base_sequence

`endif
