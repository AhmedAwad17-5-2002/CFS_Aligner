///////////////////////////////////////////////////////////////////////////////
// File:        apb_drv_item.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB driver transaction item.
//              This class extends apb_base_item by adding driver-specific 
//              fields for timing control, such as pre-drive and post-drive 
//              delays. These delays allow fine-grained control of how 
//              transactions are applied to the APB bus during simulation.
//              It also overrides convert2string() to provide detailed logging.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_DRV_ITEM
`define APB_DRV_ITEM

//------------------------------------------------------------------------------
// UVM Sequence Item: apb_drv_item
//------------------------------------------------------------------------------
// - Extends apb_base_item (adds timing knobs).
// - Used by the APB driver to model realistic transaction timing.
//------------------------------------------------------------------------------
class apb_drv_item extends apb_base_item;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    // Number of cycles to wait before driving the transaction
    rand int unsigned pre_drive_delay;
    
    // Number of cycles to wait after driving the transaction
    rand int unsigned post_drive_delay;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this item with the UVM factory for dynamic creation.
    `uvm_object_utils(apb_drv_item)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    // - "name": unique item instance name
    function new(string name = "apb_drv_item");
        super.new(name);
    endfunction : new

    // convert2string()
    // - Extends base class string representation
    // - Adds pwdata (if WRITE) and timing delays
    virtual function string convert2string();
        string result;
        result = super.convert2string();

        // Append write data only for WRITE transactions
        if (pwrite == APB_WRITE) begin
            result = $sformatf("%0s, pwdata: 0x%0h", result, pwdata);
        end

        // Append timing delays
        result = $sformatf("%0s, pre_drive_delay: %0d, post_drive_delay: %0d\n",
                            result, pre_drive_delay, post_drive_delay);

        return result;
    endfunction : convert2string

    virtual function void do_record(uvm_recorder recorder);
      super.do_record(recorder);
      recorder.record_string("direction", pwrite.name());
      recorder.record_field("address", paddr, `APB_MAX_ADDR_WIDTH);
      recorder.record_field("write_data", pwdata, `APB_MAX_DATA_WIDTH);
      recorder.record_field("pre_drive_delay", pre_drive_delay, $bits(pre_drive_delay));
      recorder.record_field("post_drive_delay", post_drive_delay, $bits(post_drive_delay));
    endfunction


    /*-------------------------------------------------------------------------------
    -- Constraints
    -------------------------------------------------------------------------------*/
    // Default constraint: limit pre-drive delay to max 5 cycles
    constraint pre_drive_delay_default {
        soft pre_drive_delay <= 5;
    }

    // Default constraint: limit post-drive delay to max 5 cycles
    constraint post_drive_delay_default {
        soft post_drive_delay <= 5;
        soft post_drive_delay > 0;
    }

endclass : apb_drv_item

`endif
