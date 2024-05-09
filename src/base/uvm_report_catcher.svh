// $Id: uvm_report_catcher.svh,v 1.1.2.10 2010/04/09 15:03:25 janick Exp $
//------------------------------------------------------------------------------
// Copyright 2010-2012 AMD
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2014 Cisco Systems, Inc.
// Copyright 2018 Intel Corporation
// Copyright 2022 Marvell International Ltd.
// Copyright 2007-2020 Mentor Graphics Corporation
// Copyright 2013-2024 NVIDIA Corporation
// Copyright 2014 Semifore
// Copyright 2010-2013 Synopsys, Inc.
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


`ifndef UVM_REPORT_CATCHER_SVH
`define UVM_REPORT_CATCHER_SVH

typedef class uvm_report_object;
typedef class uvm_report_handler;
typedef class uvm_report_server;
typedef class uvm_report_catcher;

typedef uvm_callbacks    #(uvm_report_object, uvm_report_catcher) uvm_report_cb;
typedef uvm_callback_iter#(uvm_report_object, uvm_report_catcher) uvm_report_cb_iter /* @uvm-ieee 1800.2-2020 auto D.4.4*/ ;

class sev_id_struct;
  bit sev_specified ;
  bit id_specified ;
  uvm_severity sev ;
  string  id ;
  bit is_on ;
endclass

// TITLE: Report Catcher
//
// Contains debug methods in the Accellera UVM implementation not documented
// in the IEEE 1800.2-2020 LRM


//------------------------------------------------------------------------------
//
// CLASS: uvm_report_catcher
//

