///////////////////////////////////////////////////////////////////////////////
// File:        md_coverage.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-07
// Description: MD Coverage component (UVM).
//
// This class implements functional coverage for the MD protocol. It integrates:
//   - Transaction-level coverage (offset, response, length, size, delay, crosses)
//   - Reset coverage (valid access during reset)
//   - Bit-level coverage for address and data buses (per-bit activity)
//
// Features:
//   * Covergroups for high-level protocol behavior:
//       - Access offset
//       - Response type
//       - Access size (# of bytes)
//       - Access length (2, ≤10, >10)
//       - Delay between consecutive accesses
//       - Cross coverage (offset × size)
//   * Bit-level coverage (per-bit toggling):
//       - Data bus (0 vs 1 activity)
//   * Debug helpers:
//       - `coverage2string()` returns textual summary
//       - Optional `uvm_info` printing (demo use only)
//
// NOTE: In production flows, rely on tool-generated coverage reports instead of
//       printing coverage results from within UVM code.
//
///////////////////////////////////////////////////////////////////////////////

`ifndef MD_COVERAGE
`define MD_COVERAGE


//------------------------------------------------------------------------------
// Coverage Component: md_coverage
//------------------------------------------------------------------------------
// - Subscribes to monitor transactions via analysis imp
// - Samples transaction-level, reset, and bit-level coverage
//------------------------------------------------------------------------------
class md_coverage #(int unsigned DATA_WIDTH = `DATA_WIDTH) 
    extends uvm_ext_coverage #(.VIRTUAL_INTF(md_vif),.ITEM_MON(md_mon_item)) 
    implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, ports, and fields
    -------------------------------------------------------------------------------*/

    // Agent config handle (provides VIF for reset sampling)
    md_agent_config#(.DATA_WIDTH(DATA_WIDTH)) my_agent_config;

    // Bit-level coverage wrappers (0 vs 1 activity)
    uvm_ext_cover_index_wrapper#(DATA_WIDTH) wrap_cover_data_0;
    uvm_ext_cover_index_wrapper#(DATA_WIDTH) wrap_cover_data_1;

        
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_param_utils(md_coverage#(.DATA_WIDTH(DATA_WIDTH)))

    /*-------------------------------------------------------------------------------
    -- Transaction-level Covergroups
    -------------------------------------------------------------------------------*/
    covergroup cover_item with function sample(md_mon_item my_md_mon_item);
        option.per_instance = 1;

        // Offset of access (byte granularity)
        offset : coverpoint my_md_mon_item.offset{
            option.comment = "Offset of the MD access";
            bins values[]  = {[0:(DATA_WIDTH/8)-1]};
        }

        // Response type (OKAY, ERROR, …)
        response : coverpoint my_md_mon_item.response{
            option.comment = "Response of the MD access";
        }

        // Access size (bytes)
        size : coverpoint my_md_mon_item.data.size() {
            option.comment = "Size of the MD access";
            bins values[]  = {[1:(DATA_WIDTH/8)]};
        }

        // Access length (transaction burst length)
        length : coverpoint my_md_mon_item.length {
            bins length_eq_2    = {2};
            bins length_le_10[8]= {[3:10]};
            bins length_gt_10   = {[11:$]};
            illegal_bins length_lt_1 = {0};
        }

        // Delay between two consecutive transactions
        prev_item_delay : coverpoint my_md_mon_item.prev_item_delay {
            bins back2back      = {0};
            bins length_le_5[5] = {[1:5]};
            bins length_gt_6    = {[6:$]};
        }

        // Cross coverage: offset × size
        offset_x_size : cross size, offset{
            ignore_bins ignore_offset_plus_size_gt_data_width = 
                                offset_x_size with (offset + size > (DATA_WIDTH / 8));
        }
       
    endgroup

    // Reset coverage
    covergroup cover_reset with function sample(bit valid);
        option.per_instance = 1;
        access_ongoing : coverpoint valid {
            option.comment = "An MD access was ongoing at reset";
        }
    endgroup

    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    // Constructor
    function new(string name = "md_coverage", uvm_component parent=null);
        super.new(name, parent);

        // Create transaction-level covergroup
        cover_item = new();
        cover_item.set_inst_name($sformatf("%0s_%0s", get_full_name(), "cover_item"));

        // Create reset covergroup
        cover_reset = new();
        cover_reset.set_inst_name($sformatf("%0s_%0s", get_full_name(), "cover_reset"));
    endfunction : new

    // Build phase: create bit-level coverage wrappers
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        wrap_cover_data_0 = uvm_ext_cover_index_wrapper#(DATA_WIDTH)::type_id::create("wrap_cover_data_0", this);
        wrap_cover_data_1 = uvm_ext_cover_index_wrapper#(DATA_WIDTH)::type_id::create("wrap_cover_data_1", this);
    endfunction : build_phase


    // end_of_elaboration_phase
    // - Verifies correct agent config type
    // - Ensures pointer is valid before simulation run
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // super.my_agent_config = my_agent_config;
        if(super.my_agent_config == null) begin
          `uvm_fatal("ALGORITHM_ISSUE", 
              $sformatf("Agent config pointer from %0s is null", get_full_name()))
        end
      
        if($cast(my_agent_config, super.my_agent_config) === 0) begin
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Failed cast: %0s to %0s", 
                    super.my_agent_config.get_full_name(), 
                    md_agent_config#(.DATA_WIDTH(DATA_WIDTH))::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase

    // Analysis imp callback: receive monitor item and sample coverage
    virtual function void write_mon_item(md_mon_item recieved_mon_item);
        md_vif vif = my_agent_config.get_vif();

        // Sample transaction-level coverage
        cover_item.sample(recieved_mon_item);

        // Sample bit-level coverage (per bit in data bus)
        foreach(recieved_mon_item.data[byte_idx]) begin
            for (int bit_index = 0; bit_index < 8; bit_index++) begin
                if (recieved_mon_item.data[byte_idx][bit_index]) begin
                    wrap_cover_data_1.cover_index.sample((recieved_mon_item.offset*8) + byte_idx + bit_index);
                end
                else begin
                    wrap_cover_data_0.cover_index.sample((recieved_mon_item.offset*8) + byte_idx + bit_index);
                end
            end
        end

        // Debug print (demo only)
        // `uvm_info("DEBUG", $sformatf("\nCoverage: %0s", coverage2string()), UVM_MEDIUM)
    endfunction : write_mon_item

    // Run phase: sample reset coverage continuously
    virtual task run_phase(uvm_phase phase);
        md_vif vif = my_agent_config.get_vif();
        forever begin           
            if(vif.reset_n===0) begin
                wait_reset_end();
                cover_reset.sample(vif.valid);
            end 
            else begin
                @(posedge vif.clk);
                cover_reset.sample(vif.valid);
            end
        end
    endtask

    // Reset handler hook (manual call from outside if needed)
    virtual function void handle_reset(uvm_phase phase);
        md_vif vif = my_agent_config.get_vif();
        cover_reset.sample(vif.valid);
    endfunction

    // Wait until reset deassertion
    protected virtual task wait_reset_end();
        my_agent_config.wait_reset_end();
    endtask

    // Wait until reset assertion
    protected virtual task wait_reset_start();
        my_agent_config.wait_reset_start();
    endtask

    // Return textual coverage summary (debug/demo only)
    virtual function string coverage2string();

        string result =  {
            // Overall coverage for the cover_item group
            $sformatf("\n     cover_item:              %03.2f%%", cover_item.get_inst_coverage()),

            // Coverage for individual coverpoints
            $sformatf("\n       offset:                 %03.2f%%", cover_item.offset.get_inst_coverage()),
            $sformatf("\n       response:               %03.2f%%", cover_item.response.get_inst_coverage()),
            $sformatf("\n       length:                 %03.2f%%", cover_item.length.get_inst_coverage()),
            $sformatf("\n       size:                   %03.2f%%", cover_item.size.get_inst_coverage()),

            // Cross coverage
            $sformatf("\n       offset_x_size:          %03.2f%%", cover_item.offset_x_size.get_inst_coverage()),

            // Item delay
            $sformatf("\n       prev_item_delay:        %03.2f%%", cover_item.prev_item_delay.get_inst_coverage()),

            $sformatf("\n"),

            // Reset coverage
            $sformatf("\n     cover_reset:             %03.2f%%", cover_reset.get_inst_coverage()),
            $sformatf("\n       access_ongoing:         %03.2f%%", cover_reset.access_ongoing.get_inst_coverage())
        };

        
        return $sformatf("%0s %0s",result,super.coverage2string());
    endfunction


endclass : md_coverage

`endif
