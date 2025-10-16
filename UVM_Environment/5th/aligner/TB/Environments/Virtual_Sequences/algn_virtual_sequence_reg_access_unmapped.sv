///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_reg_access_unmapped.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
//
// Description:
// -----------------------------------------------------------------------------
// This file defines the virtual sequence `algn_virtual_sequence_reg_access_unmapped`,
// which extends the base virtual sequence `algn_virtual_sequence_base`. 
//
// The purpose of this sequence is to perform randomized APB register accesses 
// **to unmapped addresses**, i.e., addresses that do not belong to the known 
// register map of the DUT. This helps verify how the DUT and APB interface handle 
// invalid or unexpected register access attempts.
//
// -----------------------------
// Verification Flow Summary:
// -----------------------------
// 1. **Initialization**
//    - The sequence starts by collecting all *valid* register addresses from the 
//      DUT register model via `get_reg_addresses()`.
//
// 2. **Random Access Loop**
//    - A random number of accesses (`num_accesses`) between 150 and 200 is selected.
//    - For each iteration, a new `apb_simple_sequence` is created and started on 
//      the `apb_sequencer`.
//    - The `paddr` used by the APB sequence is *constrained to be outside* the set 
//      of valid register addresses (using `!(my_apb_drv_item.paddr inside {addresses})`).
//      This ensures the DUT is hit with unmapped address transactions only.
//
// 3. **Timing Randomization**
//    - Between consecutive accesses, a random delay is inserted via `wait_random_time()`.
//      This delay adds timing jitter to simulate realistic traffic and improve coverage.
//
// 4. **Outcome**
//    - The DUT’s response to unmapped or invalid APB addresses can then be checked 
//      by monitors or the scoreboard to verify proper error signaling or graceful handling.
//
// -----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_REG_ACCESS_UNMAPPED
`define ALGN_VIRTUAL_SEQUENCE_REG_ACCESS_UNMAPPED

//------------------------------------------------------------------------------
// Class: algn_virtual_sequence_reg_access_unmapped
//------------------------------------------------------------------------------
// - Extends the base virtual sequence for APB-based register access testing.
// - Focuses specifically on accesses to *unmapped* addresses.
//------------------------------------------------------------------------------
class algn_virtual_sequence_reg_access_unmapped extends algn_virtual_sequence_base;

  //--------------------------------------------------------------------------
  // Randomized field: number of accesses
  //--------------------------------------------------------------------------
  rand int unsigned num_accesses;

  // Default constraint: randomize between 150 and 200 APB accesses
  constraint num_accesses_default {
    soft num_accesses inside {[150:200]};
  }

  // Register this sequence with the UVM factory
  `uvm_object_utils(algn_virtual_sequence_reg_access_unmapped)

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // Main Sequence Body
  //--------------------------------------------------------------------------
  virtual task body();
    uvm_reg_addr_t addresses[$];  // Dynamic array to store all valid register addresses

    // Step 1: Collect all valid register addresses from the model
    get_reg_addresses(addresses);

    // Step 2: Perform a series of unmapped register accesses
    for (int unsigned access_idx = 0; access_idx < num_accesses; access_idx++) begin
      apb_simple_sequence seq;

      // Create and start an APB sequence on the APB sequencer
      // The paddr constraint ensures we avoid valid register addresses
      `uvm_do_on_with(seq, p_sequencer.apb_sequencer, {
        !(my_apb_drv_item.paddr inside {addresses});
      });

      // Step 3: Wait a random number of cycles before the next access
      wait_random_time();
    end
  endtask : body

  //--------------------------------------------------------------------------
  // Function: get_reg_addresses
  //--------------------------------------------------------------------------
  // - Retrieves all register addresses from the DUT's register model
  // - Populates an array of valid register byte addresses
  //--------------------------------------------------------------------------
  protected virtual function void get_reg_addresses(ref uvm_reg_addr_t addresses[$]);
    uvm_reg registers[$];

    // Get the list of registers from the model's register block
    p_sequencer.my_algn_model.my_reg_block.get_registers(registers);

    // Collect every byte address for each register
    foreach (registers[reg_idx]) begin
      for (int byte_idx = 0; byte_idx < registers[reg_idx].get_n_bits() / 8; byte_idx++) begin
        addresses.push_back(registers[reg_idx].get_address() + byte_idx);
      end
    end
  endfunction : get_reg_addresses

  //--------------------------------------------------------------------------
  // Task: wait_random_time
  //--------------------------------------------------------------------------
  // - Waits for a random number (0–20) of clock cycles before next access
  // - Introduces random timing jitter between APB transactions
  //--------------------------------------------------------------------------
  protected virtual task wait_random_time();
    algn_vif vif = p_sequencer.my_algn_model.my_model_config.get_vif();
    int unsigned delay = $urandom_range(20, 0);

    repeat (delay) @(posedge vif.clk);
  endtask : wait_random_time

endclass : algn_virtual_sequence_reg_access_unmapped

`endif
