///////////////////////////////////////////////////////////////////////////////
// File:        algn_scoreboard_config.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-10-06
// Description: UVM configuration object for the Alignment Controller scoreboard.
//              This class encapsulates all run-time configuration parameters
//              used by the scoreboard. It centralizes control over thresholds,
//              internal check enabling, data width constraints, and interface
//              connectivity.
//
//              The configuration object is intended to be shared via the UVM
//              configuration database, ensuring consistent parameterization
//              across all verification components such as monitors, agents,
//              sequences, and scoreboards.
///////////////////////////////////////////////////////////////////////////////

`ifndef ALGN_SCOREBOARD_CONFIG
`define ALGN_SCOREBOARD_CONFIG

//------------------------------------------------------------------------------
// Class: algn_scoreboard_config
//------------------------------------------------------------------------------
// - Parameterized by DATA_WIDTH (default derived from global `DATA_WIDTH` macro).
// - Extends uvm_object so it can be created, configured, and shared at run-time.
// - Encapsulates all configuration parameters specific to the scoreboard.
//------------------------------------------------------------------------------
class algn_scoreboard_config #(int unsigned DATA_WIDTH = `DATA_WIDTH) extends uvm_object;

    //-------------------------------------------------------------------------
    // Data Members
    //-------------------------------------------------------------------------

    // Expected RX response threshold used for result comparison.
    local int unsigned expected_rx_response_threshold;

    // Expected TX response threshold used for packet count validation.
    local int unsigned expected_tx_item_threshold;

    // Expected IRQ response threshold used to validate interrupt timing or count.
    local int unsigned expected_irq_threshold;

    // Virtual interface handle used to connect scoreboard to DUT signals.
    protected algn_vif my_algn_scoreboard_vif;

    // Effective data width for the aligner (must be a power of two and ≥ 8).
    local int unsigned algn_data_width;

    // Switch to enable or disable internal scoreboard checks.
    local bit has_checks;

    //-------------------------------------------------------------------------
    // UVM Factory Registration
    //-------------------------------------------------------------------------
    // Registers the parameterized class with the UVM factory, enabling
    // dynamic creation using type_id::create().
    `uvm_object_param_utils(algn_scoreboard_config#(.DATA_WIDTH(DATA_WIDTH)))

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    // Initializes default member values to safe starting conditions.
    function new(string name = "");
        super.new(name);
        expected_rx_response_threshold = 0;
        expected_tx_item_threshold     = 0;
        expected_irq_threshold         = 0;
        algn_data_width                = 0;
        has_checks                     = 1'b0;
        my_algn_scoreboard_vif         = null;
    endfunction : new

    //-------------------------------------------------------------------------
    // Accessors / Mutators (Setters and Getters)
    //-------------------------------------------------------------------------

    // Enable/disable internal verification checks.
    virtual function bit get_has_checks();
        return has_checks;
    endfunction

    virtual function void set_has_checks(bit value);
        has_checks = value;
    endfunction

    // RX response threshold accessors.
    virtual function int unsigned get_expected_rx_response_threshold();
        return expected_rx_response_threshold;
    endfunction : get_expected_rx_response_threshold

    virtual function void set_expected_rx_response_threshold(int unsigned value);
        expected_rx_response_threshold = value;
    endfunction : set_expected_rx_response_threshold

    // TX item threshold accessors.
    virtual function int unsigned get_expected_tx_item_threshold();
        return expected_tx_item_threshold;
    endfunction : get_expected_tx_item_threshold

    virtual function void set_expected_tx_item_threshold(int unsigned value);
        expected_tx_item_threshold = value;
    endfunction : set_expected_tx_item_threshold

    // IRQ threshold accessors.
    virtual function int unsigned get_expected_irq_threshold();
        return expected_irq_threshold;
    endfunction : get_expected_irq_threshold

    virtual function void set_expected_irq_threshold(int unsigned value);
        expected_irq_threshold = value;
    endfunction : set_expected_irq_threshold

    // Data width accessors (with validity checks).
    // Enforces:
    //   * Minimum value is 8.
    //   * Value must be a power of two.
    virtual function int unsigned get_algn_data_width();
        return algn_data_width;
    endfunction

    virtual function void set_algn_data_width(int unsigned value);
        if (value < 8) begin
            `uvm_fatal("ALGORITHM_ISSUE",
                $sformatf("Minimum legal value for algn_data_width is 8, but got %0d", value))
        end
        if ($countones(value) != 1) begin
            `uvm_fatal("ALGORITHM_ISSUE",
                $sformatf("algn_data_width must be a power of 2, but got %0d", value))
        end
        algn_data_width = value;
    endfunction

    // Virtual interface accessors.
    virtual function algn_vif get_vif();
        return my_algn_scoreboard_vif;
    endfunction

    virtual function void set_vif(algn_vif value);
        if (my_algn_scoreboard_vif == null) begin
            my_algn_scoreboard_vif = value;
        end
        else begin
            `uvm_fatal("ALGORITHM_ISSUE",
                "Attempt to set virtual interface more than once")
        end
    endfunction

endclass : algn_scoreboard_config

`endif // ALGN_SCOREBOARD_CONFIG
