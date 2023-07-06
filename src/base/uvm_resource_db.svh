//----------------------------------------------------------------------
// Copyright 2011 AMD
// Copyright 2015 Analog Devices, Inc.
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2017 Cisco Systems, Inc.
// Copyright 2011 Cypress Semiconductor Corp.
// Copyright 2017 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2010-2011 Mentor Graphics Corporation
// Copyright 2014-2020 NVIDIA Corporation
// Copyright 2010-2011 Paradigm Works
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

//----------------------------------------------------------------------
// Title -- NODOCS -- UVM Resource Database
//
// Topic: Intro
//
// The <uvm_resource_db> class provides a convenience interface for
// the resources facility.  In many cases basic operations such as
// creating and setting a resource or getting a resource could take
// multiple lines of code using the interfaces in <uvm_resource_base> or
// <uvm_resource#(T)>.  The convenience layer in <uvm_resource_db>
// reduces many of those operations to a single line of code.
//
// If the run-time ~+UVM_RESOURCE_DB_TRACE~ command line option is
// specified, all resource DB accesses (read and write) are displayed.
//----------------------------------------------------------------------



// Class: uvm_resource_db
// Implementation of uvm_resource_db, as defined in section
// C.3.2.1 of 1800.2-2020, with the following additional API
//
//| class uvm_resource_db#(type T=uvm_object)
  
// @uvm-ieee 1800.2-2020 auto C.3.2.1
class uvm_resource_db #(type T=uvm_object);

  typedef uvm_resource #(T) rsrc_t;

  protected function new();
  endfunction

  // function -- NODOCS -- get_by_type
  //
  // Get a resource by type.  The type is specified in the db
  // class parameter so the only argument to this function is the
  // ~scope~.

  // @uvm-ieee 1800.2-2020 auto C.3.2.3.5
  static function rsrc_t get_by_type(string scope);
    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    return imp.get_by_type(scope);
  endfunction

  // function -- NODOCS -- get_by_name
  //
  // Imports a resource by ~name~.  The first argument is the current 
  // ~scope~ of the resource to be retrieved and the second argument is
  // the ~name~. The ~rpterr~ flag indicates whether or not to generate
  // a warning if no matching resource is found.

  // @uvm-ieee 1800.2-2020 auto C.3.2.3.4
  static function rsrc_t get_by_name(string scope,
                                     string name,
                                     bit rpterr=1);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    return imp.get_by_name(scope, name, rpterr);
  endfunction

  // function -- NODOCS -- set_default
  //
  // add a new item into the resources database.  The item will not be
  // written to so it will have its default value. The resource is
  // created using ~name~ and ~scope~ as the lookup parameters.

  // @uvm-ieee 1800.2-2020 auto C.3.2.3.2
  static function rsrc_t set_default(string scope, string name);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    return imp.set_default(scope, name);
  endfunction


  // @uvm-ieee 1800.2-2020 auto C.3.2.3.1
  static function void set(input string scope, input string name,
                           T val, input uvm_object accessor = null);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    imp.set(scope, name, val, accessor);
  endfunction


  // @uvm-ieee 1800.2-2020 auto C.3.2.3.3
  static function void set_anonymous(input string scope,
                                     T val, input uvm_object accessor = null);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    imp.set_anonymous(scope, val, accessor);
  endfunction

  // Function: set_override
  //
  // Create a new resource, write ~val~ to it, and set it into the
  // database.  Set it at the beginning of the queue in the type map and
  // the name map so that it will be (currently) the highest priority
  // resource with the specified name and type.
  //
  // @uvm-contrib
  static function void set_override(input string scope, input string name,
                                    T val, uvm_object accessor = null);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    imp.set_override(scope, name, val, accessor);
  endfunction


    
  // Function: set_override_type
  //
  // Create a new resource, write ~val~ to it, and set it into the
  // database.  Set it at the beginning of the queue in the type map so
  // that it will be (currently) the highest priority resource with the
  // specified type. It will be normal priority (i.e. at the end of the
  // queue) in the name map.
  //
  // @uvm-contrib
  static function void set_override_type(input string scope, input string name,
                                         T val, uvm_object accessor = null);

    uvm_resource_db_implementation_t #(T) imp;
    imp = uvm_resource_db_implementation_t #(T)::get_imp();
    imp.set_override_type(scope, name, val, accessor);
  endfunction

  // Function: set_override_name
  //
  // Create a new resource, write ~val~ to it, and set it into the
  // database.  Set it at the beginning of the queue in the name map so
  // that it will be (currently) the highest priority resource with the
  // specified name. It will be normal priority (i.e. at the end of the
  // queue) in the type map.
  //
  // @uvm-contrib
  static function void set_override_name(input string scope, input string name,
                                  T val, uvm_object accessor = null);

     uvm_resource_db_implementation_t #(T) imp;
     imp = uvm_resource_db_implementation_t #(T)::get_imp();
     imp.set_override_name(scope, name, val, accessor);
  endfunction

  // @uvm-ieee 1800.2-2020 auto C.3.2.3.6
  static function bit read_by_name(input string scope,
                                   input string name,
                                   inout T val, input uvm_object accessor = null);

     uvm_resource_db_implementation_t #(T) imp;
     imp = uvm_resource_db_implementation_t #(T)::get_imp();
     return imp.read_by_name(scope, name, val, accessor);
  endfunction

  // @uvm-ieee 1800.2-2020 auto C.3.2.3.7
  static function bit read_by_type(input string scope,
                                   inout T val,
                                   input uvm_object accessor = null);
    
     uvm_resource_db_implementation_t #(T) imp;
     imp = uvm_resource_db_implementation_t #(T)::get_imp();
     return imp.read_by_type(scope, val, accessor);
  endfunction


  // @uvm-ieee 1800.2-2020 auto C.3.2.3.8
  static function bit write_by_name(input string scope, input string name,
                                    input T val, input uvm_object accessor = null);

     uvm_resource_db_implementation_t #(T) imp;
     imp = uvm_resource_db_implementation_t #(T)::get_imp();
     return imp.write_by_name(scope, name, val, accessor);
  endfunction


  // @uvm-ieee 1800.2-2020 auto C.3.2.3.9
  static function bit write_by_type(input string scope,
                                    input T val, input uvm_object accessor = null);

     uvm_resource_db_implementation_t #(T) imp;
     imp = uvm_resource_db_implementation_t #(T)::get_imp();
     return imp.write_by_type(scope, val, accessor);
  endfunction

  // function -- NODOCS -- dump
  //
  // Dump all the resources in the resource pool. This is useful for
  // debugging purposes.  This function does not use the parameter T, so
  // it will dump the same thing -- the entire database -- no matter the
  // value of the parameter.

  static function void dump();
    uvm_resource_pool rp = uvm_resource_pool::get();
    rp.dump();
  endfunction

endclass


