//
//------------------------------------------------------------------------------
// Copyright 2022 Marvell International Ltd.
// Copyright 2022 NVIDIA Corporation
//
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
//
// CLASS: uvm_compat_packer
//
// The uvm_compat_packer is provided as a convenience for users with code
// written for compatibility with UVM versions 1.1d and 1.2.  The packer 
// was restructured in 1800.2, but this packer behaves like the default
// packer in those older versions.

`ifndef UVM_VERSION
// before 1800.2, the uvm_compat_packer is the uvm_packer
typedef uvm_packer uvm_compat_packer;

`else
//@uvm-compat provided as a packer compatible with the default packer in 1.2
class uvm_compat_packer extends uvm_pkg::uvm_packer ;
   bit physical = 1 ;
   bit abstract ;
   bit big_endian = 1 ;
   bit use_metadata ;
   `uvm_object_utils(uvm_compat_pkg::uvm_compat_packer)
   function new(string name = "uvm_compat_packer") ;
      super.new(name);
   endfunction

local bit m_get_packed_unstable;

function void get_packed_bits(ref bit unsigned stream[]);
  if (m_get_packed_unstable) begin
    `uvm_error("UVM/COMPAT_PACKER/UNPACK_GET_PACKED",
               "unpack method called without a prior set_packed")  
  end
  stream        = new[m_pack_iter-64];
  for (int i=0;i<m_pack_iter-64;i++)
    stream[i] = m_bits[i+64];
endfunction

`define M__UVM_GET_PACKED(T) \
function void get_packed_``T``s (ref T unsigned stream[] ); \
   int sz;                                                              \
   int offset;                                                          \
   T v;                                                                 \
   if (m_get_packed_unstable) begin                                     \
     `uvm_error("UVM/COMPAT_PACKER/UNPACK_GET_PACKED",                  \
                "unpack method called without a prior set_packed")      \
   end                                                                  \
   sz = (m_pack_iter - 64 + $high(v)) / $bits(T);                       \
   stream = new[sz];                                                    \
   foreach (stream[i]) begin                                            \
      offset = i + 64/$bits(T);                                         \
      if (i != sz-1 || (m_pack_iter % $bits(T)) == 0)                   \
	v = m_bits[ offset* $bits(T) +: $bits(T) ];                          \
      else                                                              \
	v = m_bits[ offset* $bits(T) +: $bits(T) ] & ({$bits(T){1'b1}} >> ($bits(T)-(m_pack_iter%$bits(T)))); \
      if(big_endian)                                                    \
	v = {<<{v}};                                                    \
      stream[i] = v;                                                    \
   end                                                                  \
endfunction 
`M__UVM_GET_PACKED(byte)
`M__UVM_GET_PACKED(int)
`M__UVM_GET_PACKED(longint)

`undef M__UVM_GET_PACKED

local bit m_set_packed_active ;

function void flush();
   super.flush();
   m_set_packed_active = 0 ;
   m_get_packed_unstable = 0 ;
endfunction : flush

function void set_packed_bits (ref bit stream []);

  int bit_size;

  bit_size = stream.size();

  if(big_endian)
    for (int i=bit_size-1;i>=0;i--)
      m_bits[i] = stream[i];
  else
    for (int i=0;i<bit_size;i++)
      m_bits[i] = stream[i];

  m_pack_iter = bit_size;  
  m_unpack_iter = 0; 

  m_set_packed_active = 1 ;
 
endfunction

`define M__UVM_SET_PACKED(T) \
function void set_packed_``T``s (ref T unsigned stream []); \
   int count;                                                           \
   foreach(stream[i]) begin                                             \
     if (big_endian)                                                    \
       m_bits[count +: $bits(T)] = {<<{stream[i]}};                     \
     else                                                               \
       m_bits[count +: $bits(T)] = stream[i];                           \
     count += $bits(T);                                                 \
   end                                                                  \
  m_pack_iter = stream.size() * $bits(T); //                            \
  m_unpack_iter = 0;                                                    \
  m_set_packed_active = 1 ;                                             \
endfunction 

`M__UVM_SET_PACKED(byte)
`M__UVM_SET_PACKED(int)
`M__UVM_SET_PACKED(longint)

`undef M__UVM_SET_PACKED



function void pack_field(uvm_pkg::uvm_bitstream_t value, int size);
  if (m_set_packed_active) begin
    `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
               "pack method called after set_packed")     
  end
  for (int i=0; i<size; i++)
    if(big_endian == 1)
      m_bits[m_pack_iter+i] = value[size-1-i];
    else
      m_bits[m_pack_iter+i] = value[i];
  m_pack_iter += size;
endfunction
 
function void pack_field_int(uvm_pkg::uvm_integral_t value, int size);
  if (m_set_packed_active) begin
    `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
               "pack method called after set_packed")     
  end
  for (int i=0; i<size; i++)
    if(big_endian == 1)
      m_bits[m_pack_iter+i] = value[size-1-i];
    else
      m_bits[m_pack_iter+i] = value[i];
  m_pack_iter += size;
endfunction

function void pack_bits(ref bit value[], input int size = -1);
   if (m_set_packed_active) begin
     `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
                "pack method called after set_packed")     
   end
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
     if (big_endian == 1)
       m_bits[m_pack_iter+i] = value[size-1-i];
     else
       m_bits[m_pack_iter+i] = value[i];
   m_pack_iter += size;
endfunction 

function void pack_bytes(ref byte value[], input int size = -1);
   int max_size = value.size() * $bits(byte);
   
   if (m_set_packed_active) begin
     `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
                "pack method called after set_packed")     
  end
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
         if (big_endian == 1)
           idx_select = size-1-i;
         else
           idx_select = i;
         
         m_bits[m_pack_iter+i] = value[idx_select / $bits(byte)][idx_select % $bits(byte)];
      end
   
      m_pack_iter += size;
   end
endfunction 

function void pack_ints(ref int value[], input int size = -1);
   int max_size = value.size() * $bits(int);
   
   if (m_set_packed_active) begin
     `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
                "pack method called after set_packed")     
   end
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
         if (big_endian == 1)
           idx_select = size-1-i;
         else
           idx_select = i;
         
         m_bits[m_pack_iter+i] = value[idx_select / $bits(int)][idx_select % $bits(int)];
      end
   
      m_pack_iter += size;
   end
