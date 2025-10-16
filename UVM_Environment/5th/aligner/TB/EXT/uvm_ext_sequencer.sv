`ifndef UVM_EXT_SEQUENCER
`define UVM_EXT_SEQUENCER

//------------------------------------------------------------------------------
// UVM Sequencer: uvm_ext_sequencer
//------------------------------------------------------------------------------
// - Parameterized by ITEM_DRV (default: md_drv_item).
// - Drives REQ-type transactions toward the driver.
// - Implements md_reset_handler_if for reset-aware behavior.
//------------------------------------------------------------------------------
class uvm_ext_sequencer#(type ITEM_DRV = int) extends uvm_sequencer#(.REQ(ITEM_DRV)) 
	implements uvm_ext_reset_handler_if;
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// No explicit fields here (sequencer primarily manages sequences).
	// Can be extended to hold configuration knobs or status flags if needed.
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory register
	-------------------------------------------------------------------------------*/
	// Registers uvm_ext_sequencer with UVM factory, supporting parameterization.
	`uvm_component_param_utils(uvm_ext_sequencer#(.ITEM_DRV(ITEM_DRV)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": instance name in hierarchy
	// - "parent": parent UVM component
	function new(string name = "uvm_ext_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	//------------------------------------------------------------------------------
	// handle_reset()
	//------------------------------------------------------------------------------
	// Implements reset handling logic:
	// - Stops all active sequences.
	// - Drops any outstanding objections.
	// - Restarts the current phase sequence after reset.
	//------------------------------------------------------------------------------
	virtual function void handle_reset(uvm_phase phase);
		int objections_count;

		// Stop all running sequences
		stop_sequences();

		// Drop objections if still active
		objections_count = uvm_test_done.get_objection_count(this);

		if (objections_count > 0) begin
			uvm_test_done.drop_objection(this, 
				$sformatf("Dropping %0d objections at reset", objections_count), 
				objections_count);
		end

		// Restart the current phase sequence after reset
		start_phase_sequence(phase);
	endfunction : handle_reset

	
endclass : uvm_ext_sequencer

`endif
