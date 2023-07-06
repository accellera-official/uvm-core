//
//----------------------------------------------------------------------
// Copyright 2007-2009 Cadence Design Systems, Inc.
// Copyright 2022 Marvell International Ltd.
// Copyright 2007-2022 Mentor Graphics Corporation
// Copyright 2022 NVIDIA Corporation
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


// Class: uvm_phase_hopper
//
// The UVM phase hopper is responsible for the execution of the UVM phases
// during a test.
//
// The UVM Library is responsible for calling ~run_phases~ on the
// phase hopper after transitioning the state of the UVM core to 
// UVM_CORE_RUNNING.  The core shall stay in the RUNNING state until
// the run_phases task completes, at which point it shall transition
// to the UVM_CORE_POST_RUN state.
//
// Phases are added to the hopper via the ~try_set~ method,
// and are retrieved using the ~try_get~,~get~,~try_peek~, and ~peek~ methods.
// After retrieving a new phase, the ~run_phases~ task is responsible
// for transitioning the phase's state through the appropriate path
// (see <uvm_phase_state>).
//
//
// @uvm-contrib For potential contribution to the 1800.2 standard
class uvm_phase_hopper extends uvm_object;

  `uvm_object_utils(uvm_phase_hopper)

  // Function: new
  // Creates a new uvm_phase_hopper instance with ~name~.
  //
  extern function new(string name="uvm_phase_hopper");

  // Group: Singleton Accessors
  
  // Function: get_global_hopper
  // Returns the global phase hopper.
  //
  // This method is provided as a wrapper function to conveniently retrieve the
  // phase hopper via the <uvm_coreservice_t::get_phase_hopper> method.
  extern static function uvm_phase_hopper get_global_hopper();

  // Group: Queue API
  
  // Function: try_put
  // Attempts to add a new phase to the hopper.
  //
  // If the phase is successfully added to the internal queue, then
  // <raise_objection> is called for ~phase~, and '1' is returned.
  // If the phase can not be added to the internal queue, then no 
  // objection is raised and '0' is returned.
  //
  // NOTE - By default the internal queue has no maximum depth, and
  // as such this method shall always succeed.
  extern virtual function bit try_put(uvm_phase phase);

  // Task: get
  // Retrieves the next phase from the hopper.
  //
  // The ~get~ method retrieves the next phase from the hopper, that is, removes one 
  // phase from the internal queue.  If the internal queue is empty, then the current
  // process blocks until a phase is placed in the hopper.
  //
  extern protected virtual task get(output uvm_phase phase);

  // Task: try_get
  // Attempts to retrieve the next phase from the hopper.
  //
  // The ~try_get~ method attempts to retrieve the next phase from the hopper.
  // If no phases are available, then the method returns 0; otherwise returns
  // 1.
  extern protected virtual function bit try_get(inout uvm_phase phase);

  // Task: peek
  // Copies a phase from the hopper.
  //
  // The ~peek~ method copies a phase from the internal queue without removing it.
  // If the internal queue is empty, then the current process blocks until a phase
  // is placed in the hopper.
  extern protected virtual task peek(output uvm_phase phase);

  // Task: try_peek
  // Attempts to copy a phase from the hopper.
  //
  // The ~try_peek~ method attempts to copy a phase from the internal queue without
  // removing it.  If the internal queue is empty, then the method returns 0; otherwise
  // return 1.
  extern protected virtual function bit try_peek(inout uvm_phase phase);

  // Group: Active Phase Objection

  // Function: get_objection
  // Retrieves the Active Phase Objection.
  //
  // The Active Phase Objection is used to track phases being processed by the hopper, ie. phases
  // that have been added via a call to <try_put>, but have not yet completed processing 
  // via <process_phase>.
  //
  extern protected virtual function uvm_objection get_objection();

  // Function: raise_objection
  // This is a pass through to <uvm_objection::raise_objection> on the
  // objection returned by <get_objection>.
  extern protected virtual function void raise_objection(uvm_object obj,
                                                         string description = "",
                                                         int count=1);

  // Function: drop_objection
  // This is a pass through to <uvm_objection::drop_objection> on the
  // objection returned by <get_objection>.
  extern protected virtual function void drop_objection(uvm_object obj,
                                                        string description = "",
                                                        int count=1);

  // Function: get_objection_count
  // This is a pass through to <uvm_objection::get_objection_count> on the
  // objection returned by <get_objection>.
  extern virtual function int get_objection_count( uvm_object obj = null );

  // Function: get_objection_total
  // This is a pass through to <uvm_objection::get_objection_total> on the
  // objection returned by <get_objection>.
  extern virtual function int get_objection_total( uvm_object obj = null );

  // Function: wait_for_objection
  // This is a pass through to <uvm_objection::wait_for> on the objection
  // returned by <get_objection>.
  extern virtual task wait_for_objection( uvm_objection_event objt_event,
                                          uvm_object obj = null );

  
  // Group: Phase Graph Execution

  // Task: run_phases
  // Runs all phases associated with a test.
  //
  // The default implementation causes the following steps to occur
  // in order:
  // * <try_put> is passed <uvm_domain::get_common_domain>
  // * A process is forked in a non-blocking fashion.  The forked
  //   process runs a forever loop that calls <get>.  When ~get~
  //   returns, an additional process is forked in a non-blocking 
  //   fashion that performs the following steps in order:
  //   * <process_phase> is called with the return value of ~get~.
  //   * <drop_objection> is passed the return value of ~get~.
  // * The task is blocked, waiting on `wait_for_objection(UVM_ALL_DROPPED)`.
  //
  // Note that the UVM core state shall transition to UVM_CORE_POST_RUN
  // when ~run_phases~ returns.
  extern virtual task run_phases();

  // Task: process_phase
  // Processes a phase.
  //
  // The process_phase task transitions a phase from the SCHEDULED
  // to the DONE state.  
  //
  // It calls the following tasks in order:
  // - sync_phase
  // - start_phase
  // - execute_phase
  // - end_phase
  // - cleanup_phase
  // - finish_phase
  // 
  extern protected virtual task process_phase(uvm_phase phase);

  // Task: Transitions
  // Performs actions associated with transitioning phase state to the UVM_PHASE_SYNCING state.
  extern protected virtual task sync_phase(uvm_phase phase);

  // Task: start_phase
  // Performs actions associated with transitioning phase state to the UVM_PHASE_STARTED state.
  extern protected virtual task start_phase(uvm_phase phase);

  // Task: execute_phase
  // Performs actions associated with transitioning phase state to the UVM_PHASE_EXECUTING state.
  extern protected virtual task execute_phase(uvm_phase phase);

  // Task: end_phase
  // Performs actions associated with transitioning phase state to the UVM_PHASE_ENDED state.
  extern protected virtual task end_phase(uvm_phase phase);

  // Task: cleanup_phase
  // Performs actions associated with transitioning phase state to the UVM_PHASE_CLEANUP or UVM_PHASE_JUMPING state.
  extern protected virtual task cleanup_phase(uvm_phase phase);

  // Task: finish_phase
  // Performs actions associated with transitioning phase state to the UVM_PHASE_DONE state.
  extern protected virtual task finish_phase(uvm_phase phase);

  // Task: wait_for_waiters
  // Delays execution to allow waiters on phase state changes to react.
  //
  // By default, <wait_for_waiters> shall pause for a single delta cycle.
  extern protected virtual task wait_for_waiters(uvm_phase phase, uvm_phase_state prev_state);
  

  /// Group: Phase Component Traversal
  
  // Function: traverse_on
  // Calls ~traverse~ on ~imp~, passing in ~comp~, ~node~, and ~state~.
  //
  // The ~traverse_on~ function is a hook that allows the phase hopper
  // to witness, and potentially change how a phase traverses the
  // component hierarchy.
  //
  // By default, the ~traverse_on~ method calls <uvm_phase::traverse>
  // for ~imp~ on ~comp~, which will then in turn call ~traverse_on~ for all
  // of ~imp~ on all of ~comp~'s children.
  //
  // Depending on the traversal policy of ~imp~, the phase may be
  // executed on ~comp~ before or after ~traverse_on~ is called for
  // ~comp~'s children.
  //
  // If ~comp~ is null, then the default implementation shall pass
  // <uvm_root::get> to the traverse method.
  extern virtual function void traverse_on(uvm_phase imp,
                                           uvm_component comp,
                                           uvm_phase node,
                                           uvm_phase_state state);

  // Function: execute_on
  // Calls ~execute~ on ~imp~, passing in ~comp~, and ~node~.
  //
  // Similar the ~traverse_on~, the ~execute_on~ function is a hook
  // that allows the phase hopper to witness, and potentially change
  // how a phase executes on a component.
  //
  // By default, the ~execute_on~ method calls <uvm_phase::execute>
  // for ~imp~ on ~comp~.
  extern virtual function void execute_on(uvm_phase imp,
                                          uvm_component comp,
                                          uvm_phase node);
  
  /// Implementation Artifacts

  local uvm_phase m_queue[$]; // Internal storage
  local uvm_objection m_objection; // Tracks when all phases are complete
  
endclass // uvm_phase_hopper

/// Implementation

function uvm_phase_hopper::new(string name = "uvm_phase_hopper");
  super.new(name);
  m_objection = new("phase_hopper_objection");
endfunction : new

function uvm_phase_hopper uvm_phase_hopper::get_global_hopper();
  uvm_coreservice_t cs;
  cs = uvm_coreservice_t::get();
  return cs.get_phase_hopper();
endfunction : get_global_hopper

function bit uvm_phase_hopper::try_put(uvm_phase phase);
  raise_objection(phase, "phase scheduled"); // drop in run_phases
  m_queue.push_back(phase);
  return 1;
endfunction : try_put

task uvm_phase_hopper::get(output uvm_phase phase);
  wait (m_queue.size() != 0);
  phase = m_queue.pop_front();
endtask : get

function bit uvm_phase_hopper::try_get(inout uvm_phase phase);
  if (m_queue.size() > 0) begin
    phase = m_queue.pop_front();
    return 1;
  end
  else begin
    return 0;
  end
endfunction : try_get

task uvm_phase_hopper::peek(output uvm_phase phase);
  wait (m_queue.size() != 0);
  phase = m_queue[0];
endtask : peek

function bit uvm_phase_hopper::try_peek(inout uvm_phase phase);
  if (m_queue.size() > 0) begin
    phase = m_queue[0];
    return 1;
  end
  else begin
    return 0;
  end
endfunction : try_peek

function uvm_objection uvm_phase_hopper::get_objection();
  if (m_objection == null)
    m_objection = new("phase_hopper_objection");
  return m_objection;
endfunction : get_objection

function void uvm_phase_hopper::raise_objection(uvm_object obj,
                                                string description = "",
                                                int count=1);
  uvm_objection objection;
  objection = get_objection();
  objection.raise_objection(obj, description, count);
endfunction : raise_objection

function void uvm_phase_hopper::drop_objection(uvm_object obj,
                                               string description = "",
                                               int count=1);
  uvm_objection objection;
  objection = get_objection();
  objection.drop_objection(obj, description, count);
endfunction : drop_objection

function int uvm_phase_hopper::get_objection_count(uvm_object obj = null);
  uvm_objection objection;
  objection = get_objection();
  return objection.get_objection_count(obj);
endfunction : get_objection_count

function int uvm_phase_hopper::get_objection_total(uvm_object obj = null);
  uvm_objection objection;
  objection = get_objection();
  return objection.get_objection_total(obj);
endfunction : get_objection_total

task uvm_phase_hopper::wait_for_objection( uvm_objection_event objt_event,
                                           uvm_object obj = null );
  uvm_objection objection;
  objection = get_objection();
  objection.wait_for(objt_event, obj);
endtask : wait_for_objection

task uvm_phase_hopper::run_phases();
  // initiate by starting first phase in common domain
  uvm_phase ph;
  ph = uvm_domain::get_common_domain();
  void'(this.try_put(ph));

  fork
    begin
      forever begin
        this.get(ph);
        fork
          automatic uvm_phase phase = ph;
          begin
            this.process_phase(phase);
            drop_objection(phase, "phase done"); // raised in try_put
          end
        join_none
      end
    end
  join_none

  wait_for_objection(UVM_ALL_DROPPED);
endtask : run_phases

// Inside the sync stage 
task uvm_phase_hopper::sync_phase(uvm_phase phase);
  uvm_phase::edges_t edges;
  uvm_phase_state prev_state;
  // Scheduled phases must wait for all predecessors to complete
  phase.get_predecessors(edges);
  foreach(edges[p])
    p.wait_for_state(UVM_PHASE_DONE);

  prev_state = phase.get_state();
  phase.set_state(UVM_PHASE_SYNCING);
  wait_for_waiters(phase, prev_state);

  phase.get_sync_relationships(edges);
  foreach (edges[s])
    s.wait_for_state(UVM_PHASE_SYNCING, UVM_GTE);
endtask : sync_phase

// Inside the started stage
task uvm_phase_hopper::start_phase(uvm_phase phase);
  uvm_phase_state prev_state;
  `UVM_PH_TRACE("PH/TRC/STRT","Starting phase",phase,UVM_LOW)

  prev_state = phase.get_state();
  phase.set_state(UVM_PHASE_STARTED);

  // Only nodes traverse_on
  if (phase.get_phase_type() == UVM_PHASE_NODE) begin
    uvm_phase imp;
    imp = phase.get_imp();
    traverse_on(imp, null, phase, UVM_PHASE_STARTED);
  end
      
  wait_for_waiters(phase, prev_state);
