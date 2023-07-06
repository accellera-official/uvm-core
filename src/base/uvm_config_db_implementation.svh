//----------------------------------------------------------------------
// Copyright 2021-2022 Marvell International Ltd.
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

typedef class uvm_phase;


//Internal class for config waiters
class m_uvm_waiter;
  string inst_name;
  string field_name;
  event trigger;
  function new (string inst_name, string field_name);
    this.inst_name = inst_name;
    this.field_name = field_name;
  endfunction
endclass

typedef class uvm_root;
typedef class uvm_config_db_options;
typedef class uvm_config_db_default_implementation_t;

// Class: uvm_config_db_implementation_t#(T)
// Abstract class representing the implementation details of the API for 
// uvm_config_db#(T) to allow users to create alternate implementations 
//
// @uvm-contrib
virtual class uvm_config_db_implementation_t #(type T=int) extends uvm_object;
   typedef uvm_resource #(T) rsrc_t;

   `uvm_object_abstract_param_utils(uvm_config_db_implementation_t #(T))

   local static uvm_config_db_implementation_t #(T) m_config_db_imp;

    // Function: set_imp
    //
    // Sets the implementation to be used to:
    //   1) the imp argument if it is not null, else
    //   2) the relevant factory override of uvm_config_db_implementation_t#(T) if such an override exists, else
    //   3) a new creation of uvm_config_db_default_implementation_t#(T)
    // @uvm-contrib
   static function void set_imp(uvm_config_db_implementation_t #(T) imp = null);
      if (imp == null) begin
         uvm_coreservice_t cs = uvm_coreservice_t::get();
         uvm_factory factory = cs.get_factory();
         if (factory.find_override_by_type(uvm_config_db_implementation_t#(T)::get_type(),"") == uvm_config_db_implementation_t#(T)::get_type()) begin // no override registered
            imp = uvm_config_db_default_implementation_t #(T)::type_id::create();
         end
         else imp = uvm_config_db_implementation_t #(T)::type_id::create();
      end
      m_config_db_imp = imp ;
   endfunction : set_imp

    // Function: get_imp
    //
    // Returns the implementation instance to be used.  When called the first
    // time, it gets that instance via set_imp().  For all subsequent calls, it
    // returns that same instance.
    // @uvm-contrib
   static function uvm_config_db_implementation_t #(T) get_imp();
      if (m_config_db_imp == null) set_imp();
      return m_config_db_imp;
   endfunction : get_imp

   // Function: get
   //
   // Intended to provide the functionality for uvm_config_db#(T)::get
   // @uvm-contrib
   pure virtual function bit get (uvm_component     cntxt,
                                        string            inst_name,
                                        string            field_name,
                                        inout T           value);

   // Function: set
   //
   // Intended to provide the functionality for uvm_config_db#(T)::set
   // @uvm-contrib
   pure virtual function void set(string                              cntxt_name,
                                        string                              inst_name,
                                        string                              field_name,
                                        T                                   value,
                                        int                                 cntxt_depth,
                                        uvm_pool#(string, uvm_resource#(T)) pool,
                                        uvm_component                       cntxt);

   // Function: exists
   //
   // Intended to provide the functionality for uvm_config_db#(T)::exists
   // @uvm-contrib
   pure virtual function bit exists(uvm_component cntxt, 
                                    string        inst_name,
                                    string        field_name, 
                                    bit           rpterr);

   // Function: wait_modified
   //
   // Intended to provide the functionality for uvm_config_db#(T)::wait_modified
   // @uvm-contrib
   pure virtual task wait_modified(uvm_component cntxt, 
                                   string inst_name,
                                   string field_name);

   // Function: trigger_modified
   //
   // Triggers the event associated with ~inst_name~ and ~field_name~, potentially
   // unblocking calls to <wait_modified>.
   //
   // The ~inst_name~ variable supports regular expressions via <uvm_is_match>.
   //
   // @uvm-contrib
   pure virtual function void trigger_modified(string inst_name,
                                               string field_name);

   // Function: show_msg
   //
   // Intended to print a formatted string regarding an access of a particular config item
   // @uvm-contrib
   pure virtual function void show_msg(string id,
                                       string rtype,
                                       string action,
                                       string scope,
                                       string name,
                                       uvm_object accessor,
                                       rsrc_t rsrc);


endclass

// Class: uvm_config_db_default_implementation_t#(T)
//
// Provides an implementation of uvm_config_db_implementation_t#(T).
// Users may extend this class to provide an implementation that is
// a variation of the library implementation.
//
// @uvm-contrib
class uvm_config_db_default_implementation_t #(type T=int) extends uvm_config_db_implementation_t#(T);

  function new (string name = "uvm_config_db_default_implementation");
     super.new();
  endfunction : new

  `uvm_object_param_utils(uvm_config_db_default_implementation_t #(T))

  // Function: get
  //
  // Provides an implementation of get, including support for  
  // config_db tracing
  // @uvm-accellera
  virtual function bit get (uvm_component     cntxt,
                                  string            inst_name,
                                  string            field_name,
                                  inout T           value);
    uvm_resource#(T) r;
    uvm_resource_pool rp = uvm_resource_pool::get();
    uvm_resource_types::rsrc_q_t rq;
    uvm_coreservice_t cs = uvm_coreservice_t::get();

    if(cntxt == null) 
      cntxt = cs.get_root();
    if(inst_name == "") 
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") 
      inst_name = {cntxt.get_full_name(), ".", inst_name};
 
    rq = rp.lookup_name(inst_name, field_name, uvm_resource#(T)::get_type(), 0);
    r = uvm_resource#(T)::get_highest_precedence(rq);
    
    if(uvm_config_db_options::is_tracing())
      show_msg("CFGDB/GET", "Configuration","read", inst_name, field_name, cntxt, r);

    if(r == null)
      return 0;

    value = r.read(cntxt);

    return 1;
  endfunction : get


  // Internal waiter list for wait_modified
  static local uvm_queue#(m_uvm_waiter) m_waiters[string];

  // Function: wait_modified
  //
  // Provides an implementation of wait_modified
  // @uvm-accellera
  virtual task wait_modified(uvm_component cntxt, string inst_name,
                                              string field_name);
    process p = process::self();
    string rstate;
    m_uvm_waiter waiter;
    uvm_coreservice_t cs;

    if (p != null)
      rstate = p.get_randstate();

    cs = uvm_coreservice_t::get();

    if(cntxt == null)
      cntxt = cs.get_root();
    if(cntxt != cs.get_root()) begin
      if(inst_name != "")
        inst_name = {cntxt.get_full_name(),".",inst_name};
      else
        inst_name = cntxt.get_full_name();
    end

    waiter = new(inst_name, field_name);

    if(!m_waiters.exists(field_name))
      m_waiters[field_name] = new;
    m_waiters[field_name].push_back(waiter);

    if (p != null)
      p.set_randstate(rstate);

    // wait on the waiter to trigger
    @waiter.trigger;
  
    // Remove the waiter from the waiter list 
    for(int i=0; i<m_waiters[field_name].size(); ++i) begin
      if(m_waiters[field_name].get(i) == waiter) begin
        m_waiters[field_name].delete(i);
        break;
      end
    end 
  endtask : wait_modified

  // Function: trigger_modified
  //
  // @uvm-accellera
  virtual function void trigger_modified(string inst_name,
                                         string field_name);
    //trigger any waiters
    if(m_waiters.exists(field_name)) begin
      m_uvm_waiter w;
      for(int i=0; i<m_waiters[field_name].size(); ++i) begin
        w = m_waiters[field_name].get(i);
        if(uvm_is_match(inst_name,w.inst_name) )
           ->w.trigger;  
      end
    end

  endfunction : trigger_modified    

  // Function: set
  //
  // Provides an implementation of set, including support for  
  // config_db tracing
  // @uvm-accellera
  virtual function void set(string                              cntxt_name,
                                  string                              inst_name,
                                  string                              field_name,
                                  T                                   value,
                                  int                                 cntxt_depth,
                                  uvm_pool#(string, uvm_resource#(T)) pool,
                                  uvm_component                       cntxt);

    uvm_root top;
    uvm_phase curr_phase;
    uvm_resource#(T) r;
    string lookup;
    string rstate;
    uvm_coreservice_t cs = uvm_coreservice_t::get();
    uvm_resource_pool rp = cs.get_resource_pool();
    int unsigned precedence;

    //take care of random stability during allocation
    process p = process::self();
    if (p != null)
        rstate = p.get_randstate();

    top = cs.get_root();
    curr_phase = top.m_current_phase;

    if (cntxt == null) cntxt = top;
    if (inst_name == "") inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "") begin
      string slash_or_blank = "" ;
      string close_or_blank = "" ;
      string separator = "." ;
      if (inst_name[0] == "/" && inst_name.len()>2 && inst_name[inst_name.len()-1] == "/") begin //regex
         slash_or_blank = "/";
         close_or_blank = ")/" ;
         separator = "\.(" ;
         inst_name = inst_name.substr(1,inst_name.len()-2); //strip enclosing "/"
      end
      inst_name = {slash_or_blank, 
                   cntxt.get_full_name(), 
                   separator, 
                   inst_name, 
                   close_or_blank};
    end

    // Insert the token in the middle to prevent cache
    // oddities like i=foobar,f=xyz and i=foo,f=barxyz.
    // Can't just use '.', because '.' isn't illegal
    // in field names
    lookup = {inst_name, "__M_UVM__", field_name};

    if(!pool.exists(lookup)) begin
       r = new(field_name);
       rp.set_scope(r, inst_name);
       pool.add(lookup, r);
    end
    else begin
      r = pool.get(lookup);
    end
      
    if(curr_phase != null && curr_phase.get_name() == "build")
      precedence = cs.get_resource_pool_default_precedence() - (cntxt.get_depth());
    else
      precedence = cs.get_resource_pool_default_precedence();

    rp.set_precedence(r, precedence);
    r.write(value, cntxt);

    rp.set_priority_name(r, uvm_resource_types::PRI_HIGH);

    trigger_modified(inst_name, field_name);
    
    if (p != null)
        p.set_randstate(rstate);

    if(uvm_config_db_options::is_tracing())
      show_msg("CFGDB/SET", "Configuration","set", inst_name, field_name, cntxt, r);

  endfunction : set


  // Function: exists
  //
  // Provides an implementation of get
  // @uvm-accellera
  virtual function bit exists(uvm_component cntxt, 
                                               string        inst_name,
                                               string        field_name, 
                                               bit           rpterr);

    uvm_coreservice_t cs = uvm_coreservice_t::get();

    if(cntxt == null)
      cntxt = cs.get_root();
    if(inst_name == "")
      inst_name = cntxt.get_full_name();
    else if(cntxt.get_full_name() != "")
      inst_name = {cntxt.get_full_name(), ".", inst_name};

    return (uvm_resource_db#(T)::get_by_name(inst_name,field_name,rpterr) != null);  
  endfunction : exists


  // Function: show_msg
  //
  // Provides an implementation of show_msg.
  // @uvm-accellera
  virtual function void show_msg(string id,
                                 string rtype,
                                 string action,
                                 string scope,
                                 string name,
                                 uvm_object accessor,
                                 rsrc_t rsrc);
      T foo;
      string msg=`uvm_typename(foo);

      $sformat(msg, "%s scope='%s' name='%s' (type %s) %s accessor=%s = %s",
               rtype,scope,name, msg,action,
               (accessor != null) ? accessor.get_full_name() : "<unknown>",
               rsrc==null?"null (failed lookup)":rsrc.convert2string());

      `uvm_info(id, msg, UVM_LOW)

  endfunction : show_msg
endclass : uvm_config_db_default_implementation_t 



