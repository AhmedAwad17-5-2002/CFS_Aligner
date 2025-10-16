/////////////////////////////////////////////////////////////////////////////// 
// File:        md_drv_item.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: Driver Transaction Item for MD Protocol.
//              This class defines the basic transaction (sequence item) 
//              that will be driven onto the DUT interface by the driver. 
//              It extends from md_base_item to inherit common fields 
//              and functionality, and can be expanded with protocol-
//              specific fields for MD packet transactions. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_DRV_ITEM
`define MD_DRV_ITEM

//------------------------------------------------------------------------------
// UVM Transaction: md_drv_item
//------------------------------------------------------------------------------
// - Extends md_base_item (base transaction class for MD protocol).
// - Used by the driver to send stimulus to the DUT.
// - Can be randomized in sequences to generate protocol-compliant traffic.
//------------------------------------------------------------------------------
class md_drv_item extends md_base_item;
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// TODO: Add transaction fields specific to MD protocol 
	// Example: rand bit [31:0] addr; rand bit [31:0] data;
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_drv_item with the UVM factory so it can be created 
	// dynamically (e.g., from sequences).
	`uvm_object_utils(md_drv_item)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": optional instance name for better debug/trace in UVM reports
	function new(string name = "md_drv_item");
		super.new(name);
	endfunction : new
	
endclass : md_drv_item

`endif