// @uvm-ieee 1800.2-2020 auto 6.6.1
virtual class uvm_report_catcher extends uvm_callback;

  `uvm_register_cb(uvm_report_object,uvm_report_catcher)

  typedef enum { UNKNOWN_ACTION, THROW, CAUGHT} action_e;

  local static uvm_report_message m_modified_report_message;
  local static uvm_report_message m_orig_report_message;

  local static bit m_set_action_called;

  // Counts for the demoteds and caughts
  local static int m_demoted_fatal;
  local static int m_demoted_error;
  local static int m_demoted_warning;
  local static int m_caught_fatal;
  local static int m_caught_error;
  local static int m_caught_warning;

  // Flag counts
  localparam   int DO_NOT_CATCH      = 1; 
  localparam   int DO_NOT_MODIFY     = 2; 
  local static int m_debug_flags;

  local static  bit do_report;

  
  // Function -- NODOCS -- new
  //
  // Create a new report catcher. The name argument is optional, but
  // should generally be provided to aid in debugging.

  // @uvm-ieee 1800.2-2020 auto 6.6.2
  function new(string name = "uvm_report_catcher");
    super.new(name);
    do_report = 1;
  endfunction    

  // Group -- NODOCS -- Current Message State

  // Function -- NODOCS -- get_client
  //
  // Returns the <uvm_report_object> that has generated the message that
  // is currently being processed.

  // @uvm-ieee 1800.2-2020 auto 6.6.3.1
  function uvm_report_object get_client();
    return m_modified_report_message.get_report_object(); 
  endfunction

  // Function -- NODOCS -- get_severity
  //
  // Returns the <uvm_severity> of the message that is currently being
  // processed. If the severity was modified by a previously executed
  // catcher object (which re-threw the message), then the returned 
  // severity is the modified value.

  // @uvm-ieee 1800.2-2020 auto 6.6.3.2
  function uvm_severity get_severity();
    return this.m_modified_report_message.get_severity();
  endfunction
  
  // Function -- NODOCS -- get_context
  //
  // Returns the context name of the message that is currently being
  // processed. This is typically the full hierarchical name of the component
  // that issued the message. However, if user-defined context is set from
  // a uvm_report_message, the user-defined context will be returned.

  // @uvm-ieee 1800.2-2020 auto 6.6.3.3
  function string get_context();
    string context_str;
    
    context_str = this.m_modified_report_message.get_context();
    if (context_str == "") begin
      uvm_report_handler rh = this.m_modified_report_message.get_report_handler();
      context_str = rh.get_full_name();
    end

    return context_str;
  endfunction
  
  // Function -- NODOCS -- get_verbosity
  //
  // Returns the verbosity of the message that is currently being
  // processed. If the verbosity was modified by a previously executed
  // catcher (which re-threw the message), then the returned 
  // verbosity is the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.3.4
  function int get_verbosity();
    return this.m_modified_report_message.get_verbosity();
  endfunction
  
  // Function -- NODOCS -- get_id
  //
  // Returns the string id of the message that is currently being
  // processed. If the id was modified by a previously executed
  // catcher (which re-threw the message), then the returned 
  // id is the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.3.5
  function string get_id();
    return this.m_modified_report_message.get_id();
  endfunction
  
  // Function -- NODOCS -- get_message
  //
  // Returns the string message of the message that is currently being
  // processed. If the message was modified by a previously executed
  // catcher (which re-threw the message), then the returned 
  // message is the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.3.6
  function string get_message();
     return this.m_modified_report_message.get_message();
  endfunction
  
  // Function -- NODOCS -- get_action
  //
  // Returns the <uvm_action> of the message that is currently being
  // processed. If the action was modified by a previously executed
  // catcher (which re-threw the message), then the returned 
  // action is the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.3.7
  function uvm_action get_action();
    return this.m_modified_report_message.get_action();
  endfunction
  
  // Function -- NODOCS -- get_fname
  //
  // Returns the file name of the message.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.3.8
  function string get_fname();
    return this.m_modified_report_message.get_filename();
  endfunction             

  // Function -- NODOCS -- get_line
  //
  // Returns the line number of the message.

  // @uvm-ieee 1800.2-2020 auto 6.6.3.9
  function int get_line();
    return this.m_modified_report_message.get_line();
  endfunction

  // Function -- NODOCS -- get_element_container
  //
  // Returns the element container of the message.

  function uvm_report_message_element_container get_element_container();
    return this.m_modified_report_message.get_element_container();
  endfunction

  
  // Group -- NODOCS -- Change Message State

  // Function -- NODOCS -- set_severity
  //
  // Change the severity of the message to ~severity~. Any other
  // report catchers will see the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.4.1
  protected function void set_severity(uvm_severity severity);
    this.m_modified_report_message.set_severity(severity);
  endfunction
  
  // Function -- NODOCS -- set_verbosity
  //
  // Change the verbosity of the message to ~verbosity~. Any other
  // report catchers will see the modified value.

  // @uvm-ieee 1800.2-2020 auto 6.6.4.2
  protected function void set_verbosity(int verbosity);
    this.m_modified_report_message.set_verbosity(verbosity);
  endfunction      

  // Function -- NODOCS -- set_id
  //
  // Change the id of the message to ~id~. Any other
  // report catchers will see the modified value.

  // @uvm-ieee 1800.2-2020 auto 6.6.4.3
  protected function void set_id(string id);
    this.m_modified_report_message.set_id(id);
  endfunction
  
  // Function -- NODOCS -- set_message
  //
  // Change the text of the message to ~message~. Any other
  // report catchers will see the modified value.

  // @uvm-ieee 1800.2-2020 auto 6.6.4.4
  protected function void set_message(string message);
    this.m_modified_report_message.set_message(message);
  endfunction
  
  // Function -- NODOCS -- set_action
  //
  // Change the action of the message to ~action~. Any other
  // report catchers will see the modified value.
  
  // @uvm-ieee 1800.2-2020 auto 6.6.4.5
  protected function void set_action(uvm_action action);
    this.m_modified_report_message.set_action(action);
    this.m_set_action_called = 1;
  endfunction

  // Function -- NODOCS -- set_context
  //
  // Change the context of the message to ~context_str~. Any other
  // report catchers will see the modified value.

  // @uvm-ieee 1800.2-2020 auto 6.6.4.6
  protected function void set_context(string context_str);
    this.m_modified_report_message.set_context(context_str);
  endfunction

  // Function -- NODOCS -- add_int
  //
  // Add an integral type of the name ~name~ and value ~value~ to
  // the message.  The required ~size~ field indicates the size of ~value~.
  // The required ~radix~ field determines how to display and
  // record the field. Any other report catchers will see the newly
  // added element.
  //

  protected function void add_int(string name,
                  uvm_bitstream_t value,
                  int size,
                  uvm_radix_enum radix,
                  uvm_action action = (UVM_LOG|UVM_RM_RECORD));
    this.m_modified_report_message.add_int(name, value, size, radix, action);
  endfunction


  // Function -- NODOCS -- add_string
  //
  // Adds a string of the name ~name~ and value ~value~ to the
  // message. Any other report catchers will see the newly
  // added element.
  //

  protected function void add_string(string name,
                     string value,
                                     uvm_action action = (UVM_LOG|UVM_RM_RECORD));
    this.m_modified_report_message.add_string(name, value, action);
  endfunction


  // Function -- NODOCS -- add_object
  //
  // Adds a uvm_object of the name ~name~ and reference ~obj~ to
  // the message. Any other report catchers will see the newly
  // added element.
  //

  protected function void add_object(string name,
                     uvm_object obj,
                                     uvm_action action = (UVM_LOG|UVM_RM_RECORD));
    this.m_modified_report_message.add_object(name, obj, action);
  endfunction

  // Function: print_catcher
  //
  // Prints debug information about all of the typewide report catchers that are 
  // registered.
  //
  // @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2
  
  static function void print_catcher(UVM_FILE file = 0);
      string msg;
      string enabled;
      uvm_report_catcher catcher;
      static uvm_report_cb_iter iter = new(null);
      string q[$];

      q.push_back("-------------UVM REPORT CATCHERS----------------------------\n");

      catcher = iter.first();
      while(catcher != null) begin
        if(catcher.callback_mode()) begin
              
          enabled = "ON";
        end
        
        else begin
              
          enabled = "OFF";
        end
        

        q.push_back($sformatf("%20s : %s\n", catcher.get_name(),enabled));
        catcher = iter.next();
      end
      q.push_back("--------------------------------------------------------------\n");

      `uvm_info_context("UVM/REPORT/CATCHER",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW,uvm_root::get())
  endfunction
  
  // Function: debug_report_catcher
  //
  // Turn on report catching debug information. bits[1:0] of ~what~ enable debug features
  // * bit 0 - when set to 1 -- forces catch to be ignored so that all catchers see the
  //   the reports.
  // * bit 1 - when set to 1 -- forces the message to remain unchanged
  //
  // @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2
  
  static function void debug_report_catcher(int what= 0);
    m_debug_flags = what;
  endfunction        
  
  // Group -- NODOCS -- Callback Interface
 
  // Function -- NODOCS -- catch
  //
  // This is the method that is called for each registered report catcher.
  // There are no arguments to this function. The <Current Message State>
  // interface methods can be used to access information about the 
  // current message being processed.

  // @uvm-ieee 1800.2-2020 auto 6.6.5
  pure virtual function action_e catch();
     

  // Group -- NODOCS -- Reporting

   // Function -- NODOCS -- uvm_report_fatal
   //
   // Issues a fatal message using the current message's report object.
   // This message will bypass any message catching callbacks.
   
   protected function void uvm_report_fatal(string id,
                        string message, 
                        int verbosity,
                        string fname = "",
                        int line = 0,
                        string context_name = "",
                        bit report_enabled_checked = 0);

     this.uvm_report(UVM_FATAL, id, message, UVM_NONE, fname, line,
                     context_name, report_enabled_checked);
   endfunction  


   // Function -- NODOCS -- uvm_report_error
   //
   // Issues an error message using the current message's report object.
   // This message will bypass any message catching callbacks.
   
   protected function void uvm_report_error(string id,
                        string message, 
                        int verbosity,
                        string fname = "",
                        int line = 0,
                        string context_name = "",
                        bit report_enabled_checked = 0);

     this.uvm_report(UVM_ERROR, id, message, UVM_NONE, fname, line,
                     context_name, report_enabled_checked);
   endfunction  
     

   // Function -- NODOCS -- uvm_report_warning
   //
   // Issues a warning message using the current message's report object.
   // This message will bypass any message catching callbacks.
   
   protected function void uvm_report_warning(string id,
                          string message,
                          int verbosity,
                          string fname = "",
                          int line = 0, 
                          string context_name = "",
                          bit report_enabled_checked = 0);

     this.uvm_report(UVM_WARNING, id, message, UVM_NONE, fname, line,
                     context_name, report_enabled_checked);
   endfunction  


   // Function -- NODOCS -- uvm_report_info
   //
   // Issues a info message using the current message's report object.
   // This message will bypass any message catching callbacks.
   
   protected function void uvm_report_info(string id,
                       string message, 
                       int verbosity,
                       string fname = "",
                       int line = 0,
                       string context_name = "",
                       bit report_enabled_checked = 0);

     this.uvm_report(UVM_INFO, id, message, verbosity, fname, line,
                     context_name, report_enabled_checked);
   endfunction  

   // Function -- NODOCS -- uvm_report
   //
   // Issues a message using the current message's report object.
   // This message will bypass any message catching callbacks.

   protected function void uvm_report(uvm_severity severity,
                      string id,
                      string message,
                      int verbosity,
                      string fname = "",
                      int line = 0,
                      string context_name = "",
                      bit report_enabled_checked = 0);

     uvm_report_message l_report_message;
     if (report_enabled_checked == 0) begin
       if (!uvm_report_enabled(verbosity, severity, id)) begin
         
         return;
       end

     end

     l_report_message = uvm_report_message::new_report_message();
     l_report_message.set_report_message(severity, id, message, 
                     verbosity, fname, line, context_name);
     this.uvm_process_report_message(l_report_message);
   endfunction

   protected function void uvm_process_report_message(uvm_report_message msg);
     uvm_report_object ro = m_modified_report_message.get_report_object();
     uvm_action a = ro.get_report_action(msg.get_severity(), msg.get_id());

     if(a) begin
       string composed_message;
       uvm_report_server rs = m_modified_report_message.get_report_server();

       msg.set_report_object(ro);
       msg.set_report_handler(m_modified_report_message.get_report_handler());
       msg.set_report_server(rs);
       msg.set_file(ro.get_report_file_handle(msg.get_severity(), msg.get_id()));
       msg.set_action(a);

       // no need to compose when neither UVM_DISPLAY nor UVM_LOG is set
       if (a & (UVM_LOG|UVM_DISPLAY)) begin
         
         composed_message = rs.compose_report_message(msg);
       end

       rs.execute_report_message(msg, composed_message);
     end
   endfunction


  // Function -- NODOCS -- issue
  // Immediately issues the message which is currently being processed. This
  // is useful if the message is being ~CAUGHT~ but should still be emitted.
  //
  // Issuing a message will update the report_server stats, possibly multiple 
  // times if the message is not ~CAUGHT~.

  protected function void issue();
     string composed_message;
     uvm_report_server rs = m_modified_report_message.get_report_server();

     if(uvm_action_type'(m_modified_report_message.get_action()) != UVM_NO_ACTION) begin
     
       // no need to compose when neither UVM_DISPLAY nor UVM_LOG is set
       if (m_modified_report_message.get_action() & (UVM_LOG|UVM_DISPLAY)) begin
         
         composed_message = rs.compose_report_message(m_modified_report_message);
       end

       rs.execute_report_message(m_modified_report_message, composed_message);
     end
  endfunction


  //process_all_report_catchers
  //method called by report_server.report to process catchers
  //

  static function int process_all_report_catchers(uvm_report_message rm);
    int iter;
    uvm_report_catcher catcher;
    int thrown = 1;
    uvm_severity orig_severity;
    static bit in_catcher;
    uvm_report_object l_report_object = rm.get_report_object();

    if(in_catcher == 1) begin
      return 1;
    end
    in_catcher = 1;    
    uvm_callbacks_base::m_tracing = 0;  //turn off cb tracing so catcher stuff doesn't print

    orig_severity = uvm_severity'(rm.get_severity());
    m_modified_report_message = rm;

    catcher = uvm_report_cb::get_first(iter,l_report_object);
    if (catcher != null) begin
      if(m_debug_flags & DO_NOT_MODIFY) begin
        process p = process::self(); // Keep random stability
        string randstate;
        if (p != null) begin
          
          randstate = p.get_randstate();
        end

        $cast(m_orig_report_message, rm.clone()); //have to clone, rm can be extended type
        if (p != null) begin
          
          p.set_randstate(randstate);
        end

      end
    end
    while(catcher != null) begin
      uvm_severity prev_sev;

      if (!catcher.callback_mode()) begin
        catcher = uvm_report_cb::get_next(iter,l_report_object);
        continue;
      end

      prev_sev = m_modified_report_message.get_severity();
      m_set_action_called = 0;
      thrown = catcher.process_report_catcher();

      // Set the action to the default action for the new severity
      // if it is still at the default for the previous severity,
      // unless it was explicitly set.
      if (!m_set_action_called && 
      m_modified_report_message.get_severity() != prev_sev && 
      m_modified_report_message.get_action() == 
      l_report_object.get_report_action(prev_sev, "*@&*^*^*#")) begin

        m_modified_report_message.set_action(
           l_report_object.get_report_action(m_modified_report_message.get_severity(), "*@&*^*^*#"));
      end

      if(thrown == 0) begin 
        case(orig_severity)
          UVM_FATAL:   begin
            m_caught_fatal++;
          end

          UVM_ERROR:   begin
            m_caught_error++;
          end

          UVM_WARNING: begin
            m_caught_warning++;
          end

        endcase   
        break;
      end 
      catcher = uvm_report_cb::get_next(iter,l_report_object);
    end //while

    //update counters if message was returned with demoted severity
    case(orig_severity)
      UVM_FATAL: begin    
        
        if(m_modified_report_message.get_severity() < orig_severity) begin
          
          m_demoted_fatal++;
        end

      end

      UVM_ERROR: begin
        
        if(m_modified_report_message.get_severity() < orig_severity) begin
          
          m_demoted_error++;
        end

      end

      UVM_WARNING: begin
        
        if(m_modified_report_message.get_severity() < orig_severity) begin
          
          m_demoted_warning++;
        end

      end

    endcase

    in_catcher = 0;
    uvm_callbacks_base::m_tracing = 1;  //turn tracing stuff back on

    return thrown; 
  endfunction


  //process_report_catcher
  //internal method to call user <catch()> method
  //

  local function int process_report_catcher();

    action_e act;

    act = this.catch();

    if(act == UNKNOWN_ACTION) begin
      
      this.uvm_report_error("RPTCTHR", {"uvm_report_this.catch() in catcher instance ",
        this.get_name(), " must return THROW or CAUGHT"}, UVM_NONE, `uvm_file, `uvm_line);
    end


    if(m_debug_flags & DO_NOT_MODIFY) begin
      m_modified_report_message.copy(m_orig_report_message);
    end     

    if(act == CAUGHT  && !(m_debug_flags & DO_NOT_CATCH)) begin
      return 0;
    end  

    return 1;

  endfunction


  // Function -- NODOCS -- summarize
  //
  // This function is called automatically by <uvm_report_server::report_summarize()>.
  // It prints the statistics for the active catchers.


  static function void summarize(UVM_FILE file = UVM_STDOUT);
    string s;
    uvm_root root = uvm_root::get();
    uvm_action action;
    string q[$];
    if(do_report) begin
      q.push_back("\n--- UVM Report catcher Summary ---\n\n\n");
      q.push_back($sformatf("Number of demoted UVM_FATAL reports  :%5d\n", m_demoted_fatal));
      q.push_back($sformatf("Number of demoted UVM_ERROR reports  :%5d\n", m_demoted_error));
      q.push_back($sformatf("Number of demoted UVM_WARNING reports:%5d\n", m_demoted_warning));
      q.push_back($sformatf("Number of caught UVM_FATAL reports   :%5d\n", m_caught_fatal));
      q.push_back($sformatf("Number of caught UVM_ERROR reports   :%5d\n", m_caught_error));
      q.push_back($sformatf("Number of caught UVM_WARNING reports :%5d\n", m_caught_warning));
      if(file == UVM_STDOUT) begin
        `uvm_info_context("UVM/REPORT/CATCHER",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW,root)
      end
      else begin
        // Re-route the output for the message to the file by changing the action, restoring to original setting after message reported
        action = root.get_report_action(UVM_INFO, "UVM/REPORT/CATCHER");
        root.set_report_id_action("UVM/REPORT/CATCHER", UVM_LOG);
        root.set_report_id_file("UVM/REPORT/CATCHER", file);
        `uvm_info_context("UVM/REPORT/CATCHER",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW,root)
        root.set_report_id_action("UVM/REPORT/CATCHER", action);
      end  
    end
  endfunction

  //@uvm-compat for compatibility with 1.2
  static function uvm_report_catcher get_report_catcher(string name);
    static uvm_report_cb_iter iter = new(null);
    get_report_catcher = iter.first();
    while(get_report_catcher != null) begin
      if(get_report_catcher.get_name() == name) begin
        
        return get_report_catcher;
      end

      get_report_catcher = iter.next();
    end
    return null;
  endfunction


endclass

`endif // UVM_REPORT_CATCHER_SVH
