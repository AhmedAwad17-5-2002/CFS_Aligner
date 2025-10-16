///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_reg_status.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: Virtual Sequence for Register Status Readback
//
// ---------------------------------------------------------------------------
// OVERVIEW:
// This virtual sequence is designed to verify the accessibility and integrity
// of all "Read-Only (RO)" registers within the DUT’s register model.
//
// It operates at the virtual sequencer level, interacting with the model’s
// register block (reg_block) through the UVM Register Abstraction Layer (RAL).
// The goal is to systematically read all RO registers and confirm that their
// values are accessible and stable.
//
// ---------------------------------------------------------------------------
// EXECUTION FLOW:
//
// 1. **Retrieve Register List**
//    - Obtain the full list of registers from the DUT’s register block.
//
// 2. **Filter Registers**
//    - Iterate through the register list and remove all registers that are NOT
//      "Read-Only" (i.e., writable registers). This ensures the sequence focuses
//      exclusively on read-only registers.
//
// 3. **Randomize Access Order**
//    - Shuffle the remaining RO registers to introduce access randomness and
//      detect potential ordering dependencies or bus access issues.
//
// 4. **Read Registers**
//    - Sequentially perform a `read()` operation on each RO register.
//    - Captures both `uvm_status_e` (indicating success/failure) and `data`
//      (the actual read value).
//
// This sequence is intended to be run as part of a register-access verification
// regression or a sanity test for RAL integration.
//
// ---------------------------------------------------------------------------
// DEPENDENCIES:
// - algn_virtual_sequence_base  : Base virtual sequence class
// - p_sequencer.my_algn_model   : Points to the DUT model within the environment
// - my_reg_block                : Contains all DUT registers (UVM RAL object)
//
// ---------------------------------------------------------------------------
// Typical Usage Example:
//
//   algn_virtual_sequence_reg_status seq;
//   seq = algn_virtual_sequence_reg_status::type_id::create("seq");
//   seq.start(env.virtual_sequencer);
//
// ---------------------------------------------------------------------------
// Notes:
// - No stimulus is driven to the DUT directly. Communication happens through
//   the UVM Register Layer.
// - Results can be logged, compared, or extended to include value checking.
// ---------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_REG_STATUS_SV
`define ALGN_VIRTUAL_SEQUENCE_REG_STATUS_SV

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_reg_status
// Purpose: To read all read-only registers from the DUT register model.
//------------------------------------------------------------------------------
class algn_virtual_sequence_reg_status extends algn_virtual_sequence_base;

  //--------------------------------------------------------------------------
  // UVM Factory registration
  // Enables the sequence to be created dynamically using the UVM factory.
  //--------------------------------------------------------------------------
  `uvm_object_utils(algn_virtual_sequence_reg_status)
  
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction
  
  //--------------------------------------------------------------------------
  // Task: body
  // Main execution body of the virtual sequence.
  //--------------------------------------------------------------------------
  virtual task body();
    // Local variables
    uvm_reg registers[$];     // Dynamic array to hold all registers
    uvm_status_e status;      // UVM status (OK / ERROR)
    uvm_reg_data_t data;      // Data read from the register
    
    // Step 1: Get all registers from the model's register block
    p_sequencer.my_algn_model.my_reg_block.get_registers(registers);
    
    // Step 2: Filter out non-RO registers (keep only Read-Only ones)
    for (int reg_idx = registers.size() - 1; reg_idx >= 0; reg_idx--) begin
      if (!(registers[reg_idx].get_rights() inside {"RO"})) begin
        registers.delete(reg_idx);
      end
    end
    
    // Step 3: Shuffle the remaining list of RO registers to randomize order
    registers.shuffle();
    
    // Step 4: Read each RO register and capture status/data
    foreach (registers[reg_idx]) begin
      registers[reg_idx].read(status, data);
      `uvm_info("REG_STATUS_SEQ", 
                $sformatf("Read register: %s, Data: 0x%0h, Status: %s",
                          registers[reg_idx].get_name(), data, status.name()), 
                UVM_MEDIUM)
    end
  endtask

endclass : algn_virtual_sequence_reg_status

`endif
