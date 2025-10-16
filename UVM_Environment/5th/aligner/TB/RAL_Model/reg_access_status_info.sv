/////////////////////////////////////////////////////////////////////////////// 
// File:        reg_access_status_info.sv
// Author:      Ahmed Awad-Allah Mohamed
// Date:        2025-09-21
// Description: Utility class to store register access status information.
//              - Holds the UVM status (e.g., UVM_IS_OK, UVM_NOT_OK).
//              - Holds an optional info string describing the result.
//              - Provides a factory-like static function to create instances.
//              This class is useful for returning detailed status information
//              after performing register operations in a UVM testbench. 
///////////////////////////////////////////////////////////////////////////////

`ifndef REG_ACCESS_STATUS_INFO
`define REG_ACCESS_STATUS_INFO

//------------------------------------------------------------------------------
// Class: reg_access_status_info
//------------------------------------------------------------------------------
// Lightweight container for passing around register access results.
// Contains:
//   - status : UVM status enum (success/failure)
//   - info   : Extra string description of the access result
//------------------------------------------------------------------------------
class reg_access_status_info;

  //--------------------------------------------------------------------------
  // Fields
  //--------------------------------------------------------------------------

  // Access status (constant, cannot be changed after construction)
  const uvm_status_e status;
  
  // Informational message string (constant, cannot be changed after construction)
  const string info;
  
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  // Creates a new instance of reg_access_status_info.
  // - status : UVM status of the access (e.g. UVM_IS_OK, UVM_NOT_OK)
  // - info   : String with details about the operation result
  function new(uvm_status_e status, string info);
    this.status = status;
    this.info   = info;
  endfunction
  
  //--------------------------------------------------------------------------
  // Static constructor
  //--------------------------------------------------------------------------
  // Provides a convenient factory-like function to create an instance.
  static function reg_access_status_info new_instance(uvm_status_e status, string info);
    reg_access_status_info result = new(status, info);
    return result;
  endfunction
  
endclass : reg_access_status_info

`endif
