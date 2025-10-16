/////////////////////////////////////////////////////////////////////////////// 
// File:        md_slave_base_sequencer.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: UVM Sequencer for Slave Driver Items. 
//              - This sequencer is parameterized by DATA_WIDTH. 
//              - It generates and coordinates the flow of slave sequence items 
//                (md_drv_slave_item) to the driver. 
//              - It extends md_base_sequencer to specialize for slave-side 
//                transactions. 
//              - Includes a TLM FIFO and analysis implementation to accept 
//                monitored items (md_mon_item) and buffer them until consumed 
//                by sequences. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_SLAVE_BASE_SEQUENCER
`define MD_SLAVE_BASE_SEQUENCER

//------------------------------------------------------------------------------
// UVM Sequencer: md_slave_base_sequencer
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default = 32).
// - Manages slave driver items (md_drv_slave_item).
// - Receives monitored items via an analysis port (from monitor).
// - Buffers incoming monitored items into a pending FIFO for consumption.
//------------------------------------------------------------------------------
class md_slave_base_sequencer#(int unsigned DATA_WIDTH=`DATA_WIDTH) 
	extends md_base_sequencer#(.ITEM_DRV(md_drv_slave_item)) implements uvm_ext_reset_handler_if;
	
	/*-------------------------------------------------------------------------------
	-- Interface, ports, fields
	-------------------------------------------------------------------------------*/
	// FIFO to store monitored items before sequences consume them.
	// Depth = 1 (backpressure is handled by error if FIFO is full).
	uvm_tlm_fifo #(md_mon_item) pending_items;

	// Analysis implementation port to receive md_mon_item from the monitor.
	uvm_analysis_imp #(md_mon_item, md_slave_base_sequencer) port_from_monitor; 
		
	/*-------------------------------------------------------------------------------
	-- UVM Factory registration
	-------------------------------------------------------------------------------*/
	// Registers md_slave_base_sequencer with UVM factory for dynamic creation.
	`uvm_component_param_utils(md_slave_base_sequencer#(DATA_WIDTH))
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
	
	// Constructor
	// - Initializes FIFO and analysis port.
	function new(string name = "md_slave_base_sequencer", uvm_component parent=null);
		super.new(name, parent);
		pending_items    = new("pending_items", this, 1);  // depth = 1
		port_from_monitor = new("port_from_monitor", this);
	endfunction : new

	// write()
	// - Called when monitor publishes a new md_mon_item.
	// - If the item is active, try to put it into the FIFO.
	// - Errors if FIFO is full or item cannot be pushed.
	virtual function void write(md_mon_item item);
      	if (item.is_active()) begin
        	if (pending_items.is_full()) begin
        	  	`uvm_fatal("ALGORITHM_ISSUE", 
                    	$sformatf("FIFO %0s is full (size: %0d). Possible cause: no sequence consuming items.",
                    	pending_items.get_full_name(), pending_items.size()))
        	end

        	if (pending_items.try_put(item) == 0) begin
          		`uvm_fatal("ALGORITHM_ISSUE", 
                    	$sformatf("Failed to push new item into FIFO %0s", 
                    	pending_items.get_full_name()))
        	end
      	end
    endfunction : write
    
    // handle_reset()
    // - Handles reset during simulation.
    // - Flushes pending FIFO to clear unconsumed items.
    virtual function void handle_reset(uvm_phase phase);
      	super.handle_reset(phase);
      	pending_items.flush();
    endfunction : handle_reset

endclass : md_slave_base_sequencer

`endif
