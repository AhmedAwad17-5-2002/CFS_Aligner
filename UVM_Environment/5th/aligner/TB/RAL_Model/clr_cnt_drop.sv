///////////////////////////////////////////////////////////////////////////////
// File:        clr_cnt_drop.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM register callback class that clears the CNT_DROP register
//              field after a write of '1'.  
//              When software writes a 1 to the CNT_DROP bit, the callback
//              automatically predicts the hardware behavior by resetting
//              the field back to 0, reflecting a self-clearing register bit.
///////////////////////////////////////////////////////////////////////////////

`ifndef CLR_CNT_DROP
`define CLR_CNT_DROP

//------------------------------------------------------------------------------
// UVM Register Callback: clr_cnt_drop
//------------------------------------------------------------------------------
// - Extends uvm_reg_cbs to hook into the UVM Register Layer prediction flow.
// - Monitors writes to the CNT_DROP field and forces the predicted value to 0
//   whenever a write of '1' occurs, emulating hardware clear-on-write behavior.
//------------------------------------------------------------------------------
class clr_cnt_drop extends uvm_reg_cbs; 

  // Pointer to the CNT_DROP register field that this callback will clear.
  uvm_reg_field cnt_drop;

  bit in_cb;

  // Register this class with the UVM factory for easy creation.
  `uvm_object_utils(clr_cnt_drop)
  
  //--------------------------------------------------------------------------
  // Constructor
  // - Optional 'name' argument gives the callback instance a unique identifier.
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction
  
  //--------------------------------------------------------------------------
  // post_predict
  // - Invoked by the UVM Register Layer after a prediction event (read/write).
  // - If the operation is a WRITE and the new value is 1:
  //     * Predicts the field back to 0 to model the hardware auto-clear.
  //     * Updates the predicted value so mirrors remain consistent.
  //--------------------------------------------------------------------------
  virtual function void post_predict(
    input uvm_reg_field   fld,      // Field being updated
    input uvm_reg_data_t  previous, // Previous mirrored value
    inout uvm_reg_data_t  value,    // New predicted value (modifiable)
    input uvm_predict_e   kind,     // Type of prediction (READ/WRITE)
    input uvm_path_e      path,     // Frontdoor/Backdoor path
    input uvm_reg_map     map       // Map used for the access
  );

  // $display("\n\nkind = %0s, path=%0s, previous=%h, Field=%0s\n\n",kind.name(), path.name(),previous, fld.get_name());

    if (in_cb) begin
      return;
    end
      
    in_cb = 1;

    if ((kind == UVM_PREDICT_WRITE) && (value == 1) && (previous == 0)) begin

        if(cnt_drop != null)begin
          // Force mirror to 0 to emulate self-clearing bit.
          void'(cnt_drop.predict(0));
        end
        else begin
          `uvm_fatal("CALLBACK-FATAL", "cnt_drop not connected to its related field in reg_model")
        end
        
        // Set the return value to 0 as well.
        value = 0;

        `uvm_info("CNT_DROP", $sformatf("Clearing %0s", cnt_drop.get_full_name()), UVM_HIGH)
    end

    in_cb = 0;

  endfunction : post_predict

endclass : clr_cnt_drop

`endif // CLR_CNT_DROP
