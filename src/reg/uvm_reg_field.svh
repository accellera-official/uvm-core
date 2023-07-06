//
// -------------------------------------------------------------
// Copyright 2010 AMD
// Copyright 2012 Accellera Systems Initiative
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2020-2022 Intel Corporation
// Copyright 2020-2022 Marvell International Ltd.
// Copyright 2010-2020 Mentor Graphics Corporation
// Copyright 2014-2020 NVIDIA Corporation
// Copyright 2018 Qualcomm, Inc.
// Copyright 2012-2022 Semifore
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
// -------------------------------------------------------------
//

typedef class uvm_reg_cbs;


// Class: uvm_reg_field
// This is an implementation of uvm_reg_field as described in 1800.2 with
// the addition of API described below.


// @uvm-ieee 1800.2-2020 auto 18.5.1
class uvm_reg_field extends uvm_object;

   // Variable -- NODOCS -- value
   // Mirrored field value.
   // This value can be sampled in a functional coverage model
   // or constrained when randomized.
   rand  uvm_reg_data_t  value; // Mirrored after randomize()

   local uvm_reg_data_t  m_mirrored; // What we think is in the HW
   local uvm_reg_data_t  m_desired;  // Mirrored after set()
   local string          m_access;
   local uvm_reg         m_parent;
   local int unsigned    m_lsb;
   local int unsigned    m_size;
   local bit             m_volatile;
   local uvm_reg_data_t  m_reset[string];
   local bit             m_written;
   local bit             m_read_in_progress;
   local bit             m_write_in_progress;
   local string          m_fname;
   local int             m_lineno;
   local int             m_cover_on;
   local bit             m_individually_accessible;
   local uvm_check_e     m_check;

   local static int m_max_size;
   local static bit m_policy_names[string];
   /*local*/ static uvm_reg_field m_reg_field_registry[string];

   constraint uvm_reg_field_valid {
      if (`UVM_REG_DATA_WIDTH > m_size) {
         value < (`UVM_REG_DATA_WIDTH'h1 << m_size);
      }
   }

   `uvm_object_utils(uvm_reg_field)

   //----------------------
   // Group -- NODOCS -- Initialization
   //----------------------


   // @uvm-ieee 1800.2-2020 auto 18.5.3.1
   extern function new(string name = "uvm_reg_field");



   // @uvm-ieee 1800.2-2020 auto 18.5.3.2
   extern function void configure(uvm_reg        parent,
                                  int unsigned   size,
                                  int unsigned   lsb_pos,
                                  string         access,
                                  bit            volatile,
                                  uvm_reg_data_t reset,
                                  bit            has_reset,
                                  bit            is_rand,
                                  bit            individually_accessible); 


   //---------------------
   // Group -- NODOCS -- Introspection
   //---------------------

   // Function -- NODOCS -- get_name
   //
   // Get the simple name
   //
   // Return the simple object name of this field
   //


   // Function -- NODOCS -- get_full_name
   //
   // Get the hierarchical name
   //
   // Return the hierarchal name of this field
   // The base of the hierarchical name is the root block.
   //
   extern virtual function string get_full_name();



   // @uvm-ieee 1800.2-2020 auto 18.5.4.1
   extern virtual function uvm_reg get_parent();
   extern virtual function uvm_reg get_register();


   // Function -- NODOCS -- get_lsb_pos
   //
   // Return the position of the field
   //
   // Returns the index of the least significant bit of the field
   // in the register that instantiates it.
   // An offset of 0 indicates a field that is aligned with the
   // least-significant bit of the register. 
   //
   extern virtual function int unsigned get_lsb_pos();


   // Function -- NODOCS -- get_n_bits
   //
   // Returns the width, in number of bits, of the field. 
   //
   extern virtual function int unsigned get_n_bits();

   //
   // FUNCTION -- NODOCS -- get_max_size
   // Returns the width, in number of bits, of the largest field. 
   //
   extern static function int unsigned get_max_size();



   // @uvm-ieee 1800.2-2020 auto 18.5.4.6
   extern virtual function string set_access(string mode);

   // Function: set_rand_mode
   // Modifies the ~rand_mode~ for the field instance to the specified one
   //
   // @uvm-contrib This API is being considered for potential contribution to 1800.2
   extern virtual function void set_rand_mode(bit rand_mode);

   // Function: get_rand_mode
   // Returns the rand_mode of the field instance
   //
   // @uvm-contrib This API is being considered for potential contribution to 1800.2
   extern virtual function bit get_rand_mode();

   // @uvm-ieee 1800.2-2020 auto 18.5.4.7
   extern static function bit define_access(string name);
   local static bit m_predefined = m_predefine_policies();
   extern local static function bit m_predefine_policies();
 
   // Function -- NODOCS -- get_access
   //
   // Get the access policy of the field
   //
   // Returns the current access policy of the field
   // when written and read through the specified address ~map~.
   // If the register containing the field is mapped in multiple
   // address map, an address map must be specified.
   // The access policy of a field from a specific
   // address map may be restricted by the register's access policy in that
   // address map.
   // For example, a RW field may only be writable through one of
   // the address maps and read-only through all of the other maps.
   // If the field access contradicts the map's access value
   // (field access of WO, and map access value of RO, etc), the
   // method's return value is NOACCESS.

   // @uvm-ieee 1800.2-2020 auto 18.5.4.5
   extern virtual function string get_access(uvm_reg_map map = null);



   // @uvm-ieee 1800.2-2020 auto 18.5.4.8
   extern virtual function bit is_known_access(uvm_reg_map map = null);


   // @uvm-ieee 1800.2-2020 auto 18.5.4.9
   extern virtual function void set_volatility(bit volatile);


   // @uvm-ieee 1800.2-2020 auto 18.5.4.10
   extern virtual function bit is_volatile();
   
   // Function -- NODOCS -- get_field_by_full_name
   //
   // Finds a field with the specified full hierarchical name.
   //
   // The name is the full name of the field, starting with the root block.
   // The function looks up the cached registry built after register model is locked
   //
   // If no field is found, returns ~null~.
   
   static function uvm_reg_field get_field_by_full_name(string name);
      return m_reg_field_registry[name];
   endfunction

   //--------------
   // Group -- NODOCS -- Access
   //--------------



   // @uvm-ieee 1800.2-2020 auto 18.5.5.2
   extern virtual function void set(uvm_reg_data_t  value,
                                    string          fname = "",
                                    int             lineno = 0);


   // @uvm-ieee 1800.2-2020 auto 18.5.5.1
   extern virtual function uvm_reg_data_t get(string fname = "",
                                              int    lineno = 0);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.3
   extern virtual function uvm_reg_data_t get_mirrored_value(string fname = "",
                                              int    lineno = 0);


   // @uvm-ieee 1800.2-2020 auto 18.5.5.4
   extern virtual function void reset(string kind = "HARD");



   // @uvm-ieee 1800.2-2020 auto 18.5.5.6
   extern virtual function uvm_reg_data_t get_reset(string kind = "HARD");



   // @uvm-ieee 1800.2-2020 auto 18.5.5.5
   extern virtual function bit has_reset(string kind = "HARD",
                                         bit    delete = 0);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.7
   extern virtual function void set_reset(uvm_reg_data_t value,
                                          string kind = "HARD");



   // @uvm-ieee 1800.2-2020 auto 18.5.5.8
   extern virtual function bit needs_update();



   // @uvm-ieee 1800.2-2020 auto 18.5.5.9
   extern virtual task write (output uvm_status_e       status,
                              input  uvm_reg_data_t     value,
                              input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map        map = null,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.10
   extern virtual task read  (output uvm_status_e       status,
                              output uvm_reg_data_t     value,
                              input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map        map = null,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);
               


   // @uvm-ieee 1800.2-2020 auto 18.5.5.11
   extern virtual task poke  (output uvm_status_e       status,
                              input  uvm_reg_data_t     value,
                              input  string             kind = "",
                              input  uvm_sequence_base  parent = null,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.12
   extern virtual task peek  (output uvm_status_e       status,
                              output uvm_reg_data_t     value,
                              input  string             kind = "",
                              input  uvm_sequence_base  parent = null,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);
               


   // @uvm-ieee 1800.2-2020 auto 18.5.5.13
   extern virtual task mirror(output uvm_status_e      status,
                              input  uvm_check_e       check = UVM_NO_CHECK,
                              input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map       map = null,
                              input  uvm_sequence_base parent = null,
                              input  int               prior = -1,
                              input  uvm_object        extension = null,
                              input  string            fname = "",
                              input  int               lineno = 0);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.15
   extern function void set_compare(uvm_check_e check=UVM_CHECK);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.14
   extern function uvm_check_e get_compare();

   

   // @uvm-ieee 1800.2-2020 auto 18.5.5.16
   extern function bit is_indv_accessible (uvm_door_e  path,
                                           uvm_reg_map local_map);



   // @uvm-ieee 1800.2-2020 auto 18.5.5.17
   extern function bit predict (uvm_reg_data_t    value,
                                uvm_reg_byte_en_t be = -1,
                                uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                uvm_door_e        path = UVM_FRONTDOOR,
                                uvm_reg_map       map = null,
                                string            fname = "",
                                int               lineno = 0);



   /*local*/
   extern virtual function uvm_reg_data_t XpredictX (uvm_reg_data_t cur_val,
                                                     uvm_reg_data_t wr_val,
                                                     uvm_reg_map    map);

   /*local*/
   extern virtual function uvm_reg_data_t XupdateX();
  
   /*local*/
   extern function bit Xcheck_accessX (input uvm_reg_item rw,
                                       output uvm_reg_map_info map_info);

   extern virtual task do_write(uvm_reg_item rw);
   extern virtual task do_read(uvm_reg_item rw);
   extern virtual function void do_predict 
                                  (uvm_reg_item rw,
                                   uvm_predict_e kind=UVM_PREDICT_DIRECT,
                                   uvm_reg_byte_en_t be = -1);


   extern function void pre_randomize();
   extern function void post_randomize();


   //-----------------
   // Group -- NODOCS -- Callbacks
   //-----------------

   `uvm_register_cb(uvm_reg_field, uvm_reg_cbs)



   // @uvm-ieee 1800.2-2020 auto 18.5.6.1
   virtual task pre_write  (uvm_reg_item rw); endtask



   // @uvm-ieee 1800.2-2020 auto 18.5.6.2
   virtual task post_write (uvm_reg_item rw); endtask



   // @uvm-ieee 1800.2-2020 auto 18.5.6.3
   virtual task pre_read (uvm_reg_item rw); endtask



   // @uvm-ieee 1800.2-2020 auto 18.5.6.4
   virtual task post_read  (uvm_reg_item rw); endtask


   extern virtual function void do_print (uvm_printer printer);
   extern virtual function string convert2string;
   extern virtual function uvm_object clone();
   extern virtual function void do_copy   (uvm_object rhs);
   extern virtual function bit  do_compare (uvm_object  rhs,
                                            uvm_comparer comparer);
   extern virtual function void do_pack (uvm_packer packer);
   extern virtual function void do_unpack (uvm_packer packer);

