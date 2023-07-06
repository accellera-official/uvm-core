//----------------------------------------------------------------------
// Copyright 2010-2022 AMD
// Copyright 2015 Analog Devices, Inc.
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2017-2018 Cisco Systems, Inc.
// Copyright 2011-2012 Cypress Semiconductor Corp.
// Copyright 2017 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2010-2018 Mentor Graphics Corporation
// Copyright 2013-2022 NVIDIA Corporation
// Copyright 2010-2011 Paradigm Works
// Copyright 2014 Semifore
// Copyright 2010-2014 Synopsys, Inc.
// Copyright 2017-2018 Verific
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
// Class - get_t
//
// Instances of get_t are stored in the history list as a record of each
// get.  Failed gets are indicated with rsrc set to ~null~.  This is part
// of the audit trail facility for resources.
//----------------------------------------------------------------------
class get_t;
  string name;
  string scope;
  uvm_resource_base rsrc;
  time t;
endclass

typedef class uvm_tree_printer ;

// Title: Resources

//----------------------------------------------------------------------
// Class -- NODOCS -- uvm_resource_pool
//
// The global (singleton) resource database.
//
// Each resource is stored both by primary name and by type handle.  The
// resource pool contains two associative arrays, one with name as the
// key and one with the type handle as the key.  Each associative array
// contains a queue of resources.  Each resource has a regular
// expression that represents the set of scopes over which it is visible.
//
//|  +------+------------+                          +------------+------+
//|  | name | rsrc queue |                          | rsrc queue | type |
//|  +------+------------+                          +------------+------+
//|  |      |            |                          |            |      |
//|  +------+------------+                  +-+-+   +------------+------+
//|  |      |            |                  | | |<--+---*        |  T   |
//|  +------+------------+   +-+-+          +-+-+   +------------+------+
//|  |  A   |        *---+-->| | |           |      |            |      |
//|  +------+------------+   +-+-+           |      +------------+------+
//|  |      |            |      |            |      |            |      |
//|  +------+------------+      +-------+  +-+      +------------+------+
//|  |      |            |              |  |        |            |      |
//|  +------+------------+              |  |        +------------+------+
//|  |      |            |              V  V        |            |      |
//|  +------+------------+            +------+      +------------+------+
//|  |      |            |            | rsrc |      |            |      |
//|  +------+------------+            +------+      +------------+------+
//
// The above diagrams illustrates how a resource whose name is A and
// type is T is stored in the pool.  The pool contains an entry in the
// type map for type T and an entry in the name map for name A.  The
// queues in each of the arrays each contain an entry for the resource A
// whose type is T.  The name map can contain in its queue other
// resources whose name is A which may or may not have the same type as
// our resource A.  Similarly, the type map can contain in its queue
// other resources whose type is T and whose name may or may not be A.
//
// Resources are added to the pool by calling <set>; they are retrieved
// from the pool by calling <get_by_name> or <get_by_type>.  When an object 
// creates a new resource and calls <set> the resource is made available to be
// retrieved by other objects outside of itself; an object gets a
// resource when it wants to access a resource not currently available
// in its scope.
//
// The scope is stored in the resource itself (not in the pool) so
// whether you get by name or by type the resource's visibility is
// the same.
//
// As an auditing capability, the pool contains a history of gets.  A
// record of each get, whether by <get_by_type> or <get_by_name>, is stored 
// in the audit record.  Both successful and failed gets are recorded. At
// the end of simulation, or any time for that matter, you can dump the
// history list.  This will tell which resources were successfully
// located and which were not.  You can use this information
// to determine if there is some error in name, type, or
// scope that has caused a resource to not be located or to be incorrectly
// located (i.e. the wrong resource is located).
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Class: uvm_resource_pool
//
// The library implements the following public API beyond what is 
// documented in 1800.2.
//----------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto C.2.4.1
class uvm_resource_pool;

`ifndef UVM_DISABLE_RESOURCE_POOL_SHARED_QUEUE
  typedef uvm_resource_types::rsrc_shared_q_t table_q_t;
 `define M__TABLE_Q(QUEUE_NAME) QUEUE_NAME``.value
 `define M__TABLE_GET(QUEUE_NAME, ITER) QUEUE_NAME``.value[ITER]
 `define M__TABLE_NAME "uvm_shared#(uvm_resource_base[$])"
    
`else
  typedef uvm_resource_types::rsrc_q_t table_q_t;
 `define M__TABLE_Q(QUEUE_NAME) QUEUE_NAME
 `define M__TABLE_GET(QUEUE_NAME, ITER) QUEUE_NAME``.get(ITER)
 `define M__TABLE_NAME "uvm_queue#(uvm_resource_base)"
    
