/////////////////////////////////////////////////////////////////////////////// 
// File:        messages.f
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-10-12 
// Description: 
// ▪ UVM VERBOSITY CONTROL:
//   The following `+uvm_set_verbosity` plusargs are typically used in simulation
//   (e.g., in your Questa or VCS command line) to control logging output levels.
//

//			→ Mutes all messages under the test top hierarchy.
			+uvm_set_verbosity=uvm_test_top*,_ALL_,UVM_NONE,time,0


//   		→ Shows RX FIFO activity at medium verbosity.
//			+uvm_set_verbosity=*,RX_FIFO,UVM_MEDIUM,time,0


//         	→ Shows TX FIFO activity at medium verbosity.
//			+uvm_set_verbosity=*,TX_FIFO,UVM_MEDIUM,time,0


//         	→ Displays high-verbosity messages for dropped packet counters.
			+uvm_set_verbosity=*,CNT_DROP,UVM_HIGH,time,0


//         	→ Enables detailed logs for register prediction and checking.
			+uvm_set_verbosity=*,REG_PREDICT,UVM_HIGH,time,0


//         	→ Displays low-level monitor messages when an item ends.
//			+uvm_set_verbosity=uvm_test_top.my_algn_env.*_agent.my_monitor,ITEM_END,UVM_LOW,time,0


//         	→ Displays low-level monitor messages when an item starts.
//			+uvm_set_verbosity=uvm_test_top.my_algn_env.*_agent.my_monitor,ITEM_START,UVM_LOW,time,0



// These controls allow selective debugging without modifying code.
///////////////////////////////////////////////////////////////////////////////