endclass: uvm_reg_field


//------------------------------------------------------------------------------
// IMPLEMENTATION
//------------------------------------------------------------------------------

// new

function uvm_reg_field::new(string name = "uvm_reg_field");
   super.new(name);
endfunction: new


// configure

function void uvm_reg_field::configure(uvm_reg        parent,
                                       int unsigned   size,
                                       int unsigned   lsb_pos,
                                       string         access,
                                       bit            volatile,
                                       uvm_reg_data_t reset,
                                       bit            has_reset,
                                       bit            is_rand,
                                       bit            individually_accessible); 
   m_parent = parent;
   if (size == 0) begin
      `uvm_error("RegModel",
         $sformatf("Field \"%s\" cannot have 0 bits", get_full_name()))
      size = 1;
   end

   m_size      = size;
   m_volatile  = volatile;
   m_access    = access.toupper();
   m_lsb       = lsb_pos;
   m_cover_on  = UVM_NO_COVERAGE;
   m_written   = 0;
   m_check     = volatile ? UVM_NO_CHECK : UVM_CHECK;
   m_individually_accessible = individually_accessible;

   if (has_reset)
      set_reset(reset);

   m_parent.add_field(this);

   if (!m_policy_names.exists(m_access)) begin
      `uvm_error("RegModel", {"Access policy '",access,
       "' for field '",get_full_name(),"' is not defined. Setting to RW"})
      m_access = "RW";
   end

   if (size > m_max_size)
      m_max_size = size;
   
   // Ignore is_rand if the field is known not to be writeable
   // i.e. not "RW", "WRC", "WRS", "WO", "W1", "WO1"
   case (access)
    "RO", "RC", "RS", "WC", "WS",
      "W1C", "W1S", "W1T", "W0C", "W0S", "W0T",
      "W1SRC", "W1CRS", "W0SRC", "W0CRS", "WSRC", "WCRS",
      "WOC", "WOS": is_rand = 0;
   endcase

   if (!is_rand)
     set_rand_mode(0);

