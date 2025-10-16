/////////////////////////////////////////////////////////////////////////////// 
// File:        algn_test_random_rx_err.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-12
// Description: UVM Test — Random RX Error Injection Test for the Alignment Controller
//
// -----------------------------------------------------------------------------
// OVERVIEW
// -----------------------------------------------------------------------------
// This test extends the base random test `md_random_test` and focuses on 
// verifying the DUT’s behavior when RX-side (receive path) errors occur 
// during MD packet reception.
//
// The DUT (Alignment Controller) is responsible for aligning MD packets 
// received from the RX FIFO and forwarding the aligned data to the TX FIFO. 
// This specific test injects random RX errors into the incoming MD packets 
// to check whether the DUT handles them correctly — for example, detecting, 
// discarding, or properly flagging corrupted packets.
//
// -----------------------------------------------------------------------------
// TEST FLOW
// -----------------------------------------------------------------------------
// 1. The base test (`md_random_test`) creates and configures the verification 
//    environment (agents, monitors, sequences, etc.).
//
// 2. This derived test (`algn_test_random_rx_err`) overrides the default 
//    virtual sequence to a custom sequence (`algn_virtual_sequence_rx_err`), 
//    which generates MD transactions with random RX error conditions.
//
// 3. The number of RX transactions is set to 300 to ensure wide random coverage.
//
// 4. The simulation runs with the injected errors, and coverage + scoreboard 
//    checks ensure the DUT reacts properly to corrupted packets.
//
// -----------------------------------------------------------------------------
// KEY COMPONENTS
// -----------------------------------------------------------------------------
// - Base Test: md_random_test
//   • Provides the default environment and testbench setup.
//
// - Virtual Sequence Override: algn_virtual_sequence_rx_err
//   • Custom sequence that injects RX errors during packet generation.
//
// - Parameter: num_md_rx_transactions = 300
//   • Total number of randomized RX transactions executed in this test.
//
// -----------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_TEST_RANDOM_RX_ERR_SV
`define ALGN_TEST_RANDOM_RX_ERR_SV

//------------------------------------------------------------------------------
// UVM Test Class: algn_test_random_rx_err
//------------------------------------------------------------------------------
// - Extends md_random_test (base class for random MD tests)
// - Focuses on verifying DUT behavior under RX error conditions
//------------------------------------------------------------------------------
class algn_test_random_rx_err extends md_random_test;
    
    // Register the test with the UVM factory
    `uvm_component_utils(algn_test_random_rx_err)
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    // name   : instance name
    // parent : parent component in UVM hierarchy
    //--------------------------------------------------------------------------
    function new(string name = "", uvm_component parent);
      super.new(name, parent);

      // Set the number of RX transactions for this random error test
      num_md_rx_transactions = 600;
      
      // Override the default virtual sequence used in md_random_test
      // with the RX-error-injecting sequence
      algn_virtual_sequence_rx::type_id::set_type_override(algn_virtual_sequence_rx_err::get_type());
    endfunction : new
     
  endclass : algn_test_random_rx_err
 
`endif // ALGN_TEST_RANDOM_RX_ERR_SV
