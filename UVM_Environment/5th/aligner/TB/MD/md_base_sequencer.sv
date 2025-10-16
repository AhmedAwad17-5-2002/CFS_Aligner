/////////////////////////////////////////////////////////////////////////////// 
// File:        md_base_sequencer.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM Sequencer for MD Driver Items. 
//              This sequencer manages the flow of sequence items (transactions) 
//              of type md_drv_item (or user-specified type via parameterization). 
//              It implements a reset handler to gracefully stop/restart sequences 
//              during DUT reset conditions, ensuring clean phase control and 
//              objection handling. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_BASE_SEQUENCER
`define MD_BASE_SEQUENCER

//------------------------------------------------------------------------------
// UVM Sequencer: md_base_sequencer
//------------------------------------------------------------------------------
// - Parameterized by ITEM_DRV (default: md_drv_item).
// - Drives REQ-type transactions toward the driver.
// - Implements md_reset_handler_if for reset-aware behavior.
//------------------------------------------------------------------------------
class md_base_sequencer#(type ITEM_DRV = md_drv_item) extends uvm_ext_sequencer#(.ITEM_DRV(ITEM_DRV));
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// No explicit fields here (sequencer primarily manages sequences).
	// Can be extended to hold configuration knobs or status flags if needed.
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory register
	-------------------------------------------------------------------------------*/
	// Registers md_base_sequencer with UVM factory, supporting parameterization.
	`uvm_component_param_utils(md_base_sequencer#(.ITEM_DRV(ITEM_DRV)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": instance name in hierarchy
	// - "parent": parent UVM component
	function new(string name = "md_base_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	//------------------------------------------------------------------------------
	// get_data_width()
	//------------------------------------------------------------------------------
	// Placeholder for returning data width information of MD sequencer.
	// - Must be implemented according to DUT/protocol requirements.
	//------------------------------------------------------------------------------
	virtual function int unsigned get_data_width();
		`uvm_fatal("ALGORITHM_ISSUE", "Implement get_data_width()")
		return 0;
	endfunction : get_data_width
	
endclass : md_base_sequencer

`endif
