/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_driver.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM Slave Driver for MD Protocol. 
//              This driver responds to transactions (md_drv_slave_item) 
//              initiated by the master and drives them onto the MD interface 
//              (md_vif). 
//              Responsibilities include: 
//                  - Responding to valid/ready handshakes from the master. 
//                  - Driving "ready" and "err" signals based on transaction fields. 
//                  - Formatting data/response with correct alignment. 
//                  - Handling reset behavior and restoring interface signals to idle. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_SLAVE_DRIVER
`define MD_SLAVE_DRIVER 

//------------------------------------------------------------------------------
// Class: md_slave_driver
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default taken from `DATA_WIDTH macro).
// - Extends md_driver, specialized to handle md_drv_slave_item transactions. 
// - Connects to DUT through md_vif (virtual interface).
//------------------------------------------------------------------------------
class md_slave_driver #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
    extends md_driver #(.ITEM_DRV(md_drv_slave_item), .DATA_WIDTH(DATA_WIDTH)) 
    implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Virtual interface for MD bus connection
    md_vif my_md_vif;

    // Data width in bytes (derived from DATA_WIDTH bits)
    int unsigned data_width_in_bytes;

    // Agent configuration (specialized for slave)
    /*******************************************************************************************
    ----------> Note: This hides the parent agent_config with a more specific type <----------
    to accsess get_ready_at_reset() function
    ********************************************************************************************/
    md_slave_agent_config #(.DATA_WIDTH(DATA_WIDTH)) my_agent_config;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Register driver with UVM factory for dynamic creation
    `uvm_component_param_utils(md_slave_driver#(DATA_WIDTH))
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    function new(string name = "md_slave_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    // end_of_elaboration_phase
    // - Verifies correct agent config type
    // - Ensures pointer is valid before simulation run
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        if(super.my_agent_config == null) begin
          `uvm_fatal("ALGORITHM_ISSUE", 
              $sformatf("Agent config pointer from %0s is null", get_full_name()))
        end
      
        if($cast(my_agent_config, super.my_agent_config) == 0) begin
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Failed cast: %0s to %0s", 
                    super.my_agent_config.get_full_name(), 
                    md_slave_agent_config#(DATA_WIDTH)::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase

    //--------------------------------------------------------------------------
    // Task: drive_transaction
    //--------------------------------------------------------------------------
    // - Responds to master-initiated transfer (md_drv_slave_item).
    // - Drives "ready" and "err" signals with appropriate timing.
    // - Waits for specified number of cycles before responding.
    // - Releases signals at the end of the transaction.
    //--------------------------------------------------------------------------
    protected virtual task drive_transaction(md_drv_slave_item my_drv_item);
        
        // Get virtual interface from agent config
        my_md_vif = my_agent_config.get_vif();

        // Calculate bus width in bytes
        data_width_in_bytes = DATA_WIDTH / 8;

        // Debug message
        `uvm_info("ITEM_START", $sformatf("\nDriving \"%0s\": %0s", 
                    my_drv_item.get_full_name(), 
                    my_drv_item.convert2string()), UVM_LOW)

        // Sanity check: only respond if master asserts valid
        if(my_md_vif.valid !== 1) begin
            `uvm_error("ALGORITHM_ISSUE", 
                $sformatf("Slave tried to respond with no active master transfer. Item: %0s", 
                          my_drv_item.convert2string()))
        end

        // Initial state: not ready
        my_md_vif.ready <= 0;
      
        // Wait for required number of cycles before asserting ready
        for(int i = 0; i < my_drv_item.length; i++) begin
            @(posedge my_md_vif.clk);
        end

        // Drive response back to master
        my_md_vif.ready <= 1;
        my_md_vif.err   <= bit'(my_drv_item.response);
      
        @(posedge my_md_vif.clk);
      
        // Final ready/err values after transaction
        my_md_vif.ready <= my_drv_item.ready_at_end;
        my_md_vif.err   <= 0;
    endtask : drive_transaction

    //--------------------------------------------------------------------------
    // Function: handle_reset
    //--------------------------------------------------------------------------
    // - Resets MD interface signals after DUT reset.
    // - Ensures slave driver does not leave signals in an active state.
    //--------------------------------------------------------------------------
    virtual function void handle_reset(uvm_phase phase);
        md_vif my_drv_vif = my_agent_config.get_vif();


        if (my_drv_vif == null) begin
            `uvm_fatal("NO_VIF", $sformatf("%s: no VIF in handle_reset — skipping reset clears", get_name()))
            super.handle_reset(phase);
            return;
        end
        else begin
            // Reset slave response signals
            my_drv_vif.ready <= my_agent_config.get_ready_at_reset();
            my_drv_vif.err   <= 0;
        end

        
    endfunction : handle_reset
    
endclass : md_slave_driver

`endif
