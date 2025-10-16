///////////////////////////////////////////////////////////////////////////////
// File:        test_reg_access.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: 
// -----------------------------------------------------------------------------
// Detailed Description:
// ----------------------
// This test verifies **register-level access functionality** of the DUT via 
// the APB interface. It ensures that read/write operations on mapped and 
// unmapped registers behave as expected, even when a reset occurs mid-test.
//
// Test Flow Summary:
// ------------------
// 1. **Environment Setup**
//    - The test extends `test_base`, which builds and configures the `algn_env` 
//      environment containing the APB agent and virtual sequencer.
//
// 2. **Configuration Phase**
//    - The APB driver’s `recording_detail` is set to `UVM_FULL` for detailed
//      transaction logging in the waveform/database.
//
// 3. **Execution Phase**
//    - Two virtual sequences are launched in **parallel**:
//         a. `algn_virtual_sequence_reg_access_random`: Performs randomized 
//            read/write access to valid (mapped) registers.
//         b. `algn_virtual_sequence_reg_access_unmapped`: Performs access to 
//            invalid/unmapped addresses to ensure correct DUT error handling.
//
// 4. **Reset Injection**
//    - During or between sequence execution, the DUT reset can be asserted to 
//      validate register re-initialization and robustness of the interface.
//
// 5. **Re-run Sequences**
//    - After reset, the same sequences can be replayed to confirm system recovery.
//
// 6. **Completion**
//    - Once all transactions are completed and stable, the test drops its 
//      objection and concludes successfully.
//
// Key Objectives:
// ---------------
// - Validate correct register read/write access over APB.
// - Ensure reset behavior does not cause unexpected corruption.
// - Verify unmapped address handling (error reporting / ignored access).
// - Demonstrate concurrent APB activity through multiple sequences.
// -----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef TEST_REG_ACCESS
`define TEST_REG_ACCESS

//------------------------------------------------------------------------------
// UVM Test: test_reg_access
//------------------------------------------------------------------------------
// - Extends `test_base`, which includes the environment and common setup.
// - Executes multiple APB sequences concurrently to stress DUT register access.
// - Can include mid-test reset to validate DUT robustness.
//------------------------------------------------------------------------------
class test_reg_access extends test_base;

    //-------------------------------------------------------------------------
    // Variables
    //-------------------------------------------------------------------------
    uvm_status_e    status;                 // UVM register access status
    uvm_reg_data_t  data;                   // UVM register data container

    protected int unsigned num_reg_accesses;        // Number of valid register accesses
    protected int unsigned num_unmapped_accesses;   // Number of invalid/unmapped accesses
      
    //-------------------------------------------------------------------------
    // UVM Factory Registration
    //-------------------------------------------------------------------------
    `uvm_component_utils(test_reg_access)
    
    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    // Initializes the test and sets default access counts.
    function new(string name = "test_reg_access", uvm_component parent = null);
        super.new(name, parent);
        num_reg_accesses      = 1000;  // Default number of valid accesses
        num_unmapped_accesses = 1000;  // Default number of invalid accesses
    endfunction : new

    //-------------------------------------------------------------------------
    // build_phase
    //-------------------------------------------------------------------------
    // - Called during UVM build phase.
    // - Configures the APB driver for full recording.
    // - Displays configuration summary for traceability.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Enable full transaction recording for debug and coverage analysis
        uvm_config_db#(int)::set(
            this, 
            "uvm_test_top.my_algn_env.my_apb_agent.my_apb_driver", 
            "recording_detail", 
            UVM_FULL
        );
        
        display_configurations();
    endfunction : build_phase

    //-------------------------------------------------------------------------
    // run_phase
    //-------------------------------------------------------------------------
    // - Main runtime of the test.
    // - Runs parallel register access sequences (mapped + unmapped).
    // - Optionally injects reset to test DUT recovery behavior.
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting test_reg_access sequences");

        // Initial delay before starting stimulus
        #(100ns);
      
        // Launch both sequences in parallel using fork-join
        fork
            //------------------------------------------------------------------
            // Thread #1: Randomized Register Access (Valid Addresses)
            //------------------------------------------------------------------
            begin
                algn_virtual_sequence_reg_access_random seq;
                seq = algn_virtual_sequence_reg_access_random::type_id::create("seq");

                // Constrain number of accesses
                void'(seq.randomize() with {
                    num_accesses == num_reg_accesses;
                });

                // Start on the environment’s virtual sequencer
                seq.start(my_algn_env.my_algn_virtual_sequencer);
            end

            //------------------------------------------------------------------
            // Thread #2: Unmapped Register Access (Invalid Addresses)
            //------------------------------------------------------------------
            begin
                algn_virtual_sequence_reg_access_unmapped seq;
                seq = algn_virtual_sequence_reg_access_unmapped::type_id::create("seq");

                // Constrain number of accesses
                void'(seq.randomize() with {
                    num_accesses == num_unmapped_accesses;
                });

                // Start on the environment’s virtual sequencer
                seq.start(my_algn_env.my_algn_virtual_sequencer);
            end
        join

        // Optional delay to allow stabilization or reset events
        #(100ns);
      
        phase.drop_objection(this, "All register access sequences completed"); 
    endtask : run_phase

endclass : test_reg_access

`endif
