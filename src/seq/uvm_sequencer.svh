//----------------------------------------------------------------------
// Copyright 2010-2011 AMD
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2014 Cisco Systems, Inc.
// Copyright 2007-2011 Mentor Graphics Corporation
// Copyright 2014-2022 NVIDIA Corporation
// Copyright 2010-2014 Synopsys, Inc.
// Copyright 2017 Verific
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


//------------------------------------------------------------------------------
//
// CLASS -- NODOCS -- uvm_sequencer #(REQ,RSP)
//
//------------------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto 15.5.1
class uvm_sequencer #(type REQ=uvm_sequence_item, RSP=REQ)
                                   extends uvm_sequencer_param_base #(REQ, RSP);

  typedef uvm_sequencer #( REQ , RSP) this_type;

  `uvm_component_param_utils(this_type)




  // @uvm-ieee 1800.2-2020 auto 15.5.2.1
  extern function new (string name, uvm_component parent=null);
  

  // Function -- NODOCS -- stop_sequences
  //
  // Tells the sequencer to kill all sequences and child sequences currently
  // operating on the sequencer, and remove all requests, locks and responses
  // that are currently queued.  This essentially resets the sequencer to an
  // idle state.
  //
  extern virtual function void stop_sequences();

  extern virtual function string get_type_name();

  // Group -- NODOCS -- Sequencer Interface
  // This is an interface for communicating with sequencers.
  //
  // The interface is defined as:
  //| Requests:
  //|  virtual task          get_next_item      (output REQ request);
  //|  virtual task          try_next_item      (output REQ request);
  //|  virtual task          get                (output REQ request);
  //|  virtual task          peek               (output REQ request);
  //| Responses:
  //|  virtual function void item_done          (input RSP response=null);
  //|  virtual task          put                (input RSP response);
  //| Sync Control:
  //|  virtual task          wait_for_sequences ();
  //|  virtual function bit  has_do_available   ();
  //
  // See <uvm_sqr_if_base #(REQ,RSP)> for information about this interface.
   
  // Variable -- NODOCS -- seq_item_export
  //
  // This export provides access to this sequencer's implementation of the
  // sequencer interface.
  //

  uvm_seq_item_pull_imp #(REQ, RSP, this_type) seq_item_export;

  // Task -- NODOCS -- get_next_item
  // Retrieves the next available item from a sequence.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.3
  extern virtual task          get_next_item (output REQ t);

  // Task -- NODOCS -- try_next_item
  // Retrieves the next available item from a sequence if one is available.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.4
  extern virtual task          try_next_item (output REQ t);

  // Function -- NODOCS -- item_done
  // Indicates that the request is completed.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.5
  extern virtual function void item_done     (RSP item = null);

  // Task -- NODOCS -- put
  // Sends a response back to the sequence that issued the request.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.8
  extern virtual task          put           (RSP t);

  // Task -- NODOCS -- get
  // Retrieves the next available item from a sequence.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.6
  extern task                  get           (output REQ t);

  // Task -- NODOCS -- peek
  // Returns the current request item if one is in the FIFO.
  //
  // @uvm-ieee 1800.2-2020 auto 15.5.2.7
  extern task                  peek          (output REQ t);

  /// Documented here for clarity, implemented in uvm_sequencer_base

  // Task -- NODOCS -- wait_for_sequences
  // Waits for a sequence to have a new item available.
  //

  // Function -- NODOCS -- has_do_available
  // Returns 1 if any sequence running on this sequencer is ready to supply
  // a transaction, 0 otherwise.
  //
   
  //-----------------
  // Internal Methods
  //-----------------
  // Do not use directly, not part of standard

  extern function void         item_done_trigger(RSP item = null);
  function RSP                 item_done_get_trigger_data();
    return last_rsp(0);
  endfunction
  extern protected virtual function int m_find_number_driver_connections();

endclass  


typedef uvm_sequencer #(uvm_sequence_item) uvm_virtual_sequencer;



//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

function uvm_sequencer::new (string name, uvm_component parent=null);
  super.new(name, parent);
  seq_item_export = new ("seq_item_export", this);
endfunction


// Function- stop_sequences
//
// Tells the sequencer to kill all sequences and child sequences currently
// operating on the sequencer, and remove all requests, locks and responses
// that are currently queued.  This essentially resets the sequencer to an
// idle state.
//
function void uvm_sequencer::stop_sequences();
  REQ t;
  super.stop_sequences();
  sequence_item_requested  = 0;
  get_next_item_called     = 0;
  // Empty the request fifo
  if (m_req_fifo.used()) begin
    uvm_report_info(get_full_name(), "Sequences stopped.  Removing request from sequencer fifo");
    m_req_fifo.flush();
  end
endfunction


function string uvm_sequencer::get_type_name();
  return "uvm_sequencer";
endfunction 


//-----------------
// Internal Methods
//-----------------

// m_find_number_driver_connections
// --------------------------------
// Counting the number of of connections is done at end of
// elaboration and the start of run.  If the user neglects to
// call super in one or the other, the sequencer will still
// have the correct value

function int uvm_sequencer::m_find_number_driver_connections();
  uvm_port_base #(uvm_sqr_if_base #(REQ, RSP)) provided_to_port_list[string];
  
  // Check that the seq_item_pull_port is connected
  seq_item_export.get_provided_to(provided_to_port_list);
  return provided_to_port_list.num();
endfunction


// get_next_item
// -------------

task uvm_sequencer::get_next_item(output REQ t);
  REQ req_item;

  // If a sequence_item has already been requested, then get_next_item()
  // should not be called again until item_done() has been called.

  if (get_next_item_called == 1)
    uvm_report_error(get_full_name(),
      "Get_next_item called twice without item_done or get in between", UVM_NONE);
  
  m_safe_select_item(1, t);
endtask


// try_next_item
// -------------

task uvm_sequencer::try_next_item(output REQ t);
  int selected_sequence;
  uvm_sequence_request selected_sequence_request;
  bit found_item;
  time arb_time;

  if (get_next_item_called == 1) begin
    uvm_report_error(get_full_name(), "get_next_item/try_next_item called twice without item_done or get in between", UVM_NONE);
    return;
  end
    
  // allow state from last transaction to settle such that sequences'
  // relevancy can be determined with up-to-date information
  repeat (m_wait_for_sequences_count) begin
    wait_for_sequences();

    // choose the sequence based on relevancy
    selected_sequence = m_choose_next_request();

    if (selected_sequence != -1)
      break;
  end

  t = null;

  // return if none available
  while (selected_sequence != -1) begin
  
  // now, allow chosen sequence to resume
    selected_sequence_request = arb_sequence_q[selected_sequence];
    m_set_arbitration_completed(selected_sequence_request.request_id);
    arb_sequence_q.delete(selected_sequence);
    m_update_lists();
    sequence_item_requested = 1;
    get_next_item_called = 1;

    repeat (m_wait_for_sequences_count) begin
      // give it one NBA to put a new item in the fifo
      wait_for_sequences();

      // attempt to get the item; if it fails, produce an error and return
      found_item = m_req_fifo.try_peek(t);
      if (found_item)
        return;
    end
  
    // re-arbitrate if the sequence was killed or finished after it won arbitration but before it was
    // able to send its request.
    if (selected_sequence_request.process_id.status inside {process::KILLED,process::FINISHED}) begin
      // clean up arb_completed in case the sequence never saw that it won arbitration
      if (arb_completed.exists(selected_sequence_request.request_id)) begin
        arb_completed.delete(selected_sequence_request.request_id);
      end
      // choose the sequence based on relevancy
      selected_sequence = m_choose_next_request();
    end
    else begin        
      string msg = "try_next_item: the selected sequence '%s' did not produce an item within %0d wait_for_sequences call%s.  If the sequence requires more deltas/NBA within this time step, then the wait_for_sequences_count value for this sequencer should be increased.  Note that sequences should not consume non-delta/NBA time between calls to start_item and finish_item.  Returning null item.";
      `uvm_error("TRY_NEXT_BLOCKED", $sformatf(msg, selected_sequence_request.sequence_ptr.get_full_name(),m_wait_for_sequences_count,
                                               (m_wait_for_sequences_count>1)?"s":""))
      return;
    end // else: !if(selected_sequence_request.process_id.status inside {process::KILLED,process::FINISHED})

  end // while (selected_sequence != -1)

endtask


// item_done
// ---------

function void uvm_sequencer::item_done(RSP item = null);
  REQ t;

  // Set flag to allow next get_next_item or peek to get a new sequence_item
  sequence_item_requested = 0;
  get_next_item_called = 0;
  
  if (m_req_fifo.try_get(t) == 0) begin
    uvm_report_fatal("SQRBADITMDN", {"Item_done() called with no outstanding requests.",
      " Each call to item_done() must be paired with a previous call to get_next_item()."});
  end else begin
    m_wait_for_item_sequence_id = t.get_sequence_id();
    m_wait_for_item_transaction_id = t.get_transaction_id();
  end
  
  if (item != null) begin
    seq_item_export.put_response(item);
  end

  // Grant any locks as soon as possible
  grant_queued_locks();
endfunction


// put
// ---

task uvm_sequencer::put (RSP t);
  put_response(t);
endtask


// get
// ---

task uvm_sequencer::get(output REQ t);
  m_safe_select_item(0, t);
  item_done();
endtask


// peek
// ----

task uvm_sequencer::peek(output REQ t);
  m_safe_select_item(0, t);
endtask


// item_done_trigger
// -----------------

function void uvm_sequencer::item_done_trigger(RSP item = null);
  item_done(item);
endfunction
