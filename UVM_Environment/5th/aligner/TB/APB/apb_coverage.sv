///////////////////////////////////////////////////////////////////////////////
// File:        apb_coverage.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-22
// Description: APB Coverage component (UVM).
// 
// This class implements functional coverage for the APB protocol. It integrates:
//   - Transaction-level coverage (direction, response, length, delay, transitions)
//   - Reset coverage (access ongoing at reset)
//   - Bit-level coverage for address and data buses (per-bit activity)
// 
// Features:
//   * Covergroups for high-level protocol behavior:
//       - Access direction (read/write)
//       - Response type
//       - Access length (2, ≤10, >10)
//       - Delay between consecutive accesses
//       - Reset conditions
//       - Cross/transition coverage
//   * Bit-level coverage (per-bit toggling):
//       - Address bus
//       - Write data bus
//       - Read data bus
//   * Debug helpers:
//       - `coverage2string()` returns textual summary
//       - Optional `uvm_info` debug printing for demo runs
//
// NOTE: In production flows, rely on tool-generated coverage reports instead of
//       printing coverage results from within UVM code.
// 
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_COVERAGE
`define APB_COVERAGE

//------------------------------------------------------------------------------
// Coverage Component: apb_coverage
//------------------------------------------------------------------------------
// - Subscribes to monitor transactions via analysis imp
// - Samples transaction-level, reset, and bit-level coverage
//------------------------------------------------------------------------------
class apb_coverage extends uvm_ext_coverage #(.VIRTUAL_INTF(apb_vif),.ITEM_MON(apb_mon_item))
    implements uvm_ext_reset_handler_if;
    
    /*-------------------------------------------------------------------------------
    -- Interface, ports, and fields
    -------------------------------------------------------------------------------*/
    // Agent config handle (provides VIF for reset sampling)
    apb_agent_config my_agent_config;


    // Bit-level coverage wrappers (separate for 0/1 activity)
    uvm_ext_cover_index_wrapper#(`APB_MAX_ADDR_WIDTH) wrap_cover_addr_0;
    uvm_ext_cover_index_wrapper#(`APB_MAX_ADDR_WIDTH) wrap_cover_addr_1;
    uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH) wrap_cover_wr_data_0;
    uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH) wrap_cover_wr_data_1;
    uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH) wrap_cover_rd_data_0;
    uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH) wrap_cover_rd_data_1;
        
    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_utils(apb_coverage)

    /*-------------------------------------------------------------------------------
    -- Transaction-level Covergroups
    -------------------------------------------------------------------------------*/
    covergroup cover_item with function sample(apb_mon_item my_apb_mon_item);
        option.per_instance = 1;

        // Direction: APB read/write
        direction : coverpoint my_apb_mon_item.pwrite;

        // Response type
        response : coverpoint my_apb_mon_item.response;

        // Access length
        length : coverpoint my_apb_mon_item.length {
            bins length_eq_2    = {2};
            bins length_le_10[8]= {[3:10]};
            bins length_gt_10   = {[11:$]};
        }

        // Delay between two consecutive transactions
        prev_item_delay : coverpoint my_apb_mon_item.prev_item_delay {
            bins back2back      = {0};
            bins length_le_5[5] = {[1:5]};
            bins length_gt_6    = {[6:$]};
        }

        // Cross coverage: direction x response
        response_x_direction : cross response, direction;

        // Transition coverage: read <-> write
        trans_direction : coverpoint my_apb_mon_item.pwrite {
            bins direction_trans[] = (APB_READ, APB_WRITE => APB_READ, APB_WRITE);
        }           
    endgroup

    // Reset coverage
    covergroup cover_reset with function sample(bit psel);
        option.per_instance = 1;
        access_ongoing : coverpoint psel {
            option.comment = "Was an access ongoing during reset?";
        }
    endgroup

    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    // Constructor
    function new(string name = "apb_coverage", uvm_component parent=null);
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

        wrap_cover_addr_0    = uvm_ext_cover_index_wrapper#(`APB_MAX_ADDR_WIDTH)::type_id::create("wrap_cover_addr_0",    this);
        wrap_cover_addr_1    = uvm_ext_cover_index_wrapper#(`APB_MAX_ADDR_WIDTH)::type_id::create("wrap_cover_addr_1",    this);
        wrap_cover_wr_data_0 = uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_wr_data_0", this);
        wrap_cover_wr_data_1 = uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_wr_data_1", this);
        wrap_cover_rd_data_0 = uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_rd_data_0", this);
        wrap_cover_rd_data_1 = uvm_ext_cover_index_wrapper#(`APB_MAX_DATA_WIDTH)::type_id::create("wrap_cover_rd_data_1", this);
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
      
        if($cast(my_agent_config, super.my_agent_config) == 0) begin
            `uvm_fatal("ALGORITHM_ISSUE", 
                $sformatf("Failed cast: %0s to %0s", 
                    super.my_agent_config.get_full_name(), 
                    apb_agent_config::type_id::type_name))
        end
    endfunction : end_of_elaboration_phase

    // Analysis imp callback: receive monitor item
    virtual function void write_mon_item(apb_mon_item recieved_mon_item);
        apb_vif vif = my_agent_config.get_vif();
        // Sample transaction-level coverage
        cover_item.sample(recieved_mon_item);
        cover_reset.sample(vif.psel);

        // Sample address bit activity
        for (int i = 0; i < `APB_MAX_ADDR_WIDTH; i++) begin
            if(recieved_mon_item.paddr[i])
                wrap_cover_addr_1.cover_index.sample(i);        
            else
                wrap_cover_addr_0.cover_index.sample(i);
        end

        // Sample data bit activity
        for (int i = 0; i < `APB_MAX_DATA_WIDTH; i++) begin
            if (recieved_mon_item.pwrite == APB_READ) begin
                if(recieved_mon_item.prdata[i])
                    wrap_cover_rd_data_1.cover_index.sample(i);     
                else
                    wrap_cover_rd_data_0.cover_index.sample(i);
            end else begin
                if(recieved_mon_item.pwdata[i])
                    wrap_cover_wr_data_1.cover_index.sample(i);     
                else
                    wrap_cover_wr_data_0.cover_index.sample(i);
            end
        end

        // Debug print (demo only)
        // `uvm_info("DEBUG", $sformatf("\nCoverage: %0s", coverage2string()), UVM_NONE)
    endfunction : write_mon_item

    // Run phase: sample reset coverage
    virtual task run_phase(uvm_phase phase);
        apb_vif vif = my_agent_config.get_vif();
        forever begin
            if(vif.preset_n==0) begin
                wait_reset_end();
                cover_reset.sample(vif.psel);
            end else begin
                @(posedge vif.pclk);
            end
        end
    endtask

    // Reset handler hook
    virtual function void handle_reset(uvm_phase phase);
        apb_vif vif = my_agent_config.get_vif();
        cover_reset.sample(vif.psel);
    endfunction

    // Wait until reset deassertion
    protected virtual task wait_reset_end();
        my_agent_config.wait_reset_end();
    endtask

    // Return textual coverage summary (debug/demo only)
    // This function creates a human-readable string that shows
    // coverage percentages for all covergroups in this component
    // and any child coverage wrappers.
    virtual function string coverage2string();

        // Local string that accumulates the report
        string result =  {
            // Overall coverage for the cover_item group
            $sformatf("\n     cover_item:              %03.2f%%", cover_item.get_inst_coverage()),

            // Coverage for individual coverpoints inside cover_item
            $sformatf("\n       direction:             %03.2f%%", cover_item.direction.get_inst_coverage()),
            $sformatf("\n       response:              %03.2f%%", cover_item.response.get_inst_coverage()),
            $sformatf("\n       length:                %03.2f%%", cover_item.length.get_inst_coverage()),

            // Coverage for cross coverage (response × direction)
            $sformatf("\n       response_x_direction:  %03.2f%%", cover_item.response_x_direction.get_inst_coverage()),

            // Coverage for item delay bins
            $sformatf("\n       prev_item_delay:       %03.2f%%", cover_item.prev_item_delay.get_inst_coverage()),

            // Spacer (newline)
            $sformatf("\n"),

            // Coverage for reset-related covergroup
            $sformatf("\n     cover_reset:             %03.2f%%", cover_reset.get_inst_coverage()),
            $sformatf("\n       access_ongoing:        %03.2f%%", cover_reset.access_ongoing.get_inst_coverage())
        };


        return $sformatf("%0s %0s",result,super.coverage2string());
    endfunction


endclass : apb_coverage

`endif
