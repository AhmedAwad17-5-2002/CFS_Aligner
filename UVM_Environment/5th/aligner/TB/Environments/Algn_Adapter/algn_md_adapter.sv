/////////////////////////////////////////////////////////////////////////////// 
// File:        algn_md_adapter.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-10-12 
// Description: UVM Component – Master Data Adapter
// 
// OVERVIEW:
// ---------
// The `algn_md_adapter` serves as a data translation and synchronization bridge 
// between the **MD Monitor** and the **Alignment Environment**. Its role is to 
// convert monitor-level transaction items (of type `md_mon_item`) into 
// environment-level analysis transactions (of type `algn_data_item`), 
// maintaining data integrity and transaction timing.
//
// FUNCTIONAL FLOW:
// ----------------
// 1. **Input Source**: The MD Monitor sends observed transactions through 
//    the analysis implementation port `port_in_md_adapter`.
//
// 2. **Translation**: Each received `md_mon_item` is processed inside the 
//    `mon2env()` function, which constructs a corresponding `algn_data_item`. 
//    The fields (data, offset, length, response, etc.) are copied, and the 
//    transaction state (active/inactive) determines whether a 
//    `begin_tr()` or `end_tr()` is triggered.
//
// 3. **Output Broadcast**: The converted `algn_data_item` is written to the 
//    analysis port `algn_md_adapter_aport`, allowing downstream components 
//    such as scoreboards, models, or coverage collectors to receive it.
//
// 4. **Reset Handling**: The `handle_reset()` method (currently a placeholder) 
//    can be expanded to handle soft or hard resets, ensuring no stale data 
//    is propagated during DUT resets.
//
// COMPONENT PURPOSE:
// ------------------
// - Bridges monitor and environment data domains.
// - Maintains transaction-level visibility across UVM components.
// - Provides a clean, reusable point for transaction transformation or filtering.
// 
///////////////////////////////////////////////////////////////////////////////  

`ifndef ALGN_MD_ADAPTER
`define ALGN_MD_ADAPTER

//------------------------------------------------------------------------------
// UVM Analysis Implementation Declaration
//------------------------------------------------------------------------------
// Declares an analysis implementation port named `_in_md_adapter` used to 
// connect the MD monitor's analysis port to this adapter's `write_in_md_adapter()`
// method.
`uvm_analysis_imp_decl(_in_md_adapter)


//------------------------------------------------------------------------------
// UVM Component: algn_md_adapter
//------------------------------------------------------------------------------
// - Extends `uvm_component`.
// - Acts as a transaction adapter between the MD monitor and environment-level
//   analysis components.
// - Converts `md_mon_item` objects into `algn_data_item` objects.
// - Implements reset handling via `uvm_ext_reset_handler_if`.
//------------------------------------------------------------------------------
class algn_md_adapter extends uvm_component implements uvm_ext_reset_handler_if;
	
	/*-------------------------------------------------------------------------------
	-- Interface, ports, and fields
	-------------------------------------------------------------------------------*/
	
	// Analysis port to broadcast converted algn_data_item transactions
	uvm_analysis_port #(algn_data_item) algn_md_adapter_aport;

	// Analysis implementation port to receive transactions from the MD monitor
	uvm_analysis_imp_in_md_adapter #(md_mon_item, algn_md_adapter) port_in_md_adapter;
		
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers the component with the factory for dynamic instantiation
	`uvm_component_utils(algn_md_adapter)
	
	
	/*-------------------------------------------------------------------------------
	-- Constructor
	-------------------------------------------------------------------------------*/
	// Parameters:
	// - name:    Instance name of the component
	// - parent:  Parent component in the UVM hierarchy
	function new(string name = "algn_md_adapter", uvm_component parent = null);
		super.new(name, parent);

		// Create analysis port and implementation port
		algn_md_adapter_aport = new("algn_md_adapter_aport", this);
		port_in_md_adapter    = new("port_in_md_adapter", this);
	endfunction : new



	/*-------------------------------------------------------------------------------
	-- Function: mon2env
	-------------------------------------------------------------------------------*/
	// Purpose:
	// Converts an incoming md_mon_item (from monitor) into an algn_data_item
	// suitable for environment-level analysis.
	//
	// Parameters:
	// - my_md_mon_item: The monitored MD transaction.
	//
	// Returns:
	// - algn_data_item: The converted and fully populated analysis item.
	//
	virtual function algn_data_item mon2env(md_mon_item my_md_mon_item);

		// Create a new algn_data_item using UVM factory
      	algn_data_item my_algn_data_item = algn_data_item::type_id::create("my_algn_data_item");  

      	// Copy fields from the monitored item
      	my_algn_data_item.data              = my_md_mon_item.data;
      	my_algn_data_item.offset            = my_md_mon_item.offset;     
      	my_algn_data_item.length            = my_md_mon_item.length;
      	my_algn_data_item.response          = my_md_mon_item.response;
      	my_algn_data_item.prev_item_delay   = my_md_mon_item.prev_item_delay;

      	// Indicate transaction phase (active/inactive)
      	if (my_md_mon_item.is_active())
      		void'(my_algn_data_item.begin_tr());
      	else
      		void'(my_algn_data_item.end_tr());

      	// Optional: Track source linkage if required for debugging
      	// my_algn_data_item.sources.push_back(my_md_mon_item);

     	return my_algn_data_item;
    endfunction : mon2env



	/*-------------------------------------------------------------------------------
	-- Function: write_in_md_adapter
	-------------------------------------------------------------------------------*/
	// Purpose:
	// This function is automatically triggered when the MD monitor writes a 
	// transaction to its analysis port. It calls `mon2env()` to translate the 
	// incoming transaction and broadcasts the result to all connected analysis 
	// subscribers via `algn_md_adapter_aport`.
	//
	virtual function void write_in_md_adapter(md_mon_item my_item_mon);
    	algn_data_item my_algn_data_item = mon2env(my_item_mon);
    	algn_md_adapter_aport.write(my_algn_data_item);
  	endfunction : write_in_md_adapter



	/*-------------------------------------------------------------------------------
	-- Function: handle_reset
	-------------------------------------------------------------------------------*/
	// Purpose:
	// Handles DUT reset events, ensuring proper cleanup or suspension of
	// ongoing data collection. Can be extended to clear queues or flags.
	//
	virtual function void handle_reset(uvm_phase phase);
        // TODO: Add reset synchronization or cleanup behavior as needed
    endfunction : handle_reset
	
endclass : algn_md_adapter

`endif
