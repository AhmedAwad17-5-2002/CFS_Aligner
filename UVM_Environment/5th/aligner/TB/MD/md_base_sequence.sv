/////////////////////////////////////////////////////////////////////////////// 
// File:        md_base_sequence.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: Base UVM sequence for MD driver items. 
//              This sequence provides the foundation for generating and 
//              controlling MD transactions. It extends uvm_sequence and 
//              is parameterized by ITEM_DRV (the transaction item type 
//              driven to the DUT). 
//              All specific MD sequences should extend from this base 
//              sequence to ensure consistency and reuse. 
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_BASE_SEQUENCE
`define MD_BASE_SEQUENCE

//------------------------------------------------------------------------------
// UVM Sequence: md_base_sequence
//------------------------------------------------------------------------------
// - Parameterized by ITEM_DRV (transaction type).
// - Provides common functionality for derived sequences.
// - Declares the sequencer handle (p_sequencer).
//------------------------------------------------------------------------------
class md_base_sequence #(type ITEM_DRV = md_drv_item) 
	extends uvm_sequence #(.REQ(ITEM_DRV));
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// No user-defined fields here; derived sequences may add them as needed.
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_base_sequence with UVM factory for dynamic creation.
	// Declares the sequencer type used by this sequence.
	`uvm_object_param_utils(md_base_sequence#(.ITEM_DRV(ITEM_DRV)))
	// `uvm_declare_p_sequencer(md_base_sequencer#(ITEM_DRV))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique name for the sequence instance.
	function new(string name = "md_base_sequence");
		super.new(name);
	endfunction : new
	
endclass : md_base_sequence

`endif
