/////////////////////////////////////////////////////////////////////////////// 
// File:        md_if.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-07
// Description: MD Interface definition with protocol checks.
//              This interface defines the data channel between producer (TX) 
//              and consumer (RX). It encapsulates the signals required to 
//              transmit MD packets (data, offset, size, valid/ready handshake, 
//              and error reporting). 
//              
//              The interface also includes a set of SystemVerilog Assertions 
//              (SVA) to ensure protocol correctness, such as stable data until 
//              ready is high, valid staying asserted until handshake, and 
//              proper bounds checking on offset+size.
// 
//              Modports are provided for TX and RX sides, each exposing the 
//              relevant signals as input or output. 
/////////////////////////////////////////////////////////////////////////////// 

`ifndef DATA_WIDTH
  `define DATA_WIDTH 32
`endif

`ifndef MD_IF
  `define MD_IF

//------------------------------------------------------------------------------
// Interface: md_if
//------------------------------------------------------------------------------
// Parameters:
//   - DATA_WIDTH : Data bus width in bits (default = 32). Must be >= 8 and a power of 2.
//------------------------------------------------------------------------------
interface md_if #(
  parameter DATA_WIDTH = `DATA_WIDTH
) (
  input clk   // APB clock input
  // input reset_n
);

  //--------------------------------------------------------------------------
  // Derived parameters
  //--------------------------------------------------------------------------
  localparam int unsigned OFFSET_WIDTH = DATA_WIDTH <= 8 ? 1 : $clog2(DATA_WIDTH/8);
  localparam int unsigned SIZE_WIDTH   = $clog2(DATA_WIDTH/8)+1;

  //--------------------------------------------------------------------------
  // Interface signals
  //--------------------------------------------------------------------------
  logic                          reset_n;   // Active-low reset
  bit                            valid;     // Valid request from producer
  bit        [DATA_WIDTH-1 : 0]  data;      // Data payload
  bit        [OFFSET_WIDTH-1:0]  offset;    // Starting byte offset
  bit        [SIZE_WIDTH-1:0]    size;      // Number of valid bytes
  bit                            ready;     // Ready response from consumer
  bit                            err;       // Error indicator

  //--------------------------------------------------------------------------
  // Modports
  //--------------------------------------------------------------------------
  // TX (producer) drives valid/data/offset/size, receives ready/err
  // modport tx_mp (
  //   input  clk, reset_n, ready, err, 
  //   output valid, data, offset, size
  // );

  // // RX (consumer) receives valid/data/offset/size, drives ready/err
  // modport rx_mp (
  //   input  clk, reset_n, valid, data, offset, size, 
  //   output ready, err
  // );

  //--------------------------------------------------------------------------
  // Assertions enable/disable switch
  //--------------------------------------------------------------------------
  bit has_checks;
  initial has_checks = 1;

  //--------------------------------------------------------------------------
  // Protocol Checks (Assertions)
  //--------------------------------------------------------------------------

  // Rule #1: DATA_WIDTH must be a power of 2.
  initial begin
    assert ($countones(DATA_WIDTH) == 1)
      else $fatal(0, "DATA_WIDTH (%0d) must be a power of 2", DATA_WIDTH);
  end

  // Rule #2: DATA_WIDTH minimum legal value is 8. 
  initial begin
    assert (DATA_WIDTH >= 8)
      else $fatal(0, "DATA_WIDTH (%0d) minimum legal value is 8", DATA_WIDTH);
  end

  //--------------------------------------------------------------------------
  // Rule #3: VALID must remain high until READY goes high
  //--------------------------------------------------------------------------
  property valid_high_until_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      (valid && !ready) |-> valid until_with !ready;
  endproperty
  VALID_HIGH_UNTIL_READY_A : assert property(valid_high_until_ready_p)
    else $error("valid signal did not stay high until ready became high");

  // Rule #4: data must not be X/Z while valid is high.
  property unknown_value_data_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> !$isunknown(data);
  endproperty
  UNKNOWN_VALUE_DATA_A : assert property(unknown_value_data_p)
    else $error("Detected unknown value for MD signal data");

  // Rule #5: data must remain stable until ready is high.
  property stable_data_until_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      (valid & $past(valid) & !$past(ready)) |-> $stable(data);
  endproperty
  STABLE_DATA_UNTIL_READY_A : assert property(stable_data_until_ready_p)
    else $error("data signal did not remain stable until the end of the transfer");

  // Rule #6: offset must not be X/Z while valid is high.
  property unknown_value_offset_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> !$isunknown(offset);
  endproperty
  UNKNOWN_VALUE_OFFSET_A : assert property(unknown_value_offset_p)
    else $error("Detected unknown value for MD signal offset");

  // Rule #7: offset must remain stable until ready is high.
  property stable_offset_until_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      (valid & $past(valid) & !$past(ready)) |-> $stable(offset);
  endproperty
  STABLE_OFFSET_UNTIL_READY_A : assert property(stable_offset_until_ready_p)
    else $error("offset signal did not remain stable until the end of the transfer");

  // Rule #8: size must not be X/Z while valid is high.
  property unknown_value_size_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> !$isunknown(size);
  endproperty
  UNKNOWN_VALUE_SIZE_A : assert property(unknown_value_size_p)
    else $error("Detected unknown value for MD signal size");

  // Rule #9: size must remain stable until ready is high.
  property stable_size_until_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      (valid & $past(valid) & !$past(ready)) |-> $stable(size);
  endproperty
  STABLE_SIZE_UNTIL_READY_A : assert property(stable_size_until_ready_p)
    else $error("size signal did not remain stable until the end of the transfer");

  // Rule #10: size must never be zero when valid is high.
  property size_eq_0_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> size != 0;
  endproperty
  SIZE_EQ_0_A : assert property(size_eq_0_p)
    else $error("Detected value 0 for MD signal size");

  // Rule #11: err must not be X/Z when valid & ready are both high.
  property unknown_value_err_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      (valid & ready) |-> !$isunknown(err);
  endproperty
  UNKNOWN_VALUE_ERR_A : assert property(unknown_value_err_p)
    else $error("Detected unknown value for MD signal err");

  // Rule #12: err can only be high when valid & ready are high.
  property err_high_at_valid_and_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      err |-> (valid & ready);
  endproperty
  ERR_HIGH_AT_VALID_AND_READY_A : assert property(err_high_at_valid_and_ready_p)
    else $error("Detected err signal high when ready & valid != 1");

  // Rule #13: valid must never be X/Z.
  property unknown_value_valid_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      !$isunknown(valid);
  endproperty
  UNKNOWN_VALUE_VALID_A : assert property(unknown_value_valid_p)
    else $error("Detected unknown value for MD signal valid");

  // Rule #14: ready must not be X/Z while valid is high.
  property unknown_value_ready_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> !$isunknown(ready);
  endproperty
  UNKNOWN_VALUE_READY_A : assert property(unknown_value_ready_p)
    else $error("Detected unknown value for MD signal ready");

  // Rule #15: (offset + size) must not exceed total data width (in bytes).
  property size_plus_offset_gt_data_width_p;
    @(posedge clk) disable iff(!reset_n || !has_checks)
      valid |-> (size + offset <= (DATA_WIDTH / 8));
  endproperty
  SIZE_PLUS_OFFSET_GT_DATA_WIDTH_A : assert property(size_plus_offset_gt_data_width_p)
    else $error("Detected that size + offset is greater than the data width, in bytes.");

endinterface : md_if

`endif // MD_IF
