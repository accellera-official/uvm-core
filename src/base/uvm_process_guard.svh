//----------------------------------------------------------------------
// Copyright 2023-2024 NVIDIA Corporation
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
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------

// File: Process Guards
//
// The process guard classes, <uvm_process_guard_base> and <uvm_process_guard#(T)>,
// are used to detect and potentially recover from unexpected termination of 
// a SystemVerilog process.  
//
// For example, if a process calls ~sequence.start()~ and is then
// killed via a ~disable fork~ before the sequence has completed executing, then
// the sequence and sequencer could potentially be in an unexpected state.
//
// The UVM library monitors process guards using an independent process, allowing
// callbacks when the guarded processes fail.
//
// Example:
//|
//| class my_sequence extends uvm_sequence;
//|   ... constructor, etc ...
//|   typedef uvm_process_guard#(my_sequence) guard_t;
//|   guard_t body_guard;
//|
//|   virtual task body();
//|     // Start the guard
//|     body_guard = new("my_sequence::body_guard", this);
//|
//|     ...time consuming tasks...
//|
//|     // Important tasks complete, clear the guard. We
//|     // can cast the return to void because we no longer
//|     // require it.
//|     void'(body_guard.clear());
//|   endtask : body
//|
//|   function void process_guard_triggered(guard_t guard);
//|     // Recover if the process has terminated unexpectedly
//|     this.kill();
//|   endfunction : process_guard_triggered
//|
//
// 

// Class: uvm_process_guard#(T)
// Ensures that processes are not killed in unexpected ways.
//
// The uvm_process_guard#(T) class provides a safe mechanism for triggering
// a callback when a process is unexpectedly terminated during execution.
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2
class uvm_process_guard#(type T=int) extends uvm_process_guard_base;

  // Type: this_type
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2
  typedef uvm_process_guard#(T) this_type;

  // Function: new
  // Constructor
  //
  // The ~name~ argument is the name of the process guard, while ~ctxt~ is
  // the class that implements the ~process_guard_triggered~ hook.  An error
  // shall be generated if ~ctxt~ is null.
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2
  extern function new(string name, T ctxt);

  // Function: get_context
  // Returns the context with which the process guard was initialized.
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2
  extern function T get_context();

  // Function: do_trigger
  // Hook called when the guarded process transitions to either the `FINISHED`
  // or `KILLED` state.
  //
  // The default implementation calls the `process_guard_triggered` hook on
  // the context.
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2
  extern virtual function void do_trigger();
  
  /// Implementation

  protected T m_context;

endclass : uvm_process_guard

/// Implementations

function uvm_process_guard::new(string name, uvm_process_guard::T ctxt);
  super.new(name);
  this.m_context = ctxt;
  m_pending_guards.push_back(this);
endfunction : new

function uvm_process_guard::T uvm_process_guard::get_context();
  return this.m_context;
endfunction : get_context

function void uvm_process_guard::do_trigger();
  m_context.process_guard_triggered(this);
endfunction : do_trigger