`endif // !`ifdef UVM_DISABLE_RESOURCE_POOL_SHARED_QUEUE

  table_q_t rtab [string];
  table_q_t ttab [uvm_resource_base];

  get_t get_record [$];  // history of gets

  // @uvm-ieee 1800.2-2020 auto C.2.4.2.1
  function new();
  endfunction


  // Function -- NODOCS -- get
  //
  // Returns the singleton handle to the resource pool

  // @uvm-ieee 1800.2-2020 auto C.2.4.2.2
  static function uvm_resource_pool get();
    uvm_resource_pool t_rp;
    uvm_coreservice_t cs = uvm_coreservice_t::get();
    t_rp = cs.get_resource_pool();
    return t_rp;
  endfunction


  // Function -- NODOCS -- spell_check
  //
  // Invokes the spell checker for a string s.  The universe of
  // correctly spelled strings -- i.e. the dictionary -- is the name
  // map.

  function bit spell_check(string s);
    return uvm_spell_chkr#(table_q_t)::check(rtab, s);
  endfunction

  //-----------
  // Group -- NODOCS -- Set
  //-----------

  // Function -- NODOCS -- set
  //
  // Add a new resource to the resource pool.  The resource is inserted
  // into both the name map and type map so it can be located by
  // either.
  //
  // An object creates a resources and ~sets~ it into the resource pool.
  // Later, other objects that want to access the resource must ~get~ it
  // from the pool
  //
  // Overrides can be specified using this interface.  Either a name
  // override, a type override or both can be specified.  If an
  // override is specified then the resource is entered at the front of
  // the queue instead of at the back.  It is not recommended that users
  // specify the override parameter directly, rather they use the
  // <set_override>, <set_name_override>, or <set_type_override>
  // functions.
  //

  //@uvm-compat provided for compatibility with 1.2
  function void set (uvm_resource_base rsrc, 
                     uvm_resource_types::override_t override = 0);

    // If resource handle is ~null~ then there is nothing to do.
    if (rsrc == null) return ;
    if (override) 
        set_override(rsrc, rsrc.get_scope()) ;
    else
        set_scope(rsrc, rsrc.get_scope()) ; 

  endfunction

  // @uvm-ieee 1800.2-2020 auto C.2.4.3.1
  function void set_scope (uvm_resource_base rsrc, string scope); 

    table_q_t rq;
    string name;
    uvm_resource_base type_handle;
    uvm_resource_base r;
    int unsigned i;

    // If resource handle is ~null~ then there is nothing to do.
    if(rsrc == null) begin
      uvm_report_warning("NULLRASRC", "attempting to set scope of a null resource");
      return;
    end

    // Insert into the name map.  Resources with empty names are
    // anonymous resources and are not entered into the name map
    name = rsrc.get_name();
    if ((name != "") && rtab.exists(name)) begin
      rq = rtab[name];

      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        if (`M__TABLE_GET(rq, iter) == rsrc) begin
          // Resource is already in pool, just change the scope
          rsrc.m_set_scope(scope);
          return;
        end
      end
    end 

    // If the name is new to the pool, create the new queue in
    // the name table
    if (rq == null) begin
      rq = new();
      rtab[name] = rq;
    end 

    // Insert the resource into the queue associated with its name.
    // Insert it with low priority (in the back of queue).
    `M__TABLE_Q(rq).push_back(rsrc);
    
    // Insert into the type map
    type_handle = rsrc.get_type_handle();
    if(ttab.exists(type_handle)) begin
      rq = ttab[type_handle];
    end
    else begin
      rq = new();
      ttab[type_handle] = rq;
    end

    // Insert the resource into the queue associated with its type.  
    // Insert it with low priority (in the back of queue).
    `M__TABLE_Q(rq).push_back(rsrc);

    // Set the scope of resource. 
    rsrc.m_set_scope(scope);
    rsrc.precedence = get_default_precedence(); 

  endfunction


  // Function -- NODOCS -- set_override
  //
  // The resource provided as an argument will be entered into the pool
  // and will override both by name and type.
  // Default value to 'scope' argument is violating 1800.2-2017 LRM, but it
  // is added to make the routine backward compatible

  // @uvm-ieee 1800.2-2020 auto C.2.4.3.2
  function void set_override(uvm_resource_base rsrc, string scope="<not provided>");
     string s ;
     if (rsrc == null) begin
        uvm_report_warning("NULLRASRC", "attempting to change the search priority of a null resource");
        return;
     end
     if (scope == "<not provided>") s = rsrc.get_scope();
     else s = scope ;
     set_scope(rsrc, s);
     set_priority(rsrc, uvm_resource_types::PRI_HIGH);
  endfunction


  // Function -- NODOCS -- set_name_override
  //
  // The resource provided as an argument will entered into the pool
  // using normal precedence in the type map and will override the name.
  // Default value to 'scope' argument is violating 1800.2-2017 LRM, but it
  // is added to make the routine backward compatible

  // @uvm-ieee 1800.2-2020 auto C.2.4.3.3
  function void set_name_override(uvm_resource_base rsrc, string scope="<not provided>");
    string s ;
    if (rsrc == null) begin
        uvm_report_warning("NULLRASRC", "attempting to change the search priority of a null resource");
        return;
    end
    if (scope == "<not provided>") s = rsrc.get_scope();
    else s = scope ;
    set_scope(rsrc, s);
    set_priority_name(rsrc, uvm_resource_types::PRI_HIGH);
  endfunction


  // Function -- NODOCS -- set_type_override
  //
  // The resource provided as an argument will be entered into the pool
  // using normal precedence in the name map and will override the type.
  // Default value to 'scope' argument is violating 1800.2-2017 LRM, but it
  // is added to make the routine backward compatible

  // @uvm-ieee 1800.2-2020 auto C.2.4.3.4
  function void set_type_override(uvm_resource_base rsrc, string scope="<not provided>");
    string s ;
    if (rsrc == null) begin
        uvm_report_warning("NULLRASRC", "attempting to change the search priority of a null resource");
        return;
    end
    if (scope == "<not provided>") s = rsrc.get_scope();
    else s = scope ;
    set_scope(rsrc, s);
    set_priority_type(rsrc, uvm_resource_types::PRI_HIGH);
  endfunction

  
  // @uvm-ieee 1800.2-2020 auto C.2.4.3.5
  virtual function bit get_scope(uvm_resource_base rsrc,
                                 output string scope);

    table_q_t rq;
    string name;
    uvm_resource_base r, type_handle;
    int unsigned i;

    // If resource handle is ~null~ then there is nothing to do.
    if(rsrc == null) 
      return 0;

    // Search the resouce in the name map.  Resources with empty names are
    // anonymous resources and are not entered into the name map
    name = rsrc.get_name();
    if((name != "") && rtab.exists(name)) begin
      rq = rtab[name];

      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        if (`M__TABLE_GET(rq, iter) == rsrc) begin
          // Resource is in the name table, output the scope
          scope = rsrc.get_scope();
          return 1;
        end
      end
    end

    // Resource is not in the name table, check the type table
    // (note that this is likely less efficient, so it comes second)
    type_handle = rsrc.get_type_handle();
    if (ttab.exists(type_handle)) begin
      rq = ttab[type_handle];
      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        if (`M__TABLE_GET(rq, iter) == rsrc) begin
          // Resource is in the type table, output the scope
          scope = rsrc.get_scope();
          return 1;
        end
      end
    end
    
    // Resource is not in pool
    scope = "";
    return 0;

  endfunction

  // Function -- NODOCS -- delete
  // 
  // If rsrc exists within the pool, then it is removed from all internal maps. If the rsrc is null, or does not exist
  // within the pool, then the request is silently ignored.

 
  // @uvm-ieee 1800.2-2020 auto C.2.4.3.6
  virtual function void delete ( uvm_resource_base rsrc );
    string name;
    table_q_t rq;
    uvm_resource_base type_handle;
    int    iter;

    if (rsrc != null) begin
      
      name = rsrc.get_name();
      if(name != "") begin
        if(rtab.exists(name)) begin
          rq = rtab[name];
          iter = 0;
          
          while (iter < `M__TABLE_Q(rq).size()) begin
            if (`M__TABLE_GET(rq, iter) == rsrc) begin
              `M__TABLE_Q(rq).delete(iter);
              break;
            end
            iter++;
          end
        end // if (rtab.exists(name))
      end // if (name != "")
        
      type_handle = rsrc.get_type_handle();
      if(ttab.exists(type_handle)) begin
        rq = ttab[type_handle];
        iter = 0;

        while (iter < `M__TABLE_Q(rq).size()) begin
          if (`M__TABLE_GET(rq, iter) == rsrc) begin
            `M__TABLE_Q(rq).delete(iter);
            break;
          end
          iter++;
        end
      end // if (ttab.exists(type_handle))
      
    end // if (rsrc != null)
    
  endfunction


  // function - push_get_record
  //
  // Insert a new record into the get history list.

  function void push_get_record(string name, string scope,
                                  uvm_resource_base rsrc);
    get_t impt;

    // if auditing is turned off then there is no reason
    // to save a get record
    if(!uvm_resource_options::is_auditing())
      return;

    impt = new();

    impt.name  = name;
    impt.scope = scope;
    impt.rsrc  = rsrc;
    impt.t     = $realtime;

    get_record.push_back(impt);
  endfunction

  // function - dump_get_records
  //
  // Format and print the get history list.

  function void dump_get_records();

    get_t record;
    bit success;
    string qs[$];

    qs.push_back("--- resource get records ---\n");
    foreach (get_record[i]) begin
      record = get_record[i];
      success = (record.rsrc != null);
      qs.push_back($sformatf("get: name=%s  scope=%s  %s @ %0t\n",
               record.name, record.scope,
               ((success)?"success":"fail"),
               record.t));
    end
    `uvm_info("UVM/RESOURCE/GETRECORD",`UVM_STRING_QUEUE_STREAMING_PACK(qs),UVM_NONE)
  endfunction

  //--------------
  // Group -- NODOCS -- Lookup
  //--------------
  //
  // This group of functions is for finding resources in the resource database.  
  //
  // <lookup_name> and <lookup_type> locate the set of resources that
  // matches the name or type (respectively) and is visible in the
  // current scope.  These functions return a queue of resources.
  //
  // <get_highest_precedence> traverse a queue of resources and
  // returns the one with the highest precedence -- i.e. the one whose
  // precedence member has the highest value.
  //
  // <get_by_name> and <get_by_type> use <lookup_name> and <lookup_type>
  // (respectively) and <get_highest_precedence> to find the resource with
  // the highest priority that matches the other search criteria.


  // Function -- NODOCS -- lookup_name
  //
  // Lookup resources by ~name~.  Returns a queue of resources that
  // match the ~name~, ~scope~, and ~type_handle~.  If no resources
  // match the queue is returned empty. If ~rpterr~ is set then a
  // warning is issued if no matches are found, and the spell checker is
  // invoked on ~name~.  If ~type_handle~ is ~null~ then a type check is
  // not made and resources are returned that match only ~name~ and
  // ~scope~.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.1
  function uvm_resource_types::rsrc_q_t lookup_name(string scope = "",
                                                    string name,
                                                    uvm_resource_base type_handle = null,
                                                    bit rpterr = 1);
    table_q_t rq;
    uvm_resource_types::rsrc_q_t q;
    uvm_resource_base rsrc;
    uvm_resource_base r;
    string rsrcs;

     // ensure rand stability during lookup
     begin
	process p = process::self();
	string s;
	if(p!=null) s=p.get_randstate();
	q=new();
	if(p!=null) p.set_randstate(s);
     end

     
    // resources with empty names are anonymous and do not exist in the name map
    if(name == "")
      return q;

    // Does an entry in the name map exist with the specified name?
    // If not, then we're done
    if(!rtab.exists(name)) begin
      if(rpterr) void'(spell_check(name));	
      return q;
    end	

    rsrc = null;
    rq = rtab[name];
    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      uvm_resource_base rsrc_iter;
      rsrc_iter = `M__TABLE_GET(rq, iter);
      rsrcs = rsrc_iter != null ? rsrc_iter.get_scope(): "";
      // does the type and scope match?
      if(((type_handle == null) || (rsrc_iter.get_type_handle() == type_handle)) 
         && uvm_is_match(rsrcs, scope))
        q.push_back(rsrc_iter);
    end

    return q;
  endfunction

  // Function -- NODOCS -- get_highest_precedence
  //
  // Traverse a queue, ~q~, of resources and return the one with the highest
  // precedence.  In the case where there exists more than one resource
  // with the highest precedence value, the first one that has that
  // precedence will be the one that is returned.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.2
  static function uvm_resource_base get_highest_precedence(ref uvm_resource_types::rsrc_q_t q);

    uvm_resource_base rsrc;
    uvm_resource_base r;
    int unsigned i;
    int unsigned prec;
    int unsigned c_prec;

    if(q.size() == 0)
      return null;

    // get the first resources in the queue
    rsrc = q.get(0);
    prec = (rsrc != null) ? rsrc.precedence: 0;

    // start searching from the second resource
    for(int i = 1; i < q.size(); ++i) begin
      r = q.get(i);
      c_prec = (r != null) ? r.precedence: 0;
      if(c_prec > prec) begin
        rsrc = r;
        prec = c_prec;
      end
    end

    return rsrc;

  endfunction

  // Function -- NODOCS -- sort_by_precedence
  //
  // Given a list of resources, obtained for example from <lookup_scope>,
  // sort the resources in  precedence order. The highest precedence
  // resource will be first in the list and the lowest precedence will
  // be last. Resources that have the same precedence and the same name
  // will be ordered by most recently set first.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.3
  static function void sort_by_precedence(ref uvm_resource_types::rsrc_q_t q);
    uvm_resource_types::rsrc_sv_q_t all[int];
    uvm_resource_base r;
    int unsigned prec;

    for(int i=0; i<q.size(); ++i) begin
      r = q.get(i);
      prec = (r != null) ? r.precedence: 0;
      all[prec].push_front(r); //since we will push_front in the final
    end
    q.delete();
    foreach(all[aa_iter,q_iter]) begin
      q.push_front(all[aa_iter][q_iter]);
    end
  endfunction // sort_by_precedence

  // Function -- NODOCS -- sort_by_precedence_q
  //
  // Sorts a list of resources of resources in a standard SV
  // queue instead of a uvm_queue.
  static function void sort_by_precedence_q(ref uvm_resource_types::rsrc_sv_q_t q);
    uvm_resource_types::rsrc_sv_q_t all[int];
    uvm_resource_base r;
    int unsigned prec;

    for(int i=0; i<q.size(); ++i) begin
      r = q[i];
      prec = (r != null) ? r.precedence: 0;
      all[prec].push_back(r);
    end
    q.delete();
    foreach(all[iter]) begin
      q = {q, all[iter]};
    end
  endfunction // sort_by_precedence_q    


  // Function -- NODOCS -- get_by_name
  //
  // Lookup a resource by ~name~, ~scope~, and ~type_handle~.  Whether
  // the get succeeds or fails, save a record of the get attempt.  The
  // ~rpterr~ flag indicates whether to report errors or not.
  // Essentially, it serves as a verbose flag.  If set then the spell
  // checker will be invoked and warnings about multiple resources will
  // be produced.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.4
  function uvm_resource_base get_by_name(string scope = "",
                                         string name,
                                         uvm_resource_base type_handle,
                                         bit rpterr = 1);

    uvm_resource_types::rsrc_sv_q_t svq;

    table_q_t rq;
    uvm_resource_base rsrc;

    string rsrcs;
      
    // Empty names are anonymous and do not exist in the name map
    if (name == "") begin
      push_get_record(name, scope, null);
      return null;
    end

    // Does an entry in the name map exist with the specified name?
    // If not, then we're done
    if(!rtab.exists(name)) begin
      if(rpterr) void'(spell_check(name));	
      push_get_record(name, scope, null);
      return null;
    end	

    // Find all resource for name, optionally filtering by type
    rq = rtab[name];
    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      uvm_resource_base rsrc_iter;
      rsrc_iter = `M__TABLE_GET(rq, iter);
      if ((type_handle == null) || (type_handle == rsrc_iter.get_type_handle())) begin
        svq.push_back(rsrc_iter);
      end
    end

    // Sort the resource queue
    sort_by_precedence_q(svq);

    // Return the first scope match
    foreach (svq[iter]) begin
      rsrc = svq[iter];
      rsrcs = (rsrc != null) ? rsrc.get_scope(): "";
      if (uvm_is_match(rsrcs, scope))
        break;
      else
        rsrc = null;
    end
 
    push_get_record(name, scope, rsrc);
    return rsrc;

  endfunction


  // Function -- NODOCS -- lookup_type
  //
  // Lookup resources by type. Return a queue of resources that match
  // the ~type_handle~ and ~scope~.  If no resources match then the returned
  // queue is empty.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.5
  function uvm_resource_types::rsrc_q_t lookup_type(string scope = "",
                                                    uvm_resource_base type_handle);

    uvm_resource_types::rsrc_q_t q = new();
    table_q_t rq;
    uvm_resource_base r;
    int unsigned i;

    if(type_handle == null || !ttab.exists(type_handle)) begin
      return q;
    end

    rq = ttab[type_handle];
    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      uvm_resource_base rsrc_iter;
      rsrc_iter = `M__TABLE_GET(rq, iter);
      if(rsrc_iter != null && uvm_is_match(rsrc_iter.get_scope(), scope))
        q.push_back(rsrc_iter);
    end

    return q;

  endfunction

  // Function -- NODOCS -- get_by_type
  //
  // Lookup a resource by ~type_handle~ and ~scope~.  Insert a record into
  // the get history list whether or not the get succeeded.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.6
  function uvm_resource_base get_by_type(string scope = "",
                                         uvm_resource_base type_handle);

    table_q_t rq;
    uvm_resource_base r;
    int unsigned i;

    // No type handle, or type handle not in type table
    if(type_handle == null || !ttab.exists(type_handle)) begin
      push_get_record("<type>", scope, null);
      return null;
    end

    // Find first matching scope in type table
    rq = ttab[type_handle];
    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      uvm_resource_base rsrc_iter;
      rsrc_iter = `M__TABLE_GET(rq, iter);
      if(rsrc_iter != null && uvm_is_match(rsrc_iter.get_scope(), scope)) begin
        push_get_record("<type>", scope, rsrc_iter);
        return rsrc_iter;
      end
    end

    // No matching scopes in type table
    push_get_record("<type>", scope, null);
    return null;

  endfunction

  // Function -- NODOCS -- lookup_regex_names
  //
  // This utility function answers the question, for a given ~name~,
  // ~scope~, and ~type_handle~, what are all of the resources with requested name,
  // a matching scope (where the resource scope may be a
  // regular expression), and a matching type? 
  // ~name~ and ~scope~ are explicit values.

  function uvm_resource_types::rsrc_q_t lookup_regex_names(string scope,
                                                           string name,
                                                           uvm_resource_base type_handle = null);
      return lookup_name(scope, name, type_handle, 0);
  endfunction

  // Function -- NODOCS -- lookup_regex
  //
  // Looks for all the resources whose name matches the regular
  // expression argument and whose scope matches the current scope.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.7
  function uvm_resource_types::rsrc_q_t lookup_regex(string re, scope);

    table_q_t rq;
    uvm_resource_types::rsrc_q_t result_q;
    int unsigned i;
    uvm_resource_base r;
    string s;

    result_q = new();

    foreach (rtab[name]) begin
      if ( ! uvm_is_match(re, name) ) begin
        continue;
      end
      rq = rtab[name];
      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        uvm_resource_base rsrc_iter;
        rsrc_iter = `M__TABLE_GET(rq, iter);
        if(rsrc_iter != null && uvm_is_match(rsrc_iter.get_scope(), scope))
          result_q.push_back(rsrc_iter);
      end
    end

    return result_q;

  endfunction

  // Function -- NODOCS -- lookup_scope
  //
  // This is a utility function that answers the question: For a given
  // ~scope~, what resources are visible to it?  Locate all the resources
  // that are visible to a particular scope.  This operation could be
  // quite expensive, as it has to traverse all of the resources in the
  // database.

  // @uvm-ieee 1800.2-2020 auto C.2.4.4.8
  function uvm_resource_types::rsrc_q_t lookup_scope(string scope);

    table_q_t rq;
    uvm_resource_base r;
    int unsigned i;

    int unsigned err;
    uvm_resource_types::rsrc_q_t q = new();

    //iterate in reverse order for the special case of autoconfig
    //of arrays. The array name with no [] needs to be higher priority.
    //This has no effect an manual accesses.
    string name;

    if(rtab.last(name)) begin
      do begin
        rq = rtab[name];
        for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
          uvm_resource_base rsrc_iter;
          rsrc_iter = `M__TABLE_GET(rq, iter);
          if(rsrc_iter != null && uvm_is_match(rsrc_iter.get_scope(), scope)) begin
            q.push_back(rsrc_iter);
          end
        end
      end while(rtab.prev(name));
    end

    return q;
    
  endfunction

  //--------------------
  // Group -- NODOCS -- Set Priority
  //--------------------
  //
  // Functions for altering the search priority of resources.  Resources
  // are stored in queues in the type and name maps.  When retrieving
  // resources, either by type or by name, the resource queue is search
  // from front to back.  The first one that matches the search criteria
  // is the one that is returned.  The ~set_priority~ functions let you
  // change the order in which resources are searched.  For any
  // particular resource, you can set its priority to UVM_HIGH, in which
  // case the resource is moved to the front of the queue, or to UVM_LOW in
  // which case the resource is moved to the back of the queue.

  // function- set_priority_queue
  //
  // This function handles the mechanics of moving a resource to either
  // the front or back of the queue.

  local function void set_priority_queue(uvm_resource_base rsrc,
                                         table_q_t rq,
                                         uvm_resource_types::priority_e pri);

    uvm_resource_base r;
    int unsigned i;

    string msg;
    string name = rsrc.get_name();

    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      r = `M__TABLE_GET(rq, iter); // save for later
      if (r == rsrc) begin
        i = iter;
        break;
      end
    end

    if(r != rsrc) begin
      $sformat(msg, "Handle for resource named %s is not in the name table; cannot change its priority", name);
      uvm_report_error("NORSRC", msg);
      return;
    end

    `M__TABLE_Q(rq).delete(i);

    case(pri)
      uvm_resource_types::PRI_HIGH: `M__TABLE_Q(rq).push_front(rsrc);
      uvm_resource_types::PRI_LOW:  `M__TABLE_Q(rq).push_back(rsrc);
    endcase

 endfunction


  // Function -- NODOCS -- set_priority_type
  //
  // Change the priority of the ~rsrc~ based on the value of ~pri~, the
  // priority enum argument.  This function changes the priority only in
  // the type map, leaving the name map untouched.

  // @uvm-ieee 1800.2-2020 auto C.2.4.5.1
  function void set_priority_type(uvm_resource_base rsrc,
                                  uvm_resource_types::priority_e pri);

    uvm_resource_base type_handle;
    string msg;
    table_q_t rq;

    if(rsrc == null) begin
      uvm_report_warning("NULLRASRC", "attempting to change the search priority of a null resource");
      return;
    end

    type_handle = rsrc.get_type_handle();
    if(!ttab.exists(type_handle)) begin
      $sformat(msg, "Type handle for resrouce named %s not found in type map; cannot change its search priority", rsrc.get_name());
      uvm_report_error("RNFTYPE", msg);
      return;
    end

    rq = ttab[type_handle];
    set_priority_queue(rsrc, rq, pri);
  endfunction


  // Function -- NODOCS -- set_priority_name
  //
  // Change the priority of the ~rsrc~ based on the value of ~pri~, the
  // priority enum argument.  This function changes the priority only in
  // the name map, leaving the type map untouched.

  // @uvm-ieee 1800.2-2020 auto C.2.4.5.2
  function void set_priority_name(uvm_resource_base rsrc,
                                  uvm_resource_types::priority_e pri);

    string name;
    string msg;

    if(rsrc == null) begin
      uvm_report_warning("NULLRASRC", "attempting to change the search priority of a null resource");
      return;
    end

    name = rsrc.get_name();
    if(!rtab.exists(name)) begin
      $sformat(msg, "Resrouce named %s not found in name map; cannot change its search priority", name);
      uvm_report_error("RNFNAME", msg);
      return;
    end

    set_priority_queue(rsrc, rtab[name], pri);
    
  endfunction


  // Function -- NODOCS -- set_priority
  //
  // Change the search priority of the ~rsrc~ based on the value of ~pri~,
  // the priority enum argument.  This function changes the priority in
  // both the name and type maps.

  // @uvm-ieee 1800.2-2020 auto C.2.4.5.3
  function void set_priority (uvm_resource_base rsrc,
                              uvm_resource_types::priority_e pri);
    set_priority_type(rsrc, pri);
    set_priority_name(rsrc, pri);
  endfunction


  // @uvm-ieee 1800.2-2020 auto C.2.4.5.4
  static function void set_default_precedence( int unsigned precedence);
    uvm_coreservice_t cs = uvm_coreservice_t::get();
    cs.set_resource_pool_default_precedence(precedence);
  endfunction


  static function int unsigned get_default_precedence();
    uvm_coreservice_t cs = uvm_coreservice_t::get();
    return cs.get_resource_pool_default_precedence(); 
  endfunction

  
  // @uvm-ieee 1800.2-2020 auto C.2.4.5.6
  virtual function void set_precedence(uvm_resource_base r,
                                       int unsigned p=uvm_resource_pool::get_default_precedence());

    table_q_t rq;
    string name;
    int unsigned i;
    uvm_resource_base rsrc;

    if(r == null) begin
      uvm_report_warning("NULLRASRC", "attempting to set precedence of a null resource");
      return;
    end

    name = r.get_name();
    if(rtab.exists(name)) begin
      rq = rtab[name];
      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        rsrc = `M__TABLE_GET(rq, iter); // Save for use later
        if (rsrc == r) break;
      end
    end 
  
    if(r != rsrc) begin
      uvm_report_warning("NORSRC", $sformatf("resource named %s is not placed within the pool", name));
      return;
    end

    r.precedence = p;

  endfunction


  virtual function int unsigned get_precedence(uvm_resource_base r);

    table_q_t rq;
    string name;
    int unsigned i;
    uvm_resource_base rsrc;

    if(r == null) begin
      uvm_report_warning("NULLRASRC", "attempting to get precedence of a null resource");
      return uvm_resource_pool::get_default_precedence();
    end

    name = r.get_name();
    if(rtab.exists(name)) begin
      rq = rtab[name];

      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        rsrc = `M__TABLE_GET(rq, iter); // Save for use later
        if(rsrc == r) break;
      end
    end 
  
    if(r != rsrc) begin
      uvm_report_warning("NORSRC", $sformatf("resource named %s is not placed within the pool", name));
      return uvm_resource_pool::get_default_precedence();
    end

    return r.precedence;

  endfunction


  //--------------------------------------------------------------------
  // Group -- NODOCS -- Debug
  //--------------------------------------------------------------------

  // Function: find_unused_resources
  //
  // Locate all the resources that have at least one write and no reads
  //
  // @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2

  function uvm_resource_types::rsrc_q_t find_unused_resources();

    table_q_t rq;
    uvm_resource_types::rsrc_q_t q = new;
    int unsigned i;
    uvm_resource_base r;
    uvm_resource_types::access_t a;
    int reads;
    int writes;

    foreach (rtab[name]) begin
      rq = rtab[name];
      for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
        uvm_resource_base rsrc_iter;
        rsrc_iter = `M__TABLE_GET(rq, iter);
        reads = 0;
        writes = 0;
        foreach(rsrc_iter.dbg.access[str]) begin
          a = rsrc_iter.dbg.access[str];
          reads += a.read_count;
          writes += a.write_count;
        end
        if(writes > 0 && reads == 0)
          q.push_back(rsrc_iter);
      end
    end

    return q;

  endfunction


  // Prints a single resource queue element into ~printer~
  function void m_print_resource_element(uvm_printer printer,
                                         int unsigned iter,
                                         uvm_resource_base r,
                                         bit audit=0);
    string scope;
    printer.push_element($sformatf("[%0d]", iter),
                         "uvm_resource",
                         "-",
                         "-");
    
    void'(get_scope(r, scope));
        
    printer.print_string("name", r.get_name());

    printer.print_generic_element("value",
                                  r.m_value_type_name(),
                                  "",
                                  r.m_value_as_string());
                                    
    printer.print_string("scope", scope);

    printer.print_field_int("precedence", get_precedence(r), 32, UVM_UNSIGNED);
    if (audit && (r.dbg!=null)) begin
      if (r.dbg.access.size()) begin
        printer.print_array_header("accesses",
                                   r.dbg.access.size(),
                                   "queue");
        foreach(r.dbg.access[i]) begin
          printer.print_string($sformatf("[%s]", i),
                               $sformatf("reads: %0d @ %0t  writes: %0d @ %0t",
                                         r.dbg.access[i].read_count,
                                         r.dbg.access[i].read_time,
                                         r.dbg.access[i].write_count,
                                         r.dbg.access[i].write_time));
        end // foreach(r.dbg.access[i])
        
        printer.print_array_footer(r.dbg.access.size());
      end // (r.dbg.access.size())
    end // (audit)
    
    printer.pop_element();
  endfunction : m_print_resource_element
    
  
  // Prints resouce queue into ~printer~, non-LRM
  function void m_print_resources(uvm_printer printer,
                                  string name,
                                  table_q_t rq,
                                  bit audit = 0);
    
    printer.push_element(name,
                         `M__TABLE_NAME,
                         $sformatf("%0d", `M__TABLE_Q(rq).size()));

    for (int iter=0; iter < `M__TABLE_Q(rq).size(); iter++) begin
      m_print_resource_element(printer, iter, `M__TABLE_GET(rq, iter), audit);
    end

    printer.pop_element();

  endfunction : m_print_resources
                                  
  
  // Function -- NODOCS -- print_resources
  //
  // Print the resources that are in a single queue, ~rq~.  This is a utility
  // function that can be used to print any collection of resources
  // stored in a queue.  The ~audit~ flag determines whether or not the
  // audit trail is printed for each resource along with the name,
  // value, and scope regular expression.

  function void print_resources(uvm_resource_types::rsrc_q_t rq, bit audit = 0);

    int unsigned i;
    string id;
    static uvm_tree_printer printer = new();

    // Basically this is full implementation of something
    // like uvm_object::print, but we're interleaving
    // scope data, so it's all manual.
    printer.flush();
    if (rq == null) begin
      printer.print_generic_element("",
                                    "uvm_queue#(uvm_resource_base)",
                                    "",
                                    "<null>");
    end
    else begin
      printer.push_element(rq.get_name(),
                           "uvm_queue#(uvm_resource_base)",
                           $sformatf("%0d",rq.size()),
                           uvm_object_value_str(rq));

      for (int i = 0; i < rq.size(); i++) begin
        m_print_resource_element(printer, i, rq.get(i), audit);
      end

      printer.pop_element();
    end
    `uvm_info("UVM/RESOURCE_POOL/PRINT_QUEUE",
              printer.emit(),
              UVM_NONE)
  endfunction


  // Function -- NODOCS -- dump
  //
  // dump the entire resource pool.  The resource pool is traversed and
  // each resource is printed.  The utility function print_resources()
  // is used to initiate the printing. If the ~audit~ bit is set then
  // the audit trail is dumped for each resource.

  function void dump(bit audit = 0, uvm_printer printer = null);

    string name;
    static uvm_tree_printer m_printer;

    if (m_printer == null) begin
      m_printer = new();
      m_printer.set_type_name_enabled(1);
    end
      

    if (printer == null)
      printer = m_printer;
    
    printer.flush();
    printer.push_element("uvm_resource_pool",
                         "",
                         $sformatf("%0d",rtab.size()),
                         "");
    
    foreach (rtab[name]) begin
      m_print_resources(printer, name, rtab[name], audit);
    end

    printer.pop_element();
    
    `uvm_info("UVM/RESOURCE/DUMP", printer.emit(), UVM_NONE)

  endfunction
  
endclass


`undef M__TABLE_Q
`undef M__TABLE_GET
`undef M__TABLE_NAME
