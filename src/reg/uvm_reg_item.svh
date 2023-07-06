//
//--------------------------------------------------------------
// Copyright 2010 AMD
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2022 Marvell International Ltd.
// Copyright 2010-2020 Mentor Graphics Corporation
// Copyright 2014-2020 NVIDIA Corporation
// Copyright 2004-2018 Synopsys, Inc.
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
//--------------------------------------------------------------
//

//------------------------------------------------------------------------------
// Title -- NODOCS -- Generic Register Operation Descriptors
//
// This section defines the abstract register transaction item. It also defines
// a descriptor for a physical bus operation that is used by <uvm_reg_adapter>
// subtypes to convert from a protocol-specific address/data/rw operation to
// a bus-independent, canonical r/w operation.
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// CLASS -- NODOCS -- uvm_reg_item
//
// Defines an abstract register transaction item. No bus-specific information
// is present, although a handle to a <uvm_reg_map> is provided in case a user
// wishes to implement a custom address translation algorithm.
//------------------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto 19.1.1.1
class uvm_reg_item extends uvm_sequence_item;

  `uvm_object_utils(uvm_reg_item)

  // Variable -- NODOCS -- element_kind
  //
  // Kind of element being accessed: REG, MEM, or FIELD. See <uvm_elem_kind_e>.
  //

  uvm_elem_kind_e element_kind;


  // Variable -- NODOCS -- element
  //
  // A handle to the RegModel model element associated with this transaction.
  // Use <element_kind> to determine the type to cast  to: <uvm_reg>,
  // <uvm_mem>, or <uvm_reg_field>.
  //

  uvm_object element;


  // Variable: kind
  //
  // Kind of access: READ or WRITE.
  //
  // Access to this variable is provided for randomization, otherwise interactions
  // with it shall be via the set_kind() and get_kind() accessor methods
  //
  // @uvm-contrib This variable is being considered for potential contribution to 1800.2

  rand uvm_access_e kind;


  // Variable: value
  //
  // The value to write to, or after completion, the value read from the DUT.
  // Burst operations use the <values> property.
  //
  // Access to this variable is provided for randomization, otherwise interactions
  // with it shall be via the set_value_array() and get_value_array() accessor methods
  //
  // @uvm-contrib This variable is being considered for potential contribution to 1800.2

  rand uvm_reg_data_t value[];


  // TODO: parameterize
  constraint max_values { value.size() > 0 && value.size() < 1000; }

  // Variable: offset
  //
  // For memory accesses, the offset address. For bursts,
  // the ~starting~ offset address.
  //
  // Access to this variable is provided for randomization, otherwise interactions
  // with it shall be via the set_offset() and get_offset() accessor methods
  //
  // @uvm-contrib This variable is being considered for potential contribution to 1800.2

  rand uvm_reg_addr_t offset;


  // Variable -- NODOCS -- status
  //
  // The result of the transaction: IS_OK, HAS_X, or ERROR.
  // See <uvm_status_e>.
  //

  uvm_status_e status;


  // Variable -- NODOCS -- local_map
  //
  // The local map used to obtain addresses. Users may customize
  // address-translation using this map. Access to the sequencer
  // and bus adapter can be obtained by getting this map's root map,
  // then calling <uvm_reg_map::get_sequencer> and
  // <uvm_reg_map::get_adapter>.
  //

  uvm_reg_map local_map;


  // Variable -- NODOCS -- map
  //
  // The original map specified for the operation. The actual <map>
  // used may differ when a test or sequence written at the block
  // level is reused at the system level.
  //

  uvm_reg_map map;


  // Variable -- NODOCS -- path
  //
  // The path being used: <UVM_FRONTDOOR> or <UVM_BACKDOOR>.
  //

  uvm_door_e path;


  // Variable: parent
  //
  // The sequence from which the operation originated.
  //
  // Access to this variable is provided for randomization, otherwise interactions
  // with it shall be via the set_parent() and get_parent() accessor methods
  //
  // @uvm-contrib This variable is being considered for potential contribution to 1800.2

  rand uvm_sequence_base parent;


  // Variable -- NODOCS -- prior
  //
  // The priority requested of this transfer, as defined by
  // <uvm_sequence_base::start_item>.
  //

  int prior = -1;


  // Variable: extension
  //
  // Handle to optional user data, as conveyed in the call to
  // write(), read(), mirror(), or update() used to trigger the operation.
  //
  // @uvm-contrib This variable is being considered for potential contribution to 1800.2

  rand uvm_object extension;


  // Variable -- NODOCS -- bd_kind
  //
  // If path is UVM_BACKDOOR, this member specifies the abstraction
  // kind for the backdoor access, e.g. "RTL" or "GATES".
  //

  string bd_kind;


  // Variable -- NODOCS -- fname
  //
  // The file name from where this transaction originated, if provided
  // at the call site.
  //

  string fname;


  // Variable -- NODOCS -- lineno
  //
  // The file name from where this transaction originated, if provided
  // at the call site.
  //

  int lineno;



  // @uvm-ieee 1800.2-2020 auto 19.1.1.3.1
  function new(string name="");
    super.new(name);
    value = new[1];
  endfunction



  // @uvm-ieee 1800.2-2020 auto 19.1.1.3.2
  virtual function string convert2string();
    string s,value_s;
    s = {"kind=",kind.name(),
         " ele_kind=",element_kind.name(),
         " ele_name=",element==null?"null":element.get_full_name() };

    if (value.size() > 1 && uvm_report_enabled(UVM_HIGH, UVM_INFO, "RegModel")) begin
      value_s = "'{";
      foreach (value[i])
         value_s = {value_s,$sformatf("%0h,",value[i])};
      value_s[value_s.len()-1]="}";
    end
    else
      value_s = $sformatf("%0h",value[0]);
    s = {s, " value=",value_s};

    if (element_kind == UVM_MEM)
      s = {s, $sformatf(" offset=%0h",offset)};
    s = {s," map=",(map==null?"null":map.get_full_name())," path=",path.name()};
    s = {s," status=",status.name()};
    return s;
  endfunction


  // Function: do_copy
  //
  // Copy the ~rhs~ object into this object. The ~rhs~ object must
  // derive from <uvm_reg_item>.
  //
  // @uvm-contrib This API is being considered for potential contribution to 1800.2

  virtual function void do_copy(uvm_object rhs);
    uvm_reg_item rhs_;
    if (rhs == null)
     `uvm_fatal("REG/NULL","do_copy: rhs argument is null")

    if (!$cast(rhs_,rhs)) begin
      `uvm_error("WRONG_TYPE","Provided rhs is not of type uvm_reg_item")
      return;
    end
    super.do_copy(rhs);
    set_element_kind(rhs_.get_element_kind());
    set_element(rhs_.get_element());
    set_kind(rhs_.get_kind());
    rhs_.get_value_array(value);
    set_offset(rhs_.get_offset());
    set_status(rhs_.get_status());
    set_local_map(rhs_.get_local_map());
    set_map(rhs_.get_map());
    set_door(rhs_.get_door());
    set_extension(rhs_.get_extension());
    set_bd_kind(rhs_.get_bd_kind());
    set_parent_sequence(rhs_.get_parent_sequence());
    set_priority(rhs_.get_priority());
    set_fname(rhs_.get_fname());
    set_line(rhs_.get_line());
  endfunction

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.1
  extern virtual function void set_element_kind(uvm_elem_kind_e element_kind);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.1
  extern virtual function uvm_elem_kind_e get_element_kind();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.2
  extern virtual function void set_element(uvm_object element);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.2
  extern virtual function uvm_object get_element();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.3
  extern virtual function void set_kind(uvm_access_e kind);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.3
  extern virtual function uvm_access_e get_kind();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.4
  extern virtual function void set_value(uvm_reg_data_t value, int unsigned idx = 0);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.4
  extern virtual function uvm_reg_data_t get_value(int unsigned idx = 0);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.4
  extern virtual function void set_value_size(int unsigned sz);

  // @uvm-ieee 1800.2-2020 manual 19.1.1.2.4
  extern virtual function int unsigned get_value_size();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.4
  extern virtual function void set_value_array(const ref uvm_reg_data_t value[]);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.4
  extern virtual function void get_value_array(ref uvm_reg_data_t value[]);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.5
  extern virtual function void set_offset(uvm_reg_addr_t offset);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.5
  extern virtual function uvm_reg_addr_t get_offset();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.6
  extern virtual function void set_status(uvm_status_e status);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.6
  extern virtual function uvm_status_e get_status();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.7
  extern virtual function void set_local_map(uvm_reg_map map);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.7
  extern virtual function uvm_reg_map get_local_map();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.8
  extern virtual function void set_map(uvm_reg_map map);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.8
  extern virtual function uvm_reg_map get_map();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.9
  extern virtual function void set_door(uvm_door_e door);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.9
  extern virtual function uvm_door_e get_door();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.10
  extern virtual function void set_parent_sequence(uvm_sequence_base parent);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.10
  extern virtual function uvm_sequence_base get_parent_sequence();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.11
  extern virtual function void set_priority(int value);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.11
  extern virtual function int get_priority();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.12
  extern virtual function void set_extension(uvm_object extension);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.12
  extern virtual function uvm_object get_extension();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.13
  extern virtual function void set_bd_kind(string bd_kind);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.13
  extern virtual function string get_bd_kind();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.14
  extern virtual function void set_fname(string fname);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.14
  extern virtual function string get_fname();

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.15
  extern virtual function void set_line(int line);

  // @uvm-ieee 1800.2-2020 auto 19.1.1.2.15
  extern virtual function int get_line();


endclass

function void uvm_reg_item::set_element_kind(uvm_elem_kind_e element_kind);
  this.element_kind = element_kind;
endfunction

function uvm_elem_kind_e uvm_reg_item::get_element_kind();
  return element_kind;
endfunction

function void uvm_reg_item::set_element(uvm_object element);
  this.element = element;
endfunction

function uvm_object uvm_reg_item::get_element();
  return element;
endfunction

function void uvm_reg_item::set_kind(uvm_access_e kind);
  this.kind = kind;
endfunction

function uvm_access_e uvm_reg_item::get_kind();
  return kind;
endfunction

function void uvm_reg_item::set_value(uvm_reg_data_t value, int unsigned idx = 0);
  if(idx < this.value.size()) begin
    this.value[idx] = value;
  end
  else begin
    this.value = new[idx+1](this.value);
    this.value[idx] = value;
  end
endfunction

function uvm_reg_data_t uvm_reg_item::get_value(int unsigned idx = 0);
  if(idx < this.value.size()) begin
    return this.value[idx];
  end
  else begin
    return 0;
  end

endfunction

function void uvm_reg_item::set_value_size(int unsigned sz);
  value = new[sz](value);
endfunction

function int unsigned uvm_reg_item::get_value_size();
  return value.size();
endfunction

function void uvm_reg_item::set_value_array(const ref uvm_reg_data_t value[]);
  this.value = value;
endfunction

function void uvm_reg_item::get_value_array(ref uvm_reg_data_t value[]);
  value = this.value;
endfunction

function void uvm_reg_item::set_offset(uvm_reg_addr_t offset);
  this.offset = offset;
endfunction

function uvm_reg_addr_t uvm_reg_item::get_offset();
  return offset;
endfunction

function void uvm_reg_item::set_status(uvm_status_e status);
  this.status = status;
endfunction

function uvm_status_e uvm_reg_item::get_status();
  return status;
endfunction

function void uvm_reg_item::set_local_map(uvm_reg_map map);
  local_map = map;
endfunction

function uvm_reg_map uvm_reg_item::get_local_map();
  return local_map;
endfunction

function void uvm_reg_item::set_map(uvm_reg_map map);
  this.map = map;
endfunction

function uvm_reg_map uvm_reg_item::get_map();
  return map;
endfunction

function void uvm_reg_item::set_door(uvm_door_e door);
  this.path = door;
endfunction

function uvm_door_e uvm_reg_item::get_door();
  return path;
endfunction

function void uvm_reg_item::set_parent_sequence(uvm_sequence_base parent);
  this.parent = parent;
endfunction

function uvm_sequence_base uvm_reg_item::get_parent_sequence();
  return parent;
endfunction

function void uvm_reg_item::set_priority(int value);
  prior = value;
endfunction

function int uvm_reg_item::get_priority();
  return prior;
endfunction

function void uvm_reg_item::set_extension(uvm_object extension);
  this.extension = extension;
endfunction

function uvm_object uvm_reg_item::get_extension();
  return extension;
endfunction

function void uvm_reg_item::set_bd_kind(string bd_kind);
  this.bd_kind = bd_kind;
endfunction

function string uvm_reg_item::get_bd_kind();
  return bd_kind;
endfunction

function void uvm_reg_item::set_fname(string fname);
  this.fname = fname;
endfunction

function string uvm_reg_item::get_fname();
  return fname;
endfunction

function void uvm_reg_item::set_line(int line);
  this.lineno = line;
endfunction

function int uvm_reg_item::get_line();
  return lineno;
endfunction


typedef struct {


  uvm_access_e kind;



  uvm_reg_addr_t addr;



  uvm_reg_data_t data;



  int n_bits;

  /*
  constraint valid_n_bits {
     n_bits > 0;
     n_bits <= `UVM_REG_DATA_WIDTH;
  }
  */



  uvm_reg_byte_en_t byte_en;



  uvm_status_e status;

} uvm_reg_bus_op;
