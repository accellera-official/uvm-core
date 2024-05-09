// 
//------------------------------------------------------------------------------
// Copyright 2010-2012 AMD
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2017 Cisco Systems, Inc.
// Copyright 2014 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2007-2014 Mentor Graphics Corporation
// Copyright 2013-2024 NVIDIA Corporation
// Copyright 2010-2014 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------------------------

//----------------------------------------------------------------------
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------


typedef class uvm_root;
typedef class uvm_report_object;
typedef class uvm_report_message;
   
// Title -- NODOCS -- Globals

//------------------------------------------------------------------------------
//
// Group -- NODOCS -- Simulation Control
//
//------------------------------------------------------------------------------

// Task -- NODOCS -- run_test
//
// Convenience function for uvm_top.run_test(). See <uvm_root> for more
// information.

// @uvm-ieee 1800.2-2020 auto F.3.1.2
task run_test (string test_name="");
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.run_test(test_name);
endtask

//----------------------------------------------------------------------------
//
// Group -- NODOCS -- Reporting
//
//----------------------------------------------------------------------------



// @uvm-ieee 1800.2-2020 auto F.3.2.1
function uvm_report_object uvm_get_report_object();
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  return top;
endfunction


// Function -- NODOCS -- uvm_report_enabled
//
// Returns 1 if the configured verbosity in ~uvm_top~ for this 
// severity/id is greater than or equal to ~verbosity~ else returns 0.
// 
// See also <uvm_report_object::uvm_report_enabled>.
//
// Static methods of an extension of uvm_report_object, e.g. uvm_component-based
// objects, cannot call ~uvm_report_enabled~ because the call will resolve to
// the <uvm_report_object::uvm_report_enabled>, which is non-static.
// Static methods cannot call non-static methods of the same class. 

// @uvm-ieee 1800.2-2020 auto F.3.2.2
function int uvm_report_enabled (int verbosity,
                                 uvm_severity severity=UVM_INFO, string id="");
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  return top.uvm_report_enabled(verbosity,severity,id);
endfunction

