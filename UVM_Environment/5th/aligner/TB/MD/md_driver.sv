///////////////////////////////////////////////////////////////////////////////
// File:        md_driver.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-07
// Description: MD Driver.
//              This UVM driver fetches MD transactions (md_drv_item) from the 
//              sequencer, translates them into pin-level activity on the MD 
//              interface (via the virtual interface), and implements the MD 
//              protocol handshake.
//
//              Features:
//                - Drives MD transactions from sequences
//                - Implements proper MD handshake timing
//                - Supports configurable pre-drive and post-drive delays
//                - Handles reset and returns bus to IDLE state
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_DRIVER
`define MD_DRIVER

//------------------------------------------------------------------------------
// UVM Driver: md_driver
//------------------------------------------------------------------------------
// - Extends uvm_driver with transaction type md_drv_item.
// - Drives transactions on the MD interface using the standard MD protocol.
// - Implements reset handling (via md_reset_handler_if).
//------------------------------------------------------------------------------
class md_driver #(type ITEM_DRV = md_drv_item, int unsigned DATA_WIDTH = `DATA_WIDTH) 
    extends uvm_ext_driver #(.ITEM_DRV(ITEM_DRV),.VIRTUAL_INTF(md_vif));
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Configuration object containing MD virtual interface and agent settings
    md_agent_config #(.DATA_WIDTH(DATA_WIDTH)) my_agent_config;


    // Process handle used to track the transaction-driving process
    // (needed to safely kill/restart when reset is asserted)
    protected process process_drive_transactions;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Register this parameterized driver with the UVM factory
    `uvm_component_param_utils(md_driver#(.ITEM_DRV(ITEM_DRV), .DATA_WIDTH(DATA_WIDTH)))
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - name:   instance name
    // - parent: parent component in the UVM hierarchy
    function new(string name = "md_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // super.my_agent_config = my_agent_config;
        if(super.my_agent_config == null) begin
          `uvm_fatal("ALGORITHM_ISSUE", 
              $sformatf("Agent config pointer from %0s is null", get_full_name()))
        end
      
        if($cast(my_agent_config, super.my_agent_config) == 0) begin
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Failed cast: %0s to %0s", 
                    super.my_agent_config.get_full_name(), 
                    md_agent_config#(.DATA_WIDTH(DATA_WIDTH))::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase
    
endclass : md_driver

`endif