endtask : start_phase

// Inside the executing stage
task uvm_phase_hopper::execute_phase(uvm_phase phase);
  uvm_phase_state prev_state;
  prev_state = phase.get_state();
  phase.set_state(UVM_PHASE_EXECUTING);

  // Only nodes traverse_on
  if (phase.get_phase_type() != UVM_PHASE_NODE) begin
    wait_for_waiters(phase, prev_state);
    return;
  end
  else begin
    uvm_root top;
    uvm_phase imp;
    uvm_task_phase task_phase;
    top = uvm_root::get();
    imp = phase.get_imp();
    if (!$cast(task_phase, imp)) begin
      // Non-Task (ie. Function) phase
      wait_for_waiters(phase, prev_state);
      traverse_on(imp, null, phase, UVM_PHASE_EXECUTING);
    end
    else begin
      // Task phases
      fork : master_phase_process
        begin
          phase.m_phase_proc = process::self();
          traverse_on(task_phase, null, phase, UVM_PHASE_EXECUTING);
          // This shouldn't be strictly necessary, as kill
          // should kill subprocesses even if the process
          // has ended, but leaving it in for compatibility.
          wait(0);
        end // else: !if(!$cast(task_phase, imp))
      join_none

      // Give sequences, etc. a chance to object
      uvm_wait_for_nba_region();

      // Wait for one of three criterion to end-of-phase:
      // - JUMP (Premature end)
      // - ALL DROPPED
      // - TIMEOUT
      fork
        begin // guard
          
          fork
            begin // JUMP (Premature end)
              wait (phase.m_premature_end);
              `UVM_PH_TRACE("PH/TRC/EXE/JUMP","PHASE EXIT ON JUMP REQUEST",phase,UVM_DEBUG)
            end // JUMP (Premature end)
            
            begin // ALL DROPPED
              int unsigned ready_to_end_count;
              bit do_ready_to_end; // bit used for ready_to_end iterations
              uvm_objection phase_done;
              phase_done = phase.get_objection();
              // OVM semantic: don't end until objection raised or stop request
              if (phase_done.get_objection_total(top) ||
                  phase.m_use_ovm_run_semantic && imp.get_name() == "run") begin
                if (!phase_done.m_top_all_dropped)
                  phase_done.wait_for(UVM_ALL_DROPPED, top);
                `UVM_PH_TRACE("PH/TRC/EXE/ALLDROP","PHASE EXIT ALL_DROPPED",phase,UVM_DEBUG)
              end
              else begin
                `UVM_PH_TRACE("PH/TRC/SKIP","No objections raised, skipping phase",phase,UVM_LOW)
              end
              
              phase.wait_for_self_and_siblings_to_drop() ;
              do_ready_to_end = 1;
              
              //--------------
              // READY_TO_END:
              //--------------
              
              while (do_ready_to_end) begin
                uvm_wait_for_nba_region(); // Let all siblings see no objections before traverse_on might raise another 
                `UVM_PH_TRACE("PH_READY_TO_END","PHASE READY TO END",phase,UVM_DEBUG)
                ready_to_end_count++;
                `UVM_PH_TRACE("PH_READY_TO_END_CB","CALLING READY_TO_END CB",phase,UVM_HIGH)
                phase.set_state(UVM_PHASE_READY_TO_END);
                if (imp != null)
                  traverse_on(imp, null, phase, UVM_PHASE_READY_TO_END);
                
                uvm_wait_for_nba_region(); // Give traverse_on targets a chance to object 
                
                phase.wait_for_self_and_siblings_to_drop();
                do_ready_to_end = (phase.get_state() == UVM_PHASE_EXECUTING) && 
                                  (ready_to_end_count < phase.get_max_ready_to_end_iterations()) ; //when we don't wait in task above, we drop out of while loop
              end
            end // ALL DROPPED
            
            begin // TIMEOUT
              if (phase.get_name() == "run") begin
                string delay_type;
                time   delay_time;
                uvm_object objectors[$];
                if (top.phase_timeout == 0)
                  wait(top.phase_timeout != 0);
                `UVM_PH_TRACE("PH/TRC/TO_WAIT", 
                              $sformatf("STARTING PHASE TIMEOUT WATCHDOG (timeout == %t)", top.phase_timeout), 
                              phase, UVM_HIGH)
                `uvm_delay(top.phase_timeout)
                if ($time == `UVM_DEFAULT_TIMEOUT) begin
                  delay_type = "Default";
                  delay_time = `UVM_DEFAULT_TIMEOUT;
                end
                else begin
                  delay_type = "Explicit";
                  delay_time = top.phase_timeout;
                end
                
                `UVM_PH_TRACE("PH/TRC/TIMEOUT", "PHASE TIMEOUT WATCHDOG EXPIRED", phase, UVM_LOW)
                m_objection.get_objectors(objectors);
                foreach (objectors[i]) begin
                  uvm_phase p;
                  if ($cast(p, objectors[i])) begin
		    uvm_objection p_done;
		    p_done = p.get_objection();
                    if ((p_done != null) && (p_done.get_objection_total() > 0)) begin
                      `UVM_PH_TRACE("PH/TRC/TIMEOUT/OBJCTN", 
                                    $sformatf("Phase '%s' has outstanding objections:\n%s", p.get_full_name(), p_done.convert2string()),
                                    phase,
                                    UVM_LOW)
                    end
                  end // $cast
                end // foreach (objectors[i])
                
                `uvm_fatal("PH_TIMEOUT",
                           $sformatf("%s timeout of %0t hit, indicating a probable testbench issue",
                                     delay_type, delay_time)
                           )
                
              end // if (phase.get_name() == "run")
              else begin
                wait (0); // never unblock for non-run phase
              end
            end // TIMEOUT
            
          join_any
          disable fork;
          
        end // fork begin
        
      join // guard
      
    end // else: !if(!$cast(task_phase, imp))
    
  end // else: !if(phase.get_type() != UVM_PHASE_NODE)
  