endfunction: configure


// get_parent

function uvm_reg uvm_reg_field::get_parent();
   return m_parent;
endfunction: get_parent


// get_full_name

function string uvm_reg_field::get_full_name();
   return {m_parent.get_full_name(), ".", get_name()};
endfunction: get_full_name


// get_register

function uvm_reg uvm_reg_field::get_register();
   return m_parent;
endfunction: get_register


// get_lsb_pos

function int unsigned uvm_reg_field::get_lsb_pos();
   return m_lsb;
endfunction: get_lsb_pos


// get_n_bits

function int unsigned uvm_reg_field::get_n_bits();
   return m_size;
endfunction: get_n_bits


// get_max_size

function int unsigned uvm_reg_field::get_max_size();
   return m_max_size;
endfunction: get_max_size


// is_known_access

function bit uvm_reg_field::is_known_access(uvm_reg_map map = null);
   string acc = get_access(map);
   case (acc)
    "RO", "RW", "RC", "RS", "WC", "WS",
      "W1C", "W1S", "W1T", "W0C", "W0S", "W0T",
      "WRC", "WRS", "W1SRC", "W1CRS", "W0SRC", "W0CRS", "WSRC", "WCRS",
      "WO", "WOC", "WOS", "W1", "WO1" : return 1;
   endcase
   return 0;
endfunction


// get_access

function string uvm_reg_field::get_access(uvm_reg_map map = null);
   string field_access = m_access;

   if (map == uvm_reg_map::backdoor())
     return field_access;

   // Is the register restricted in this map?
   case (m_parent.get_rights(map))
     "RW":
       // No restrictions
       return field_access;

     "RO":
       case (field_access)
        "RW", "RO", "WC", "WS",
          "W1C", "W1S", "W1T", "W0C", "W0S", "W0T",
          "W1"
        : field_access = "RO";
        
        "RC", "WRC", "W1SRC", "W0SRC", "WSRC"
        : field_access = "RC";
        
        "RS", "WRS", "W1CRS", "W0CRS", "WCRS"
        : field_access = "RS";
        
         "WO", "WOC", "WOS", "WO1": begin
            field_access = "NOACCESS";
         end

         // No change for the other modes
       endcase

     "WO":
       case (field_access)
	     "RW","WRC","WRS" : field_access = "WO";
	     "W1SRC" : field_access = "W1S";
	     "W0SRC": field_access = "W0S";
	     "W1CRS": field_access = "W1C";
	     "W0CRS": field_access = "W0C";
		 "WCRS": field_access = "WC";
	     "W1" : field_access = "W1";
	     "WO1" : field_access = "WO1";
	     "WSRC" : field_access = "WS";
         "RO","RC","RS": field_access = "NOACCESS";
         // No change for the other modes
         //         "WO","WC","WS","W1C","W1S","W0C","W0S","W0T","W1" : null;
         
       endcase

     default:
       begin
         field_access = "NOACCESS";
         `uvm_warning("RegModel", {"Register '",m_parent.get_full_name(),
                      "' containing field '",get_name(),"' is mapped in map '",
                      map.get_full_name(),"' with unknown access right '", m_parent.get_rights(map), "'"})
       end
   endcase
   return field_access;
endfunction: get_access


// set_access

function string uvm_reg_field::set_access(string mode);
   set_access = m_access;
   m_access = mode.toupper();
   if (!m_policy_names.exists(m_access)) begin
      `uvm_error("RegModel", {"Access policy '",m_access,
                              "' is not a defined field access policy"})
      m_access = set_access;
   end
endfunction: set_access


// set_rand_mode

function void uvm_reg_field::set_rand_mode(bit rand_mode);
    value.rand_mode(rand_mode);
endfunction: set_rand_mode   


// get_rand_mode

function bit uvm_reg_field::get_rand_mode();
    return bit'(value.rand_mode());
endfunction: get_rand_mode 


// define_access

function bit uvm_reg_field::define_access(string name);
   if (!m_predefined) m_predefined = m_predefine_policies();

   name = name.toupper();

   if (m_policy_names.exists(name)) return 0;

   m_policy_names[name] = 1;
   return 1;
endfunction


// m_predefined_policies

function bit uvm_reg_field::m_predefine_policies();
   if (m_predefined) return 1;

   m_predefined = 1;
   
   void'(define_access("RO"));
   void'(define_access("RW"));
   void'(define_access("RC"));
   void'(define_access("RS"));
   void'(define_access("WRC"));
   void'(define_access("WRS"));
   void'(define_access("WC"));
   void'(define_access("WS"));
   void'(define_access("WSRC"));
   void'(define_access("WCRS"));
   void'(define_access("W1C"));
   void'(define_access("W1S"));
   void'(define_access("W1T"));
   void'(define_access("W0C"));
   void'(define_access("W0S"));
   void'(define_access("W0T"));
   void'(define_access("W1SRC"));
   void'(define_access("W1CRS"));
   void'(define_access("W0SRC"));
   void'(define_access("W0CRS"));
   void'(define_access("WO"));
   void'(define_access("WOC"));
   void'(define_access("WOS"));
   void'(define_access("W1"));
   void'(define_access("WO1"));
   return 1;
endfunction


// set_volatility

