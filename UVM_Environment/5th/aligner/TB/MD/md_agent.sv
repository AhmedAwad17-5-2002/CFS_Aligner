/////////////////////////////////////////////////////////////////////////////// 
// File:        md_agent.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM Agent for MD Protocol Verification. 
//              ---------------------------------------------------------------
//              The MD agent encapsulates the driver, sequencer, monitor, and 
//              optional coverage components for the MD protocol interface. 
//              It supports both ACTIVE and PASSIVE modes, controlled via the 
//              agent configuration object (md_agent_config). 
//
//              Key Responsibilities:
//                - Retrieves virtual interface (md_vif) from the UVM config_db. 
//                - Builds driver & sequencer in ACTIVE mode, or only monitor in 
//                  PASSIVE mode. 
//                - Propagates reset events to all child components that implement 
//                  the reset handler interface. 
//                - Optionally connects monitor output to coverage component. 
//
//              Components included in ACTIVE mode:
//                - md_driver: drives transactions onto the MD interface. 
//                - md_sequencer: provides stimulus items to the driver. 
//              Always included:
//                - md_monitor: observes bus activity. 
//              Optional:
//                - md_coverage: records functional coverage from monitor analysis. 
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_AGENT
`define MD_AGENT

//------------------------------------------------------------------------------
// UVM Agent: md_agent
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH and ITEM_DRV (transaction type).
// - Implements md_reset_handler_if (reset propagation interface).
// - Builds sequencer/driver when ACTIVE, or monitor-only when PASSIVE.
//------------------------------------------------------------------------------
class md_agent #( int unsigned DATA_WIDTH=`DATA_WIDTH, type ITEM_DRV = md_drv_item) 
    extends uvm_ext_agent#(.VIRTUAL_INTF(md_vif), .ITEM_MON(md_mon_item), .ITEM_DRV(ITEM_DRV));

    

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_param_utils(md_agent #(.DATA_WIDTH(DATA_WIDTH), .ITEM_DRV(ITEM_DRV)))


    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/

    // Constructor
    function new(string name = "md_agent", uvm_component parent=null);
        super.new(name, parent);

        // uvm_ext_agent_config#(.VIRTUAL_INTF(md_vif))::
        //     type_id::set_inst_override(md_agent_config#(DATA_WIDTH)::get_type(), "my_agent_config", this);

        uvm_ext_monitor#(.VIRTUAL_INTF(md_vif), .ITEM_MON(md_mon_item))::
            type_id::set_inst_override(md_monitor#(DATA_WIDTH)::get_type(), "my_monitor", this);

        uvm_ext_coverage#(.VIRTUAL_INTF(md_vif), .ITEM_MON(md_mon_item))::
            type_id::set_inst_override(md_coverage#(DATA_WIDTH)::get_type(), "my_coverage", this);

        uvm_ext_driver#(.VIRTUAL_INTF(md_vif), .ITEM_DRV(ITEM_DRV))::
            type_id::set_inst_override(md_driver#(.DATA_WIDTH(DATA_WIDTH), .ITEM_DRV(ITEM_DRV))::get_type(), "my_driver", this);

        uvm_ext_sequencer#(.ITEM_DRV(ITEM_DRV))::type_id::
            set_inst_override(md_base_sequencer#(ITEM_DRV)::get_type(), "my_sequencer", this);
    endfunction : new

endclass : md_agent

`endif
