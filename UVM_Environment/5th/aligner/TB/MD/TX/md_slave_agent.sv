/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_agent.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM Slave Agent for MD Interface. 
//              This agent extends the base md_agent to implement the 
//              slave-side functionality of the MD protocol. 
//              Responsibilities: 
//                - Responds to transactions initiated by a salve. 
//                - Overrides the default configuration, driver, and sequencer 
//                  with slave-specific components. 
//                - Provides connectivity between monitor and sequencer 
//                  for passive-to-active communication. 
//              The agent can be configured via md_slave_agent_config. 
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_SLAVE_AGENT
`define MD_SLAVE_AGENT

//------------------------------------------------------------------------------
// UVM Slave Agent: md_slave_agent
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default comes from `DATA_WIDTH macro).
// - Extends md_agent (base class for MD protocol agents).
// - Registers with UVM factory for dynamic instantiation.
// - Applies instance overrides so that:
//      * md_agent_config   → md_slave_agent_config
//      * md_driver         → md_slave_driver
//      * md_base_sequencer → md_slave_sequencer
//------------------------------------------------------------------------------
class md_slave_agent #(int unsigned DATA_WIDTH = `DATA_WIDTH) 
	extends md_agent #(
						.DATA_WIDTH(DATA_WIDTH), 
						.ITEM_DRV(md_drv_slave_item)
					  );
	
	/*-------------------------------------------------------------------------------
	-- Interface, ports, fields
	-------------------------------------------------------------------------------*/
	// No additional fields are defined here.
	// All common fields/handles (driver, monitor, sequencer, config) 
	// are inherited from md_agent.
	// md_slave_agent_config#(.DATA_WIDTH(DATA_WIDTH)) my_agent_config;

	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers this parameterized agent with UVM factory.
	// Allows dynamic creation using type_id::create().
	`uvm_component_param_utils(md_slave_agent#(.DATA_WIDTH(DATA_WIDTH)))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - name: unique component instance name
	// - parent: parent component in UVM hierarchy
	// - Also installs instance overrides for slave-specific components.
	function new(string name = "md_slave_agent", uvm_component parent = null);
		super.new(name, parent);

		// Override config class with slave-specific config
		// md_agent_config #(.DATA_WIDTH(DATA_WIDTH))::type_id::
		// 	set_inst_override(
		// 		md_slave_agent_config#(.DATA_WIDTH(DATA_WIDTH))::get_type(), // new config type
		// 		"my_agent_config",                                        	 // base config being overridden
		// 		this                                                         // scope = this agent
		// 	);

		my_agent_config     = md_slave_agent_config#(.DATA_WIDTH(DATA_WIDTH))
                                ::type_id::create("my_agent_config", this);

		// Override driver with slave driver
		md_driver #(.ITEM_DRV(md_drv_slave_item), .DATA_WIDTH(DATA_WIDTH))::type_id::
			set_inst_override(
				md_slave_driver#(.DATA_WIDTH(DATA_WIDTH))::get_type(),       // new driver type
				"my_driver",                                              // base driver being overridden
				this                                                         // scope = this agent
			);

		// Override sequencer with slave sequencer
		md_base_sequencer #(.ITEM_DRV(md_drv_slave_item))::type_id::
			set_inst_override(
				md_slave_sequencer#(.DATA_WIDTH(DATA_WIDTH))::get_type(),    // new sequencer type
			    "my_sequencer",                                           // base sequencer being overridden
			    this                                                         // scope = this agent
			);

		
	endfunction : new

	// Connect Phase
	// - Called during UVM connect phase.
	// - Connects the monitor’s analysis port to the slave sequencer’s port.
	virtual function void connect_phase(uvm_phase phase);
      	super.connect_phase(phase);
      	connect_port_from_mon_to_slave_seqr();
    endfunction

	virtual function void build_phase(uvm_phase phase);
		
                                
        super.build_phase(phase);
    endfunction : build_phase

    
    // Connect monitor output to sequencer input
    // - Enables driving transactions in the slave sequencer based on observed activity.
    // - Useful for reactive/protocol-driven slave behavior.
    protected virtual function void connect_port_from_mon_to_slave_seqr();
      	if(my_agent_config.get_is_active() == UVM_ACTIVE) begin
        	md_slave_sequencer#(DATA_WIDTH) my_sequencer;
        
        	// Ensure sequencer is of correct slave type
        	if($cast(my_sequencer, super.my_sequencer) == 0) begin
          		`uvm_fatal("ALGORITHM_ISSUE", 
          			$sformatf("Could not cast %0s to %0s", 
          				super.my_sequencer.get_full_name(), 
          				md_slave_sequencer#(DATA_WIDTH)::type_id::type_name))
        	end
        
        	// Connect monitor's analysis port to sequencer’s input port
        	my_monitor.monitor_aport.connect(my_sequencer.port_from_monitor);
      	end
    endfunction
	
endclass : md_slave_agent

`endif
