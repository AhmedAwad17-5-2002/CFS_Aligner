///////////////////////////////////////////////////////////////////////////////
// File:        apb_agent.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Agent.
//              This UVM agent encapsulates the components needed to drive and 
//              monitor the APB bus:
//                 - apb_driver     : drives transactions to DUT
//                 - apb_sequencer  : provides transactions to driver
//                 - apb_monitor    : monitors DUT activity
//                 - apb_coverage   : collects functional coverage (optional)
//                 - apb_agent_config : configuration object
//
//              It can operate in active or passive mode:
//                 - Active  : driver + sequencer + monitor (stimulus + observation)
//                 - Passive : only monitor (observation only)
//
//              This agent also implements reset handling (via apb_reset_handler_if).
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_AGENT
`define APB_AGENT

//------------------------------------------------------------------------------
// UVM Agent: apb_agent
//------------------------------------------------------------------------------
// - Extends uvm_agent
// - Implements apb_reset_handler_if for propagating reset handling
// - Builds and connects driver, sequencer, monitor, and coverage
//------------------------------------------------------------------------------
class apb_agent extends uvm_ext_agent#(
                            .VIRTUAL_INTF(apb_vif), 
                            .ITEM_MON(apb_mon_item), 
                            .ITEM_DRV(apb_drv_item)
                            );

    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // apb_agent_config my_agent_config;

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_param_utils(apb_agent)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    function new(string name = "", uvm_component parent);
        super.new(name, parent);
        
        // uvm_ext_agent_config#(.VIRTUAL_INTF(apb_vif))::type_id::
        //     set_inst_override(apb_agent_config::get_type(), "my_agent_config", this);

        uvm_ext_monitor#(.VIRTUAL_INTF(apb_vif), .ITEM_MON(apb_mon_item))::type_id::
            set_inst_override(apb_monitor::get_type(), "my_monitor", this);

        uvm_ext_coverage#(.VIRTUAL_INTF(apb_vif), .ITEM_MON(apb_mon_item))::type_id::
            set_inst_override(apb_coverage::get_type(), "my_coverage", this);

        uvm_ext_driver#(.VIRTUAL_INTF(apb_vif), .ITEM_DRV(apb_drv_item))::type_id::
            set_inst_override(apb_driver::get_type(), "my_driver", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // my_agent_config     = apb_agent_config::type_id::create("my_agent_config", this);
                                
        super.build_phase(phase);
    endfunction : build_phase
 
endclass : apb_agent

`endif
