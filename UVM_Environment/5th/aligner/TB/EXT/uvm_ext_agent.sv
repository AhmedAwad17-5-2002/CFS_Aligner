`ifndef UVM_EXT_AGENT
`define UVM_EXT_AGENT
// import apb_pkg::*; 
// import md_pkg::*;  

//------------------------------------------------------------------------------
// UVM Agent: uvm_ext_agent
//------------------------------------------------------------------------------
// - Extends uvm_agent
// - Implements apb_reset_handler_if for propagating reset handling
// - Builds and connects driver, sequencer, monitor, and coverage
//------------------------------------------------------------------------------
class uvm_ext_agent#(   type VIRTUAL_INTF=int,
                        type ITEM_MON=uvm_sequence_item,
                        type ITEM_DRV=uvm_sequence_item/*,
                        string CONFIG_NAME = "A7A",
                        type CONFIG_TYPE = uvm_object*/) 
    extends uvm_agent implements uvm_ext_reset_handler_if;

    /*-------------------------------------------------------------------------------
    -- Interface, port, fields
    -------------------------------------------------------------------------------*/
    

    // Configuration object for APB agent
    uvm_ext_agent_config#(.VIRTUAL_INTF(VIRTUAL_INTF)) my_agent_config;

    // UVM agent components
    uvm_ext_sequencer #(.ITEM_DRV(ITEM_DRV))                          my_sequencer;
    uvm_ext_driver #(.ITEM_DRV(ITEM_DRV),.VIRTUAL_INTF(VIRTUAL_INTF)) my_driver;
    uvm_ext_monitor#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON)) my_monitor;
    uvm_ext_coverage#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON))my_coverage;

    /*-------------------------------------------------------------------------------
    -- UVM Factory registration
    -------------------------------------------------------------------------------*/
    `uvm_component_param_utils(uvm_ext_agent#(  .VIRTUAL_INTF(VIRTUAL_INTF), 
                                                .ITEM_MON(ITEM_MON), 
                                                .ITEM_DRV(ITEM_DRV)
                                )            )
	
    /*-------------------------------------------------------------------------------
    -- Functions
    -------------------------------------------------------------------------------*/
    
    // Constructor
    function new(string name = "uvm_ext_agent", uvm_component parent=null);
        super.new(name, parent);

        
    endfunction : new
 
    //--------------------------------------------------------------------------
    // Build Phase
    // - Creates config, monitor, and optionally driver/sequencer/coverage
    //   depending on agent configuration (active/passive, coverage on/off).
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(uvm_ext_agent_config#(.VIRTUAL_INTF(VIRTUAL_INTF)))::get(this, "","my_agent_config", my_agent_config))begin
            `uvm_fatal("DB_FATAL",$sformatf("Couldn't filed %0s configuration in db",get_name()))
        end
        else begin
            `uvm_info("CONFIG","configration object is got successfully", UVM_FULL)
        end

        my_monitor          = uvm_ext_monitor#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON))
                                ::type_id::create("my_monitor", this);

        // Create driver + sequencer only if active
        if (my_agent_config.get_is_active() == UVM_ACTIVE) begin
            my_sequencer = uvm_ext_sequencer#(.ITEM_DRV(ITEM_DRV))
                            ::type_id::create("my_sequencer", this);

            my_driver    = uvm_ext_driver #(.ITEM_DRV(ITEM_DRV),.VIRTUAL_INTF(VIRTUAL_INTF))
                            ::type_id::create("my_driver", this);
        end

        // Create coverage collector if enabled
        if (my_agent_config.get_has_coverage() == 1) begin
            my_coverage = uvm_ext_coverage#(.VIRTUAL_INTF(VIRTUAL_INTF),.ITEM_MON(ITEM_MON))
                            ::type_id::create("my_coverage", this);
        end
    endfunction : build_phase
        
    //--------------------------------------------------------------------------
    // Connect Phase
    // - Hook up connections between components and config
    //--------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Get virtual interface from config_db
        if (my_agent_config.my_vif==null) begin
            `uvm_fatal("NO_VIF", 
                $sformatf("Could not get from config_db the virtual interface using name"))
        end
        else begin
            // my_agent_config.set_vif(my_vif);
            $display("set %0s VIF", get_name());
        end

        


        // Pass config to monitor
        my_monitor.my_agent_config = my_agent_config;

        // Connect driver to sequencer if active
        if (my_agent_config.get_is_active() == UVM_ACTIVE) begin
            my_driver.seq_item_port.connect(my_sequencer.seq_item_export);
            my_driver.my_agent_config = my_agent_config;
        end

        // Connect monitor to coverage if coverage enabled
        if (my_agent_config.get_has_coverage() == 1) begin
            my_monitor.monitor_aport.connect(my_coverage.my_analysis_imp_mon_item);
            my_coverage.my_agent_config = my_agent_config;
        end
    endfunction : connect_phase

    //--------------------------------------------------------------------------
    // Reset Handling
    //--------------------------------------------------------------------------

    // This function propagates a reset event to all child components
    // that implement the `apb_reset_handler_if` interface.
    /*
    ✅ Casting to Interface Class (like your case)
    SystemVerilog also has interface class (basically “pure abstract interfaces,” similar to Java/C++).
    If a class implements that interface, you can $cast it
    */
    virtual function void handle_reset(uvm_phase phase);

        // Dynamic array to hold all direct child components of this component
        uvm_component children[$];

        // UVM built-in function: fills `children` with all child components
        get_children(children);

        // Iterate through all children
        foreach (children[idx]) begin

            // Declare a handle of type `apb_reset_handler_if` (interface class)
            // Initially null, will point to the child if the cast succeeds
            uvm_ext_reset_handler_if reset_handler;

            // Try to cast the current child (children[idx]) to the interface
            // `$cast` returns 1 (true) if the child implements `apb_reset_handler_if`
            if ($cast(reset_handler, children[idx])) begin

                // If cast succeeded: call the reset handler of that child
                // The child now "looks like" a reset_handler interface object
                reset_handler.handle_reset(phase);
            end
    end

    // Debug print: shows the list of all children found
    // $display("children %p", children);

endfunction


    // Wait until reset starts
    protected virtual task wait_reset_start();
        my_agent_config.wait_reset_start();
    endtask
         
    // Wait until reset ends
    protected virtual task wait_reset_end();
        my_agent_config.wait_reset_end();
    endtask

    //--------------------------------------------------------------------------
    // Run Phase
    // - Forever wait for reset start → propagate reset → wait for reset end
    //--------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        forever begin
            wait_reset_start();
            handle_reset(phase);
            wait_reset_end();
        end
    endtask

endclass : uvm_ext_agent

`endif
