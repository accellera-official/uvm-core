//
//------------------------------------------------------------------------------
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2017-2018 Cisco Systems, Inc.
// Copyright 2014 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2007-2022 Mentor Graphics Corporation
// Copyright 2013-2020 NVIDIA Corporation
// Copyright 2018 Qualcomm, Inc.
// Copyright 2014 Semifore
// Copyright 2018 Synopsys, Inc.
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


//------------------------------------------------------------------------------
// CLASS -- NODOCS -- uvm_packer
//
// The uvm_packer class provides a policy object for packing and unpacking
// uvm_objects. The policies determine how packing and unpacking should be done.
// Packing an object causes the object to be placed into a bit (byte or int)
// array. If the `uvm_field_* macro are used to implement pack and unpack,
// by default no metadata information is stored for the packing of dynamic
// objects (strings, arrays, class objects).
//
//-------------------------------------------------------------------------------

typedef bit signed [(`UVM_PACKER_MAX_BYTES*8)-1:0] uvm_pack_bitstream_t;

// Class: uvm_packer
// Implementation of uvm_packer, as defined in section
// 16.5.1 of 1800.2-2020

// @uvm-ieee 1800.2-2020 auto 16.5.1
class uvm_packer extends uvm_policy;

   // @uvm-ieee 1800.2-2020 auto 16.5.2.3
   `uvm_object_utils(uvm_packer)

    uvm_factory m_factory;	
    local uvm_object m_object_references[int];
   

  // Function -- NODOCS -- set_packed_*
  // Implementation of P1800.2 16.5.3.1
  //
  // The LRM specifies the set_packed_* methods as being
  // signed, whereas the <uvm_object::unpack> methods are specified
  // as unsigned.  This is being tracked in Mantis 6423.
  //
  // The reference implementation has implemented these methods
  // as unsigned so as to remain consistent.
  //
  //| virtual function void set_packed_bits( ref bit unsigned stream[] );
  //| virtual function void set_packed_bytes( ref byte unsigned stream[] );
  //| virtual function void set_packed_ints( ref int unsigned stream[] );
  //| virtual function void set_packed_longints( ref longint unsigned stream[] );
  //
   
  // @uvm-ieee 1800.2-2020 auto 16.5.3.1
  extern virtual function void set_packed_bits (ref bit unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.1
  extern virtual function void set_packed_bytes (ref byte unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.1
  extern virtual function void set_packed_ints (ref int unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.1
  extern virtual function void set_packed_longints (ref longint unsigned stream[]);
   
  // Function -- NODOCS -- get_packed_*
  // Implementation of P1800.2 16.5.3.2
  //
  // The LRM specifies the get_packed_* methods as being
  // signed, whereas the <uvm_object::pack> methods are specified
  // as unsigned.  This is being tracked in Mantis 6423.
  //
  // The reference implementation has implemented these methods
  // as unsigned so as to remain consistent.
  //
  //| virtual function void get_packed_bits( ref bit unsigned stream[] );
  //| virtual function void get_packed_bytes( ref byte unsigned stream[] );
  //| virtual function void get_packed_ints( ref int unsigned stream[] );
  //| virtual function void get_packed_longints( ref longint unsigned stream[] );
  //
   
  // @uvm-ieee 1800.2-2020 auto 16.5.3.2
  extern virtual function void get_packed_bits (ref bit unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.2
  extern virtual function void get_packed_bytes (ref byte unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.2
  extern virtual function void get_packed_ints (ref int unsigned stream[]);

  // @uvm-ieee 1800.2-2020 auto 16.5.3.2
  extern virtual function void get_packed_longints (ref longint unsigned stream[]);
   
  //----------------//
  // Group -- NODOCS -- Packing //
  //----------------//

  // @uvm-ieee 1800.2-2020 auto 16.5.2.4
  static function void set_default (uvm_packer packer) ;
     uvm_coreservice_t coreservice ;
     coreservice = uvm_coreservice_t::get() ;
     coreservice.set_default_packer(packer) ;
  endfunction

  // @uvm-ieee 1800.2-2020 auto 16.5.2.5
  static function uvm_packer get_default () ;
     uvm_coreservice_t coreservice ;
     coreservice = uvm_coreservice_t::get() ;
     return coreservice.get_default_packer() ;
  endfunction

  
  // @uvm-ieee 1800.2-2020 auto 16.5.2.2
  extern virtual function void flush ();
  // Function -- NODOCS -- pack_field
  //
  // Packs an integral value (less than or equal to 4096 bits) into the
  // packed array. ~size~ is the number of bits of ~value~ to pack.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.8
  extern virtual function void pack_field (uvm_bitstream_t value, int size);


  // Function -- NODOCS -- pack_field_int
  //
  // Packs the integral value (less than or equal to 64 bits) into the
  // pack array.  The ~size~ is the number of bits to pack, usually obtained by
  // ~$bits~. This optimized version of <pack_field> is useful for sizes up
  // to 64 bits.

  // @uvm-ieee 1800.2-2020 auto 16.5.2.1
  extern function new(string name="");

  // @uvm-ieee 1800.2-2020 auto 16.5.4.9
  extern virtual function void pack_field_int (uvm_integral_t value, int size);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.1
  extern virtual function void pack_bits(ref bit value[], input int size = -1);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.10
  extern virtual function void pack_bytes(ref byte value[], input int size = -1);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.11
  extern virtual function void pack_ints(ref int value[], input int size = -1);

  // recursion functions


   
  // Function -- NODOCS -- pack_string
  //
  // Packs a string value into the pack array. 
  //
  // When the metadata flag is set, the packed string is terminated by a ~null~
  // character to mark the end of the string.
  //
  // This is useful for mixed language communication where unpacking may occur
  // outside of SystemVerilog UVM.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.5
  extern virtual function void pack_string (string value);


  // Function -- NODOCS -- pack_time
  //
  // Packs a time ~value~ as 64 bits into the pack array.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.6
  extern virtual function void pack_time (time value); 


  // Function -- NODOCS -- pack_real
  //
  // Packs a real ~value~ as 64 bits into the pack array. 
  //
  // The real ~value~ is converted to a 6-bit scalar value using the function
  // $real2bits before it is packed into the array.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.7
  extern virtual function void pack_real (real value);


  // Function -- NODOCS -- pack_object
  //
  // Packs an object value into the pack array. 
  //
  // A 4-bit header is inserted ahead of the string to indicate the number of
  // bits that was packed. If a ~null~ object was packed, then this header will
  // be 0. 
  //
  // This is useful for mixed-language communication where unpacking may occur
  // outside of SystemVerilog UVM.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.2
  extern virtual function void pack_object (uvm_object value);
  
  extern virtual function void pack_object_with_meta (uvm_object value);
  
  extern virtual function void pack_object_wrapper (uvm_object_wrapper value);


  //------------------//
  // Group -- NODOCS -- Unpacking //
  //------------------//
  
  // Function -- NODOCS -- is_null
  //
  // This method is used during unpack operations to peek at the next 4-bit
  // chunk of the pack data and determine if it is 0.
  //
  // If the next four bits are all 0, then the return value is a 1; otherwise
  // it is 0. 
  //
  // This is useful when unpacking objects, to decide whether a new object
  // needs to be allocated or not.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.3
  extern virtual function bit is_null ();


  extern virtual function bit is_object_wrapper();
  // Function -- NODOCS -- unpack_field
  //
  // Unpacks bits from the pack array and returns the bit-stream that was
  // unpacked. ~size~ is the number of bits to unpack; the maximum is 4096 bits.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.16
  extern virtual function uvm_bitstream_t unpack_field (int size);

  // Function -- NODOCS -- unpack_field_int
  //
  // Unpacks bits from the pack array and returns the bit-stream that was
  // unpacked. 
  //
  // ~size~ is the number of bits to unpack; the maximum is 64 bits. 
  // This is a more efficient variant than unpack_field when unpacking into
  // smaller vectors.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.17
  extern virtual function uvm_integral_t unpack_field_int (int size);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.18
  extern virtual function void unpack_bits(ref bit value[], input int size = -1);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.19
  extern virtual function void unpack_bytes(ref byte value[], input int size = -1);


  // @uvm-ieee 1800.2-2020 auto 16.5.4.12
  extern virtual function void unpack_ints(ref int value[], input int size = -1);
   

  // Function -- NODOCS -- unpack_string
  //
  // Unpacks a string. 
  //
  // @uvm-ieee 1800.2-2020 auto 16.5.4.13
  extern virtual function string unpack_string ();


  // Function -- NODOCS -- unpack_time
  //
  // Unpacks the next 64 bits of the pack array and places them into a
  // time variable.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.14
  extern virtual function time unpack_time (); 


  // Function -- NODOCS -- unpack_real
  //
  // Unpacks the next 64 bits of the pack array and places them into a
  // real variable. 
  //
  // The 64 bits of packed data are converted to a real using the $bits2real
  // system function.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.15
  extern virtual function real unpack_real ();


  // Function -- NODOCS -- unpack_object
  //
  // Unpacks an object and stores the result into ~value~. 
  //
  // ~value~ must be an allocated object that has enough space for the data
  // being unpacked. The first four bits of packed data are used to determine
  // if a ~null~ object was packed into the array.
  //
  // The <is_null> function can be used to peek at the next four bits in
  // the pack array before calling this method.

  // @uvm-ieee 1800.2-2020 auto 16.5.4.4
  extern virtual function void unpack_object (uvm_object value);
  
  extern virtual function void unpack_object_with_meta (inout uvm_object value);

  extern virtual function uvm_object_wrapper unpack_object_wrapper();


  // Function -- NODOCS -- get_packed_size
  //
  // Returns the number of bits that were packed.

  // @uvm-ieee 1800.2-2020 auto 16.5.3.3
  extern virtual function int get_packed_size(); 


  //------------------//
  // Group -- NODOCS -- Variables //
  //------------------//

  // variables and methods primarily for internal use

  static bit bitstream[];   // local bits for (un)pack_bytes
  static bit fabitstream[]; // field automation bits for (un)pack_bytes
  int        m_pack_iter; // Used to track the bit of the next pack
  int        m_unpack_iter; // Used to track the bit of the next unpack

  bit   reverse_order;      //flip the bit order around
  byte  byte_size     = 8;  //set up bytesize for endianess
  int   word_size     = 16; //set up worksize for endianess
  bit   nopack;             //only count packable bits

  uvm_pack_bitstream_t m_bits;
  
  //@uvm-compat
  bit physical = 1;

  //@uvm-compat
  bit abstract = 1 ;


  extern function void index_error(int index, string id, int sz);
  extern function bit enough_bits(int needed, string id);

  //@uvm-compat provided to support uvm_compat_pkg
  function string unpack_string_with_size (int num_chars=-1);
     return unpack_string();
  endfunction

endclass



//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

// NOTE- max size limited to BITSTREAM bits parameter (default: 4096)


// index_ok
// --------

function void uvm_packer::index_error(int index, string id, int sz);
    uvm_report_error("PCKIDX", 
        $sformatf("index %0d for get_%0s too large; valid index range is 0-%0d.",
                  index,id,((m_pack_iter+sz-1)/sz)-1), UVM_NONE);
endfunction


// enough_bits
// -----------

function bit uvm_packer::enough_bits(int needed, string id);
  if ((m_pack_iter - m_unpack_iter) < needed) begin
    uvm_report_error("PCKSZ",
        $sformatf("%0d bits needed to unpack %0s, yet only %0d available.",
                  needed, id, (m_pack_iter - m_unpack_iter)), UVM_NONE);
    return 0;
  end
  return 1;
endfunction


// get_packed_size
// ---------------

function int uvm_packer::get_packed_size();
  return m_pack_iter - m_unpack_iter;
endfunction


function void uvm_packer::flush();
  // The iterators are spaced 64b from the beginning, enough to store
  // the iterators during get_packed_* and retrieve them during
  // set_packed_*.  Without this, set_packed_[byte|int|longint] will
  // move the iterators too far.
  m_pack_iter = 64;
  m_unpack_iter = 64;
  m_bits       = 0;
  m_object_references.delete();
  m_object_references[0] = null;
  m_factory = null;
  super.flush();
endfunction : flush

// get_packed_bits
// --------

function void uvm_packer::get_packed_bits(ref bit unsigned stream[]);
  stream        = new[m_pack_iter];
  m_bits[31:0]  = m_pack_iter; /* Reserved bits */
  m_bits[63:32] = m_unpack_iter; /* Reserved bits */
  for (int i=0;i<m_pack_iter;i++)
    stream[i] = m_bits[i];
endfunction

`define M__UVM_GET_PACKED(T) \
function void uvm_packer::get_packed_``T``s (ref T unsigned stream[] ); \
   int sz;                                                              \
   T v;                                                                 \
   sz = (m_pack_iter + $high(v)) / $bits(T);                            \
   m_bits[31:0] = m_pack_iter; /* Reserved Bits */                      \
   m_bits[63:32] = m_unpack_iter; /* Reserved Bits */                   \
   stream = new[sz];                                                    \
   foreach (stream[i]) begin                                            \
      if (i != sz-1 || (m_pack_iter % $bits(T)) == 0)                   \
	v = m_bits[ i* $bits(T) +: $bits(T) ];                          \
      else                                                              \
	v = m_bits[ i* $bits(T) +: $bits(T) ] & ({$bits(T){1'b1}} >> ($bits(T)-(m_pack_iter%$bits(T)))); \
      stream[i] = v;                                                    \
   end                                                                  \
endfunction 

`M__UVM_GET_PACKED(byte)
`M__UVM_GET_PACKED(int)
`M__UVM_GET_PACKED(longint)

`undef M__UVM_GET_PACKED

// set_packed_bits
// --------

function void uvm_packer::set_packed_bits (ref bit stream []);

  int bit_size;

  bit_size = stream.size();

    for (int i=0;i<bit_size;i++)
      m_bits[i] = stream[i];

  m_pack_iter = m_bits[31:0]; /* Reserved Bits */
  m_unpack_iter = m_bits[63:32]; /* Reserved Bits */
 
endfunction

`define M__UVM_SET_PACKED(T) \
function void uvm_packer::set_packed_``T``s (ref T unsigned stream []); \
   int count;                                                           \
   foreach(stream[i]) begin                                             \
     m_bits[count +: $bits(T)] = stream[i];                             \
     count += $bits(T);                                                 \
   end                                                                  \
  m_pack_iter = m_bits[31:0]; /* Reserved Bits */                       \
  m_unpack_iter = m_bits[63:32]; /* Reserved Bits */                    \
endfunction 

`M__UVM_SET_PACKED(byte)
`M__UVM_SET_PACKED(int)
`M__UVM_SET_PACKED(longint)

`undef M__UVM_SET_PACKED


// PACK


// pack_object
// ---------

function void uvm_packer::pack_object(uvm_object value);
  uvm_field_op field_op;
  if (value == null ) begin
    m_bits[m_pack_iter +: 4] = 0;
    m_pack_iter += 4;
    return ;
  end
  else begin
    m_bits[m_pack_iter +: 4]  = 4'hF;
    m_pack_iter += 4;
  end
  
  push_active_object(value);
  field_op = uvm_field_op::m_get_available_op() ;
  field_op.set(UVM_PACK,this,value);
  value.do_execute_op(field_op);
  if (field_op.user_hook_enabled()) begin
    value.do_pack(this);
  end
  field_op.m_recycle();
  void'(pop_active_object());
endfunction

// Function: pack_object_with_meta
// Packs ~obj~ into the packer data stream, such that
// it can be unpacked via an associated <unpack_object_with_meta>
// call.
//
// Unlike <pack_object>, the pack_object_with_meta method keeps track
// of what objects have already been packed in this call chain.  The
// first time an object is passed to pack_object_with_meta after a
// call to <flush>, the object is assigned a unique id.  Subsequent
// calls to pack_object_with_meta will only add the unique id to the
// stream.  This allows structural information to be maintained through
// pack/unpack operations.
//
// Note: pack_object_with_meta is not compatible with <unpack_object>
// and <is_null>.  The object can only be unpacked via 
// <unpack_object_with_meta>.
//
// @uvm-contrib This API is being considered for potential contribution to 1800.2
function void uvm_packer::pack_object_with_meta(uvm_object value);
  int reference_id;
  foreach(m_object_references[i]) begin
    if (m_object_references[i] == value) begin
      pack_field_int(i,32);
      return;
    end
  end
  
  // Size will always be >0 because 0 is the null
  reference_id = m_object_references.size();
  pack_field_int(reference_id,32);
  m_object_references[reference_id] = value;
  pack_object_wrapper(value.get_object_type());

  pack_object(value); 
endfunction


function void uvm_packer::pack_object_wrapper(uvm_object_wrapper value);
  string type_name;
  if (value != null) begin 
    pack_string(value.get_type_name());
  end
endfunction   
// pack_real
// ---------

function void uvm_packer::pack_real(real value);
  pack_field_int($realtobits(value), 64);
endfunction
  

// pack_time
// ---------

function void uvm_packer::pack_time(time value);
  pack_field_int(value, 64);
  //m_bits[m_pack_iter +: 64] = value; this overwrites endian adjustments
endfunction
  

// pack_field
// ----------

function void uvm_packer::pack_field(uvm_bitstream_t value, int size);
  for (int i=0; i<size; i++)
      m_bits[m_pack_iter+i] = value[i];
  m_pack_iter += size;
endfunction
  

// pack_field_int
// --------------

function void uvm_packer::pack_field_int(uvm_integral_t value, int size);
  for (int i=0; i<size; i++)
      m_bits[m_pack_iter+i] = value[i];
  m_pack_iter += size;
endfunction
  
// pack_bits
// -----------------

function void uvm_packer::pack_bits(ref bit value[], input int size = -1);
   if (size < 0)
     size = value.size();

   if (size > value.size()) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("pack_bits called with size '%0d', which exceeds value.size() of '%0d'",
                           size,
                           value.size()))
      return;
   end
   
   for (int i=0; i<size; i++)
       m_bits[m_pack_iter+i] = value[i];
   m_pack_iter += size;
endfunction 

// pack_bytes
// -----------------

function void uvm_packer::pack_bytes(ref byte value[], input int size = -1);
   int max_size = value.size() * $bits(byte);
   
   if (size < 0)
     size = max_size;

   if (size > max_size) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("pack_bytes called with size '%0d', which exceeds value size of '%0d'",
                           size,
                           max_size))
      return;
   end
   else begin
      int idx_select;

      for (int i=0; i<size; i++) begin
           idx_select = i;
         
         m_bits[m_pack_iter+i] = value[idx_select / $bits(byte)][idx_select % $bits(byte)];
      end
   
      m_pack_iter += size;
   end
endfunction 

// pack_ints
// -----------------

function void uvm_packer::pack_ints(ref int value[], input int size = -1);
   int max_size = value.size() * $bits(int);
   
   if (size < 0)
     size = max_size;

   if (size > max_size) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("pack_ints called with size '%0d', which exceeds value size of '%0d'",
                           size,
                           max_size))
      return;
   end
   else begin
      int idx_select;

      for (int i=0; i<size; i++) begin
           idx_select = i;
         
         m_bits[m_pack_iter+i] = value[idx_select / $bits(int)][idx_select % $bits(int)];
      end
   
      m_pack_iter += size;
   end
endfunction 


// pack_string
// -----------

function void uvm_packer::pack_string(string value);
  byte b;
  foreach (value[index]) begin
     m_bits[m_pack_iter +: 8] = value[index];
     m_pack_iter += 8;
  end
   m_bits[m_pack_iter +: 8] = 0;
   m_pack_iter += 8;
endfunction 


// UNPACK


// is_null
// -------

function bit uvm_packer::is_null();
    return (m_bits[m_unpack_iter+:4]==0);
endfunction


function bit uvm_packer::is_object_wrapper();
    return (m_bits[m_unpack_iter+:4]==1);
endfunction
// unpack_object
// -------------

function void uvm_packer::unpack_object(uvm_object value);
  uvm_field_op field_op;
  
  if (is_null()) begin
    if (value != null) begin
      `uvm_error("UVM/BASE/PACKER/UNPACK/N2NN", "attempt to unpack a null object into a not-null object!")
      return;
    end
    m_unpack_iter += 4; // advance past the null
    return;
  end
  else begin
    if (value == null) begin
      `uvm_error("UVM/BASE/PACKER/UNPACK/NN2N", "attempt to unpack a non-null object into a null object!")
      return;
    end
    m_unpack_iter += 4; // advance past the !null
    push_active_object(value);
    field_op = uvm_field_op::m_get_available_op() ;
    field_op.set(UVM_UNPACK,this,value);
    value.do_execute_op(field_op);
    if (field_op.user_hook_enabled()) begin
       value.do_unpack(this);
    end
    field_op.m_recycle();
    void'(pop_active_object());
  end

endfunction

// Function: unpack_object_with_meta
// Unpacks an object which was packed into the packer data
// stream using <pack_object_with_meta>.
//
// Unlike <unpack_object>, the unpack_object_with_meta method keeps track
// of what objects have already been unpacked in this call chain.  If the
// packed object was null, then ~value~ is set to null.  Otherwise, if this
// is the first time the object's unique id  
// has been encountered since a call to <flush>,
// then unpack_object_with_meta checks ~value~ to determine if it is the
// correct type.  If it is not the correct type, or if ~value~ is null, 
// then the packer shall create a new object instance for the unpack operation, 
// using the data provided by <pack_object_with_meta>. If ~value~ is of the 
// correct type, then it is used as the object instance for the unpack operation.
// Subsequent calls to unpack_object_with_meta for this unique id shall
// simply set ~value~ to this object instance.
//
// Note: unpack_object_with_meta is not compatible with <pack_object>
// or <is_null>.  The object must have been packed via
// <pack_object_with_meta>.
//
// @uvm-contrib This API is being considered for potential contribution to 1800.2
function void uvm_packer::unpack_object_with_meta(inout uvm_object value);
  int reference_id; 
  reference_id = unpack_field_int(32);
  if (m_object_references.exists(reference_id)) begin
    value = m_object_references[reference_id];
    return;
  end
  else begin
    uvm_object_wrapper __wrapper = unpack_object_wrapper();
    if ((__wrapper != null) && 
        ((value == null) || (value.get_object_type() != __wrapper))) begin 
      value = __wrapper.create_object("");
      if (value == null) begin
        value = __wrapper.create_component("",null);
      end
    end 
  end
  m_object_references[reference_id] = value;
  unpack_object(value);
endfunction


function uvm_object_wrapper uvm_packer::unpack_object_wrapper();
  string type_name;
  type_name = unpack_string();
  if (m_factory == null)
    m_factory = uvm_factory::get();
  if (m_factory.is_type_name_registered(type_name)) begin
    return m_factory.find_wrapper_by_name(type_name);
  end
  return null;

endfunction
  
// unpack_real
// -----------

function real uvm_packer::unpack_real();
  if (enough_bits(64,"real")) begin
    return $bitstoreal(unpack_field_int(64));
  end
endfunction
  

// unpack_time
// -----------

function time uvm_packer::unpack_time();
  if (enough_bits(64,"time")) begin
    return unpack_field_int(64);
  end
endfunction
  

// unpack_field
// ------------

function uvm_bitstream_t uvm_packer::unpack_field(int size);
  unpack_field = 'b0;
  if (enough_bits(size,"integral")) begin
    m_unpack_iter += size;
    for (int i=0; i<size; i++)
        unpack_field[i] = m_bits[m_unpack_iter-size+i];
  end
endfunction
  

// unpack_field_int
// ----------------

function uvm_integral_t uvm_packer::unpack_field_int(int size);
  unpack_field_int = 'b0;
  if (enough_bits(size,"integral")) begin
    m_unpack_iter += size;
    for (int i=0; i<size; i++)
        unpack_field_int[i] = m_bits[m_unpack_iter-size+i];
  end
endfunction
  
// unpack_bits
// -------------------

function void uvm_packer::unpack_bits(ref bit value[], input int size = -1);
   if (size < 0)
     size = value.size();

   if (size > value.size()) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("unpack_bits called with size '%0d', which exceeds value.size() of '%0d'",
                           size,
                           value.size()))
      return;
   end
   
   if (enough_bits(size, "integral")) begin
      m_unpack_iter += size;
      for (int i=0; i<size; i++)
          value[i] = m_bits[m_unpack_iter-size+i];
   end
endfunction

// unpack_bytes
// -------------------

function void uvm_packer::unpack_bytes(ref byte value[], input int size = -1);
   int max_size = value.size() * $bits(byte);
   if (size < 0)
     size = max_size;

   if (size > max_size) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("unpack_bytes called with size '%0d', which exceeds value size of '%0d'",
                           size,
                           value.size()))
      return;
   end
   else begin
      if (enough_bits(size, "integral")) begin
         m_unpack_iter += size;

         for (int i=0; i<size; i++) begin
              value[ i / $bits(byte) ][ i % $bits(byte) ] = m_bits[m_unpack_iter-size+i];
         
         end
      end // if (enough_bits(size, "integral"))
   end
endfunction

// unpack_ints
// -------------------

function void uvm_packer::unpack_ints(ref int value[], input int size = -1);
   int max_size = value.size() * $bits(int);
   if (size < 0)
     size = max_size;

   if (size > max_size) begin
      `uvm_error("UVM/BASE/PACKER/BAD_SIZE",
                 $sformatf("unpack_ints called with size '%0d', which exceeds value size of '%0d'",
                           size,
                           value.size()))
      return;
   end
   else begin
      if (enough_bits(size, "integral")) begin
         m_unpack_iter += size;

         for (int i=0; i<size; i++) begin
              value[ i / $bits(int) ][ i % $bits(int) ] = m_bits[m_unpack_iter-size+i];
         end   
      end
   end
endfunction


// unpack_string
// -------------

function string uvm_packer::unpack_string();
  byte b;
  int i; i=0;

  while(enough_bits(8,"string") && 
        (m_bits[m_unpack_iter+:8] != 0) )
  begin
    // silly, because cannot append byte/char to string
    unpack_string = {unpack_string," "};
      unpack_string[i] = m_bits[m_unpack_iter +: 8];
    m_unpack_iter += 8;
    ++i;
  end
  if(enough_bits(8,"string"))
    m_unpack_iter += 8;
endfunction 


// Constructor implementation
function uvm_packer::new(string name="");
  super.new(name);
  flush();
endfunction


