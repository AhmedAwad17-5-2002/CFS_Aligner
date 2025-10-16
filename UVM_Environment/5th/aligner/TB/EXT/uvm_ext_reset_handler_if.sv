`ifndef UVM_EXT_RESET_HANDLER_IF
  `define UVM_EXT_RESET_HANDLER_IF

  interface class uvm_ext_reset_handler_if;
    
    //Function to handle the reset
    pure virtual function void handle_reset(uvm_phase phase);
    
  endclass

`endif