///////////////////////////////////////////////////////////////////////////////
// File:        TB.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        06/10/2025
// Description: UVM Testbench Top Module for the Aligner DUT
//              ------------------------------------------------------------
//              This top-level testbench connects all DUT interfaces (APB,
//              MD_RX, MD_TX, and Aligner) and provides clock/reset generation.
//              It also sets the virtual interfaces into the UVM config DB
//              to make them accessible to UVM components (agents, monitors, etc.).
//              Finally, it launches the UVM test using run_test().
///////////////////////////////////////////////////////////////////////////////

`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/test_pkg.sv"
`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Parameters_checker/param_checker.sv"
`include "uvm_macros.svh"
module TB ();
	import uvm_pkg::*;
	import test_pkg::*;

	param_checker #(.ALGN_DATA_WIDTH(`DATA_WIDTH), .FIFO_DEPTH(8)) my_param_checker;

	//--------------------------------------------------------------------------
	// Clock and IRQ Signals
	//--------------------------------------------------------------------------
	bit i_clk;
	bit irq;

	//--------------------------------------------------------------------------
	// Interface Instantiations
	//--------------------------------------------------------------------------

	// APB Interface
	apb_if #(
		.APB_MAX_DATA_WIDTH(`APB_MAX_DATA_WIDTH),
		.APB_MAX_ADDR_WIDTH(`APB_MAX_ADDR_WIDTH)
	) my_apb_if (
		.pclk(i_clk)
	);

	// MD_TX Interface
	md_if #(.DATA_WIDTH(`DATA_WIDTH)) my_md_tx_if (
		.clk(i_clk)
	);

	// MD_RX Interface
	md_if #(.DATA_WIDTH(`DATA_WIDTH)) my_md_rx_if (
		.clk(i_clk)
	);

	// Aligner Interface
	algn_if my_algn_if (
		.clk(i_clk)
	);

	//--------------------------------------------------------------------------
	// Clock Generation (100 MHz => 10 ns period)
	//--------------------------------------------------------------------------
	always #5 i_clk = ~i_clk;

	//--------------------------------------------------------------------------
	// Reset Generation
	//--------------------------------------------------------------------------
	initial begin
		my_apb_if.preset_n = 1;
		#20 my_apb_if.preset_n = 0;
		#20 my_apb_if.preset_n = 1;
	end

	//--------------------------------------------------------------------------
	// DUT Instantiation
	//--------------------------------------------------------------------------
	cfs_aligner #(
		.ALGN_DATA_WIDTH  (`DATA_WIDTH),
		.FIFO_DEPTH       (`FIFO_DEPTH)
		) 
	DUT (
		.clk          (i_clk),
		.reset_n      (my_apb_if.preset_n),

		// APB Interface connections
		.paddr        (my_apb_if.paddr),
		.pwrite       (my_apb_if.pwrite),
		.psel         (my_apb_if.psel),
		.penable      (my_apb_if.penable),
		.pwdata       (my_apb_if.pwdata),
		.pready       (my_apb_if.pready),
		.prdata       (my_apb_if.prdata),
		.pslverr      (my_apb_if.pslverr),

		// MD RX Interface
		.md_rx_valid  (my_md_rx_if.valid),
		.md_rx_data   (my_md_rx_if.data),
		.md_rx_offset (my_md_rx_if.offset),
		.md_rx_size   (my_md_rx_if.size),
		.md_rx_ready  (my_md_rx_if.ready),
		.md_rx_err    (my_md_rx_if.err),

		// MD TX Interface
		.md_tx_valid  (my_md_tx_if.valid),
		.md_tx_data   (my_md_tx_if.data),
		.md_tx_offset (my_md_tx_if.offset),
		.md_tx_size   (my_md_tx_if.size),
		.md_tx_ready  (my_md_tx_if.ready),
		.md_tx_err    (my_md_tx_if.err),

		// Interrupt
		.irq          (irq)
	);


	//--------------------------------------------------------------------------
	// Interface Signal Connections (Reset + Handshake)
	//--------------------------------------------------------------------------
	assign my_md_rx_if.reset_n  = my_apb_if.preset_n;
	assign my_md_tx_if.reset_n  = my_apb_if.preset_n;
	assign my_algn_if.reset_n   = my_apb_if.preset_n;
	assign my_algn_if.irq       = irq;

	// FIFO handshake tracking from DUT internals
	assign my_algn_if.rx_fifo_push = DUT.core.rx_fifo.push_valid & DUT.core.rx_fifo.push_ready;
	assign my_algn_if.rx_fifo_pop  = DUT.core.rx_fifo.pop_valid  & DUT.core.rx_fifo.pop_ready;
	assign my_algn_if.tx_fifo_push = DUT.core.tx_fifo.push_valid & DUT.core.tx_fifo.push_ready;
	assign my_algn_if.tx_fifo_pop  = DUT.core.tx_fifo.pop_valid  & DUT.core.tx_fifo.pop_ready;

	//--------------------------------------------------------------------------
	// UVM Configuration and Test Execution
	//--------------------------------------------------------------------------
	initial begin
		my_param_checker = new ("my_param_checker", null);
		// my_param_checker.dut_ptr = DUT;
		my_param_checker.chk_dut("aligner_sv");
		// Enable waveform dump
		$dumpfile("dump.vcd");
		$dumpvars;

		// Set virtual interfaces in the UVM config DB
		uvm_config_db#(virtual apb_if #(
			.APB_MAX_DATA_WIDTH(`APB_MAX_DATA_WIDTH),
			.APB_MAX_ADDR_WIDTH(`APB_MAX_ADDR_WIDTH)
		))::set(null, "*", "apb_vif", my_apb_if);

		uvm_config_db#(virtual md_if #(.DATA_WIDTH(`DATA_WIDTH)))
			::set(null, "*", "md_rx_vif", my_md_rx_if);

		uvm_config_db#(virtual md_if #(.DATA_WIDTH(`DATA_WIDTH)))
			::set(null, "*", "md_tx_vif", my_md_tx_if);

		uvm_config_db#(virtual algn_if)
			::set(null, "*", "algn_vif", my_algn_if);

		// Start the UVM test
		run_test("");

		$finish;
	end

	//--------------------------------------------------------------------------
	// Optional: Dump the current UVM config DB contents for debugging
	//--------------------------------------------------------------------------
	initial begin
		`uvm_info("CFG_DUMP", "Dumping uvm_config_db...", UVM_LOW)
		uvm_config_db#(uvm_object)::dump();
	end

endmodule : TB
