///////////////////////////////////////////////////////////////////////////////
// File:        apb_mon_item.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB monitor transaction item.
//              This class extends apb_base_item with fields captured by the
//              monitor from DUT activity. It represents *observed* bus 
//              transactions, including read data, response type, transfer
//              length, and timing information (inter-transaction delay).
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_MON_ITEM
`define APB_MON_ITEM

//------------------------------------------------------------------------------
// UVM Sequence Item: apb_mon_item
//------------------------------------------------------------------------------
// - Extends apb_base_item with monitor-specific fields.
// - Represents DUT-observed transactions rather than generated ones.
//------------------------------------------------------------------------------
class apb_mon_item extends apb_base_item;
	
    /*-------------------------------------------------------------------------------
    -- Interface, port, fields (captured by monitor)
    -------------------------------------------------------------------------------*/
    // Read data returned by the slave during a read transaction
    apb_data prdata;

    // Response from the slave (e.g., OKAY, ERROR, etc.)
    apb_response response;

    // Number of beats or cycles the transaction lasted
    int unsigned length;

    // Delay between this item and the previous monitored item
    int unsigned prev_item_delay;

    // (Optional future fields: pready, pslverr, etc.)
    // logic pready;
    // logic pslverr;
	
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_object_utils(apb_mon_item)
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/

    // Constructor
    function new(string name = "apb_mon_item");
        super.new(name);
    endfunction : new


    virtual function void do_record(uvm_recorder recorder);
      super.do_record(recorder);
      recorder.record_string("direction", pwrite.name());
      recorder.record_field("address", paddr, `APB_MAX_ADDR_WIDTH);
      recorder.record_field("write_data", pwdata, `APB_MAX_DATA_WIDTH);
      recorder.record_field("read_data", prdata, `APB_MAX_DATA_WIDTH);
      recorder.record_field("length", length, $bits(length));
      recorder.record_field("prev_item_delay", prev_item_delay, $bits(prev_item_delay));
      recorder.record_string("response",response.name());
    endfunction

    // convert2string()
    // - Extends base class string representation
    // - Adds prdata, response, length, and timing delay
    virtual function string convert2string();
        string result;
        result = super.convert2string();

        result = $sformatf(
            "%0s, prdata: 0x%0h, response: %0s, length: %0d, prev_item_delay: %0d\n",
            result, prdata, response.name(), length, prev_item_delay
        );

        return result;
    endfunction : convert2string
	
endclass : apb_mon_item

`endif
