/////////////////////////////////////////////////////////////////////////////// 
// File:        algn_data_item.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-10-12 
// Description: Master Monitor Transaction Item for the Alignment Environment.
// 
// Detailed Description & Flow:
// ---------------------------------------------
// The `algn_data_item` class represents a *single MD transaction* captured or 
// generated within the verification environment of the Alignment Controller DUT.
// 
// This object is primarily used by the **monitor** and **scoreboard** components 
// to encapsulate all relevant information about one transaction cycle. Each 
// `algn_data_item` instance holds the payload data, offsets, delays, responses, 
// and length — allowing easy correlation between stimulus and observed DUT 
// behavior.
//
// Typical Flow in the Environment:
// ---------------------------------------------
// 1. **Monitor Phase:**
//    - The monitor samples DUT signals (RX/TX data, valid, ready, etc.).
//    - Once a full MD packet or transaction is detected, it constructs an 
//      `algn_data_item` object.
//    - All fields such as `data`, `offset`, `prev_item_delay`, `response`, 
//      and `length` are filled in based on DUT activity.
// 
// 2. **Scoreboard/Analysis Phase:**
//    - The completed `algn_data_item` is sent through an analysis port.
//    - The scoreboard compares expected vs. actual transactions.
// 
// 3. **Reporting & Debug:**
//    - Functions `convert2string()` and `data2string()` provide formatted text 
//      for easy debugging, coverage reports, or log files.
//
// This structure helps maintain clean separation between signal-level 
// observation (monitors) and transaction-level analysis (scoreboard).
///////////////////////////////////////////////////////////////////////////////  

`ifndef ALGN_DATA_ITEM
`define ALGN_DATA_ITEM

//------------------------------------------------------------------------------
// Class: algn_data_item
//------------------------------------------------------------------------------
// - Extends: uvm_sequence_item (base class for UVM transaction objects).
// - Purpose: Stores one MD transaction observed by the monitor or used as 
//            stimulus. Provides utilities for debug and formatted printing.
//------------------------------------------------------------------------------
class algn_data_item extends uvm_sequence_item;
	
	/*-------------------------------------------------------------------------------
	-- Fields (randomizable / captured data)
	-------------------------------------------------------------------------------*/
	
	// Time delay between this transaction and the previous one (cycles or ns)
	int unsigned prev_item_delay;

	// Dynamic array holding the transaction payload data
	bit [7:0] data[$];

	// Byte offset associated with this transaction (alignment tracking)
	int unsigned offset;

	// Response code captured from DUT (e.g., MD_OKAY, MD_ERR)
	md_response response;

	// Number of cycles the transfer lasted
	int unsigned length;

	// String representation of raw payload data (for logs)
	string only_data;

	// Optional: list of related or source data items (e.g., sub-packets)
	algn_data_item sources[$];
	
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers this object with the UVM factory, enabling dynamic creation
	`uvm_object_utils(algn_data_item)
	
	
	/*-------------------------------------------------------------------------------
	-- Constructor
	-------------------------------------------------------------------------------*/
	// Initializes the object and sets default name
	function new(string name = "algn_data_item");
		super.new(name);
	endfunction : new

	
	/*-------------------------------------------------------------------------------
	-- Utility Functions
	-------------------------------------------------------------------------------*/

	//------------------------------------------------------------------------------
	// Function: convert2string
	//------------------------------------------------------------------------------
	// Purpose:
	//   Converts the contents of the transaction into a human-readable string,
	//   including data, offset, delay, response, and timing.
	// Usage:
	//   $display("%s", tr.convert2string());
	//------------------------------------------------------------------------------
	virtual function string convert2string();
		string data_as_string;

		data_as_string = $sformatf(
			"\n\n\t\t\t\t------> [%0t..%0s]  data: %0s, offset: %0d, prev_item_delay: %0d, response: %0s <-----\n\n\n\n",
			get_begin_time(),
			is_active() ? "" : $sformatf("%0t", get_end_time()), 
			data2string(), 
			offset, 
			prev_item_delay, 
			response.name()
		);

		return $sformatf("%0s\n--------------------------------------------------------------------------------------------------------------------------------------------------------------------------",
			data_as_string);
	endfunction : convert2string


	//------------------------------------------------------------------------------
	// Function: data2string
	//------------------------------------------------------------------------------
	// Purpose:
	//   Converts the payload data array into a formatted hex string. 
	//   Example Output: "{'hAA, 'hBB, 'hCC}"
	//------------------------------------------------------------------------------
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
	
endclass : algn_data_item

`endif
