`include "uvm_macros.svh"
import uvm_pkg::*;  // <<--- THIS IS REQUIRED

class param_checker #(int unsigned ALGN_DATA_WIDTH = 0, int unsigned FIFO_DEPTH = 0)
  extends uvm_component;

  `uvm_component_param_utils(param_checker#(.ALGN_DATA_WIDTH(ALGN_DATA_WIDTH),
                                            .FIFO_DEPTH(FIFO_DEPTH)))

  // Constructor
  function new(string name = "param_checker", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void chk_dut(string module_name = "");
    if (module_name == "aligner_sv") begin
      chk_aligner_sv();
    end
  endfunction

  function void chk_aligner_sv();
    int unsigned value_data_width;
    int unsigned value_fifo_depth;

    void'(uvm_hdl_read("TB.DUT.ALGN_DATA_WIDTH", value_data_width));
    void'(uvm_hdl_read("TB.DUT.FIFO_DEPTH", value_fifo_depth));
    if (ALGN_DATA_WIDTH != value_data_width || FIFO_DEPTH != value_fifo_depth)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d/%0d, Got %0d/%0d",
                  ALGN_DATA_WIDTH, FIFO_DEPTH, value_data_width, value_fifo_depth))
  	else 
  		$display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");




    void'(uvm_hdl_read("TB.DUT.core.ALGN_DATA_WIDTH", value_data_width));
    void'(uvm_hdl_read("TB.DUT.core.FIFO_DEPTH", value_fifo_depth));
    if (ALGN_DATA_WIDTH != value_data_width || FIFO_DEPTH != value_fifo_depth)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d/%0d, Got %0d/%0d",
                  ALGN_DATA_WIDTH, FIFO_DEPTH, value_data_width, value_fifo_depth))
    else 
      $display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");



    void'(uvm_hdl_read("TB.DUT.core.rx_ctrl.ALGN_DATA_WIDTH", value_data_width));
    if (ALGN_DATA_WIDTH != value_data_width)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d, Got %0d",
                  ALGN_DATA_WIDTH, value_data_width))
    else 
      $display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");




    void'(uvm_hdl_read("TB.DUT.core.tx_ctrl.ALGN_DATA_WIDTH", value_data_width));
   if (ALGN_DATA_WIDTH != value_data_width)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d, Got %0d",
                  ALGN_DATA_WIDTH, value_data_width))
    else 
      $display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");



    void'(uvm_hdl_read("TB.DUT.core.rx_fifo.FIFO_DEPTH", value_fifo_depth));
    if (FIFO_DEPTH != value_fifo_depth)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d, Got %0d",
                   FIFO_DEPTH, value_fifo_depth))
    else 
      $display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");


    void'(uvm_hdl_read("TB.DUT.core.tx_fifo.FIFO_DEPTH", value_fifo_depth));
    if (FIFO_DEPTH != value_fifo_depth)
      `uvm_fatal("PARAM_MISMATCH", $sformatf("Parameter mismatch: Expected %0d, Got %0d",
                   FIFO_DEPTH, value_fifo_depth))
    else 
      $display("TMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM");
  endfunction

endclass : param_checker
