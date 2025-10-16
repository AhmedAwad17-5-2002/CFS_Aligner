/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_agent.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: Master Agent for MD protocol. 
//              This class extends the base md_agent and specializes it for 
//              master operations. It overrides configuration, driver, and 
//              sequencer components with master-specific implementations. 
//              The agent is parameterized by DATA_WIDTH to allow flexible 
//              transaction widths. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_AGENT
`define MD_MASTER_AGENT

//------------------------------------------------------------------------------
// UVM Agent: md_master_agent
//------------------------------------------------------------------------------
// - Extends md_agent with DATA_WIDTH parameterization.
// - Overrides configuration, driver, and sequencer using UVM factory instance 
//   overrides to bind master-specific components at runtime.
//------------------------------------------------------------------------------
class md_master_agent #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
	extends md_agent #(
		.DATA_WIDTH(`DATA_WIDTH), 
		.ITEM_DRV(md_drv_master_item)
		);
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// No new ports/fields defined here (inherits from md_agent).
	// All specialization is done via factory overrides in the constructor.
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory register
	-------------------------------------------------------------------------------*/
	// Register the parameterized class with UVM factory.
	// Allows md_master_agent to be created dynamically.
	`uvm_component_param_utils(md_master_agent#(.DATA_WIDTH(DATA_WIDTH)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": instance name
	// - "parent": parent component in hierarchy
	// Performs instance overrides for:
	//   1. md_agent_config   -> md_master_agent_config
	//   2. md_driver         -> md_master_driver
	//   3. md_sequencer      -> md_master_sequencer
	function new(string name = "md_master_agent", uvm_component parent=null);
		super.new(name, parent);
		
		// Override agent config with master-specific config
		// md_agent_config #(.DATA_WIDTH(DATA_WIDTH)) :: type_id :: 
		// 	set_inst_override(md_master_agent_config #(.DATA_WIDTH(DATA_WIDTH)) :: get_type(), 
		// 	                  "my_agent_config", this);

		// Override driver with master driver
		md_driver #(.ITEM_DRV(md_drv_master_item), .DATA_WIDTH(DATA_WIDTH)) :: type_id :: 
			set_inst_override(md_master_driver #(.DATA_WIDTH(DATA_WIDTH)) :: get_type(), 
			                  "my_driver", this);	

		// Override sequencer with master sequencer
		md_base_sequencer #(.ITEM_DRV(md_drv_master_item)) :: type_id :: 
			set_inst_override(md_master_sequencer #(.DATA_WIDTH(DATA_WIDTH)) :: get_type(), 
			                  "my_sequencer", this);
	endfunction : new


	virtual function void build_phase(uvm_phase phase);
		my_agent_config     = md_master_agent_config#(.DATA_WIDTH(DATA_WIDTH))
                                ::type_id::create("my_agent_config", this);
                                
        super.build_phase(phase);
    endfunction : build_phase
	
endclass : md_master_agent

`endif
