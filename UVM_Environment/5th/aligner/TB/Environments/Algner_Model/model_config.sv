///////////////////////////////////////////////////////////////////////////////
// File:        model_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: UVM configuration object for the Alignment Controller register
//              layer. This object holds configuration parameters—such as
//              whether run-time checks are enabled and the aligner data width—
//              and provides safe setters/getters with validity checks.
//              It can be placed in the UVM configuration database so that
//              different components (e.g., agents, sequences) can access the
//              same configuration values consistently.
////////////////////////////////////////////////////////////////////////////////

`ifndef MODEL_CONFIG
`define MODEL_CONFIG

//------------------------------------------------------------------------------
// model_config
//------------------------------------------------------------------------------
// Parameterized by DATA_WIDTH (default comes from global `DATA_WIDTH macro).
// Extends uvm_object so it can be used as a configuration object in UVM.
//------------------------------------------------------------------------------
class model_config #(int unsigned DATA_WIDTH = `DATA_WIDTH) extends uvm_object;

    //-------------------------------------------------------------------------
    // Data Members
    //-------------------------------------------------------------------------

    // Switch to enable/disable internal verification checks.
    local bit has_checks;

    // Effective data width for the aligner (must be power-of-two and ≥ 8).
    local int unsigned algn_data_width;

    //Virtual interface
    protected algn_vif my_algn_vif;

    //-------------------------------------------------------------------------
    // UVM Factory Registration
    //-------------------------------------------------------------------------
    // Enables model_config to be created dynamically with type_id::create().
    `uvm_object_param_utils(model_config#(.DATA_WIDTH(DATA_WIDTH)))

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    // name : optional instance name
    // Initializes has_checks to enabled and sets algn_data_width to the
    // parameter DATA_WIDTH.
    function new(string name = "");
        super.new(name);
        has_checks      = 1;                  // Enable checks by default
        algn_data_width = DATA_WIDTH;         // Default to provided DATA_WIDTH
    endfunction

    //-------------------------------------------------------------------------
    // Accessors
    //-------------------------------------------------------------------------

    // Getter for has_checks control field.
    virtual function bit get_has_checks();
        return has_checks;
    endfunction

    // Setter for has_checks control field.
    virtual function void set_has_checks(bit value);
        has_checks = value;
    endfunction

    // Getter for algn_data_width control field.
    virtual function int unsigned get_algn_data_width();
        return algn_data_width;
    endfunction

    // Setter for algn_data_width control field.
    // Enforces:
    //   * Minimum legal value is 8.
    //   * Value must be a power of 2.
    virtual function void set_algn_data_width(int unsigned value);
        // Check minimum value
        if (value < 8) begin
            `uvm_fatal("ALGORITHM_ISSUE",
                $sformatf("The minimum legal value for algn_data_width is 8 but user tried to set it to %0d", 
                    value))
        end

        // Ensure value is a power of two
        if ($countones(value) != 1) begin
            `uvm_fatal("ALGORITHM_ISSUE",
                $sformatf("The value for algn_data_width must be a power of 2 but user tried to set it to %0d", 
                    value))
        end

        algn_data_width = value;
    endfunction



    //Getter for the virtual interface
    virtual function algn_vif get_vif();
      return my_algn_vif;
    endfunction
    
    //Setter for the virtual interface
    virtual function void set_vif(algn_vif value);
      if(my_algn_vif == null) begin
        my_algn_vif = value;
      end
      else begin
        `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
      end
    endfunction

endclass : model_config

`endif // model_config