endtask : execute_phase

task uvm_phase_hopper::end_phase(uvm_phase phase);
  if (phase.get_phase_type() == UVM_PHASE_NODE) begin
    uvm_phase_state prev_state;
    uvm_phase imp;
    prev_state = phase.get_state();
    imp = phase.get_imp();

    if(phase.m_premature_end) begin
      uvm_phase jump_phase;
      jump_phase = phase.get_jump_target();
      if(jump_phase != null) begin 
        `uvm_info("PH_JUMP",
              $sformatf("phase %s (schedule %s, domain %s) is jumping to phase %s",
                        phase.get_name(), 
                        phase.get_schedule_name(), 
                        phase.get_domain_name(), 
                        jump_phase.get_name()),
              UVM_MEDIUM)
      end
      else begin
        `uvm_info("PH_JUMP",
              $sformatf("phase %s (schedule %s, domain %s) is ending prematurely",
                        phase.get_name(), 
                        phase.get_schedule_name(), 
                        phase.get_domain_name()),
              UVM_MEDIUM)
      end
  
      wait_for_waiters(phase, prev_state); // LET ANY WAITERS ON READY_TO_END TO WAKE UP
      `UVM_PH_TRACE("PH_END","ENDING PHASE PREMATURELY",phase,UVM_HIGH)
      
    end
    else begin
      // WAIT FOR PREDECESSORS:  // WAIT FOR PREDECESSORS:
      // function phases only
      uvm_task_phase task_phase;
      if (!$cast(task_phase, phase.get_imp()))
        phase.m_wait_for_pred();
    end
  
    //-------
    // ENDED:
    //-------
    // execute 'phase_ended' callbacks
    `UVM_PH_TRACE("PH_END","ENDING PHASE",phase,UVM_HIGH)
    phase.set_state(UVM_PHASE_ENDED);
    if (imp != null)
      traverse_on(imp, null, phase, UVM_PHASE_ENDED);
    wait_for_waiters(phase, prev_state);
  end // if (phase_type == UVM_PHASE_NODE)
 
