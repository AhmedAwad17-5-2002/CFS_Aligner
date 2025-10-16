/////////////////////////////////////////////////////////////////////////////// 
// File:        md_master_driver.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-02 
// Description: UVM Master Driver for MD Protocol. 
//              This driver fetches transactions (md_drv_master_item) from 
//              the sequencer and drives them onto the MD interface (md_vif). 
//              It is responsible for: 
//                  - Performing protocol timing (delays, valid/ready handshake). 
//                  - Formatting and aligning data according to offset and width. 
//                  - Handling reset behavior and returning interface signals to idle. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MASTER_DRIVER
`define MD_MASTER_DRIVER 

//------------------------------------------------------------------------------
// Class: md_master_driver
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default comes from `DATA_WIDTH macro).
// - Extends md_driver, specializing it to drive md_drv_master_item transactions.
// - Communicates with DUT via md_vif.
//------------------------------------------------------------------------------
class md_master_driver #(int unsigned DATA_WIDTH=`DATA_WIDTH) 
    extends md_driver #(.ITEM_DRV(md_drv_master_item), .DATA_WIDTH(DATA_WIDTH)) implements uvm_ext_reset_handler_if;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Virtual interface for MD bus connection
    md_vif my_md_vif;

    // Data width in bytes (derived from DATA_WIDTH bits)
    int unsigned data_width_in_bytes;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Allows the driver to be created via the factory
    `uvm_component_param_utils(md_master_driver#(DATA_WIDTH))
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
	
    // Constructor
    function new(string name = "md_master_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Task: drive_transaction
    //--------------------------------------------------------------------------
    // - Drives a single md_drv_master_item onto the MD interface.
    // - Handles pre/post drive delays.
    // - Performs valid/ready handshake.
    // - Formats data with correct offset alignment.
    //--------------------------------------------------------------------------
    protected virtual task drive_transaction(md_drv_master_item my_drv_item);
        
        // Get virtual interface from agent config
        my_md_vif = my_agent_config.get_vif();

        // Calculate width in bytes
        data_width_in_bytes = DATA_WIDTH / 8;

        // Debug message
        `uvm_info("ITEM_START", $sformatf("\nDriving \"%0s\": %0s", 
                    my_drv_item.get_full_name(), 
                    my_drv_item.convert2string()), UVM_LOW)

        

        // Safety check: offset + data size must not exceed bus width
        if(my_drv_item.offset + my_drv_item.data.size() > data_width_in_bytes)
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Trying to drive an item with offset %0d and %0d bytes but the width of the data bus, in bytes, is %0d",
                my_drv_item.offset, my_drv_item.data.size(), data_width_in_bytes))


        my_md_vif.data   <= 'h0;
        my_md_vif.offset <= 'h0;
        my_md_vif.size   <= 'h0;
        my_md_vif.valid  <= 'h0;

        // Apply pre-drive delay cycles
        if(my_drv_item.pre_drive_delay != 0)
            for (int i = 0; i < my_drv_item.pre_drive_delay; i++) begin
                @(posedge my_md_vif.clk);
            end

        // Assert valid signal
        my_md_vif.valid <= 1;

        // Format and drive data on bus
        begin
            bit [DATA_WIDTH-1 : 0] data = 0;
            foreach (my_drv_item.data[idx]) begin
                bit [DATA_WIDTH-1 : 0] temp_data;
                // Align each byte according to offset
                temp_data = my_drv_item.data[idx] 
                            << ((my_drv_item.offset + idx) * 8);
                data = temp_data | data;
            end
            my_md_vif.data <= data;
        end

        // Drive offset and size
        my_md_vif.offset <= my_drv_item.offset;
        my_md_vif.size   <= my_drv_item.data.size();

        // Wait for ready handshake
        @(posedge my_md_vif.clk);
        while(my_md_vif.ready != 1) begin
            @(posedge my_md_vif.clk);
        end

        // Clear interface signals after transaction
        my_md_vif.data   <= 'h0;
        my_md_vif.offset <= 'h0;
        my_md_vif.size   <= 'h0;
        my_md_vif.valid  <= 'h0; 

        // Apply post-drive delay cycles
        if(my_drv_item.post_drive_delay != 0)
            for (int i = 0; i < my_drv_item.post_drive_delay; i++) begin
                @(posedge my_md_vif.clk);
            end
    endtask : drive_transaction

    //--------------------------------------------------------------------------
    // Function: handle_reset
    //--------------------------------------------------------------------------
    // - Handles DUT reset by clearing MD interface signals.
    // - Ensures driver does not leave signals asserted after reset.
    //--------------------------------------------------------------------------
    virtual function void handle_reset(uvm_phase phase);
        md_vif my_drv_vif = my_agent_config.get_vif();

        if (my_drv_vif == null) begin
            `uvm_fatal("NO_VIF", $sformatf("%s: no VIF in handle_reset — skipping reset clears", get_name()))
            super.handle_reset(phase);
            return;
        end
        else begin
            // Reset signals to idle values
            my_drv_vif.data   <= 'h0;
            my_drv_vif.offset <= 'h0;
            my_drv_vif.size   <= 'h0;
            my_drv_vif.valid  <= 'h0;  
        end

        
    endfunction : handle_reset
	
endclass : md_master_driver

`endif
