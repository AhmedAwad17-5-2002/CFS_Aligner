///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_reg_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: 
// -----------------------------------------------------------------------------
// Virtual Sequence: Register Configuration Test Sequence
// -----------------------------------------------------------------------------
// This virtual sequence extends `algn_virtual_sequence_base` and is responsible
// for performing random register configuration operations on the DUT’s register
// block (`my_reg_block`) via the model’s register interface.
//
// ----------------------------
// Overall Flow and Behavior:
// ----------------------------
// 1. The sequence first retrieves all registers from the DUT register block.
// 2. It filters out any registers that are *read-only* (i.e., not RW or WO).
// 3. The remaining configurable registers are shuffled randomly to introduce
//    non-deterministic access order across simulation runs.
// 4. Each selected register is randomized (to produce random valid data).
// 5. The randomized value is written into the DUT using the `update()` method.
// 
// ----------------------------
// Verification Purpose:
// ----------------------------
// - To verify that all writable registers can be accessed and programmed
//   correctly through the UVM Register Model (UVM RAL).
// - To ensure register mirroring and field constraints are respected.
// - To introduce controlled randomness that enhances coverage and confidence
//   in the register interface functionality.
// 
// This sequence can be extended or reused in regression environments for 
// register programming sanity tests, configuration verification, or as a 
// base for more complex sequences (e.g., configuration + functional stimulus).
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_REG_CONFIG
`define ALGN_VIRTUAL_SEQUENCE_REG_CONFIG

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_reg_config
//------------------------------------------------------------------------------
// - Extends: algn_virtual_sequence_base
// - Purpose: Randomly writes values to all writable DUT registers.
// - Interacts with: p_sequencer.my_algn_model.my_reg_block
//------------------------------------------------------------------------------
class algn_virtual_sequence_reg_config extends algn_virtual_sequence_base;
  
  // Register this class with the UVM factory for dynamic creation
  `uvm_object_utils(algn_virtual_sequence_reg_config)
  
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction
  
  //--------------------------------------------------------------------------
  // Task: body
  //--------------------------------------------------------------------------
  // Main sequence logic executed when the sequence starts.
  //--------------------------------------------------------------------------
  virtual task body();
    uvm_reg registers[$];     // Dynamic array to hold all DUT registers
    uvm_status_e status;      // Status for register operations
    
    // ------------------------------------------------------------
    // 1. Retrieve all registers from the DUT register block
    // ------------------------------------------------------------
    p_sequencer.my_algn_model.my_reg_block.get_registers(registers);
    
    // ------------------------------------------------------------
    // 2. Remove non-writable registers (only keep RW or WO)
    // ------------------------------------------------------------
    for (int reg_idx = registers.size() - 1; reg_idx >= 0; reg_idx--) begin
      if (!(registers[reg_idx].get_rights() inside {"RW", "WO"})) begin
        registers.delete(reg_idx);
      end
    end
    
    // ------------------------------------------------------------
    // 3. Shuffle register list for random access order
    // ------------------------------------------------------------
    registers.shuffle();
    
    // ------------------------------------------------------------
    // 4. Randomize and update each writable register
    // ------------------------------------------------------------
    foreach (registers[reg_idx]) begin
      void'(registers[reg_idx].randomize());   // Randomize register fields
      registers[reg_idx].update(status);       // Write the randomized value
    end 
  endtask
  
endclass : algn_virtual_sequence_reg_config

`endif
