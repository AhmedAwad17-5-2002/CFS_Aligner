///////////////////////////////////////////////////////////////////////////////
// File:        apb_driver.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Driver.
//              This UVM driver fetches APB transactions (apb_drv_item) from the 
//              sequencer, translates them into pin-level activity on the APB 
//              interface (via the virtual interface), and implements the APB 
//              protocol handshake (PSEL, PENABLE, PREADY, PWRITE, PWDATA, PADDR).
//              
//              Features:
//                - Drives APB transactions from sequences
//                - Implements proper APB handshake timing
//                - Supports configurable pre-drive and post-drive delays
//                - Handles reset and returns bus to IDLE state
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_DRIVER
`define APB_DRIVER

//------------------------------------------------------------------------------
// UVM Driver: apb_driver
//------------------------------------------------------------------------------
// - Extends uvm_driver with transaction type apb_drv_item.
// - Drives transactions on the APB interface using the standard APB protocol.
// - Implements reset handling (via apb_reset_handler_if).
//------------------------------------------------------------------------------
class apb_driver extends uvm_ext_driver #(.ITEM_DRV(apb_drv_item),.VIRTUAL_INTF(apb_vif)) 
    implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Configuration handle (contains APB virtual interface and settings)
    apb_agent_config my_agent_config;

    apb_drv_item my_drv_item;
    
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_utils(apb_driver)
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    function new(string name = "apb_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new


    // end_of_elaboration_phase
    // - Verifies correct agent config type
    // - Ensures pointer is valid before simulation run
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
                    apb_agent_config::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase


    // drive_transaction
    // - Implements APB protocol handshake for a single transaction.
    protected virtual task drive_transaction(apb_drv_item my_drv_item);
        apb_vif my_drv_vif = my_agent_config.get_vif();

        `uvm_info("ITEM_START", $sformatf("\nDriving transaction: %0s", 
                   my_drv_item.convert2string()), UVM_LOW)

        //----------------------------------------------------------------------
        // Step 0: Initialize signals (IDLE state)
        //----------------------------------------------------------------------
        my_drv_vif.pwrite  <= 0;
        my_drv_vif.psel    <= 0;
        my_drv_vif.penable <= 0;
        my_drv_vif.pwdata  <= 0;
        my_drv_vif.paddr   <= 0;

        //----------------------------------------------------------------------
        // Step 1: Apply pre-drive delay (optional, configured per transaction)
        //----------------------------------------------------------------------
        repeat (my_drv_item.pre_drive_delay) @(posedge my_drv_vif.pclk);

        //----------------------------------------------------------------------
        // Step 2: Address and control phase
        //----------------------------------------------------------------------
        my_drv_vif.pwrite <= bit'(my_drv_item.pwrite);
        my_drv_vif.psel   <= 1'b1;
        my_drv_vif.paddr  <= my_drv_item.paddr;

        if (my_drv_item.pwrite == APB_WRITE) begin
            my_drv_vif.pwdata <= my_drv_item.pwdata;
        end

        //----------------------------------------------------------------------
        // Step 3: Access phase (assert PENABLE)
        //----------------------------------------------------------------------
        @(posedge my_drv_vif.pclk);
        my_drv_vif.penable <= 1'b1;
        @(posedge my_drv_vif.pclk);

        //----------------------------------------------------------------------
        // Step 4: Wait for transaction handshake completion
        // - Transaction ends when PREADY=1 or PSLVERR=1
        //----------------------------------------------------------------------
        while (my_drv_vif.pready !== 1'b1) begin
            @(posedge my_drv_vif.pclk);
        end

        //----------------------------------------------------------------------
        // Step 5: Return to IDLE
        //----------------------------------------------------------------------
        my_drv_vif.pwrite  <= 0;
        my_drv_vif.psel    <= 0;
        my_drv_vif.penable <= 0;
        my_drv_vif.pwdata  <= 0;
        my_drv_vif.paddr   <= 0;


        //----------------------------------------------------------------------
        // Step 6: Apply post-drive delay (optional, configured per transaction)
        //----------------------------------------------------------------------
        repeat (my_drv_item.post_drive_delay) @(posedge my_drv_vif.pclk);
    endtask : drive_transaction

    // handle_reset
    // - Kills driving process and resets interface signals to idle.
    virtual function void handle_reset(uvm_phase phase);
       apb_vif my_drv_vif = my_agent_config.get_vif();
       super.handle_reset(phase);

       if (my_drv_vif == null) begin
            `uvm_fatal("NO_VIF", $sformatf("%s: no VIF in handle_reset — skipping reset clears", get_name()))
            super.handle_reset(phase);
            return;
        end
        else begin
            // Reset signals to idle
            my_drv_vif.psel    <= 0;
            my_drv_vif.penable <= 0;
            my_drv_vif.pwrite  <= 0;
            my_drv_vif.paddr   <= 0;
            my_drv_vif.pwdata  <= 0;
        end
    endfunction : handle_reset

    
endclass : apb_driver

`endif
