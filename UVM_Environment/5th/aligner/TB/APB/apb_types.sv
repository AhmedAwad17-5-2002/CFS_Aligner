///////////////////////////////////////////////////////////////////////////////
// File:        apb_types.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-08-20
// Description: Common APB type definitions used across items, driver, monitor,
//              and sequences. Provides typedefs and enums for directions,
//              responses, addresses, and data widths.
///////////////////////////////////////////////////////////////////////////////

`ifndef APB_TYPES
`define APB_TYPES

//------------------------------------------------------------------------------
// Virtual interface typedef
//------------------------------------------------------------------------------
typedef virtual apb_if apb_vif;


//------------------------------------------------------------------------------
// APB transfer direction
// - APB_READ  : Indicates a read transfer (slave drives prdata).
// - APB_WRITE : Indicates a write transfer (master drives pwdata).
//------------------------------------------------------------------------------
typedef enum bit {
    APB_READ  = 0,
    APB_WRITE = 1
} apb_dir;


//------------------------------------------------------------------------------
// APB address type
// - Width is configurable through `APB_MAX_ADDR_WIDTH` macro.
//------------------------------------------------------------------------------
typedef bit[`APB_MAX_ADDR_WIDTH-1:0] apb_addr;


//------------------------------------------------------------------------------
// APB data type
// - Width is configurable through `APB_MAX_DATA_WIDTH` macro.
//------------------------------------------------------------------------------
typedef bit[`APB_MAX_DATA_WIDTH-1:0] apb_data;


//------------------------------------------------------------------------------
// APB response type
// - APB_OKAY : Normal operation, no error.
// - APB_ERR  : Indicates a slave error response.
//------------------------------------------------------------------------------
typedef enum bit {
    APB_OKAY = 0,
    APB_ERR  = 1
} apb_response;

`endif // APB_TYPES
