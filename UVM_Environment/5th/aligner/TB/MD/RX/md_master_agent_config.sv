/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_agent_config.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM configuration class for the MD Master Agent.
//              This class extends the base md_agent_config and provides 
//              configuration parameters specific to the Master agent. 
//              It enables customization of agent behavior such as 
//              data width and interface connections.
//              The config object is shared across components to ensure 
//              consistent settings for the MD Master Agent in the 
//              verification environment.
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_AGENT_CONFIG
`define MD_MASTER_AGENT_CONFIG

//------------------------------------------------------------------------------
// UVM Configuration Class: md_master_agent_config
//------------------------------------------------------------------------------
// - Extends md_agent_config (generic agent configuration base class).
// - Parameterized by DATA_WIDTH to allow flexible bus sizes.
// - Used to configure MD Master Agent instances (e.g., driver, sequencer, monitor).
//------------------------------------------------------------------------------
class md_master_agent_config #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
	extends md_agent_config #(.DATA_WIDTH(DATA_WIDTH));
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// NOTE: Add any master-specific configuration fields here.
	// Example:
	// bit enable_coverage;   // Enable/disable coverage collection
	// string master_id;      // Identifier for debugging multiple agents
	
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers this config class with UVM factory, enabling factory overrides
	// and dynamic creation.
	`uvm_object_param_utils(md_master_agent_config #(.DATA_WIDTH(DATA_WIDTH)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": instance name (default = "md_master_agent_config")
	// - "parent": parent component in the UVM hierarchy (null for top-level configs)
	function new(string name = "md_master_agent_config");
		super.new(name);
	endfunction : new


		
	
endclass : md_master_agent_config

`endif
