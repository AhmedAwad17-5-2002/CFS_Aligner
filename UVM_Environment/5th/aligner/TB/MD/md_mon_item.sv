/////////////////////////////////////////////////////////////////////////////// 
// File:        md_mon_item.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: Master Monitor Transaction Item. 
//              Represents a transaction observed by the master monitor. 
//              This object captures all relevant fields of the transaction 
//              driven onto the DUT interface, including delays, payload data, 
//              offsets, and response type. Constraints (to be added in the 
//              future) ensure bounded and realistic values. 
//              Provides utility functions for recording, debug, and 
//              string-based visualization of transaction contents. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_MON_ITEM
`define MD_MON_ITEM

//------------------------------------------------------------------------------
// Class: md_mon_item
//------------------------------------------------------------------------------
// - Extends: md_base_item (base transaction class)
// - Purpose: Stores one MD transaction observed by the monitor.
//------------------------------------------------------------------------------
class md_mon_item extends md_base_item;
	
	/*-------------------------------------------------------------------------------
	-- Fields (randomizable / captured data)
	-------------------------------------------------------------------------------*/
	
	// Delay before the current transaction (useful for timing correlation)
	int unsigned prev_item_delay;

	// Data payload observed (dynamic array of bytes)
	bit [7:0] data[$];

	// Offset of the transaction (useful for alignment rules in protocol)
	int unsigned offset;

	// Response associated with this transaction (MD_OKAY, MD_ERR, etc.)
	md_response response;

	// Length of the transfer in clock cycles
	int unsigned length;

	// String for storing or printing pure data representation
	string only_data;
	
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers this object with the UVM factory so it can be created dynamically
	`uvm_object_utils(md_mon_item)
	
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	function new(string name = "md_mon_item");
		super.new(name);
	endfunction : new

	// Record object fields into the UVM recorder (for waveform/debug databases)
	virtual function void do_record(uvm_recorder recorder);
		super.do_record(recorder);
		recorder.record_string("data", data2string());
		recorder.record_field("size", data.size(), $bits(data.size()));
		recorder.record_field("offset", offset, $bits(offset));
		recorder.record_field("length", length, $bits(length));
		recorder.record_field("prev_item_delay", prev_item_delay, $bits(prev_item_delay));
		recorder.record_string("response", response.name());
	endfunction : do_record

	// Convert object contents to a human-readable string (for logs/debug)
	virtual function string convert2string();
		string data_as_string;

		data_as_string = $sformatf(
			"\n\n\t\t\t\t------> [%0t..%0s]  data: %0s, offset: %0d, prev_item_delay: %0d, response: %0s <-----\n\n\n\n",
			get_begin_time(), is_active() ? "" : $sformatf("%0t", get_end_time()), 
			data2string(), offset, prev_item_delay, response.name());

		return $sformatf("%0s\n--------------------------------------------------------------------------------------------------------------------------------------------------------------------------",
			data_as_string);
	endfunction : convert2string

	// Helper: convert data array into formatted hex string
	virtual function string data2string();
		string datatostring = "{";
		foreach (data[idx]) begin
			datatostring = $sformatf("%0s'h%02x%0s", 
				datatostring, 
				data[idx], 
				(idx == data.size()-1 ? "}" : ", "));
		end
		only_data = datatostring;
		return datatostring;
	endfunction : data2string
	
endclass : md_mon_item

`endif
