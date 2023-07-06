//----------------------------------------------------------------------
// Copyright 2010-2011 AMD
// Copyright 2015 Analog Devices, Inc.
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2017-2018 Cisco Systems, Inc.
// Copyright 2011-2012 Cypress Semiconductor Corp.
// Copyright 2017 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2010-2022 Mentor Graphics Corporation
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
// Class: uvm_resource #(T)
// Implementation of uvm_resource#(T) as defined in section C.2.5.1 of
// 1800.2-2020.
//----------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto C.2.5.1
class uvm_resource #(type T=int) extends uvm_resource_base;

  typedef uvm_resource#(T) this_type;

  // singleton handle that represents the type of this resource
  static this_type my_type = get_type();

  // Can't be rand since things like rand strings are not legal.
  protected T val;

  // Because of uvm_resource#(T)::get_type, we can't use
  // the macros.  We need to do it all manually.
  typedef uvm_object_registry#(this_type) type_id;
  virtual function uvm_object_wrapper get_object_type();
    return type_id::get();
  endfunction : get_object_type
  virtual function uvm_object create (string name="");
    this_type tmp;
    if (name=="") tmp = new();
    else tmp = new(name);
    return tmp;
  endfunction : create
  `uvm_type_name_decl($sformatf("uvm_resource#(%s)", `uvm_typename(T)))
  
  
  // @uvm-ieee 1800.2-2020 auto C.2.5.2
  function new(string name="", string scope="<not provided>"); //scope argument added for compatibility
    super.new(name,scope);
  endfunction

  virtual function string m_value_type_name();
    return `uvm_typename(T);
  endfunction : m_value_type_name
                                    
  virtual function string m_value_as_string();
    return $sformatf("%p", val);
  endfunction : m_value_as_string
                                    
  //----------------------
  // Group -- NODOCS -- Type Interface
  //----------------------
  //
  // Resources can be identified by type using a static type handle.
  // The parent class provides the virtual function interface
  // <get_type_handle>.  Here we implement it by returning the static type
  // handle.

  // Function -- NODOCS -- get_type
  //
  // Static function that returns the static type handle.  The return
  // type is this_type, which is the type of the parameterized class.

  static function this_type get_type();
    if(my_type == null)
      my_type = new();
    return my_type;
  endfunction

  // Function -- NODOCS -- get_type_handle
  //
  // Returns the static type handle of this resource in a polymorphic
  // fashion.  The return type of get_type_handle() is
  // uvm_resource_base.  This function is not static and therefore can
  // only be used by instances of a parameterized resource.

  // @uvm-ieee 1800.2-2020 auto C.2.5.3.2
  function uvm_resource_base get_type_handle();
    return get_type();
  endfunction
  
  //----------------------------
  // Group -- NODOCS -- Read/Write Interface
  //----------------------------
  //
  // <read> and <write> provide a type-safe interface for getting and
  // setting the object in the resource container.  The interface is
  // type safe because the value argument for <write> and the return
  // value of <read> are T, the type supplied in the class parameter.
  // If either of these functions is used in an incorrect type context
  // the compiler will complain.

  // Function: read
  //
  //| function T read(uvm_object accessor = null);
  //
  // This function is the implementation of the uvm_resource#(T)::read 
  // method detailed in IEEE1800.2-2020 section C.2.5.4.1
  //
  // The Accellera implementation passes ~accessor~ to <do_read> and
  // returns the result.

  // @uvm-ieee 1800.2-2020 auto C.2.5.4.1
  function T read(uvm_object accessor = null);
    return do_read(accessor);
  endfunction

  // Function: do_read
  //
  //| virtual function T do_read(uvm_object accessor);
  //
  // The ~do_read~ method is a user-definable hook that allows users customization over
  // what actions are performed during a read operation.
  //
  // If auditing, it calls uvm_resource_debug::record_read_access before 
  // returning the value.  This detail of this API is specific to the 
  // Accellera implementation and is not being considered for contribution to 1800.2
  
  //@uvm-contrib For potential contribution to 1800.2
  virtual function T do_read(uvm_object accessor);
    if (uvm_resource_options::is_auditing()) begin
       record_read_access(accessor);
    end
    return val;
  endfunction : do_read    
  
  // Function: write
  //
  //| function void write(T t, uvm_object accessor = null);
  //
  // This function is the implementation of the uvm_resource#(T)::write 
  // method detailed in IEEE1800.2-2020 section C.2.5.4.2
  //
  // The Accellera implementation passes ~t~ and ~accessor~ to <do_write>.

  // @uvm-ieee 1800.2-2020 auto C.2.5.4.2
  function void write(T t, uvm_object accessor = null);
    do_write(t, accessor);
  endfunction

  // Function: do_write
  //
  //| virtual function void do_write(T t, uvm_object accessor);
  // 
  // The ~do_write~ method is a user-definable hook that allows users customization over
  // what actions are performed during a write operation.
  //
  // If auditing, it calls uvm_resource_base::record_write_access before 
  // writing the value.  This detail of this API is specific to the 
  // Accellera implementation and is not being considered for contribution to 1800.2

  //@uvm-contrib For potential contribution to 1800.2
  virtual function void do_write(T t, uvm_object accessor);
    if(is_read_only()) begin
      uvm_report_error("resource", $sformatf("resource %s is read only -- cannot modify", get_name()));
      return;
    end

    // Set the modified bit and record the transaction only if the value
    // has actually changed.
    if(val == t)
      return;

    if (uvm_resource_options::is_auditing()) begin
       record_write_access(accessor);
    end

    // set the value and set the dirty bit
    val = t;
    modified = 1;
  endfunction : do_write
  


  // Function -- NODOCS -- get_highest_precedence
  //
  // In a queue of resources, locate the first one with the highest
  // precedence whose type is T.  This function is static so that it can
  // be called from anywhere.

  static function this_type get_highest_precedence(ref uvm_resource_types::rsrc_q_t q);

    this_type rsrc;
    this_type r;
    uvm_resource_types::rsrc_q_t tq;
    uvm_resource_base rb;
    uvm_resource_pool rp = uvm_resource_pool::get();

    if(q.size() == 0)
      return null;

    tq = new();
    rsrc = null;

    for(int i = 0; i < q.size(); ++i) begin
      if($cast(r, q.get(i))) begin
        tq.push_back(r) ;
      end
    end

    rb = rp.get_highest_precedence(tq);
    if (!$cast(rsrc, rb))
       return null;
 
    return rsrc;

  endfunction

  //@uvm-compat provided for compatibility with 1.2
  function void set_priority (uvm_resource_types::priority_e pri);
    uvm_resource_pool rp = uvm_resource_pool::get();
    rp.set_priority(this, pri);
  endfunction

endclass

