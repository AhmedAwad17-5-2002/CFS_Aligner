///////////////////////////////////////////////////////////////////////////////
// File:        algn_virtual_sequence_reg_access_random.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        12/10/2025
// Description: 
//   Virtual Sequence for Random Register Access Testing of the Alignment Controller.
//
//   ---------------------------------------------------------------------------
//   OVERVIEW AND FLOW:
//   ---------------------------------------------------------------------------
//   • This sequence extends the base virtual sequence (algn_virtual_sequence_base)
//     and is responsible for generating *random APB register accesses* through
//     the environment’s APB sequencer.
//
//   • The goal is to verify register accessibility and robustness of the 
//     register model by performing random read/write operations across all
//     registers in the DUT register block.
//
//   • The high-level flow of the sequence is as follows:
//
//       1. Retrieve the list of registers from the DUT’s UVM register model.
//       2. Randomize how many register accesses will be performed (between 150–200).
//       3. For each access:
//            - Randomly select a register.
//            - Randomly choose whether to READ or WRITE.
//            - Perform the chosen operation:
//                ▪ READ  → calls .read() and logs the status.
//                ▪ WRITE → randomizes register fields and calls .update().
//            - Wait for a random delay between 0–20 cycles before the next access.
//       4. Repeat until all accesses are completed.
//
//   • This sequence runs at the virtual sequencer level, coordinating register
//     model accesses that indirectly drive transactions through the lower-level
//     APB agent’s sequencer/driver.
//
//   ---------------------------------------------------------------------------
//   DESIGN INTENT:
//   ---------------------------------------------------------------------------
//   - Stress-test the register model with randomized access patterns.
//   - Verify correct read/write handling in both UVM model and DUT response.
//   - Introduce randomized temporal spacing between transactions to simulate
//     realistic traffic timing.
//   - Provide a flexible, reusable virtual sequence for regression campaigns.
//
//   ---------------------------------------------------------------------------
//   NOTE:
//   ---------------------------------------------------------------------------
//   This virtual sequence assumes the environment hierarchy includes:
//       p_sequencer.my_algn_model.my_reg_block
//   and that the model configuration provides a valid virtual interface handle.
//
//   ---------------------------------------------------------------------------
//   Example Usage:
//       algn_virtual_sequence_reg_access_random seq;
//       seq = algn_virtual_sequence_reg_access_random::type_id::create("seq");
//       seq.start(p_sequencer);
//
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_VIRTUAL_SEQUENCE_REG_ACCESS_RANDOM
`define ALGN_VIRTUAL_SEQUENCE_REG_ACCESS_RANDOM

class algn_virtual_sequence_reg_access_random extends algn_virtual_sequence_base;

  // ---------------------------------------------------------------------------
  // Randomized Variables
  // ---------------------------------------------------------------------------

  // Number of register accesses to perform (randomized between 150–200)
  rand int unsigned num_accesses;

  // Constraint: Default number of accesses range
  constraint num_accesses_default {
    soft num_accesses inside {[150:200]};
  }

  // Register this class with the UVM factory
  `uvm_object_utils(algn_virtual_sequence_reg_access_random)

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Task: body
  // ---------------------------------------------------------------------------
  // Main execution task for the sequence.
  // Randomly performs register reads/writes through the register model.
  virtual task body();
    uvm_reg registers[$];      // Dynamic array to store register handles
    uvm_status_e status;       // UVM status returned from register operations
    uvm_reg_data_t data;       // Data value used for reads

    // 1. Get all registers from the DUT’s register model
    p_sequencer.my_algn_model.my_reg_block.get_registers(registers);

    // 2. Loop through randomized number of accesses
    for (int unsigned access_idx = 0; access_idx < num_accesses; access_idx++) begin
      // Randomly select a register index
      int unsigned reg_idx = $urandom_range(registers.size() - 1, 0);

      // Randomly determine whether to READ or WRITE
      uvm_access_e access = get_random_access(registers[reg_idx], access_idx);

      // 3. Perform the operation based on the selected access type
      case (access)

        UVM_READ: begin
          // Perform a read operation on the selected register
          registers[reg_idx].read(status, data);
        end

        UVM_WRITE: begin
          // Randomize the register contents before writing
          void'(registers[reg_idx].randomize());

          // Update the register (writes randomized data to DUT)
          registers[reg_idx].update(status);
        end

        default: begin
          // Fatal error for unsupported access type (should not occur)
          `uvm_fatal("ALGORITHM_ISSUE",
                     $sformatf("Unsupported value for access: %0s", access.name()))
        end

      endcase

      // 4. Wait a random time before next transaction
      wait_random_time();
    end

  endtask : body

  // ---------------------------------------------------------------------------
  // Function: get_random_access
  // ---------------------------------------------------------------------------
  // Randomly chooses between UVM_READ or UVM_WRITE for each register access.
  protected virtual function uvm_access_e get_random_access(uvm_reg register, int unsigned access_idx);
    uvm_access_e result;

    void'(std::randomize(result) with {
      result inside {UVM_READ, UVM_WRITE};
    });

    return result;
  endfunction : get_random_access

  // ---------------------------------------------------------------------------
  // Task: wait_random_time
  // ---------------------------------------------------------------------------
  // Waits for a random delay (0–20 clock cycles) before issuing the next access.
  protected virtual task wait_random_time();
    algn_vif vif = p_sequencer.my_algn_model.my_model_config.get_vif();
    int unsigned delay = $urandom_range(20, 0);

    repeat (delay) begin
      @(posedge vif.clk);
    end
  endtask : wait_random_time

endclass : algn_virtual_sequence_reg_access_random

`endif