endtask : end_phase

task uvm_phase_hopper::cleanup_phase(uvm_phase phase);

  // Only nodes need cleanup/jumping
  if (phase.get_phase_type() == UVM_PHASE_NODE) begin
    uvm_objection phase_done;
    uvm_phase_state prev_state;
    prev_state = phase.get_state();
    // kill this phase's threads
    if(phase.m_premature_end) 
      phase.set_state(UVM_PHASE_JUMPING);
    else
      phase.set_state(UVM_PHASE_CLEANUP);

    if (phase.m_phase_proc != null) begin
      phase.m_phase_proc.kill();
      phase.m_phase_proc = null;
    end
    wait_for_waiters(phase, prev_state);
    phase_done = phase.get_objection();
    if (phase_done != null)
      phase_done.clear();
  end // if (phase_type == UVM_PHASE_NODE)
  
endtask : cleanup_phase
  
task uvm_phase_hopper::finish_phase(uvm_phase phase);
  uvm_objection phase_done;
  uvm_phase jump_phase;
  uvm_phase_state prev_state;

  phase_done = phase.get_objection();
  jump_phase = phase.get_jump_target();
  prev_state = phase.get_state();
  
  // If jump_to() was called then we need to clear all the successor
  // phases which may still be running and then initiate the new
  // phase.  If we are doing a forward jump then we want to set the
  // state of this phase's successors to UVM_PHASE_DONE.  This
  // will let us pretend that all the phases between here and there
  // were executed and completed.  Thus any dependencies will be
  // satisfied preventing deadlocks.

  if(jump_phase != null) begin
    if(phase.is_jumping_forward()) begin
      phase.clear_successors(UVM_PHASE_DONE,jump_phase);
    end
    jump_phase.clear_successors();
    phase.set_jump_phase(null);
  end
  else begin
    
    `UVM_PH_TRACE("PH/TRC/DONE","Completed phase",phase,UVM_LOW)
    phase.set_state(UVM_PHASE_DONE);
    phase.m_phase_proc = null;
  end

  wait_for_waiters(phase, prev_state);
  begin
    if (phase_done != null)
      phase_done.clear();
  end

  //-----------
  // SCHEDULE:
  //-----------
  if(jump_phase != null) begin
    void'(this.try_put(jump_phase));
    `UVM_PH_TRACE("PH/TRC/SCHEDULED",{"Scheduled from phase ",phase.get_full_name()},jump_phase,UVM_LOW)
  end
  else begin
    uvm_phase::edges_t edges;
    uvm_phase succ_q[$];
    phase.get_successors(edges);
    if (edges.size() != 0) begin
      // Need to sort the list
      uvm_phase succ;

      foreach (edges[succ])
        succ_q.push_back(succ);
      succ_q.sort with ( item.get_full_name() );

      // execute all the successors
      foreach (succ_q[i]) begin
        uvm_phase_state succ_prev_state;
        succ = succ_q[i];
        succ_prev_state = succ.get_state();
        if(succ_prev_state < UVM_PHASE_SCHEDULED) begin
          succ.set_state(UVM_PHASE_SCHEDULED);
          wait_for_waiters(succ, succ_prev_state);
          void'(this.try_put(succ));
        `UVM_PH_TRACE("PH/TRC/SCHEDULED",{"Scheduled from phase ",phase.get_full_name()},succ,UVM_LOW)
        end
      end
    end
  end
  
endtask : finish_phase

  
task uvm_phase_hopper::process_phase(uvm_phase phase);

    sync_phase(phase);
    start_phase(phase);
    execute_phase(phase);
    end_phase(phase);
    cleanup_phase(phase);
    finish_phase(phase);
    
endtask : process_phase

task uvm_phase_hopper::wait_for_waiters(uvm_phase phase, uvm_phase_state prev_state);
  #0;
endtask : wait_for_waiters

function void uvm_phase_hopper::traverse_on(uvm_phase imp,
                                            uvm_component comp,
                                            uvm_phase node,
                                            uvm_phase_state state);
  if (comp == null)
    comp = uvm_root::get();
  imp.traverse(comp, node, state);
endfunction : traverse_on

function void uvm_phase_hopper::execute_on(uvm_phase imp,
                                           uvm_component comp,
                                           uvm_phase node);
  imp.execute(comp, node);
endfunction : execute_on
  
