/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_base_sequence.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM sequence for generating a simple MD master transaction. 
//              This sequence creates a randomized md_drv_master_item with 
//              size and offset constraints that ensure alignment within 
//              the sequencer’s data width. The sequence then sends the item 
//              to the driver via the sequencer. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_BASE_SEQUENCE
`define MD_MASTER_BASE_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: md_master_base_sequence
//------------------------------------------------------------------------------
// - Extends md_base_sequence parameterized with md_drv_master_item.
// - Generates a randomized transaction item (md_drv_master_item).
// - Applies constraints to guarantee data size + offset fit in the sequencer’s
//   data width.
// - Sends the item to the driver using `uvm_send`.
//------------------------------------------------------------------------------
class md_master_base_sequence 
	extends md_base_sequence #(.ITEM_DRV(md_drv_master_item));
	
	
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers sequence with UVM factory for dynamic creation
	`uvm_object_utils(md_master_base_sequence)
	`uvm_declare_p_sequencer(md_master_base_sequencer)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique sequence instance name
	function new(string name = "md_master_base_sequence");
		super.new(name);
	endfunction : new

	// body task
	// - Main sequence entry point
	// - Sends the randomized transaction item to the driver
	
endclass : md_master_base_sequence

`endif
