/////////////////////////////////////////////////////////////////////////////// 
// File:        md_pkg.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: MD (Message/Data) package for the UVM-based verification 
//              environment of the Aligner DUT. 
// 
//              This package acts as a central container that collects all 
//              MD-related definitions, including interfaces, types, 
//              configuration classes, sequence items, drivers, sequencers, 
//              sequences, agents, and coverage. 
// 
//              By centralizing all these components, this package ensures: 
//                - Simplified compilation order 
//                - Better modularity and reusability 
//                - Easy integration of RX (Master) and TX (Slave) MD flows 
// 
//              The package essentially provides a "single point of entry" 
//              for all MD verification elements in the UVM testbench. 
/////////////////////////////////////////////////////////////////////////////// 

`ifndef MD_PKG
`define MD_PKG

//------------------------------------------------------------------------------
// UVM + Interface includes
//------------------------------------------------------------------------------

// MD interface definition (connects DUT and TB components)
`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/Interfaces/md_if.sv" 
`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/PKGs/uvm_ext_pkg.sv"

package md_pkg;

	//------------------------------------------------------------------------------
	// UVM Base Imports
	//------------------------------------------------------------------------------
	`include "uvm_macros.svh"   // Required UVM macros (factory registration, utils, etc.)
	import uvm_pkg::*;          // Import UVM base classes (uvm_component, uvm_env, etc.)
	import uvm_ext_pkg::*;

	//------------------------------------------------------------------------------
	// MD Type and Configuration Definitions
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_types.sv"               // MD typedefs and enums
	// `include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_reset_handler_if.sv"    // Reset handling interface
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_agent_config.sv"        // Base MD agent configuration

	// RX/TX Agent configurations
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_agent_config.sv" // Master agent config
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_agent_config.sv"  // Slave agent config

	//------------------------------------------------------------------------------
	// Sequence Items (Transactions)
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_base_item.sv"            // Base transaction class
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_drv_item.sv"             // Generic driver item
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_mon_item.sv"             // Monitor item
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_drv_master_item.sv"   // Master-specific transaction
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_drv_slave_item.sv"    // Slave-specific transaction

	//------------------------------------------------------------------------------
	// Drivers & Monitors
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_driver.sv"               // Base driver
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_monitor.sv"              // Monitor
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_driver.sv"     // Master driver
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_driver.sv"      // Slave driver

	//------------------------------------------------------------------------------
	// Sequencers
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_base_sequencer.sv"             // Base sequencer
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_base_sequencer.sv"  // Master base sequencer
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_sequencer.sv"       // Master sequencer
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_base_sequencer.sv"   // Slave base sequencer
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_sequencer.sv"        // Slave sequencer

	//------------------------------------------------------------------------------
	// Sequences
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_base_sequence.sv"              // Base sequence
	// RX (Master) sequences
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_base_sequence.sv"
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_simple_sequence.sv"  // Example master sequence
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_good_transaction.sv" // Valid master transaction
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_bad_transaction.sv"  // Invalid master transaction

	// TX (Slave) sequences
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_base_sequence.sv"
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_simple_sequence.sv"
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_response_sequence.sv"           // One-time response
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_response_forever_sequence.sv"   // Continuous response

	//------------------------------------------------------------------------------
	// Coverage
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_coverage.sv"

	//------------------------------------------------------------------------------
	// Agents
	//------------------------------------------------------------------------------
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/md_agent.sv"              // Generic MD agent
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/TX/md_slave_agent.sv"     // Slave agent
	`include "E:/K.O/Self-learning/CFS_Aligner/UVM_Environment/5th/aligner/TB/MD/RX/md_master_agent.sv"    // Master agent

endpackage : md_pkg

`endif
