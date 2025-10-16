/////////////////////////////////////////////////////////////////////////////// 
// File:        md_types.sv 
// Author:      Ahmed Awad-Allah Mohamed 
// Date:        2025-09-07 
// Description: Type definitions related to the MD (Memory/Data) interface. 
//              - Provides a typedef for the virtual interface handle (md_vif) 
//                to be used throughout the UVM testbench. 
//              - Defines an enumeration for MD response codes to indicate 
//                success (OKAY) or error (ERR) during transactions. 
///////////////////////////////////////////////////////////////////////////////  

`ifndef MD_TYPES
`define MD_TYPES

//------------------------------------------------------------------------------
// md_vif typedef
//------------------------------------------------------------------------------
// - Defines a virtual interface type for md_if
// - Parameterized by DATA_WIDTH (macro must be defined globally in the testbench)
// - Used in UVM components (e.g., driver, monitor, agent) to connect to the DUT
//------------------------------------------------------------------------------
typedef virtual md_if #(.DATA_WIDTH(`DATA_WIDTH)) md_vif;


//------------------------------------------------------------------------------
// md_response enum
//------------------------------------------------------------------------------
// - Defines MD response codes used in the protocol
// - MD_OKAY : Transaction completed successfully
// - MD_ERR  : Transaction failed due to an error condition
//------------------------------------------------------------------------------
typedef enum bit {
    MD_OKAY = 0,   // Successful transaction
    MD_ERR  = 1    // Error occurred
} md_response;

`endif
