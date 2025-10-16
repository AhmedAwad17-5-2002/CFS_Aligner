/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_bad_transaction.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM sequence for generating a simple MD master transaction. 
//              This sequence creates a randomized md_drv_master_item with 
//              size and offset constraints that ensure alignment within 
//              the sequencer’s data width. The sequence then sends the item 
//              to the driver via the sequencer. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_BAD_TRANSACTION
`define MD_MASTER_BAD_TRANSACTION

//------------------------------------------------------------------------------
// UVM Sequence: md_master_bad_transaction
//------------------------------------------------------------------------------
// - Extends md_base_sequence parameterized with md_drv_master_item.
// - Generates a randomized transaction item (md_drv_master_item).
// - Applies constraints to guarantee data size + offset fit in the sequencer’s
//   data width.
// - Sends the item to the driver using `uvm_send`.
//------------------------------------------------------------------------------
class md_master_bad_transaction extends md_master_base_sequence;
	
	/*-------------------------------------------------------------------------------
	-- Fields
	-------------------------------------------------------------------------------*/
	// Randomized master driver item (transaction to send to DUT)
	rand md_drv_master_item my_md_drv_master_item;

	// Hard constraints to ensure item validity based on sequencer data width
	constraint my_md_drv_master_item_hard {
		// Data must have non-zero size
		my_md_drv_master_item.data.size() > 1;
		my_md_drv_master_item.data.size() != 4;

		// // Data size must not exceed sequencer data width (in bytes)
		my_md_drv_master_item.data.size() <= p_sequencer.get_data_width()/8;

		// // Offset must be within sequencer data width (in bytes)
		my_md_drv_master_item.offset <= p_sequencer.get_data_width()/8;

		// Offset + data size must fit within sequencer data width
		my_md_drv_master_item.data.size()  + my_md_drv_master_item.offset <= p_sequencer.get_data_width()/8;
	}

	constraint md_drv_master_valid_item {

		if(my_md_drv_master_item.data.size()==2){
			my_md_drv_master_item.offset == 1;
		}

		// if(my_md_drv_master_item.data.size()==4){
		// 	my_md_drv_master_item.offset !=0;
		// }

		if(my_md_drv_master_item.data.size()==3){
			my_md_drv_master_item.offset inside {[0:1]};
		}
	}


	// constraint md_drv_master_arbitration {
	// 	solve my_md_drv_master_item_hard before md_drv_master_valid_item; 
	// }
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers sequence with UVM factory for dynamic creation
	`uvm_object_utils(md_master_bad_transaction)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique sequence instance name
	function new(string name = "md_master_bad_transaction");
		super.new(name);

		// Create transaction item using UVM factory
		my_md_drv_master_item = md_drv_master_item::type_id::create("my_md_drv_master_item");

		// Disable default constraints (only custom hard constraint applies)
		my_md_drv_master_item.data_default.constraint_mode(0);
		my_md_drv_master_item.offset_default.constraint_mode(0);
	endfunction : new

	// body task
	// - Main sequence entry point
	// - Sends the randomized transaction item to the driver
	virtual task body();
		`uvm_send(my_md_drv_master_item)
	endtask : body
	
endclass : md_master_bad_transaction

`endif