endfunction 

function void pack_string(string value);
  byte b;
  if (m_set_packed_active) begin
    `uvm_error("UVM/COMPAT_PACKER/SET_PACKED_PACK",
               "pack method called after set_packed")     
  end
  foreach (value[index]) begin
    if(big_endian == 1) begin
      b = value[index];
      for(int i=0; i<8; ++i)
        m_bits[m_pack_iter+i] = b[7-i];
    end 
    else 
      m_bits[m_pack_iter +: 8] = value[index];
    m_pack_iter += 8;
  end
  if (use_metadata == 1) begin
    m_bits[m_pack_iter +: 8] = 0;
    m_pack_iter += 8;
  end
endfunction 

function uvm_pkg::uvm_bitstream_t unpack_field(int size);
  unpack_field = 'b0;
  if (enough_bits(size,"integral")) begin
    m_unpack_iter += size;
    for (int i=0; i<size; i++)
      if(big_endian == 1)
        unpack_field[i] = m_bits[m_unpack_iter-i-1];
      else
        unpack_field[i] = m_bits[m_unpack_iter-size+i];
  end
  if (!m_set_packed_active) m_get_packed_unstable = 1 ;
endfunction

function uvm_pkg::uvm_integral_t unpack_field_int(int size);
  unpack_field_int = 'b0;
  if (enough_bits(size,"integral")) begin
    m_unpack_iter += size;
    for (int i=0; i<size; i++)
      if(big_endian == 1)
        unpack_field_int[i] = m_bits[m_unpack_iter-i-1];
      else
        unpack_field_int[i] = m_bits[m_unpack_iter-size+i];
  end
  if (!m_set_packed_active) m_get_packed_unstable = 1 ;
endfunction
  
function void unpack_bits(ref bit value[], input int size = -1);
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
        if (big_endian == 1)
          value[i] = m_bits[m_unpack_iter-i-1];
        else
          value[i] = m_bits[m_unpack_iter-size+i];
   end
   if (!m_set_packed_active) m_get_packed_unstable = 1 ;
endfunction

function void unpack_bytes(ref byte value[], input int size = -1);
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
            if (big_endian == 1)
              value[ i / $bits(byte) ][ i % $bits(byte) ] = m_bits[m_unpack_iter-i-1];
            else
              value[ i / $bits(byte) ][ i % $bits(byte) ] = m_bits[m_unpack_iter-size+i];
         
         end
      end // if (enough_bits(size, "integral"))
   end
   if (!m_set_packed_active) m_get_packed_unstable = 1 ;
endfunction

function void unpack_ints(ref int value[], input int size = -1);
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
            if (big_endian == 1)
              value[ i / $bits(int) ][ i % $bits(int) ] = m_bits[m_unpack_iter-i-1];
            else
              value[ i / $bits(int) ][ i % $bits(int) ] = m_bits[m_unpack_iter-size+i];
         end   
      end
   end
   if (!m_set_packed_active) m_get_packed_unstable = 1 ;
endfunction


function string unpack_string();
   return unpack_string_with_size();
endfunction

function string unpack_string_with_size(int num_chars=-1);
  string unpack_str ;
  byte b;
  int i; i=0;

  while(enough_bits(8,"string") && 
          ((num_chars == -1) ? (m_bits[m_unpack_iter+:8] != 0) :
                                  (i < num_chars)) 
       )
  begin
    // silly, because cannot append byte/char to string
    unpack_str = {unpack_str," "};
    if(big_endian == 1) begin
      for(int j=0; j<8; ++j)
        b[7-j] = m_bits[m_unpack_iter+j];
      unpack_str[i] = b;
    end 
    else
      unpack_str[i] = m_bits[m_unpack_iter +: 8];
    m_unpack_iter += 8;
    ++i;
  end
  if(enough_bits(8,"string"))
    m_unpack_iter += 8;
  if (!m_set_packed_active) m_get_packed_unstable = 1 ;
  return unpack_str;
endfunction 

function void pack_object(uvm_object value);
  uvm_field_op field_op;
  
  push_active_object(value);
  field_op = uvm_field_op::m_get_available_op() ;
  field_op.set(UVM_PACK,this,value);
  value.do_execute_op(field_op);
  if (field_op.user_hook_enabled()) begin
     if ((get_active_object_depth() > 1) && use_metadata) begin
        m_bits[m_pack_iter +: 4] = 1;
        m_pack_iter += 4;
     end
    value.do_pack(this);
  end
  else if ((get_active_object_depth() > 1) && use_metadata) begin
     m_bits[m_pack_iter +: 4] = 0;
     m_pack_iter += 4;
  end
  field_op.m_recycle();
  void'(pop_active_object());
endfunction

function void unpack_object(uvm_pkg::uvm_object value);
  uvm_pkg::uvm_field_op field_op;
  
  if ((get_active_object_depth() > 1) && use_metadata && is_null()) begin
    if (value != null) begin
      `uvm_error("UVM/COMPAT_PACKER/UNPACK_N2NN", "attempt to unpack a null object into a not-null object!")
      return;
    end
    m_unpack_iter += 4; // advance past the null
    return;
  end
  else begin
    if (value == null) begin
      `uvm_error("UVM/COMPAT_PACKER/UNPACK_NN2N", "attempt to unpack a non-null object into a null object!")
      return;
    end
    if ((get_active_object_depth() > 1) && use_metadata) m_unpack_iter += 4; // advance past the !null
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

// The following API was commented as "primarily for internal use" in 1.2
// 
virtual function void unpack_object_ext(inout uvm_object value);
  unpack_object(value);
endfunction

function void index_error(int index, string id, int sz);
    uvm_report_error("PCKIDX", 
        $sformatf("index %0d for get_%0s too large; valid index range is 0-%0d.",
                  index,id,((m_pack_iter+sz-1)/sz)-1), UVM_NONE);
endfunction

virtual function bit unsigned get_bit(int unsigned index);
  if (index >= m_pack_iter)
    index_error(index, "bit",1);
  return m_bits[index];
endfunction

virtual function byte unsigned get_byte(int unsigned index);
  if (index >= (m_pack_iter+7)/8)
    index_error(index, "byte",8);
  return m_bits[index*8 +: 8];
endfunction

virtual function int unsigned get_int(int unsigned index);
  if (index >= (m_pack_iter+31)/32)
    index_error(index, "int",32);
  return m_bits[(index*32) +: 32];
endfunction

virtual function void get_bits(ref bit unsigned bits[]);
   get_packed_bits(bits);
endfunction

virtual function void get_bytes(ref byte unsigned bytes[]);
   get_packed_bytes(bytes);
endfunction

virtual function void get_ints(ref int unsigned ints[]);
   get_packed_ints(ints);
endfunction

virtual function void put_bits (ref bit bitstream []);
   set_packed_bits(bitstream);
endfunction

virtual function void put_bytes (ref byte unsigned bytestream []);
   set_packed_bytes(bytestream);
endfunction

virtual function void put_ints (ref int unsigned intstream []);
   set_packed_ints(intstream);
endfunction

virtual function void set_packed_size();
   // no additional functionality required now
endfunction

function void reset() ;
   flush();
endfunction
// End "primarily for internal use" API

endclass

`endif
