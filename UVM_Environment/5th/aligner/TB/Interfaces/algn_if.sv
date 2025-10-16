///////////////////////////////////////////////////////////////////////////////
// File:        algn_if.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: Alignment Controller Interface
//
// ----------------------------------------------------------------------------
// Overview and Flow Description:
// ----------------------------------------------------------------------------
// The `algn_if` interface serves as the communication bridge between the
// Alignment Controller DUT and the UVM testbench environment. It encapsulates
// all control and handshake signals necessary to monitor and drive the DUT.
//
// The flow works as follows:
//  1. The DUT operates on the provided system clock (`clk`) and responds to
//     the active-low reset (`reset_n`) to initialize its internal logic.
//  2. RX FIFO and TX FIFO handshake signals (`push`/`pop`) coordinate data
//     transfer operations between the DUT and external FIFO logic or models.
//     - `rx_fifo_push`: Asserted when a new RX packet is available.
//     - `rx_fifo_pop` : Asserted when the DUT reads from the RX FIFO.
//     - `tx_fifo_push`: Asserted when the DUT writes aligned data into TX FIFO.
//     - `tx_fifo_pop` : Asserted when TX FIFO data is read or transmitted.
//  3. The DUT asserts `irq` (interrupt request) to notify the testbench or CPU
//     that an operation (e.g., alignment completion or FIFO condition) has
//     occurred.
//  4. The optional signal `max_drop` can be used to indicate overflow,
//     packet drop, or threshold events for diagnostic or debug purposes.
//
// The UVM testbench accesses this interface via a *virtual interface*
// reference, allowing components such as drivers, monitors, and scoreboards
// to sample and control the DUT signals during simulation.
// ----------------------------------------------------------------------------
//
// Notes:
// - This interface is synthesizable and simulation-friendly.
// - The `clk` signal is passed as a port to ensure tight synchronization
//   with the testbench and DUT timing domains.
// - Additional control/status signals may be added as the DUT evolves.
//
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_IF
`define ALGN_IF

//------------------------------------------------------------------------------
// Interface: algn_if
//------------------------------------------------------------------------------
// Provides a set of DUT I/O signals for APB-independent control and handshake
// operations between the Alignment Controller and the verification environment.
//------------------------------------------------------------------------------
interface algn_if(input clk);

  //--------------------------------------------------------------------------
  // Reset signal
  //--------------------------------------------------------------------------
  logic reset_n;           // Active-low asynchronous reset signal for DUT

  //--------------------------------------------------------------------------
  // Interrupt signal
  //--------------------------------------------------------------------------
  logic irq;               // DUT interrupt output to signal alignment completion or events

  //--------------------------------------------------------------------------
  // RX FIFO control signals
  //--------------------------------------------------------------------------
  logic rx_fifo_push;      // Indicates new RX data available for DUT to read
  logic rx_fifo_pop;       // Indicates DUT has consumed RX data

  //--------------------------------------------------------------------------
  // TX FIFO control signals
  //--------------------------------------------------------------------------
  logic tx_fifo_push;      // Indicates DUT has produced aligned data into TX FIFO
  logic tx_fifo_pop;       // Indicates TX FIFO data has been read or sent downstream

endinterface : algn_if

`endif