// Function -- NODOCS -- uvm_report

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_report( uvm_severity severity,
                          string id,
                          string message,
                          int verbosity = (severity == uvm_severity'(UVM_ERROR)) ? UVM_LOW :
                                          (severity == uvm_severity'(UVM_FATAL)) ? UVM_NONE : UVM_MEDIUM,
                          string filename = "",
                          int line = 0,
                          string context_name = "",
                          bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report(severity, id, message, verbosity, filename, line, context_name, report_enabled_checked);
endfunction 

// Undocumented DPI available version of uvm_report
export "DPI-C" function m__uvm_report_dpi;
function void m__uvm_report_dpi(int severity,
                                string id,
                                string message,
                                int    verbosity,
                                string filename,
                                int    line);
   uvm_report(uvm_severity'(severity), id, message, verbosity, filename, line);
endfunction : m__uvm_report_dpi

// Function -- NODOCS -- uvm_report_info

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_report_info(string id,
                  string message,
                              int verbosity = UVM_MEDIUM,
                  string filename = "",
                  int line = 0,
                              string context_name = "",
                              bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_info(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_warning

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_report_warning(string id,
                                 string message,
                                 int verbosity = UVM_MEDIUM,
                 string filename = "",
                 int line = 0,
                                 string context_name = "",
                                 bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_warning(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_error

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_report_error(string id,
                               string message,
                               int verbosity = UVM_NONE,
                   string filename = "",
                   int line = 0,
                               string context_name = "",
                               bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_error(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_report_fatal
//
// These methods, defined in package scope, are convenience functions that
// delegate to the corresponding component methods in ~uvm_top~. They can be
// used in module-based code to use the same reporting mechanism as class-based
// components. See <uvm_report_object> for details on the reporting mechanism. 
//
// *Note:* Verbosity is ignored for warnings, errors, and fatals to ensure users
// do not inadvertently filter them out. It remains in the methods for backward
// compatibility.

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_report_fatal(string id,
                           string message,
                               int verbosity = UVM_NONE,
                   string filename = "",
                   int line = 0,
                               string context_name = "",
                               bit report_enabled_checked = 0);
  uvm_root top;
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_report_fatal(id, message, verbosity, filename, line, context_name,
    report_enabled_checked);
endfunction


// Function -- NODOCS -- uvm_process_report_message
//
// This method, defined in package scope, is a convenience function that
// delegate to the corresponding component method in ~uvm_top~. It can be
// used in module-based code to use the same reporting mechanism as class-based
// components. See <uvm_report_object> for details on the reporting mechanism.

// @uvm-ieee 1800.2-2020 auto F.3.2.3
function void uvm_process_report_message(uvm_report_message report_message);
  uvm_root top;
  uvm_coreservice_t cs;
  process p;
  p = process::self();
  cs = uvm_coreservice_t::get();
  top = cs.get_root();
  top.uvm_process_report_message(report_message);
endfunction


// TODO merge with uvm_enum_wrapper#(uvm_severity)
function bit uvm_string_to_severity (string sev_str, output uvm_severity sev);
  case (sev_str)
    "UVM_INFO": begin
      sev = UVM_INFO;
    end

    "UVM_WARNING": begin
      sev = UVM_WARNING;
    end

    "UVM_ERROR": begin
      sev = UVM_ERROR;
    end

    "UVM_FATAL": begin
      sev = UVM_FATAL;
    end

    default: begin
      return 0;
    end

  endcase
  return 1;
endfunction


function automatic bit uvm_string_to_action (string action_str, output uvm_action action);
  string actions[$];
  uvm_string_split(action_str,"|",actions);
  uvm_string_to_action = 1;
  action = 0;
  foreach(actions[i]) begin
    case (actions[i])
      "UVM_NO_ACTION": begin
        action |= UVM_NO_ACTION;
      end

      "UVM_DISPLAY":   begin
        action |= UVM_DISPLAY;
      end

      "UVM_LOG":       begin
        action |= UVM_LOG;
      end

      "UVM_COUNT":     begin
        action |= UVM_COUNT;
      end

      "UVM_EXIT":      begin
        action |= UVM_EXIT;
      end

      "UVM_CALL_HOOK": begin
        action |= UVM_CALL_HOOK;
      end

      "UVM_STOP":      begin
        action |= UVM_STOP;
      end

      "UVM_RM_RECORD": begin
        action |= UVM_RM_RECORD;
      end

      default: begin
        uvm_string_to_action = 0;
      end

    endcase
  end
endfunction
  
function automatic bit uvm_string_to_verbosity(string verb_str, output uvm_verbosity verb_enum);
    case (verb_str)
      "NONE"       : begin verb_enum = UVM_NONE;   return 1; end
      "UVM_NONE"   : begin verb_enum = UVM_NONE;   return 1; end
      "LOW"        : begin verb_enum = UVM_LOW;    return 1; end
      "UVM_LOW"    : begin verb_enum = UVM_LOW;    return 1; end
      "MEDIUM"     : begin verb_enum = UVM_MEDIUM; return 1; end
      "UVM_MEDIUM" : begin verb_enum = UVM_MEDIUM; return 1; end
      "HIGH"       : begin verb_enum = UVM_HIGH;   return 1; end
      "UVM_HIGH"   : begin verb_enum = UVM_HIGH;   return 1; end
      "FULL"       : begin verb_enum = UVM_FULL;   return 1; end
      "UVM_FULL"   : begin verb_enum = UVM_FULL;   return 1; end
      "DEBUG"      : begin verb_enum = UVM_DEBUG;  return 1; end
      "UVM_DEBUG"  : begin verb_enum = UVM_DEBUG;  return 1; end
      default      : begin                         return 0; end
    endcase
endfunction
  
  
//----------------------------------------------------------------------------
//
// Group: Miscellaneous
//
// The library implements the following public API at the package level beyond
// what is documented in IEEE 1800.2.
//----------------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto F.3.3.1
function bit uvm_is_match (string expr, string str);
  return (uvm_re_match(.re(expr), .str(str), .deglob(1)) == 0);
endfunction


parameter UVM_LINE_WIDTH = `UVM_LINE_WIDTH;
parameter UVM_NUM_LINES = `UVM_NUM_LINES;
parameter UVM_SMALL_STRING = UVM_LINE_WIDTH*8-1;
parameter UVM_LARGE_STRING = UVM_LINE_WIDTH*UVM_NUM_LINES*8-1;


//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_string_to_bits
//
// Converts an input string to its bit-vector equivalent. Max bit-vector
// length is approximately 14000 characters.
//----------------------------------------------------------------------------

function logic[UVM_LARGE_STRING:0] uvm_string_to_bits(string str);
  $swrite(uvm_string_to_bits, "%0s", str);
endfunction

// @uvm-ieee 1800.2-2020 auto F.3.1.1
function uvm_core_state get_core_state();
   if (m_uvm_core_state.size() == 0) begin
     return UVM_CORE_UNINITIALIZED;
   end

   else begin
     return m_uvm_core_state[0];
   end

endfunction

// Function: uvm_init
// Implementation of uvm_init, as defined in section
// F.3.1.3 in 1800.2-2020.
//
// *Note:* The LRM states that subsequent calls to <uvm_init> after
// the first are silently ignored, however there are scenarios wherein
// the implementation breaks this requirement.
//
// If the core state (see <get_core_state>) is ~UVM_CORE_PRE_INIT~ when <uvm_init>,
// is called, then the library can not determine the appropriate core service.  As
// such, the default core service will be constructed and a fatal message
// shall be generated.
//
// If the core state is past ~UVM_CORE_PRE_INIT~, and ~cs~ is a non-null core 
// service instance different than the value passed to the first <uvm_init> call, 
// then the library will generate a warning message to alert the user that this 
// call to <uvm_init> is being ignored.
//
// @uvm-contrib This API represents a potential contribution to IEEE 1800.2
  
// @uvm-ieee 1800.2-2020 auto F.3.1.3
function void uvm_init(uvm_coreservice_t cs=null);
  uvm_default_coreservice_t dcs;
  
  if(get_core_state()!=UVM_CORE_UNINITIALIZED) begin
    if (get_core_state() == UVM_CORE_PRE_INIT) begin
      // If we're in this state, something very strange has happened.
      // We've called uvm_init, and it is actively assigning the
      // core service, but the core service isn't actually set yet.
      // This means that either the library messed something up, or
      // we have a race occurring between two threads.  Either way, 
      // this is non-recoverable.  We're going to setup using the default
      // core service, and immediately fatal out.
      dcs = new();
      uvm_coreservice_t::set(dcs);
      `uvm_fatal("UVM/INIT/MULTI", "Non-recoverable race during uvm_init")
    end
    else begin
      // After PRE_INIT, we can check to see if this is worth reporting
      // as a warning.  We only report it if the value for ~cs~ is _not_
      // the current core service, and ~cs~ is not null.
      uvm_coreservice_t actual;
      actual = uvm_coreservice_t::get();
      if ((cs != actual) && (cs != null)) begin
        `uvm_warning("UVM/INIT/MULTI", "uvm_init() called after library has already completed initialization, subsequent calls are ignored!")
      end
    end
    return;
  end
  m_uvm_core_state.push_front(UVM_CORE_PRE_INIT);

  // We control the implementation of uvm_default_coreservice_t::new
  // and uvm_coreservice_t::set (which is undocumented).  As such,
  // we guarantee that they will not trigger any calls to uvm_init.
  if(cs == null) begin
    dcs = new();
    cs = dcs;
  end
  uvm_coreservice_t::set(cs);

  // After this point, it should be safe to query the
  // corservice for anything.  We're not done with
  // initialization, but the coreservice (and the
  // various elements it controls) are 'stable'.
  //
  // Note that a user could have something silly
  // in their own space, like a specialization of
  // uvm_root with a constructor that relies on a
  // specialization of uvm_factory with a
  // constructor that relies on the specialized
  // root being constructed...  but there's not
  // really anything that can be done about that.
  m_uvm_core_state.push_front(UVM_CORE_INITIALIZING);
  
  foreach(uvm_deferred_init[idx]) begin
    uvm_deferred_init[idx].initialize();
  end
  
  uvm_deferred_init.delete();
  
  begin
    uvm_root top;
    top = uvm_root::get();
    // These next calls were moved to uvm_init from uvm_root,
    // because they could emit messages, resulting in the
    // report server being queried, which causes uvm_init.
    top.report_header();
    top.m_check_uvm_field_flag_size();
    // This sets up the global verbosity. Other command line args may
    // change individual component verbosity.
    top.m_check_verbosity();
  end

  m_uvm_core_state.push_front(UVM_CORE_INITIALIZED);

  // initialize compat fields from uvm_object_globals
  uvm_default_table_printer = new();
  uvm_default_tree_printer = new();
  uvm_default_line_printer = new();
  uvm_default_printer = uvm_default_table_printer;
  uvm_default_packer = new();
  uvm_default_comparer = new();
    
endfunction

//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_bits_to_string
//
// Converts an input bit-vector to its string equivalent. Max bit-vector
// length is approximately 14000 characters.
//----------------------------------------------------------------------------

function string uvm_bits_to_string(logic [UVM_LARGE_STRING:0] str);
  $swrite(uvm_bits_to_string, "%0s", str);
endfunction


//----------------------------------------------------------------------------
//
// Task: uvm_wait_for_nba_region
//
// This task will block until SystemVerilog's NBA region (or Re-NBA region if 
// called from a program context).  The purpose is to continue the calling 
// process only after allowing other processes any number of delta cycles (#0) 
// to settle out.
//
// @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2
//----------------------------------------------------------------------------

task uvm_wait_for_nba_region;

  // Nonblocking assignment requires static
  static int nba;
  static int next_nba;

  //If `included directly in a program block, can't use a non-blocking assign,
  //but it isn't needed since program blocks are in a separate region.
`ifndef UVM_NO_WAIT_FOR_NBA
  next_nba++;
  nba <= next_nba;
  @(nba);
`else
  repeat(`UVM_POUND_ZERO_COUNT) #0;
`endif


endtask

  
//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_split_string
//
// Returns a queue of strings, ~values~, that is the result of the ~str~ split
// based on the ~sep~.  For example:
//
//| uvm_split_string("1,on,false", ",", splits);
//
// Results in the 'splits' queue containing the three elements: 1, on and 
// false.
//----------------------------------------------------------------------------
//@uvm-compat provided for backward compatibility with 1800.2-2017
function automatic void uvm_split_string (string str, byte sep, ref string values[$]);
  int s = 0, e = 0;
  values.delete();
  while(e < str.len()) begin
    for(s=e; e<str.len(); ++e) begin
      
      if(str[e] == sep) begin
        break;
      end

    end

    if(s != e) begin
      
      values.push_back(str.substr(s,e-1));
    end

    e++;
  end
endfunction


//----------------------------------------------------------------------------
//
// Function -- NODOCS -- uvm_string_split
// Returns a queue of strings, values, that is the result of the str split based 
// on the sep. values shall be a queue.
//----------------------------------------------------------------------------

function automatic void uvm_string_split (string str, byte sep, ref string values[$]);
  int s = 0, e = 0, limit;
  values.delete();
  limit = str.len() + 1;
  do begin 
    
    for(s=e; e<str.len(); ++e) begin
        
      if(str[e] == sep) begin
        break;
      end

    end

    values.push_back(str.substr(s,e-1));
    e++;
  end
  while(e < limit);
endfunction

  
// Class -- NODOCS -- uvm_enum_wrapper#(T)
//
// The ~uvm_enum_wrapper#(T)~ class is a utility mechanism provided
// as a convenience to the end user.  It provides a <from_name>
// method which is the logical inverse of the System Verilog ~name~ 
// method which is built into all enumerations.

// @uvm-ieee 1800.2-2020 auto F.3.4.1
class uvm_enum_wrapper#(type T=uvm_active_passive_enum) extends uvm_void;

    protected static T map[string];


    // @uvm-ieee 1800.2-2020 auto F.3.4.2
    static function bit from_name(string name, ref T value);
        if (map.size() == 0) begin
          
          m_init_map();
        end


        if (map.exists(name)) begin
          value = map[name];
          return 1;
        end
        else begin
          return 0;
        end
    endfunction : from_name

    // Function- m_init_map
    // Initializes the name map, only needs to be performed once
    protected static function void m_init_map();
        T e = e.first();
        do begin 
          
          map[e.name()] = e;
          e = e.next();
        end
        while (e != e.first());
    endfunction : m_init_map

    // Function- new
    // Prevents accidental instantiations
    protected function new();
    endfunction : new

endclass : uvm_enum_wrapper

// Class -- NODOCS -- uvm_shared#(T)
//
// The ~uvm_shared#(T)~ class is a utility mechanism provided as
// a convenience method for passing potentially large values
// such as arrays, queues, or bitstreams by reference instead
// of by value.  The data itself is contained in a single
// ~value~ variable.
//
// Unlike ref ports, the uvm_shared#(T) can be saved and used
// after a function/task scope has been exited.
//
// @uvm-contrib - For potential contribution to 1800.2 standard
class uvm_shared#(type T=int) extends uvm_void;
  // Variable- value
  // The value contained within the ref.
  T value;
endclass : uvm_shared