function void uvm_reg_field::set_volatility(bit volatile);
   m_volatile = volatile;
endfunction


// is_volatile

function bit uvm_reg_field::is_volatile();
   return m_volatile;
endfunction


// XpredictX

function uvm_reg_data_t uvm_reg_field::XpredictX (uvm_reg_data_t cur_val,
                                                  uvm_reg_data_t wr_val,
                                                  uvm_reg_map    map);
   uvm_reg_data_t mask = ('b1 << m_size)-1;
   
   case (get_access(map))
     "RO":    return cur_val;
     "RW":    return wr_val;
     "RC":    return cur_val;
     "RS":    return cur_val;
     "WC":    return '0;
     "WS":    return mask;
     "WRC":   return wr_val;
     "WRS":   return wr_val;
     "WSRC":  return mask;
     "WCRS":  return '0;
     "W1C":   return cur_val & (~wr_val);
     "W1S":   return cur_val | wr_val;
     "W1T":   return cur_val ^ wr_val;
     "W0C":   return cur_val & wr_val;
     "W0S":   return cur_val | (~wr_val & mask);
     "W0T":   return cur_val ^ (~wr_val & mask);
     "W1SRC": return cur_val | wr_val;
     "W1CRS": return cur_val & (~wr_val);
     "W0SRC": return cur_val | (~wr_val & mask);
     "W0CRS": return cur_val & wr_val;
     "WO":    return wr_val;
     "WOC":   return '0;
     "WOS":   return mask;
     "W1":    return (m_written) ? cur_val : wr_val;
     "WO1":   return (m_written) ? cur_val : wr_val;
     "NOACCESS": return cur_val;
     default: return wr_val;
   endcase

   `uvm_fatal("RegModel", "uvm_reg_field::XpredictX(): Internal error")
   return 0;
endfunction: XpredictX



// predict

function bit uvm_reg_field::predict (uvm_reg_data_t    value,
                                     uvm_reg_byte_en_t be = -1,
                                     uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                     uvm_door_e        path = UVM_FRONTDOOR,
                                     uvm_reg_map       map = null,
                                     string            fname = "",
                                     int               lineno = 0);
  uvm_reg_item rw = new;
  rw.set_value(value,0);
  rw.set_door(path);
  rw.set_map(map);
  rw.set_fname(fname);
  rw.set_line(lineno);
  do_predict(rw, kind, be);
  predict = (rw.get_status() == UVM_NOT_OK) ? 0 : 1;
endfunction: predict


// do_predict

function void uvm_reg_field::do_predict(uvm_reg_item      rw,
                                        uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                        uvm_reg_byte_en_t be = -1);
   
   uvm_reg_data_t field_val = rw.get_value(0) & ((1 << m_size)-1);

   if (rw.get_status() != UVM_NOT_OK)
     rw.set_status(UVM_IS_OK);

   // Assume that the entire field is enabled
   if (!be[0])
     return;

   m_fname = rw.get_fname();
   m_lineno = rw.get_line();

   case (kind)

     UVM_PREDICT_WRITE:
       begin
         uvm_reg_field_cb_iter cbs = new(this);

         if (rw.get_door() == UVM_FRONTDOOR || rw.get_door() == UVM_PREDICT)
            field_val = XpredictX(m_mirrored, field_val, rw.get_map());

         m_written = 1;

         for (uvm_reg_cbs cb = cbs.first(); cb != null; cb = cbs.next())
            cb.post_predict(this, m_mirrored, field_val, 
                            UVM_PREDICT_WRITE, rw.get_door(), rw.get_map());

         field_val &= ('b1 << m_size)-1;

       end

     UVM_PREDICT_READ:
       begin
         uvm_reg_field_cb_iter cbs = new(this);

         if (rw.get_door() == UVM_FRONTDOOR || rw.get_door() == UVM_PREDICT) begin

            string acc = get_access(rw.get_map());

            if (acc == "RC" ||
                acc == "WRC" ||
                acc == "WSRC" ||
                acc == "W1SRC" ||
                acc == "W0SRC")
              field_val = 0;  // (clear)

            else if (acc == "RS" ||
                     acc == "WRS" ||
                     acc == "WCRS" ||
                     acc == "W1CRS" ||
                     acc == "W0CRS")
              field_val = ('b1 << m_size)-1; // all 1's (set)

            else if (acc == "WO" ||
                     acc == "WOC" ||
                     acc == "WOS" ||
                     acc == "WO1" ||
                     acc == "NOACCESS")
              return;
         end

         for (uvm_reg_cbs cb = cbs.first(); cb != null; cb = cbs.next())
            cb.post_predict(this, m_mirrored, field_val,
                            UVM_PREDICT_READ, rw.get_door(), rw.get_map());

         field_val &= ('b1 << m_size)-1;

       end

     UVM_PREDICT_DIRECT:
       begin
         if (m_parent.is_busy()) begin
           `uvm_warning("RegModel", {"Trying to predict value of field '",
              get_name(),"' while register '",m_parent.get_full_name(),
              "' is being accessed"})
           rw.set_status(UVM_NOT_OK);
         end
       end
   endcase

   // update the mirror with predicted value
   m_mirrored = field_val;
   m_desired  = field_val;
   this.value = field_val;

endfunction: do_predict


// XupdateX

function uvm_reg_data_t  uvm_reg_field::XupdateX();
   // Figure out which value must be written to get the desired value
   // given what we think is the current value in the hardware
   XupdateX = 0;

   case (m_access)
      "RO":    XupdateX = m_desired;
      "RW":    XupdateX = m_desired;
      "RC":    XupdateX = m_desired;
      "RS":    XupdateX = m_desired;
      "WRC":   XupdateX = m_desired;
      "WRS":   XupdateX = m_desired;
      "WC":    XupdateX = m_desired;  // Warn if != 0
      "WS":    XupdateX = m_desired;  // Warn if != 1
      "WSRC":  XupdateX = m_desired;  // Warn if != 1
      "WCRS":  XupdateX = m_desired;  // Warn if != 0
      "W1C":   XupdateX = ~m_desired;
      "W1S":   XupdateX = m_desired;
      "W1T":   XupdateX = m_desired ^ m_mirrored;
      "W0C":   XupdateX = m_desired;
      "W0S":   XupdateX = ~m_desired;
      "W0T":   XupdateX = ~(m_desired ^ m_mirrored);
      "W1SRC": XupdateX = m_desired;
      "W1CRS": XupdateX = ~m_desired;
      "W0SRC": XupdateX = ~m_desired;
      "W0CRS": XupdateX = m_desired;
      "WO":    XupdateX = m_desired;
      "WOC":   XupdateX = m_desired;  // Warn if != 0
      "WOS":   XupdateX = m_desired;  // Warn if != 1
      "W1":    XupdateX = m_desired;
      "WO1":   XupdateX = m_desired;
      default: XupdateX = m_desired;      
   endcase
   XupdateX &= (1 << m_size) - 1;
   
endfunction: XupdateX


// set

function void uvm_reg_field::set(uvm_reg_data_t  value,
                                 string          fname = "",
                                 int             lineno = 0);
   uvm_reg_data_t mask = ('b1 << m_size)-1;

   m_fname = fname;
   m_lineno = lineno;
   if (value >> m_size) begin
      `uvm_warning("RegModel",
         $sformatf("Specified value (0x%h) greater than field \"%s\" size (%0d bits)",
             value, get_name(), m_size))
      value &= mask;
   end

   if (m_parent.is_busy()) begin
      `uvm_warning("UVM/FLD/SET/BSY",
                   $sformatf("Setting the value of field \"%s\" while containing register \"%s\" is being accessed may result in loss of desired field value. A race condition between threads concurrently accessing the register model is the likely cause of the problem.",
                             get_name(), m_parent.get_full_name()))
   end

   case (m_access)
      "RO":    m_desired = m_desired;
      "RW":    m_desired = value;
      "RC":    m_desired = m_desired;
      "RS":    m_desired = m_desired;
      "WC":    m_desired = '0;
      "WS":    m_desired = mask;
      "WRC":   m_desired = value;
      "WRS":   m_desired = value;
      "WSRC":  m_desired = mask;
      "WCRS":  m_desired = '0;
      "W1C":   m_desired = m_desired & (~value);
      "W1S":   m_desired = m_desired | value;
      "W1T":   m_desired = m_desired ^ value;
      "W0C":   m_desired = m_desired & value;
      "W0S":   m_desired = m_desired | (~value & mask);
      "W0T":   m_desired = m_desired ^ (~value & mask);
      "W1SRC": m_desired = m_desired | value;
      "W1CRS": m_desired = m_desired & (~value);
      "W0SRC": m_desired = m_desired | (~value & mask);
      "W0CRS": m_desired = m_desired & value;
      "WO":    m_desired = value;
      "WOC":   m_desired = '0;
      "WOS":   m_desired = mask;
      "W1":    m_desired = (m_written) ? m_desired : value;
      "WO1":   m_desired = (m_written) ? m_desired : value;
      default: m_desired = value;
   endcase
   this.value = m_desired;
endfunction: set

 
// get

function uvm_reg_data_t  uvm_reg_field::get(string  fname = "",
                                            int     lineno = 0);
   m_fname = fname;
   m_lineno = lineno;
   get = m_desired;
endfunction: get

 
// get_mirrored_value

function uvm_reg_data_t  uvm_reg_field::get_mirrored_value(string  fname = "",
                                            int     lineno = 0);
   if (is_volatile())
       `uvm_warning("UVM/FLD/GET_MIRRORED_VAL/VOL",$sformatf("Mirrored value returned for volatile field \"%s\" may not reflect the actual current value.",this.get_full_name()))
   m_fname = fname;
   m_lineno = lineno;
   get_mirrored_value = m_mirrored;
endfunction: get_mirrored_value


// reset

function void uvm_reg_field::reset(string kind = "HARD");

   if (!m_reset.exists(kind))
      return;
   
   m_mirrored = m_reset[kind];
   m_desired  = m_mirrored;
   value      = m_mirrored;

   if (kind == "HARD")
      m_written  = 0;

endfunction: reset


// has_reset

function bit uvm_reg_field::has_reset(string kind = "HARD",
                                      bit    delete = 0);

   if (!m_reset.exists(kind)) return 0;

   if (delete) m_reset.delete(kind);

   return 1;
endfunction: has_reset


// get_reset

function uvm_reg_data_t
   uvm_reg_field::get_reset(string kind = "HARD");

   if (!m_reset.exists(kind))
      return m_desired;

   return m_reset[kind];

endfunction: get_reset


// set_reset

function void uvm_reg_field::set_reset(uvm_reg_data_t value,
                                       string kind = "HARD");
   m_reset[kind] = value & ((1<<m_size) - 1);
endfunction: set_reset


// needs_update

function bit uvm_reg_field::needs_update();
   if (get_access() inside {"RO","RC","RS"})
       return 0;
   needs_update = (m_mirrored != m_desired) | m_volatile;
endfunction: needs_update


typedef class uvm_reg_map_info;


// Xcheck_accessX

function bit uvm_reg_field::Xcheck_accessX(input uvm_reg_item rw,
                                           output uvm_reg_map_info map_info);
  uvm_reg_map local_tmp_map;
                        
   if (rw.get_door() == UVM_DEFAULT_DOOR) begin
     uvm_reg_block blk = m_parent.get_block();
     rw.set_door(blk.get_default_door());
   end

   if (rw.get_door() == UVM_BACKDOOR) begin
      if (m_parent.get_backdoor() == null && !m_parent.has_hdl_path()) begin
         `uvm_warning("RegModel",
            {"No backdoor access available for field '",get_full_name(),
            "' . Using frontdoor instead."})
         rw.set_door(UVM_FRONTDOOR);
      end
      else
        rw.set_map(uvm_reg_map::backdoor());
   end

   if (rw.get_door() != UVM_BACKDOOR) begin
     
     rw.set_local_map(m_parent.get_local_map(rw.get_map()));

     if (rw.get_local_map() == null) begin        
        local_tmp_map = rw.get_map();
        `uvm_error(get_type_name(), 
           {"No transactor available to physically access memory from map '",
            local_tmp_map.get_full_name(),"'"})
        rw.set_status(UVM_NOT_OK);
        return 0;
     end

     local_tmp_map = rw.get_local_map;
     map_info = local_tmp_map.get_reg_map_info(m_parent);

     if (map_info.frontdoor == null && map_info.unmapped) begin
        `uvm_error("RegModel", {"Field '",get_full_name(),
                   "' in register that is unmapped in map '",
                   local_tmp_map.get_full_name(),
                   "' and does not have a user-defined frontdoor"})
        rw.set_status(UVM_NOT_OK);
        return 0;
     end

     if (rw.get_map() == null)
       rw.set_map(rw.get_local_map());
   end

   return 1;
endfunction


// write

task uvm_reg_field::write(output uvm_status_e       status,
                          input  uvm_reg_data_t     value,
                          input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                          input  uvm_reg_map        map = null,
                          input  uvm_sequence_base  parent = null,
                          input  int                prior = -1,
                          input  uvm_object         extension = null,
                          input  string             fname = "",
                          input  int                lineno = 0);

   uvm_reg_item rw;
    
   set(value);
    
   rw = uvm_reg_item::type_id::create("field_write_item",,get_full_name());
   rw.set_element(this);
   rw.set_element_kind(UVM_FIELD);
   rw.set_kind(UVM_WRITE);
   rw.set_value(value, 0);
   rw.set_door(path);
   rw.set_map(map);
   rw.set_parent_sequence(parent);
   rw.set_priority(prior);
   rw.set_extension(extension);
   rw.set_fname(fname);
   rw.set_line(lineno);

   do_write(rw);

   status = rw.get_status();

endtask


// do_write

task uvm_reg_field::do_write(uvm_reg_item rw);

   uvm_reg_data_t   value_adjust;
   uvm_reg_map_info map_info;
   uvm_reg_field    fields[$];
   bit bad_side_effect;

   m_parent.XatomicX(1);
   m_fname  = rw.get_fname();
   m_lineno = rw.get_line();

   if (!Xcheck_accessX(rw,map_info)) begin
     m_parent.XatomicX(0);
     return;
   end

   m_write_in_progress = 1'b1;

   if (rw.get_value(0) >> m_size) begin
     uvm_reg_data_t tmp_value;
      `uvm_warning("RegModel", {"uvm_reg_field::write(): Value greater than field '",
                          get_full_name(),"'"})
      tmp_value = rw.get_value(0);
      tmp_value &= ((1<<m_size)-1);
      rw.set_value(tmp_value, 0);
   end

   // Get values to write to the other fields in register
   m_parent.get_fields(fields);
   foreach (fields[i]) begin

      if (fields[i] == this) begin
         value_adjust |= rw.get_value(0) << m_lsb;
         continue;
      end

      // It depends on what kind of bits they are made of...
      case (fields[i].get_access(rw.get_local_map()))
        // These...
        "RO", "RC", "RS", "W1C", "W1S", "W1T", "W1SRC", "W1CRC":
          // Use all 0's
          value_adjust |= 0;

        // These...
        "W0C", "W0S", "W0T", "W0SRC", "W0CRS":
          // Use all 1's
          value_adjust |= ((1<<fields[i].get_n_bits())-1) << fields[i].get_lsb_pos();

        // These might have side effects! Bad!
        "WC", "WS", "WCRS", "WSRC", "WOC", "WOS":
           bad_side_effect = 1;

        default:
           value_adjust |= fields[i].m_mirrored << fields[i].get_lsb_pos();

      endcase
   end

`ifdef UVM_REG_NO_INDIVIDUAL_FIELD_ACCESS
   rw.set_element_kind(UVM_REG);
   rw.set_element(m_parent);
   rw.set_value(value_adjust, 0);
   m_parent.do_write(rw);   
`else        

   if (!is_indv_accessible(rw.get_door(),rw.get_local_map())) begin
      rw.set_element_kind(UVM_REG);
      rw.set_element(m_parent);
      rw.set_value(value_adjust, 0);
      m_parent.do_write(rw);

      if (bad_side_effect) begin
         `uvm_warning("RegModel", $sformatf("Writing field \"%s\" will cause unintended side effects in adjoining Write-to-Clear or Write-to-Set fields in the same register", this.get_full_name()))
      end
   end
   else begin
     uvm_reg_map item_map = rw.get_local_map();
     uvm_reg_map system_map = item_map.get_root_map();
     uvm_reg_field_cb_iter cbs = new(this);

     m_parent.Xset_busyX(1);

     rw.set_status(UVM_IS_OK);
      
     pre_write(rw);
     for (uvm_reg_cbs cb=cbs.first(); cb!=null; cb=cbs.next())
        cb.pre_write(rw);

     if (rw.get_status() != UVM_IS_OK) begin
        m_write_in_progress = 1'b0;
        m_parent.Xset_busyX(0);
        m_parent.XatomicX(0);
        
        return;
     end
            
     item_map.do_write(rw);

     if (system_map.get_auto_predict())
        // ToDo: Call parent.XsampleX();
        do_predict(rw, UVM_PREDICT_WRITE);

     post_write(rw);
     for (uvm_reg_cbs cb=cbs.first(); cb!=null; cb=cbs.next())
        cb.post_write(rw);

     m_parent.Xset_busyX(0);
      
   end

`endif

   m_write_in_progress = 1'b0;
   m_parent.XatomicX(0);

endtask: do_write


// read

task uvm_reg_field::read(output uvm_status_e       status,
                         output uvm_reg_data_t     value,
                         input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                         input  uvm_reg_map        map = null,
                         input  uvm_sequence_base  parent = null,
                         input  int                prior = -1,
                         input  uvm_object         extension = null,
                         input  string             fname = "",
                         input  int                lineno = 0);

   uvm_reg_item rw;
   rw = uvm_reg_item::type_id::create("field_read_item",,get_full_name());
   rw.set_element(this);
   rw.set_element_kind(UVM_FIELD);
   rw.set_kind(UVM_READ);
   rw.set_value(0,0);
   rw.set_door(path);
   rw.set_map(map);
   rw.set_parent_sequence(parent);
   rw.set_priority(prior);
   rw.set_extension(extension);
   rw.set_fname(fname);
   rw.set_line(lineno);

   do_read(rw);

   value = rw.get_value(0);
   status = rw.get_status();

endtask: read


// do_read

task uvm_reg_field::do_read(uvm_reg_item rw);

   uvm_reg_map_info map_info;
   uvm_reg_map rw_local_map;
   bit bad_side_effect;
   
   m_parent.XatomicX(1);
   m_fname  = rw.get_fname();
   m_lineno = rw.get_line();
   m_read_in_progress = 1'b1;
  
   if (!Xcheck_accessX(rw,map_info))
     return;
   
   rw_local_map = rw.get_local_map();
   
`ifdef UVM_REG_NO_INDIVIDUAL_FIELD_ACCESS
   rw.set_element_kind(UVM_REG);
   rw.set_element(m_parent);
   m_parent.do_read(rw);
   rw.set_value(((rw.get_value(0) >> m_lsb) & ((1<<m_size))-1), 0);
   bad_side_effect = 1;
`else

   if (!is_indv_accessible(rw.get_door(),rw_local_map)) begin
      uvm_reg_data_t value;
      rw.set_element_kind(UVM_REG);
      rw.set_element(m_parent);
      bad_side_effect = 1;
      m_parent.do_read(rw);
      value = rw.get_value(0);
      rw.set_value(((value >> m_lsb) & ((1<<m_size))-1),0);
   end
   else begin

     uvm_reg_map system_map = rw_local_map.get_root_map();
     uvm_reg_field_cb_iter cbs = new(this);

     m_parent.Xset_busyX(1);

     rw.set_status(UVM_IS_OK);
      
     pre_read(rw);
     for (uvm_reg_cbs cb = cbs.first(); cb != null; cb = cbs.next())
        cb.pre_read(rw);

     if (rw.get_status() != UVM_IS_OK) begin
        m_read_in_progress = 1'b0;
        m_parent.Xset_busyX(0);
        m_parent.XatomicX(0);

        return;
     end
            
     rw_local_map.do_read(rw);


     if (system_map.get_auto_predict())
        // ToDo: Call parent.XsampleX();
        do_predict(rw, UVM_PREDICT_READ);

     post_read(rw);
     for (uvm_reg_cbs cb=cbs.first(); cb!=null; cb=cbs.next())
        cb.post_read(rw);

     m_parent.Xset_busyX(0);
      
   end

`endif

   m_read_in_progress = 1'b0;
   m_parent.XatomicX(0);

   if (bad_side_effect) begin
      uvm_reg_field fields[$];
      m_parent.get_fields(fields);
      foreach (fields[i]) begin
         string mode;
         if (fields[i] == this)
            continue;
         mode = fields[i].get_access();
         if (mode == "RC" ||
             mode == "RS" ||
             mode == "WRC" ||
             mode == "WRS" ||
             mode == "WSRC" ||
             mode == "WCRS" ||
             mode == "W1SRC" ||
             mode == "W1CRS" ||
             mode == "W0SRC" ||
             mode == "W0CRS") begin
            `uvm_warning("RegModel", {"Reading field '",get_full_name(),
                "' will cause unintended side effects in adjoining ",
                "Read-to-Clear or Read-to-Set fields in the same register"})
         end
      end
   end

endtask: do_read
               

// is_indv_accessible

function bit uvm_reg_field::is_indv_accessible(uvm_door_e  path,
                                               uvm_reg_map local_map);

   if (path == UVM_BACKDOOR) begin
      `uvm_warning("RegModel",
         {"Individual BACKDOOR field access not available for field '",
         get_full_name(), "'. Accessing complete register instead."})
      return 0;
   end

   if (!m_individually_accessible) begin
         `uvm_warning("RegModel",
            {"Individual field access not available for field '",
            get_full_name(), "'. Accessing complete register instead."})
      return 0;
   end

   // Cannot access individual fields if the container register
   // has a user-defined front-door
   if (m_parent.get_frontdoor(local_map) != null) begin
      `uvm_warning("RegModel",
                   {"Individual field access not available for field '",
                    get_name(), "' because register '", m_parent.get_full_name(), "' has a user-defined front-door. Accessing complete register instead."})
      return 0;
   end
   
   begin
     uvm_reg_map system_map = local_map.get_root_map();
     uvm_reg_adapter adapter = system_map.get_adapter();
     if ((adapter != null) && !adapter.supports_byte_enable) begin
       `uvm_warning("RegModel", 
                    {"Target bus does not support byte enable, field '", get_full_name(),
                     ". Accessing complete register instead."})
       return 0;
     end
   end

   begin
     int fld_idx;
     int bus_width = local_map.get_n_bytes();
     uvm_reg_field fields[$];

     m_parent.get_fields(fields);

     if (fields.size() == 1) begin
        return 1;
     end
     else begin
        int prev_lsb,this_lsb,next_lsb; 
        int prev_sz,this_sz,next_sz; 
        int bus_sz = bus_width*8;

        foreach (fields[i]) begin
           if (fields[i] == this) begin
              fld_idx = i;
              break;
           end
        end

        this_lsb = fields[fld_idx].get_lsb_pos();
        this_sz  = fields[fld_idx].get_n_bits();

        if (fld_idx>0) begin
          prev_lsb = fields[fld_idx-1].get_lsb_pos();
          prev_sz  = fields[fld_idx-1].get_n_bits();
        end

        if (fld_idx < fields.size()-1) begin
          next_lsb = fields[fld_idx+1].get_lsb_pos();
          next_sz  = fields[fld_idx+1].get_n_bits();
        end

        // if first field in register
        if (fld_idx == 0 &&
           ((next_lsb % bus_sz) == 0 ||
            (next_lsb - this_sz) > (next_lsb % bus_sz)))
           return 1;

        // if last field in register
        else if (fld_idx == (fields.size()-1) &&
            ((this_lsb % bus_sz) == 0 ||
             (this_lsb - (prev_lsb + prev_sz)) >= (this_lsb % bus_sz)))
           return 1;

        // if somewhere in between
        else begin
           if ((this_lsb % bus_sz) == 0) begin
              if ((next_lsb % bus_sz) == 0 ||
                  (next_lsb - (this_lsb + this_sz)) >= (next_lsb % bus_sz))
                  return 1;
           end 
           else begin
              if ( (next_lsb - (this_lsb + this_sz)) >= (next_lsb % bus_sz) &&
                  ((this_lsb - (prev_lsb + prev_sz)) >= (this_lsb % bus_sz)) )
                 return 1;
           end
        end
     end
   end
   
   `uvm_warning("RegModel", 
       {"Field '", get_full_name(),"' is not the only field within the entire bus width. ",
       "Individual field access will not be available. ",
       "Accessing complete register instead."})

   return 0;

endfunction


// poke

task uvm_reg_field::poke(output uvm_status_e      status,
                         input  uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_sequence_base parent = null,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
   uvm_reg_data_t  tmp;

   m_fname = fname;
   m_lineno = lineno;

   if (value >> m_size) begin
      `uvm_warning("RegModel",
         {"uvm_reg_field::poke(): Value exceeds size of field '",
          get_name(),"'"})
      value &= value & ((1<<m_size)-1);
   end


   m_parent.XatomicX(1);
   m_parent.m_is_locked_by_field = 1'b1;

   tmp = 0;

   // What is the current values of the other fields???
   m_parent.peek(status, tmp, kind, parent, extension, fname, lineno);

   if (status == UVM_NOT_OK) begin
      `uvm_error("RegModel", {"uvm_reg_field::poke(): Peek of register '",
         m_parent.get_full_name(),"' returned status ",status.name()})
      m_parent.XatomicX(0);
      m_parent.m_is_locked_by_field = 1'b0;
      return;
   end

   // Force the value for this field then poke the resulting value
   tmp &= ~(((1<<m_size)-1) << m_lsb);
   tmp |= value << m_lsb;
   m_parent.poke(status, tmp, kind, parent, extension, fname, lineno);

   m_parent.XatomicX(0);
   m_parent.m_is_locked_by_field = 1'b0;
endtask: poke


// peek

task uvm_reg_field::peek(output uvm_status_e      status,
                         output uvm_reg_data_t    value,
                         input  string            kind = "",
                         input  uvm_sequence_base parent = null,
                         input  uvm_object        extension = null,
                         input  string            fname = "",
                         input  int               lineno = 0);
   uvm_reg_data_t  reg_value;

   m_fname = fname;
   m_lineno = lineno;

   m_parent.peek(status, reg_value, kind, parent, extension, fname, lineno);
   value = (reg_value >> m_lsb) & ((1<<m_size))-1;

endtask: peek
               

// mirror

task uvm_reg_field::mirror(output uvm_status_e      status,
                           input  uvm_check_e       check = UVM_NO_CHECK,
                           input  uvm_door_e        path = UVM_DEFAULT_DOOR,
                           input  uvm_reg_map       map = null,
                           input  uvm_sequence_base parent = null,
                           input  int               prior = -1,
                           input  uvm_object        extension = null,
                           input  string            fname = "",
                           input  int               lineno = 0);
   m_fname = fname;
   m_lineno = lineno;
   m_parent.mirror(status, check, path, map, parent, prior, extension,
                      fname, lineno);
endtask: mirror


// set_compare

function void uvm_reg_field::set_compare(uvm_check_e check=UVM_CHECK);
  m_check = check;
endfunction


// get_compare

function uvm_check_e uvm_reg_field::get_compare();
  return m_check;
endfunction

// pre_randomize

function void uvm_reg_field::pre_randomize();
   // Update the only publicly known property with the current
   // desired value so it can be used as a state variable should
   // the rand_mode of the field be turned off.
   value = m_desired;
endfunction: pre_randomize


// post_randomize

function void uvm_reg_field::post_randomize();
   m_desired = value;
endfunction: post_randomize


// do_print

function void uvm_reg_field::do_print (uvm_printer printer);
  printer.print_generic(get_name(), get_type_name(), -1, convert2string());
endfunction


// convert2string

function string uvm_reg_field::convert2string();
   string fmt;
   string res_str;
   string t_str;
   bit with_debug_info;
   string prefix;
   uvm_reg reg_=get_register();

   $sformat(fmt, "%0d'h%%%0dh", get_n_bits(),
            (get_n_bits()-1)/4 + 1);
   $sformat(convert2string, {"%s %s %s[%0d:%0d]=",fmt,"%s"}, prefix,
            get_access(),
            reg_.get_name(),
            get_lsb_pos() + get_n_bits() - 1,
            get_lsb_pos(), m_desired,
            (m_desired != m_mirrored) ? $sformatf({" (Mirror: ",fmt,")"},
               m_mirrored) : ""); 

   if (m_read_in_progress == 1'b1) begin
      if (m_fname != "" && m_lineno != 0)
         $sformat(res_str, " from %s:%0d",m_fname, m_lineno);
      convert2string = {convert2string, "\n", "currently being read", res_str}; 
   end
   if (m_write_in_progress == 1'b1) begin
      if (m_fname != "" && m_lineno != 0)
         $sformat(res_str, " from %s:%0d",m_fname, m_lineno);
      convert2string = {convert2string, "\n", res_str, "currently being written"}; 
   end
endfunction: convert2string


// clone

function uvm_object uvm_reg_field::clone();
  `uvm_fatal("RegModel","RegModel field cannot be cloned")
  return null;
endfunction

// do_copy

function void uvm_reg_field::do_copy(uvm_object rhs);
  `uvm_warning("RegModel","RegModel field copy not yet implemented")
  // just a set(rhs.get()) ?
endfunction


// do_compare

function bit uvm_reg_field::do_compare (uvm_object  rhs,
                                        uvm_comparer comparer);
  `uvm_warning("RegModel","RegModel field compare not yet implemented")
  // just a return (get() == rhs.get()) ?
  return 0;
endfunction


// do_pack

function void uvm_reg_field::do_pack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel field cannot be packed")
endfunction


// do_unpack

function void uvm_reg_field::do_unpack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel field cannot be unpacked")
endfunction
