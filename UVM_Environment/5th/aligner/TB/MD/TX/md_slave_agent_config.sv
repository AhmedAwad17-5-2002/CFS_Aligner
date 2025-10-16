/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_agent_config.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: Configuration class for the MD Slave Agent. 
//              This class extends the generic md_agent_config with a 
//              parameterized DATA_WIDTH. It provides configuration 
//              information that controls the behavior of the MD Slave Agent 
//              (such as interface connections, protocol parameters, etc.). 
//              It is registered with the UVM factory to allow flexible 
//              testbench reuse and configurability. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_SLAVE_AGENT_CONFIG
`define MD_SLAVE_AGENT_CONFIG

//------------------------------------------------------------------------------
// UVM Configuration: md_slave_agent_config
//------------------------------------------------------------------------------
// - Extends md_agent_config with DATA_WIDTH parameterization.
// - Holds configuration data for the MD Slave Agent.
// - Enables UVM factory-based creation and overrides.
//------------------------------------------------------------------------------
class md_slave_agent_config #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
	extends md_agent_config #(.DATA_WIDTH(DATA_WIDTH));
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
	// Add fields here to configure the slave agent, e.g.:
	// - active/passive mode
	// - virtual interface handles
	// - protocol-specific settings
	// (currently no extra fields are defined)

	//Value of "ready" signal at reset
    local bit ready_at_reset=1;
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_slave_agent_config with UVM factory.
	// Allows type-based or instance-based overrides during testbench construction.
	`uvm_object_param_utils(md_slave_agent_config #(.DATA_WIDTH(DATA_WIDTH)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - "name": unique instance name
	// - "parent": parent component in UVM hierarchy
	function new(string name = "md_slave_agent_config");
		super.new(name);			
	endfunction : new


	//Setter for field ready_at_reset
    virtual function void set_ready_at_reset(bit set_ready_at_reset);
      ready_at_reset = set_ready_at_reset;
    endfunction
    
    //Getter for field ready_at_reset
    virtual function bit get_ready_at_reset();
      return ready_at_reset;
    endfunction
	
endclass : md_slave_agent_config

`endif
