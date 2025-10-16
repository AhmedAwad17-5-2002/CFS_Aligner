`ifndef UVM_EXT_COVERAGE
`define UVM_EXT_COVERAGE

//------------------------------------------------------------------------------
// Declare analysis imp type for receiving monitor transactions
//------------------------------------------------------------------------------
`uvm_analysis_imp_decl(_mon_item)


//------------------------------------------------------------------------------
// Base class for bit-level coverage wrappers
//------------------------------------------------------------------------------
virtual class uvm_ext_cover_index_wrapper_base extends uvm_component;
    
    // Constructor
    function new(string name = "", uvm_component parent);
      super.new(name, parent);
    endfunction

    // Abstract method: return coverage report as string
    pure virtual function string coverage2string();   
endclass


//------------------------------------------------------------------------------
// Parametric wrapper for simple bit-level covergroup
//------------------------------------------------------------------------------
// - Builds a covergroup with bins [0:MAX_VALUE_PLUS_1-1]
// - Used for per-bit coverage of address/data buses
//------------------------------------------------------------------------------
class uvm_ext_cover_index_wrapper #(int unsigned MAX_VALUE_PLUS_1 = 32)
  extends uvm_ext_cover_index_wrapper_base;
    
    // Covergroup: tracks which bit positions (indices) toggle
    covergroup cover_index with function sample(int unsigned value);
        option.per_instance = 1;

        index : coverpoint value {
            option.comment = "Index of toggling bit";
            bins values [MAX_VALUE_PLUS_1] = {[0:MAX_VALUE_PLUS_1-1]};
        }
    endgroup : cover_index
    
    // Register with UVM factory
    `uvm_component_param_utils(uvm_ext_cover_index_wrapper#(MAX_VALUE_PLUS_1))
    
    // Constructor
    function new(string name = "cover_index_wrapper", uvm_component parent=null);
        super.new(name, parent);
        cover_index = new();
        cover_index.set_inst_name($sformatf("%0s_%0s", get_full_name(), "cover_index"));
    endfunction : new

    // String representation of coverage (debug/demo only)
    virtual function string coverage2string();
      return {
        $sformatf("\n     cover_index:         %03.2f%%", cover_index.get_inst_coverage()),
        $sformatf("\n       index:             %03.2f%%", cover_index.index.get_inst_coverage())
      };
    endfunction
    
endclass : uvm_ext_cover_index_wrapper


//------------------------------------------------------------------------------
// Coverage Component: uvm_ext_coverage
//------------------------------------------------------------------------------
// - Subscribes to monitor transactions via analysis imp
// - Samples transaction-level, reset, and bit-level coverage
//------------------------------------------------------------------------------
class uvm_ext_coverage #(type VIRTUAL_INTF = int, type ITEM_MON = uvm_sequence_item) 
    extends uvm_component implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, ports, and fields
    -------------------------------------------------------------------------------*/
    // Analysis imp port: connects to monitor to receive transactions
    uvm_analysis_imp_mon_item #(ITEM_MON,uvm_ext_coverage#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON)))
                                my_analysis_imp_mon_item;

    // Agent config handle (provides VIF for reset sampling)
    uvm_ext_agent_config#(.VIRTUAL_INTF(VIRTUAL_INTF)) my_agent_config;


        
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_param_utils(uvm_ext_coverage#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON)))

    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    // Constructor
    function new(string name = "uvm_ext_coverage", uvm_component parent=null);
        super.new(name, parent);


        // Create analysis imp (subscribe to monitor)
        my_analysis_imp_mon_item = new("my_analysis_imp_mon_item", this);
    endfunction : new


    // Analysis imp callback: receive monitor item and sample coverage
    virtual function void write_mon_item(ITEM_MON recieved_mon_item);

    endfunction : write_mon_item

    // Reset handler hook (manual call from outside if needed)
    virtual function void handle_reset(uvm_phase phase);

    endfunction

    // Wait until reset deassertion
    protected virtual task wait_reset_end();

    endtask

    // Wait until reset assertion
    protected virtual task wait_reset_start();

    endtask

    // Return textual coverage summary (debug/demo only)
    virtual function string coverage2string();
        string result;
        // Append child coverage reports (bit-level wrappers)
        uvm_component children[$];
        get_children(children);

        foreach(children[idx]) begin
            uvm_ext_cover_index_wrapper_base wrapper;
            if($cast(wrapper, children[idx])) begin
                result = $sformatf("%s\n\nChild component: %0s%0s",
                            result, wrapper.get_name(), wrapper.coverage2string());
            end
        end

        return result;
    endfunction

    // Report phase: dump coverage (demo only, not for production use)
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", $sformatf("\nCoverage: %0s", coverage2string()), UVM_DEBUG)
    endfunction

endclass : uvm_ext_coverage

`endif
