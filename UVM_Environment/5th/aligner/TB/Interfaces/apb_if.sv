///////////////////////////////////////////////////////////////////////////////
// File:        apb_if.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: APB Interface definition with protocol assertions.
//              - Bundles all APB signals (address, data, control).
//              - Parameterized for configurable bus widths.
//              - Contains SystemVerilog Assertions (SVA) to enforce protocol
//                rules and detect illegal/unknown values.
//              - Can be connected both to DUT and testbench components 
//                (driver, monitor, checker, etc.).
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_IF_SV
`define APB_IF_SV

//------------------------------------------------------------------------------
// Default configuration (can be overridden before including this file)
//------------------------------------------------------------------------------
`ifndef APB_MAX_DATA_WIDTH
  `define APB_MAX_DATA_WIDTH 32
`endif

`ifndef APB_MAX_ADDR_WIDTH
  `define APB_MAX_ADDR_WIDTH 16
`endif

`ifndef FIFO_DEPTH
  `define FIFO_DEPTH 8
`endif

//------------------------------------------------------------------------------
// APB Interface
//------------------------------------------------------------------------------
interface apb_if #(
    parameter APB_MAX_DATA_WIDTH = `APB_MAX_DATA_WIDTH, // Data bus width
    parameter APB_MAX_ADDR_WIDTH = `APB_MAX_ADDR_WIDTH  // Address bus width
) (
    input pclk   // APB clock input
);

    //--------------------------------------------------------------------------
    // APB standard signals
    //--------------------------------------------------------------------------
    logic                           preset_n;    // Active-low reset
    bit   [APB_MAX_ADDR_WIDTH-1:0]  paddr;       // Address bus
    bit                             pwrite;      // Write control (1=write, 0=read)
    bit                             psel;        // Slave select
    bit                             penable;     // Enable transfer
    bit   [APB_MAX_DATA_WIDTH-1:0]  pwdata;      // Write data
    logic                           pready;      // Slave ready
    logic  [APB_MAX_DATA_WIDTH-1:0] prdata;      // Read data
    logic                           pslverr;     // Error response

    // Enable/disable assertions
    bit has_checks;

    initial has_checks = 1;


    //--------------------------------------------------------------------------
    // APB protocol sequences
    //--------------------------------------------------------------------------
    sequence setup_phase_s;
        (psel == 1'b1) &&
        (($past(psel) == 1'b0) || 
         (($past(psel) == 1'b1) && $past(pready == 1'b1))) &&
        (pready == 1'b0);
    endsequence

    sequence access_phase_s;
        (psel == 1'b1) && (penable == 1'b1);
    endsequence

    sequence exiting_access_phase_s;
        (psel == 1'b1) && (penable == 1'b1) &&
        ((pready == 1'b1) || (pslverr == 1'b1));
    endsequence


    //--------------------------------------------------------------------------
    // Assertions: Protocol checks
    //--------------------------------------------------------------------------

    // PENABLE must be 0 in setup phase
    property penable_at_setup_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (setup_phase_s |-> (penable == 1'b0));
    endproperty
    PENABLE_AT_SETUP_PHASE_A : assert property(penable_at_setup_phase_p)
        else $error("PENABLE at Setup Phase is not 0");

    // PENABLE must transition to 1 when entering access phase
    property penable_entering_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (setup_phase_s |=> (penable == 1'b1));
    endproperty
    PENABLE_ENTERING_ACCESS_PHASE_A : assert property(penable_entering_access_phase_p)
        else $error("PENABLE did not become 1 entering Access Phase");

    // PENABLE must fall when exiting access phase
    property penable_exiting_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (exiting_access_phase_s |=> $fell(penable));
    endproperty
    PENABLE_EXITING_ACCESS_PHASE_A : assert property(penable_exiting_access_phase_p)
        else $error("PENABLE did not fall exiting Access Phase");

    // PENABLE must remain 1 during access phase
    property penable_stable_at_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (access_phase_s |-> (penable == 1'b1));
    endproperty
    PENABLE_STABLE_AT_ACCESS_PHASE_A : assert property(penable_stable_at_access_phase_p)
        else $error("PENABLE not stable during Access Phase");

    // PWRITE must remain stable during access phase
    property pwrite_stable_at_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (access_phase_s |-> $stable(pwrite));
    endproperty
    PWRITE_STABLE_AT_ACCESS_PHASE_A : assert property(pwrite_stable_at_access_phase_p)
        else $error("PWRITE not stable during Access Phase");

    // PADDR must remain stable during access phase
    property paddr_stable_at_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (access_phase_s |-> $stable(paddr));
    endproperty
    PADDR_STABLE_AT_ACCESS_PHASE_A : assert property(paddr_stable_at_access_phase_p)
        else $error("PADDR not stable during Access Phase");

    // PWDATA must remain stable during write transfers
    property pwdata_stable_at_access_phase_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (access_phase_s and (pwrite == 1'b1) |-> $stable(pwdata));
    endproperty
    PWDATA_STABLE_AT_ACCESS_PHASE_A : assert property(pwdata_stable_at_access_phase_p)
        else $error("PWDATA not stable during Access Phase");


    //--------------------------------------------------------------------------
    // Assertions: X/Z value checks
    //--------------------------------------------------------------------------

    property unknown_value_psel_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        ($isunknown(psel) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PSEL_A : assert property(unknown_value_psel_p)
        else $error("Unknown value on PSEL");

    property unknown_value_penable_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (psel == 1'b1) |-> ($isunknown(penable) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PENABLE_A : assert property(unknown_value_penable_p)
        else $error("Unknown value on PENABLE");

    property unknown_value_pwrite_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (psel == 1'b1) |-> ($isunknown(pwrite) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PWRITE_A : assert property(unknown_value_pwrite_p)
        else $error("Unknown value on PWRITE");

    property unknown_value_paddr_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (psel == 1'b1) |-> ($isunknown(paddr) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PADDR_A : assert property(unknown_value_paddr_p)
        else $error("Unknown value on PADDR");

    property unknown_value_pwdata_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        ((psel == 1'b1) && (pwrite == 1'b1)) |-> ($isunknown(pwdata) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PWDATA_A : assert property(unknown_value_pwdata_p)
        else $error("Unknown value on PWDATA");

    property unknown_value_prdata_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        ((psel == 1'b1) && (pwrite == 1'b0) && (pready == 1'b1) && (pslverr == 1'b0)) 
            |-> ($isunknown(prdata) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PRDATA_A : assert property(unknown_value_prdata_p)
        else $error("Unknown value on PRDATA");

    property unknown_value_pready_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        (psel == 1'b1) |-> ($isunknown(pready) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PREADY_A : assert property(unknown_value_pready_p)
        else $error("Unknown value on PREADY");

    property unknown_value_pslverr_p;
        @(posedge pclk) disable iff (!preset_n || !has_checks)
        ((psel == 1'b1) && (pready == 1)) |-> ($isunknown(pslverr) == 1'b0);
    endproperty
    UNKNOWN_VALUE_PSLVERR_A : assert property(unknown_value_pslverr_p)
        else $error("Unknown value on PSLVERR");

endinterface : apb_if

`endif