/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_base_sequencer.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM Sequencer for Master Driver Items. 
//              This sequencer is parameterized by DATA_WIDTH and 
//              coordinates the generation and delivery of master 
//              sequence items (md_drv_master_item) to the driver. 
//              It extends the generic md_sequencer base class to 
//              specialize for master transactions. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_base_SEQUENCER
`define MD_MASTER_base_SEQUENCER

//------------------------------------------------------------------------------
// UVM Sequencer: md_master_base_sequencer
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default = 32).
// - Generates master driver items (md_drv_master_item).
// - Acts as the communication channel between sequences and the driver.
// - Provides a helper function to return the configured DATA_WIDTH.
//------------------------------------------------------------------------------
class md_master_base_sequencer 
	extends md_base_sequencer#(.ITEM_DRV(md_drv_master_item));
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// (No extra fields defined here; inherits sequencer base functionality)
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_master_base_sequencer with UVM factory for dynamic creation
	`uvm_component_utils(md_master_base_sequencer)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": instance name
	// - "parent": parent component in UVM hierarchy
	function new(string name = "md_master_base_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new


	// get_data_width()
	// - Utility function to return the configured DATA_WIDTH
	// virtual function int unsigned get_data_width();
	// 	return DATA_WIDTH;
	// endfunction : get_data_width

	
endclass : md_master_base_sequencer

`endif
