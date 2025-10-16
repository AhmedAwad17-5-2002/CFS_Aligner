///////////////////////////////////////////////////////////////////////////////
// File:        md_random_test.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: Comprehensive randomized test for the Alignment Controller DUT.
//
// ----------------------------------------------------------------------------
// OVERVIEW
// ----------------------------------------------------------------------------
// This UVM test verifies the DUT’s (Alignment Controller) register-level and 
// data-path behavior under randomized APB transactions and mid-traffic reset 
// conditions. It extends `test_base`, which provides access to the UVM 
// environment (`my_algn_env`) that encapsulates master/slave agents and 
// configuration objects.
//
// The DUT is expected to:
//   - Correctly handle randomized APB read/write transactions
//   - Maintain protocol compliance under back-to-back traffic
//   - Recover cleanly from asynchronous reset injections during active sequences
//   - Correctly align MD packets from RX FIFO and push aligned data into TX FIFO
//
// ----------------------------------------------------------------------------
// TEST FLOW
// ----------------------------------------------------------------------------
// 1. **Initialization**
//      - Build phase configures full transaction recording for all APB agents.
//      - Environment hierarchy (agents, drivers, monitors) is fully built.
//
// 2. **Slave Background Activity**
//      - `md_slave_response_forever_sequence` starts in the background, 
//        continuously providing responses to incoming master requests.
//
// 3. **Main Traffic Generation**
//      - Multiple randomized virtual sequences are run:
//          a. `algn_virtual_sequence_reg_config`
//          b. `algn_virtual_sequence_rx`
//          c. `algn_virtual_sequence_reg_status`
//      - These sequences represent register programming, RX packet stimulation,
//        and post-reset status verification.
//
// 4. **Reset Injection**
//      - During traffic, resets may be asserted/deasserted by the virtual 
//        sequences or DUT interface control.
//      - DUT behavior is monitored to ensure it resumes correct operation.
//
// 5. **Completion**
//      - After all randomized transactions finish, the test drops its objection,
//        prints the UVM topology, and ends cleanly.
//
// ----------------------------------------------------------------------------
// KEY FEATURES
// ----------------------------------------------------------------------------
//  - Randomized register-level APB operations (valid + invalid).
//  - Continuous slave responses.
//  - Reset during ongoing traffic.
//  - DUT resilience and recovery verification.
//  - Dynamic creation of all sequences via UVM factory.
// ----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_RANDOM_TEST
`define MD_RANDOM_TEST

//------------------------------------------------------------------------------
// UVM Test: md_random_test
//------------------------------------------------------------------------------
// - Extends test_base (which instantiates `my_algn_env`).
// - Launches randomized APB sequences and performs mid-test resets.
// - Verifies correct DUT recovery and data-path consistency post-reset.
//------------------------------------------------------------------------------
class md_random_test extends test_base;

    //--------------------------------------------------------------------------
    // Sequence handles
    //--------------------------------------------------------------------------
    md_master_simple_sequence   my_md_master_simple_sequence;    // Random APB writes
    md_master_bad_transaction   my_md_master_bad_transaction;    // Invalid APB ops
    md_master_good_transaction  my_md_master_good_transaction;   // Valid APB ops

    uvm_status_e status;           // Status from register API calls
    uvm_reg_data_t data;           // Temporary storage for read/write data

    // Number of MD RX transactions to be sent per iteration
    protected int unsigned num_md_rx_transactions;

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    // Registers this test class with the UVM factory, enabling
    // instantiation via `type_id::create()`
    `uvm_component_utils(md_random_test)
    
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    // Arguments:
    //   - name   : Instance name of the test
    //   - parent : Parent component in the UVM hierarchy
    //
    // Initializes the number of MD RX transactions per test run.
    function new(string name = "md_random_test", uvm_component parent=null);
        super.new(name, parent);
        num_md_rx_transactions = 500;
    endfunction : new


    //--------------------------------------------------------------------------
    // build_phase
    //--------------------------------------------------------------------------
    // - Configures full transaction recording for driver and monitor
    //   components inside both master and slave APB agents.
    // - Uses `uvm_config_db` to propagate configuration to lower components.
    // - Calls `display_configurations()` to print active settings.
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Enable full UVM transaction recording for all relevant components
        uvm_config_db#(int)::set(this,
            "uvm_test_top.my_algn_env.my_md_master_agent.my_driver",
            "recording_detail", UVM_FULL);
        uvm_config_db#(int)::set(this,
            "uvm_test_top.my_algn_env.my_md_master_agent.my_monitor",
            "recording_detail", UVM_FULL);
        uvm_config_db#(int)::set(this,
            "uvm_test_top.my_algn_env.my_md_slave_agent.my_driver",
            "recording_detail", UVM_FULL);
        uvm_config_db#(int)::set(this,
            "uvm_test_top.my_algn_env.my_md_slave_agent.my_monitor",
            "recording_detail", UVM_FULL);

        // Display configuration summary for debug visibility
        display_configurations();                                    
    endfunction : build_phase


    //--------------------------------------------------------------------------
    // run_phase
    //--------------------------------------------------------------------------
    // Main test sequence execution:
    //   1. Waits for DUT stabilization.
    //   2. Starts background slave response sequence.
    //   3. Executes randomized register and RX sequences in multiple iterations.
    //   4. Allows time for DUT to process and stabilize post-reset.
    //   5. Completes by dropping the test objection.
    virtual task run_phase(uvm_phase phase);
      
        phase.raise_objection(this, "TEST_RUNNING");
       
        #(100ns);  // Initial delay for DUT stabilization
       
        //--------------------------------------------------------------------------
        // Start slave response forever sequence (runs in background)
        //--------------------------------------------------------------------------
        fork
            begin
                md_slave_response_forever_sequence seq = 
                    md_slave_response_forever_sequence::type_id::create("seq");
                seq.start(my_algn_env.my_md_slave_agent.my_sequencer);
            end
        join_none
      
        //--------------------------------------------------------------------------
        // Main randomized loop
        //--------------------------------------------------------------------------
        repeat (10) begin

            // If model is empty, configure DUT registers
            if (my_algn_env.my_algn_model.is_empty()) begin
                algn_virtual_sequence_reg_config seq = 
                    algn_virtual_sequence_reg_config::type_id::create("seq");
                void'(seq.randomize());
                seq.start(my_algn_env.my_algn_virtual_sequencer);
            end

            // Run multiple RX traffic sequences
            repeat (num_md_rx_transactions) begin
                algn_virtual_sequence_rx seq = 
                    algn_virtual_sequence_rx::type_id::create("seq");
                seq.set_sequencer(my_algn_env.my_algn_virtual_sequencer);
                void'(seq.randomize());
                seq.start(my_algn_env.my_algn_virtual_sequencer);
            end

            // Allow DUT time to process traffic and potential reset recovery
            begin
                algn_vif vif = my_algn_env.my_algn_env_config.get_vif();
                repeat (100) @(posedge vif.clk);
            end 

            // Read back and verify status registers post-traffic
            begin
                algn_virtual_sequence_reg_status seq = 
                    algn_virtual_sequence_reg_status::type_id::create("seq");
                void'(seq.randomize());
                seq.start(my_algn_env.my_algn_virtual_sequencer);
            end
        end
      
        #(500ns); // Final wait before test ends
      
        phase.drop_objection(this, "TEST_RUNNING");

        // Print final UVM topology for debug
        uvm_top.print_topology(); 
    endtask : run_phase

endclass : md_random_test

`endif
