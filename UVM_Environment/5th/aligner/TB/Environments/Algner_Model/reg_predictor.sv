/////////////////////////////////////////////////////////////////////////////// 
// File:        reg_predictor.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-21 
// Description: UVM Register Predictor for the Alignment Controller DUT.
//              - Extends uvm_reg_predictor to predict register model state
//                based on observed APB bus transactions.
//              - Checks legality of register accesses according to DUT
//                specification and model_config constraints.
//              - Reports errors when invalid transactions occur (e.g., writes
//                to RO registers, reads from WO registers, or illegal CTRL
//                register values).
//              - Acts as the bridge between observed bus-level transactions
//                and the UVM Register Abstraction Layer (RAL).
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_PREDICTOR
`define REG_PREDICTOR

//------------------------------------------------------------------------------
// Class: reg_predictor
//------------------------------------------------------------------------------
// Parameterized register predictor for APB transactions.
// - BUSTYPE    : Transaction type (default = uvm_sequence_item).
// - DATA_WIDTH : Bus data width (default = `DATA_WIDTH).
//------------------------------------------------------------------------------
class reg_predictor #(
    type BUSTYPE = uvm_sequence_item, 
    int unsigned DATA_WIDTH = `DATA_WIDTH
) extends uvm_reg_predictor#(.BUSTYPE(BUSTYPE));

    // Register with UVM factory (parameterized version)
    `uvm_component_param_utils(reg_predictor#(.BUSTYPE(BUSTYPE), .DATA_WIDTH(DATA_WIDTH)))

    // Register configuration object (passed via config_db)
    model_config #(.DATA_WIDTH(DATA_WIDTH)) my_model_config;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "", uvm_component parent);
        super.new(name, parent);
    endfunction

    //--------------------------------------------------------------------------
    // Build phase
    // - Retrieves model_config object from UVM config_db
    // - Fatal error if not found
    //--------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(model_config #(.DATA_WIDTH(DATA_WIDTH)))::get(this, "","my_model_config", my_model_config)) begin
            `uvm_fatal("DB_FATAL", $sformatf("Couldn't find %0s configuration in db", get_name()))
        end
    endfunction

    //--------------------------------------------------------------------------
    // Utility function: Extracts a field value from a full register value
    //--------------------------------------------------------------------------
    protected virtual function uvm_reg_data_t get_reg_field_value(uvm_reg_field reg_field, uvm_reg_data_t reg_data);
        uvm_reg_data_t mask = (('h1 << reg_field.get_n_bits()) - 1) << reg_field.get_lsb_pos();
        return (mask & reg_data) >> reg_field.get_lsb_pos();
    endfunction

    //--------------------------------------------------------------------------
    // Function: get_exp_response
    // - Determines expected DUT response for a given bus operation
    // - Enforces protocol-level and register-specific checks:
    //   * Invalid address → error
    //   * RO register write → error
    //   * WO register read → error
    //   * Illegal CTRL.SIZE or CTRL.OFFSET combination → error
    //--------------------------------------------------------------------------
    protected virtual function reg_access_status_info get_exp_response(uvm_reg_bus_op operation);
        uvm_reg register;
        register = map.get_reg_by_offset(operation.addr, (operation.kind == UVM_READ));

        // 1. Address with no register mapping → APB error
        if(register == null) begin
            return reg_access_status_info::new_instance(UVM_NOT_OK, 
                "Access to a location on which no register is mapped");
        end

        // 2. Write to RO register → APB error
        if(operation.kind == UVM_WRITE) begin
            uvm_reg_map_info info = map.get_reg_map_info(register);
            if(info.rights == "RO") begin
                return reg_access_status_info::new_instance(UVM_NOT_OK, 
                    "Write access to a full read-only register");
            end
        end

        // 3. Read from WO register → APB error
        if(operation.kind == UVM_READ) begin
            uvm_reg_map_info info = map.get_reg_map_info(register);
            if(info.rights == "WO") begin
                return reg_access_status_info::new_instance(UVM_NOT_OK, 
                    "Read access from a full write-only register");
            end
        end

        // 4. Special handling for illegal CTRL register writes
        if(operation.kind == UVM_WRITE) begin
            reg_ctrl ctrl;
            if($cast(ctrl, register)) begin
                uvm_reg_data_t size_value   = get_reg_field_value(ctrl.SIZE,   operation.data);
                uvm_reg_data_t offset_value = get_reg_field_value(ctrl.OFFSET, operation.data);

                // Writing 0 to CTRL.SIZE → error
                if(size_value == 0) begin
                    return reg_access_status_info::new_instance(UVM_NOT_OK, 
                        "Write value 0 to CTRL.SIZE");
                end

                // Illegal (SIZE, OFFSET) alignment → error
                if(((my_model_config.get_algn_data_width() / 8) + offset_value) % size_value != 0) begin
                    return reg_access_status_info::new_instance(UVM_NOT_OK, 
                        $sformatf("Illegal access to CTRL - OFFSET: %0d, SIZE: %0d, aligner data width: %0d",
                                  offset_value, size_value, my_model_config.get_algn_data_width()));
                end

                // SIZE + OFFSET > data width → error
                if(offset_value + size_value > (my_model_config.get_algn_data_width() / 8)) begin
                    return reg_access_status_info::new_instance(UVM_NOT_OK, 
                        $sformatf("Illegal access to CTRL -> OFFSET (%0d) + SIZE (%0d) > aligner data width: %0d",
                                  offset_value, size_value, my_model_config.get_algn_data_width()));
                end
            end
        end

        // Default: Access is legal
        return reg_access_status_info::new_instance(UVM_IS_OK, "All OK");
    endfunction

    //--------------------------------------------------------------------------
    // Function: write
    // - Called for every observed bus transaction
    // - Converts bus transaction into reg_bus_op using adapter
    // - Compares DUT response vs expected response (if checks are enabled)
    // - Updates RAL model if transaction is legal
    //--------------------------------------------------------------------------
    virtual function void write(BUSTYPE tr);
        uvm_reg_bus_op operation;
        adapter.bus2reg(tr, operation);

        // Perform legality checks if enabled
        if(my_model_config.get_has_checks()) begin
            reg_access_status_info exp_response = get_exp_response(operation);
            if(exp_response.status != operation.status) begin
                `uvm_error("DUT_ERROR", $sformatf(
                    "\nMismatch detected for the bus operation status - expected: %0s,\nreceived: %0s on access: %0s\nReason: %0s\n",
                    exp_response.status.name(), operation.status.name(), tr.convert2string(), exp_response.info))
            end
        end

        // If legal, update reg model via parent predictor
        if(operation.status == UVM_IS_OK) begin
            super.write(tr);
            // Debug print (optional)
            // $display("status = %0s  %0s", operation.status.name(), tr.convert2string());
        end
    endfunction

endclass : reg_predictor

`endif
