/////////////////////////////////////////////////////////////////////////////// 
// File:        md_base_item.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: Base transaction class (UVM sequence item) for MD protocol. 
//              This class represents the fundamental data object that will be 
//              used in sequences and passed between sequencer, driver, and monitor. 
//              It can be extended to add protocol-specific fields (e.g. headers, 
//              payload, control signals). 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_BASE_ITEM
`define MD_BASE_ITEM

//------------------------------------------------------------------------------
// Class: md_base_item
//------------------------------------------------------------------------------
// - Extends uvm_sequence_item (base class for all UVM transactions).
// - Acts as a "transaction container" for MD protocol verification.
// - Registered with UVM factory for easy creation and automation.
//------------------------------------------------------------------------------
class md_base_item extends uvm_sequence_item;
	
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_base_item with the UVM factory.
	// This allows it to be created dynamically and used with utilities like 
	// `uvm_create, `uvm_do, etc.
	`uvm_object_utils(md_base_item)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": object instance name (optional, defaults to "md_base_item")
	function new(string name = "md_base_item");
		super.new(name);
	endfunction : new
	
endclass : md_base_item

`endif
