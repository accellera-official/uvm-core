//
// -------------------------------------------------------------
// Copyright 2010 AMD
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2019 Cisco Systems, Inc.
// Copyright 2020-2022 Intel Corporation
// Copyright 2020-2022 Marvell International Ltd.
// Copyright 2010-2022 Mentor Graphics Corporation
// Copyright 2014-2020 NVIDIA Corporation
// Copyright 2014 Semifore
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


// @uvm-ieee 1800.2-2020 auto 18.1.1
class uvm_reg_block extends uvm_object;


   `uvm_object_utils(uvm_reg_block)


   local uvm_reg_block  parent;

   local static bit     m_roots[uvm_reg_block]; 
   local static int unsigned m_root_names[string];
    
   local string               m_name;
   local static bit           m_enable_reg_lookup_cache; 
   local static uvm_reg_block m_reg_block_registry[string];
	
   local uvm_reg_block  blks[int unsigned];
   local uvm_reg        regs[int unsigned];
   local uvm_vreg       vregs[int unsigned];
   local uvm_mem        mems[int unsigned];
   local bit            maps[uvm_reg_map];

   // Variable -- NODOCS -- default_path
   // Default access path for the registers and memories in this block.
   // @uvm-compat made public for compatibility with 1.2
   uvm_door_e default_path = UVM_DEFAULT_DOOR;

   local string         default_hdl_path = "RTL";
   local uvm_reg_backdoor backdoor;
   local uvm_object_string_pool #(uvm_queue #(string)) hdl_paths_pool;
   local string         root_hdl_paths[string];

   local bit            locked;

   local int            has_cover;
   local int            cover_on;
   local string         fname;
   local int            lineno;

   local event m_uvm_lock_model_complete;
	
   local static int id;

   //----------------------
   // Group -- NODOCS -- Initialization
   //----------------------

   // Function -- NODOCS -- new
   //
   // Create a new instance and type-specific configuration
   //
   // Creates an instance of a block abstraction class with the specified
   // name.
   //
   // ~has_coverage~ specifies which functional coverage models are present in
   // the extension of the block abstraction class.
   // Multiple functional coverage models may be specified by adding their
   // symbolic names, as defined by the <uvm_coverage_model_e> type.

   // @uvm-ieee 1800.2-2020 manual 18.1.2.1
   extern function new(string name="", int has_coverage=UVM_NO_COVERAGE);


   // Function -- NODOCS -- configure
   //
   // Instance-specific configuration
   //
   // Specify the parent block of this block.
   // A block without parent is a root block.
   //
   // If the block file corresponds to a hierarchical RTL structure,
   // its contribution to the HDL path is specified as the ~hdl_path~.
   // Otherwise, the block does not correspond to a hierarchical RTL
   // structure (e.g. it is physically flattened) and does not contribute
   // to the hierarchical HDL path of any contained registers or memories.

   // @uvm-ieee 1800.2-2020 manual 18.1.2.2
   extern function void configure(uvm_reg_block parent=null,
                                  string hdl_path="");


   // Function -- NODOCS -- create_map
   //
   // Create an address map in this block
   //
   // Create an address map with the specified ~name~, then
   // configures it with the following properties.
   //
   // base_addr - the base address for the map. All registers, memories,
   //             and sub-blocks within the map will be at offsets to this
   //             address
   //
   // n_bytes   - the byte-width of the bus on which this map is used 
   //
   // endian    - the endian format. See <uvm_endianness_e> for possible
   //             values
   //
   // byte_addressing - specifies whether consecutive addresses refer are 1 byte
   //             apart (TRUE) or ~n_bytes~ apart (FALSE). Default is TRUE. 
   //
   //| APB = create_map("APB", 0, 1, UVM_LITTLE_ENDIAN, 1);

   // @uvm-ieee 1800.2-2020 manual 18.1.2.3
   extern virtual function uvm_reg_map create_map(string name,
                                                  uvm_reg_addr_t base_addr,
                                                  int unsigned n_bytes,
                                                  uvm_endianness_e endian,
                                                  bit byte_addressing = 1);


   // Function -- NODOCS -- check_data_width
   //
   // Check that the specified data width (in bits) is less than
   // or equal to the value of `UVM_REG_DATA_WIDTH
   //
   // This method is designed to be called by a static initializer
   //
   //| class my_blk extends uvm_reg_block;
   //|   local static bit m_data_width = check_data_width(356);
   //|   ...
   //| endclass
   //
   extern protected static function bit check_data_width(int unsigned width);



   // Function -- NODOCS -- set_default_map
   //
   // Defines the default address map
   //
   // Set the specified address map as the <default_map> for this
   // block. The address map must be a map of this address block.

   // @uvm-ieee 1800.2-2020 manual 18.1.2.4
   extern function void set_default_map (uvm_reg_map map);


   // Variable -- NODOCS -- default_map
   //
   // Default address map
   //
   // Default address map for this block, to be used when no
   // address map is specified for a register operation and that
   // register is accessible from more than one address map.
   //
   // It is also the implicit address map for a block with a single,
   // unnamed address map because it has only one physical interface.
   //
   uvm_reg_map default_map;

   // @uvm-ieee 1800.2-2020 manual 18.1.2.5
   extern function uvm_reg_map get_default_map ();

   extern virtual function void set_parent(uvm_reg_block parent);

   /*local*/ extern function void add_block (uvm_reg_block blk);
   /*local*/ extern function void add_map   (uvm_reg_map map);
   /*local*/ extern function void add_reg   (uvm_reg  rg);
   /*local*/ extern function void add_vreg  (uvm_vreg vreg);
   /*local*/ extern function void add_mem   (uvm_mem  mem);


   // Function -- NODOCS -- lock_model
   //
   // Lock a model and build the address map.
   //
   // Recursively lock an entire register model
   // and build the address maps to enable the
   // <uvm_reg_map::get_reg_by_offset()> and
   // <uvm_reg_map::get_mem_by_offset()> methods.
   //
   // Once locked, no further structural changes,
   // such as adding registers or memories,
   // can be made.

   // @uvm-ieee 1800.2-2020 manual 18.1.2.6
   extern virtual function void lock_model();

	// brings back the register mode to a state before lock_model() so that a subsequent lock_model() can be issued

   // @uvm-ieee 1800.2-2020 manual 18.1.2.7
   virtual function void unlock_model();
	   bit s[uvm_reg_block]=m_roots;
	   m_roots.delete();
	   
   		foreach (blks[blk_]) 
      		blks[blk_].unlock_model();
           
        foreach (regs[rg_])
            regs[rg_].Xunlock_modelX();
        
   		m_roots=s;
   		foreach(m_roots[b])
	   		m_roots[b]=0;
   		
        uvm_reg_block::m_reg_block_registry.delete(this.get_full_name()); //Clear block pointer cache
        m_name = ""; //Clear cached full name
   		locked=0;
   endfunction

   // @uvm-ieee 1800.2-2020 manual 18.1.2.9
   virtual task wait_for_lock();
	   @m_uvm_lock_model_complete;
   endtask


   // Function -- NODOCS -- is_locked
   //
   // Return TRUE if the model is locked.

   // @uvm-ieee 1800.2-2020 manual 18.1.2.10
   extern function bit is_locked();


   //---------------------
   // Group -- NODOCS -- Introspection
   //---------------------


   // Function -- NODOCS -- get_name
   //
   // Get the simple name
   //
   // Return the simple object name of this block.
   //


   // Function -- NODOCS -- get_full_name
   //
   // Get the hierarchical name
   //
   // Return the hierarchal name of this block.
   // The base of the hierarchical name is the root block.
   //
   extern virtual function string get_full_name();


   // Function -- NODOCS -- get_parent
   //
   // Get the parent block
   //
   // If this a top-level block, returns ~null~. 

   // @uvm-ieee 1800.2-2020 manual 18.1.3.1
   extern virtual function uvm_reg_block get_parent();


   // Function -- NODOCS -- get_root_blocks
   //
   // Get the all root blocks
   //
   // Returns an array of all root blocks in the simulation.

   // @uvm-ieee 1800.2-2020 manual 18.1.3.2
   extern static  function void get_root_blocks(ref uvm_reg_block blks[$]);
      

   // Function -- NODOCS -- find_blocks
   //
   // Find the blocks whose hierarchical names match the
   // specified ~name~ glob.
   // If a ~root~ block is specified, the name of the blocks are
   // relative to that block, otherwise they are absolute.
   //
   // Returns the number of blocks found.

   // @uvm-ieee 1800.2-2020 manual 18.1.3.3
   extern static function int find_blocks(input string        name,
                                          ref   uvm_reg_block blks[$],
                                          input uvm_reg_block root = null,
                                          input uvm_object    accessor = null);
      

   // Function -- NODOCS -- find_block
   //
   // Find the first block whose hierarchical names match the
   // specified ~name~ glob.
   // If a ~root~ block is specified, the name of the blocks are
   // relative to that block, otherwise they are absolute.
   //
   // Returns the first block found or ~null~ otherwise.
   // A warning is issued if more than one block is found.

   // @uvm-ieee 1800.2-2020 manual 18.1.3.4
   extern static function uvm_reg_block find_block(input string        name,
                                                   input uvm_reg_block root = null,
                                                   input uvm_object    accessor = null);
      

   // Function -- NODOCS -- get_blocks
   //
   // Get the sub-blocks
   //
   // Get the blocks instantiated in this blocks.
   // If ~hier~ is TRUE, recursively includes any sub-blocks.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.5
   extern virtual function void get_blocks (ref uvm_reg_block  blks[$],
                                            input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_maps
   //
   // Get the address maps
   //
   // Get the address maps instantiated in this block.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.6
   extern virtual function void get_maps (ref uvm_reg_map maps[$]);


   // Function -- NODOCS -- get_registers
   //
   // Get the registers
   //
   // Get the registers instantiated in this block.
   // If ~hier~ is TRUE, recursively includes the registers
   // in the sub-blocks.
   //
   // Note that registers may be located in different and/or multiple
   // address maps. To get the registers in a specific address map,
   // use the <uvm_reg_map::get_registers()> method.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.7
   extern virtual function void get_registers (ref uvm_reg regs[$],
                                               input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_fields
   //
   // Get the fields
   //
   // Get the fields in the registers instantiated in this block.
   // If ~hier~ is TRUE, recursively includes the fields of the registers
   // in the sub-blocks.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.8
   extern virtual function void get_fields (ref uvm_reg_field  fields[$],
                                            input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_memories
   //
   // Get the memories
   //
   // Get the memories instantiated in this block.
   // If ~hier~ is TRUE, recursively includes the memories
   // in the sub-blocks.
   //
   // Note that memories may be located in different and/or multiple
   // address maps. To get the memories in a specific address map,
   // use the <uvm_reg_map::get_memories()> method.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.9
   extern virtual function void get_memories (ref uvm_mem mems[$],
                                              input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_virtual_registers
   //
   // Get the virtual registers
   //
   // Get the virtual registers instantiated in this block.
   // If ~hier~ is TRUE, recursively includes the virtual registers
   // in the sub-blocks.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.10
   extern virtual function void get_virtual_registers(ref uvm_vreg regs[$],
                                                input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_virtual_fields
   //
   // Get the virtual fields
   //
   // Get the virtual fields from the virtual registers instantiated
   // in this block.
   // If ~hier~ is TRUE, recursively includes the virtual fields
   // in the virtual registers in the sub-blocks.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.11
   extern virtual function void get_virtual_fields (ref uvm_vreg_field fields[$],
                                                 input uvm_hier_e hier=UVM_HIER);


   // Function -- NODOCS -- get_block_by_name
   //
   // Finds a sub-block with the specified simple name.
   //
   // The name is the simple name of the block, not a hierarchical name.
   // relative to this block.
   // If no block with that name is found in this block, the sub-blocks
   // are searched for a block of that name and the first one to be found
   // is returned.
   //
   // If no blocks are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.12
   extern virtual function uvm_reg_block get_block_by_name (string name);  


   // Function -- NODOCS -- get_block_by_full_name
   //
   // Finds a sub-block with the specified full hierarchical name.
   //
   // The name is the full name of the block, starting with the root block.
   // The function looks up the cached registry built after register model is locked
   //
   // If no blocks are found, returns ~null~.

   extern static function uvm_reg_block get_block_by_full_name(string name);
   
   
   // Function -- NODOCS -- get_map_by_name
   //
   // Finds an address map with the specified simple name.
   //
   // The name is the simple name of the address map, not a hierarchical name.
   // relative to this block.
   // If no map with that name is found in this block, the sub-blocks
   // are searched for a map of that name and the first one to be found
   // is returned.
   //
   // If no address maps are found, returns ~null~.

   // @uvm-ieee 1800.2-2020 manual 18.1.3.13
   extern virtual function uvm_reg_map get_map_by_name (string name);


   // Function -- NODOCS -- get_reg_by_name
   //
   // Finds a register with the specified simple name.
   //
   // The name is the simple name of the register, not a hierarchical name.
   // relative to this block.
   // If no register with that name is found in this block, the sub-blocks
   // are searched for a register of that name and the first one to be found
   // is returned.
   //
   // If no registers are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.14
   extern virtual function uvm_reg get_reg_by_name (string name);


   // Function -- NODOCS -- get_field_by_name
   //
   // Finds a field with the specified simple name.
   //
   // The name is the simple name of the field, not a hierarchical name.
   // relative to this block.
   // If no field with that name is found in this block, the sub-blocks
   // are searched for a field of that name and the first one to be found
   // is returned.
   //
   // If no fields are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.15
   extern virtual function uvm_reg_field get_field_by_name (string name);


   // Function -- NODOCS -- get_mem_by_name
   //
   // Finds a memory with the specified simple name.
   //
   // The name is the simple name of the memory, not a hierarchical name.
   // relative to this block.
   // If no memory with that name is found in this block, the sub-blocks
   // are searched for a memory of that name and the first one to be found
   // is returned.
   //
   // If no memories are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.16
   extern virtual function uvm_mem get_mem_by_name (string name);


   // Function -- NODOCS -- get_vreg_by_name
   //
   // Finds a virtual register with the specified simple name.
   //
   // The name is the simple name of the virtual register,
   // not a hierarchical name.
   // relative to this block.
   // If no virtual register with that name is found in this block,
   // the sub-blocks are searched for a virtual register of that name
   // and the first one to be found is returned.
   //
   // If no virtual registers are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.17
   extern virtual function uvm_vreg get_vreg_by_name (string name);


   // Function -- NODOCS -- get_vfield_by_name
   //
   // Finds a virtual field with the specified simple name.
   //
   // The name is the simple name of the virtual field,
   // not a hierarchical name.
   // relative to this block.
   // If no virtual field with that name is found in this block,
   // the sub-blocks are searched for a virtual field of that name
   // and the first one to be found is returned.
   //
   // If no virtual fields are found, returns ~null~.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.3.18
   extern virtual function uvm_vreg_field get_vfield_by_name (string name);


   //----------------
   // Group -- NODOCS -- Coverage
   //----------------


   // Function -- NODOCS -- build_coverage
   //
   // Check if all of the specified coverage model must be built.
   //
   // Check which of the specified coverage model must be built
   // in this instance of the block abstraction class,
   // as specified by calls to <uvm_reg::include_coverage()>.
   //
   // Models are specified by adding the symbolic value of individual
   // coverage model as defined in <uvm_coverage_model_e>.
   // Returns the sum of all coverage models to be built in the
   // block model.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.1
   extern protected function uvm_reg_cvr_t build_coverage(uvm_reg_cvr_t models);


   // Function -- NODOCS -- add_coverage
   //
   // Specify that additional coverage models are available.
   //
   // Add the specified coverage model to the coverage models
   // available in this class.
   // Models are specified by adding the symbolic value of individual
   // coverage model as defined in <uvm_coverage_model_e>.
   //
   // This method shall be called only in the constructor of
   // subsequently derived classes.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.2
   extern virtual protected function void add_coverage(uvm_reg_cvr_t models);


   // Function -- NODOCS -- has_coverage
   //
   // Check if block has coverage model(s)
   //
   // Returns TRUE if the block abstraction class contains a coverage model
   // for all of the models specified.
   // Models are specified by adding the symbolic value of individual
   // coverage model as defined in <uvm_coverage_model_e>.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.3
   extern virtual function bit has_coverage(uvm_reg_cvr_t models);


   // Function -- NODOCS -- set_coverage
   //
   // Turns on coverage measurement.
   //
   // Turns the collection of functional coverage measurements on or off
   // for this block and all blocks, registers, fields and memories within it.
   // The functional coverage measurement is turned on for every
   // coverage model specified using <uvm_coverage_model_e> symbolic
   // identifiers.
   // Multiple functional coverage models can be specified by adding
   // the functional coverage model identifiers.
   // All other functional coverage models are turned off.
   // Returns the sum of all functional
   // coverage models whose measurements were previously on.
   //
   // This method can only control the measurement of functional
   // coverage models that are present in the various abstraction classes,
   // then enabled during construction.
   // See the <uvm_reg_block::has_coverage()> method to identify
   // the available functional coverage models.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.5
   extern virtual function uvm_reg_cvr_t set_coverage(uvm_reg_cvr_t is_on);


   // Function -- NODOCS -- get_coverage
   //
   // Check if coverage measurement is on.
   //
   // Returns TRUE if measurement for all of the specified functional
   // coverage models are currently on.
   // Multiple functional coverage models can be specified by adding the
   // functional coverage model identifiers.
   //
   // See <uvm_reg_block::set_coverage()> for more details. 
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.4
   extern virtual function bit get_coverage(uvm_reg_cvr_t is_on = UVM_CVR_ALL);


   // Function -- NODOCS -- sample
   //
   // Functional coverage measurement method
   //
   // This method is invoked by the block abstraction class
   // whenever an address within one of its address map
   // is successfully read or written.
   // The specified offset is the offset within the block,
   // not an absolute address.
   //
   // Empty by default, this method may be extended by the
   // abstraction class generator to perform the required sampling
   // in any provided functional coverage model.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.6
   protected virtual function void  sample(uvm_reg_addr_t offset,
                                           bit            is_read,
                                           uvm_reg_map    map);
   endfunction


   // Function -- NODOCS -- sample_values
   //
   // Functional coverage measurement method for field values
   //
   // This method is invoked by the user
   // or by the <uvm_reg_block::sample_values()> method of the parent block
   // to trigger the sampling
   // of the current field values in the
   // block-level functional coverage model.
   // It recursively invokes the <uvm_reg_block::sample_values()>
   // and <uvm_reg::sample_values()> methods
   // in the blocks and registers in this block.
   //
   // This method may be extended by the
   // abstraction class generator to perform the required sampling
   // in any provided field-value functional coverage model.
   // If this method is extended, it MUST call super.sample_values().
   
   // @uvm-ieee 1800.2-2020 manual 18.1.4.7
   extern virtual function void sample_values();

   /*local*/ extern function void XsampleX(uvm_reg_addr_t addr,
                                           bit            is_read,
                                           uvm_reg_map    map);


   //--------------
   // Group -- NODOCS -- Access
   //--------------

   // Function -- NODOCS -- get_default_door

   // @uvm-ieee 1800.2-2020 manual 18.1.5.1
   extern virtual function uvm_door_e get_default_door();

   // Function -- NODOCS -- set_default_door

   // @uvm-ieee 1800.2-2020 manual 18.1.5.2
   extern virtual function void set_default_door(uvm_door_e door);

   // @uvm-compat provided for compatibility with 1.2
   virtual function uvm_path_e get_default_path();
      return get_default_door();
   endfunction 

   // Function -- NODOCS -- reset
   //
   // Reset the mirror for this block.
   //
   // Sets the mirror value of all registers in the block and sub-blocks
   // to the reset value corresponding to the specified reset event.
   // See <uvm_reg_field::reset()> for more details.
   // Does not actually set the value of the registers in the design,
   // only the values mirrored in their corresponding mirror.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.5.3
   extern virtual function void reset(string kind = "HARD");


   // Function -- NODOCS -- needs_update
   //
   // Check if DUT registers need to be written
   //
   // If a mirror value has been modified in the abstraction model
   // without actually updating the actual register
   // (either through randomization or via the <uvm_reg::set()> method,
   // the mirror and state of the registers are outdated.
   // The corresponding registers in the DUT need to be updated.
   //
   // This method returns TRUE if the state of at least one register in
   // the block or sub-blocks needs to be updated to match the mirrored
   // values.
   // The mirror values, or actual content of registers, are not modified.
   // For additional information, see <uvm_reg_block::update()> method.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.5.4
   extern virtual function bit needs_update();


   // Task -- NODOCS -- update
   //
   // Batch update of register.
   //
   // Using the minimum number of write operations, updates the registers
   // in the design to match the mirrored values in this block and sub-blocks.
   // The update can be performed using the physical
   // interfaces (front-door access) or back-door accesses.
   // This method performs the reverse operation of <uvm_reg_block::mirror()>. 
   
   // @uvm-ieee 1800.2-2020 manual 18.1.5.5
   extern virtual task update(output uvm_status_e       status,
                              input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);


   // Task -- NODOCS -- mirror
   //
   // Update the mirrored values
   //
   // Read all of the registers in this block and sub-blocks and update their
   // mirror values to match their corresponding values in the design.
   // The mirroring can be performed using the physical interfaces
   // (front-door access) or back-door accesses.
   // If the ~check~ argument is specified as <UVM_CHECK>,
   // an error message is issued if the current mirrored value
   // does not match the actual value in the design.
   // This method performs the reverse operation of <uvm_reg_block::update()>.
    
   // @uvm-ieee 1800.2-2020 manual 18.1.5.6
   extern virtual task mirror(output uvm_status_e       status,
                              input  uvm_check_e        check = UVM_NO_CHECK,
                              input  uvm_door_e         path  = UVM_DEFAULT_DOOR,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);


   // Task -- NODOCS -- write_reg_by_name
   //
   // Write the named register
   //
   // Equivalent to <get_reg_by_name()> followed by <uvm_reg::write()>
   
   // @uvm-ieee 1800.2-2020 manual D.3.1
   extern virtual task write_reg_by_name(
                              output uvm_status_e        status,
                              input  string              name,
                              input  uvm_reg_data_t      data,
                              input  uvm_door_e     path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map         map = null,
                              input  uvm_sequence_base   parent = null,
                              input  int                 prior = -1,
                              input  uvm_object          extension = null,
                              input  string              fname = "",
                              input  int                 lineno = 0);


   // Task -- NODOCS -- read_reg_by_name
   //
   // Read the named register
   //
   // Equivalent to <get_reg_by_name()> followed by <uvm_reg::read()>
   
   // @uvm-ieee 1800.2-2020 manual D.3.2
   extern virtual task read_reg_by_name(
                              output uvm_status_e       status,
                              input  string             name,
                              output uvm_reg_data_t     data,
                              input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map        map = null,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);


   // Task -- NODOCS -- write_mem_by_name
   //
   // Write the named memory
   //
   // Equivalent to <get_mem_by_name()> followed by <uvm_mem::write()>
   
   // @uvm-ieee 1800.2-2020 manual D.3.3
   extern virtual task write_mem_by_name(
                              output uvm_status_e       status,
                              input  string             name,
                              input  uvm_reg_addr_t     offset,
                              input  uvm_reg_data_t     data,
                              input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map        map = null,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);


   // Task -- NODOCS -- read_mem_by_name
   //
   // Read the named memory
   //
   // Equivalent to <get_mem_by_name()> followed by <uvm_mem::read()>
   
   // @uvm-ieee 1800.2-2020 manual D.3.4
   extern virtual task read_mem_by_name(
                              output uvm_status_e       status,
                              input  string             name,
                              input  uvm_reg_addr_t     offset,
                              output uvm_reg_data_t     data,
                              input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                              input  uvm_reg_map        map = null,
                              input  uvm_sequence_base  parent = null,
                              input  int                prior = -1,
                              input  uvm_object         extension = null,
                              input  string             fname = "",
                              input  int                lineno = 0);


   extern virtual task readmemh(string filename);
   extern virtual task writememh(string filename);



   //----------------
   // Group -- NODOCS -- Backdoor
   //----------------

   // Function -- NODOCS -- get_backdoor
   //
   // Get the user-defined backdoor for all registers in this block
   //
   // Return the user-defined backdoor for all register in this
   // block and all sub-blocks -- unless overridden by a backdoor set
   // in a lower-level block or in the register itself.
   //
   // If ~inherited~ is TRUE, returns the backdoor of the parent block
   // if none have been specified for this block.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.2
   extern function uvm_reg_backdoor get_backdoor(bit inherited = 1);


   // Function -- NODOCS -- set_backdoor
   //
   // Set the user-defined backdoor for all registers in this block
   //
   // Defines the backdoor mechanism for all registers instantiated
   // in this block and sub-blocks, unless overridden by a definition
   // in a lower-level block or register.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.3
   extern function void set_backdoor (uvm_reg_backdoor bkdr,
                                      string fname = "",
                                      int lineno = 0);


   // Function -- NODOCS --  clear_hdl_path
   //
   // Delete HDL paths
   //
   // Remove any previously specified HDL path to the block instance
   // for the specified design abstraction.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.4
   extern function void clear_hdl_path (string kind = "RTL");


   // Function -- NODOCS --  add_hdl_path
   //
   // Add an HDL path
   //
   // Add the specified HDL path to the block instance for the specified
   // design abstraction. This method may be called more than once for the
   // same design abstraction if the block is physically duplicated
   // in the design abstraction
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.5
   extern function void add_hdl_path (string path, string kind = "RTL");


   // Function -- NODOCS --   has_hdl_path
   //
   // Check if a HDL path is specified
   //
   // Returns TRUE if the block instance has a HDL path defined for the
   // specified design abstraction. If no design abstraction is specified,
   // uses the default design abstraction specified for this block or
   // the nearest block ancestor with a specified default design abstraction.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.6
   extern function bit has_hdl_path (string kind = "");


   // Function -- NODOCS --  get_hdl_path
   //
   // Get the incremental HDL path(s)
   //
   // Returns the HDL path(s) defined for the specified design abstraction
   // in the block instance.
   // Returns only the component of the HDL paths that corresponds to
   // the block, not a full hierarchical path
   //
   // If no design abstraction is specified, the default design abstraction
   // for this block is used.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.7
   extern function void get_hdl_path (ref string paths[$], input string kind = "");


   // Function -- NODOCS --  get_full_hdl_path
   //
   // Get the full hierarchical HDL path(s)
   //
   // Returns the full hierarchical HDL path(s) defined for the specified
   // design abstraction in the block instance.
   // There may be more than one path returned even
   // if only one path was defined for the block instance, if any of the
   // parent components have more than one path defined for the same design
   // abstraction
   //
   // If no design abstraction is specified, the default design abstraction
   // for each ancestor block is used to get each incremental path.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.8
   extern function void get_full_hdl_path (ref string paths[$],
                                           input string kind = "",
                                           string separator = ".");


   // Function -- NODOCS -- set_default_hdl_path
   //
   // Set the default design abstraction
   //
   // Set the default design abstraction for this block instance.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.9
   extern function void   set_default_hdl_path (string kind);


   // Function -- NODOCS --  get_default_hdl_path
   //
   // Get the default design abstraction
   //
   // Returns the default design abstraction for this block instance.
   // If a default design abstraction has not been explicitly set for this
   // block instance, returns the default design abstraction for the
   // nearest block ancestor.
   // Returns "" if no default design abstraction has been specified.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.10
   extern function string get_default_hdl_path ();


   // Function -- NODOCS -- set_hdl_path_root
   //
   // Specify a root HDL path
   //
   // Set the specified path as the absolute HDL path to the block instance
   // for the specified design abstraction.
   // This absolute root path is prepended to all hierarchical paths
   // under this block. The HDL path of any ancestor block is ignored.
   // This method overrides any incremental path for the
   // same design abstraction specified using <add_hdl_path>.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.11
   extern function void set_hdl_path_root (string path, string kind = "RTL");


   // Function -- NODOCS -- is_hdl_path_root
   //
   // Check if this block has an absolute path
   //
   // Returns TRUE if an absolute HDL path to the block instance
   // for the specified design abstraction has been defined.
   // If no design abstraction is specified, the default design abstraction
   // for this block is used.
   
   // @uvm-ieee 1800.2-2020 manual 18.1.6.12
   extern function bit is_hdl_path_root (string kind = "");


   extern virtual function void   do_print      (uvm_printer printer);
   extern virtual function void   do_copy       (uvm_object rhs);
   extern virtual function bit    do_compare    (uvm_object  rhs,
                                                 uvm_comparer comparer);
   extern virtual function void   do_pack       (uvm_packer packer);
   extern virtual function void   do_unpack     (uvm_packer packer);
   extern virtual function string convert2string ();
   extern virtual function uvm_object clone();
   
   extern local function void Xinit_address_mapsX();


   // @uvm-ieee 1800.2-2020 manual 18.1.2.8
   virtual function void set_lock(bit v);
	   locked=v;
	   foreach(blks[idx])
		   blks[idx].set_lock(v);
   endfunction
   
   // remove all knowledge of map m and all regs|mems|vregs contained in m from the block

   // @uvm-ieee 1800.2-2020 manual 18.1.6.11
   virtual function void unregister(uvm_reg_map m);
	   foreach(regs[idx]) begin
			if(regs[idx].is_in_map(m))
				regs.delete(idx);
	   end	
	   foreach(mems[idx]) begin
		   if(mems[idx].is_in_map(m))
			   mems.delete(idx);
	   end	
	   foreach(vregs[idx]) begin
		   if(vregs[idx].is_in_map(m))
			   vregs.delete(idx);
	   end
	   maps.delete(m);
   endfunction
   
   
   //----------------------
   // Group -- NODOCS -- Control knobs
   //----------------------
   
   extern local function void m_do_cmdline_settings();
   
   static function void set_reg_lookup_cache(bit enable_caching=1);
       m_enable_reg_lookup_cache=enable_caching;
       `uvm_info("RegModel",$sformatf("Register lookup cache build flag set to %0d",enable_caching),UVM_MEDIUM)
   endfunction
   
   static function bit is_reg_lookup_cache_enable();
       return m_enable_reg_lookup_cache;
   endfunction
   
endclass: uvm_reg_block

//------------------------------------------------------------------------


// m_do_perf_control_settings
// ----------------------

function void uvm_reg_block::m_do_cmdline_settings();
    if($test$plusargs("UVM_ENABLE_REG_LOOKUP_CACHE"))
        uvm_reg_block::set_reg_lookup_cache(1);
endfunction

//---------------
// Initialization
//---------------

// check_data_width

function bit uvm_reg_block::check_data_width(int unsigned width);
   if (width <= $bits(uvm_reg_data_t)) return 1;

   `uvm_fatal("RegModel", $sformatf("Register model requires that UVM_REG_DATA_WIDTH be defined as %0d or greater. Currently defined as %0d", width, `UVM_REG_DATA_WIDTH))

   return 0;
endfunction


// new

function uvm_reg_block::new(string name="", int has_coverage=UVM_NO_COVERAGE);
   super.new(name);
   hdl_paths_pool = new("hdl_paths");
   this.has_cover = has_coverage;
   // Root block until registered with a parent
   m_roots[this] = 0;
   if (m_root_names.exists(name))
     m_root_names[name]++;
   else
     m_root_names[name] = 1;
endfunction: new


// configure

function void uvm_reg_block::configure(uvm_reg_block parent=null, string hdl_path="");
  this.parent = parent; 
  if (parent != null)
    this.parent.add_block(this);
  add_hdl_path(hdl_path);
endfunction


// add_block

function void uvm_reg_block::add_block (uvm_reg_block blk);
   int unsigned uid;
   
   uid = blk.get_inst_id();
   
   if (this.is_locked()) begin
      `uvm_error("RegModel", "Cannot add subblock to locked block model")
      return;
   end
   if (this.blks.exists(uid)) begin
      `uvm_error("RegModel", {"Subblock '",blk.get_name(),
         "' has already been registered with block '",get_name(),"'"})
       return;
   end
   blks[uid] = blk;
   if (m_roots.exists(blk)) m_roots.delete(blk);
   
   begin
	   string name=blk.get_name();
   	   if(m_root_names.exists(name)) m_root_names[name]--;
   end	
endfunction


// add_reg

function void uvm_reg_block::add_reg(uvm_reg rg);
   int unsigned uid;
   
   uid = rg.get_inst_id();
   
   if (this.is_locked()) begin
      `uvm_error("RegModel", "Cannot add register to locked block model")
      return;
   end

   if (this.regs.exists(uid)) begin
      `uvm_error("RegModel", {"Register '",rg.get_name(),
         "' has already been registered with block '",get_name(),"'"})
       return;
   end

   regs[uid] = rg;
endfunction: add_reg


// add_vreg

function void uvm_reg_block::add_vreg(uvm_vreg vreg);
   int unsigned uid;
   
   uid = vreg.get_inst_id();
   
   if (this.is_locked()) begin
      `uvm_error("RegModel", "Cannot add virtual register to locked block model")
      return;
   end

   if (this.vregs.exists(uid)) begin
      `uvm_error("RegModel", {"Virtual register '",vreg.get_name(),
         "' has already been registered with block '",get_name(),"'"})
       return;
   end
   vregs[uid] = vreg;
endfunction: add_vreg


// add_mem

function void uvm_reg_block::add_mem(uvm_mem mem);
   int unsigned uid;
   
   uid = mem.get_inst_id();

   if (this.is_locked()) begin
      `uvm_error("RegModel", "Cannot add memory to locked block model")
      return;
   end

   if (this.mems.exists(uid)) begin
      `uvm_error("RegModel", {"Memory '",mem.get_name(),
         "' has already been registered with block '",get_name(),"'"})
       return;
   end
   mems[uid] = mem;
endfunction: add_mem


// set_parent

function void uvm_reg_block::set_parent(uvm_reg_block parent);
  if (this != parent)
    this.parent = parent;
endfunction


// is_locked

function bit uvm_reg_block::is_locked();
   return this.locked;
endfunction: is_locked


// lock_model

function void uvm_reg_block::lock_model();

   if (is_locked())
     return;

   locked = 1;
   m_name = get_full_name();          //Cache the full name of block
   m_reg_block_registry[m_name]=this; //Cache this block pointer in full_name registry

   foreach (regs[rg_]) begin
      regs[rg_].Xlock_modelX();
   end

   foreach (mems[mem_]) begin
      mems[mem_].Xlock_modelX();
   end

   foreach (blks[blk_]) begin
      blks[blk_].lock_model();
   end

   if (this.parent == null) begin
      int max_size = uvm_reg::get_max_size();
       
      m_do_cmdline_settings();

      if (uvm_reg_field::get_max_size() > max_size)
         max_size = uvm_reg_field::get_max_size();

      if (uvm_mem::get_max_size() > max_size)
         max_size = uvm_mem::get_max_size();

      if (max_size > `UVM_REG_DATA_WIDTH) begin
         `uvm_fatal("RegModel", $sformatf("Register model requires that UVM_REG_DATA_WIDTH be defined as %0d or greater. Currently defined as %0d", max_size, `UVM_REG_DATA_WIDTH))
      end

      Xinit_address_mapsX();

      // Check that root register models have unique names
      // NOTE:: https://accellera.mantishub.io/view.php?id=6532     
      if(m_root_names[get_name()]>1)
	      `uvm_error("UVM/REG/DUPLROOT",$sformatf("There are %0d root register models named \"%s\". The names of the root register models have to be unique",
		      m_root_names[get_name()], get_name()))

      -> m_uvm_lock_model_complete;
   end else begin
       // Initialize root maps within sub-blocks
       // NOTE: https://accellera.mantishub.io/view.php?id=6398
       foreach(maps[_map])
            if(_map.get_parent_map() == null) 
                _map.Xinit_address_mapX();
   end 

endfunction



//--------------------------
// Get Hierarchical Elements
//--------------------------

function string uvm_reg_block::get_full_name();
   if (m_name =="") begin
       if (parent == null)
           return get_name();
       else
           return {parent.get_full_name(), ".", get_name()};
   end
   return m_name;

endfunction: get_full_name


// get_fields

function void uvm_reg_block::get_fields(ref uvm_reg_field fields[$],
                                        input uvm_hier_e hier=UVM_HIER);

   foreach (regs[rg_]) begin
     regs[rg_].get_fields(fields);
   end
   
   if (hier == UVM_HIER)
     foreach (blks[blk_])
     begin
       blks[blk_].get_fields(fields);
     end

endfunction: get_fields


// get_virtual_fields

function void uvm_reg_block::get_virtual_fields(ref uvm_vreg_field fields[$],
                                                input uvm_hier_e hier=UVM_HIER);

   foreach (vregs[vreg_]) begin
     vregs[vreg_].get_fields(fields);
   end
   
   if (hier == UVM_HIER)
     foreach (blks[blk_]) begin
       blks[blk_].get_virtual_fields(fields);
     end
endfunction: get_virtual_fields


// get_registers

function void uvm_reg_block::get_registers(ref uvm_reg regs[$],
                                           input uvm_hier_e hier=UVM_HIER);
   foreach (this.regs[rg])
     regs.push_back(this.regs[rg]);

   if (hier == UVM_HIER)
     foreach (blks[blk_]) begin
       blks[blk_].get_registers(regs);
     end
endfunction: get_registers


// get_virtual_registers

function void uvm_reg_block::get_virtual_registers(ref uvm_vreg regs[$],
                                                   input uvm_hier_e hier=UVM_HIER);

   foreach (vregs[rg])
     regs.push_back(vregs[rg]);

   if (hier == UVM_HIER)
     foreach (blks[blk_]) begin
       blks[blk_].get_virtual_registers(regs);
     end
endfunction: get_virtual_registers


// get_memories

function void uvm_reg_block::get_memories(ref uvm_mem mems[$],
                                          input uvm_hier_e hier=UVM_HIER);

   foreach (this.mems[mem_]) begin
     mems.push_back(this.mems[mem_]);
   end

   if (hier == UVM_HIER)
     foreach (blks[blk_]) begin
       blks[blk_].get_memories(mems);
     end

endfunction: get_memories


// get_blocks

function void uvm_reg_block::get_blocks(ref uvm_reg_block blks[$],
                                        input uvm_hier_e hier=UVM_HIER);

   foreach (this.blks[blk_]) begin
     blks.push_back(this.blks[blk_]);
     if (hier == UVM_HIER)
       this.blks[blk_].get_blocks(blks);
   end

endfunction: get_blocks


// get_root_blocks

function void uvm_reg_block::get_root_blocks(ref uvm_reg_block blks[$]);

   foreach (m_roots[blk]) begin
      blks.push_back(blk);
   end

endfunction


// find_blocks
function int uvm_reg_block::find_blocks(input string        name,
                                        ref   uvm_reg_block blks[$],
                                        input uvm_reg_block root = null,
                                        input uvm_object    accessor = null);
   uvm_reg_block r[$];
   uvm_reg_block b[$];
   static uvm_reg_block find_blocks_cache[string][$];
   blks.delete();
    
   if (root != null) begin
          name = {root.get_full_name(), ".", name};
          b='{root};
   end else begin
          get_root_blocks(b);
   end

   // Check if this block name pattern was previously searched
   if(is_reg_lookup_cache_enable() && find_blocks_cache[name].size()>0) begin
       blks = find_blocks_cache[name];
   end else begin
       foreach(b[idx]) begin
           r.push_back(b[idx]);
           b[idx].get_blocks(r);
       end                    
    
              
       foreach(r[idx]) begin
                   if ( uvm_is_match( name, r[idx].get_full_name() ) )
                             blks.push_back(r[idx]);
    
       end
       //Store matched blocks in a lookup cache
       if (is_reg_lookup_cache_enable())
            find_blocks_cache[name] = blks;
   end

   return blks.size();
endfunction




function uvm_reg_block uvm_reg_block::find_block(input string        name,
                                                 input uvm_reg_block root = null,
                                                 input uvm_object    accessor = null);

   uvm_reg_block blks[$];
   if (!find_blocks(name, blks, root, accessor))
      return null;

   if (blks.size() > 1) begin
      `uvm_warning("MRTH1BLK",
                   {"More than one block matched the name \"", name, "\"."})
   end
   

   return blks[0];
endfunction


// get_maps

function void uvm_reg_block::get_maps(ref uvm_reg_map maps[$]);

   foreach (this.maps[map])
     maps.push_back(map);

endfunction


// get_parent

function uvm_reg_block uvm_reg_block::get_parent();
   get_parent = this.parent;
endfunction: get_parent


//------------
// Get-By-Name
//------------

// get_block_by_name

function uvm_reg_block uvm_reg_block::get_block_by_name(string name);

   if (get_name() == name)
     return this;
   
   get_block_by_name = uvm_reg_block::get_block_by_full_name({this.get_full_name(),".",name});
   if (get_block_by_name != null )
       return get_block_by_name;
       

   foreach (blks[blk_]) begin
      uvm_reg_block subblks[$];
      blks[blk_].get_blocks(subblks, UVM_HIER);

      foreach (subblks[j]) begin
         get_block_by_name = uvm_reg_block::get_block_by_full_name({subblks[j].get_full_name(),".",name});
         if (get_block_by_name != null )
            return get_block_by_name;
      end 
   end

   `uvm_warning("RegModel", {"Unable to locate block '",name,
                "' in block '",get_full_name(),"'"})
   return null;

endfunction: get_block_by_name

// get_block_by_full_name

function uvm_reg_block uvm_reg_block::get_block_by_full_name(string name);
    get_block_by_full_name=m_reg_block_registry[name];
endfunction: get_block_by_full_name


// get_reg_by_name

function uvm_reg uvm_reg_block::get_reg_by_name(string name);

   // Search for reg in 'this' block
   get_reg_by_name = uvm_reg::get_reg_by_full_name({this.get_full_name(),".",name});
   if (get_reg_by_name != null )
       return get_reg_by_name;
   
   // Search for reg in child blocks in depth first search. Return the first match
   foreach (blks[blk_]) begin
      uvm_reg_block subblks[$];
      get_reg_by_name = uvm_reg::get_reg_by_full_name({blks[blk_].get_full_name(),".",name});
      if (get_reg_by_name != null )
        return get_reg_by_name;
      
      blks[blk_].get_blocks(subblks, UVM_HIER);

      foreach (subblks[j]) begin
         get_reg_by_name = uvm_reg::get_reg_by_full_name({subblks[j].get_full_name(),".",name});
         if (get_reg_by_name != null )
            return get_reg_by_name;
      end 
   end

   `uvm_warning("RegModel", {"Unable to locate register '",name,
                "' in block '",get_full_name(),"'"})
   return null;

endfunction: get_reg_by_name


// get_vreg_by_name

function uvm_vreg uvm_reg_block::get_vreg_by_name(string name);

   foreach (vregs[rg_]) begin
     if (vregs[rg_].get_name() == name)
       return vregs[rg_];
   end

   foreach (blks[blk_]) begin
      uvm_vreg subvregs[$];
      blks[blk_].get_virtual_registers(subvregs, UVM_HIER);

      foreach (subvregs[j])
         if (subvregs[j].get_name() == name)
            return subvregs[j];
   end

   `uvm_warning("RegModel", {"Unable to locate virtual register '",name,
                "' in block '",get_full_name(),"'"})
   return null;

endfunction: get_vreg_by_name


// get_mem_by_name

function uvm_mem uvm_reg_block::get_mem_by_name(string name);

   foreach (mems[mem_]) begin
     if (mems[mem_].get_name() == name)
       return mems[mem_];
   end

   foreach (blks[blk_]) begin
      uvm_mem submems[$];
      blks[blk_].get_memories(submems, UVM_HIER);

      foreach (submems[j])
         if (submems[j].get_name() == name)
            return submems[j];
   end

   `uvm_warning("RegModel", {"Unable to locate memory '",name,
                "' in block '",get_full_name(),"'"})
   return null;

endfunction: get_mem_by_name


// get_field_by_name

function uvm_reg_field uvm_reg_block::get_field_by_name(string name);

   foreach (regs[rg_]) begin
      uvm_reg_field fields[$];

      regs[rg_].get_fields(fields);
      foreach (fields[i])
        if (fields[i].get_name() == name)
          return fields[i];
   end

   foreach (blks[blk_]) begin
      uvm_reg subregs[$];
      blks[blk_].get_registers(subregs, UVM_HIER);
       
      foreach (subregs[j]) begin
         uvm_reg_field fields[$];
         subregs[j].get_fields(fields);
         foreach (fields[i])
            if (fields[i].get_name() == name)
               return fields[i];
      end
   end

   `uvm_warning("RegModel", {"Unable to locate field '",name,
                "' in block '",get_full_name(),"'"})

   return null;

endfunction: get_field_by_name


// get_vfield_by_name

function uvm_vreg_field uvm_reg_block::get_vfield_by_name(string name);

   foreach (vregs[rg_]) begin
      uvm_vreg_field fields[$];

      vregs[rg_].get_fields(fields);
      foreach (fields[i])
        if (fields[i].get_name() == name)
          return fields[i];
   end

   foreach (blks[blk_]) begin
      uvm_vreg subvregs[$];
      blks[blk_].get_virtual_registers(subvregs, UVM_HIER);

      foreach (subvregs[j]) begin
         uvm_vreg_field fields[$];
         subvregs[j].get_fields(fields);
         foreach (fields[i])
            if (fields[i].get_name() == name)
               return fields[i];
      end
   end

   `uvm_warning("RegModel", {"Unable to locate virtual field '",name,
                "' in block '",get_full_name(),"'"})

   return null;

endfunction: get_vfield_by_name



//-------------
// Coverage API
//-------------

// set_coverage

function uvm_reg_cvr_t uvm_reg_block::set_coverage(uvm_reg_cvr_t is_on);
   this.cover_on = this.has_cover & is_on;

   foreach (regs[rg_]) begin
     void'(regs[rg_].set_coverage(is_on));
   end

   foreach (mems[mem_]) begin
     void'(mems[mem_].set_coverage(is_on));
   end

   foreach (blks[blk_]) begin
     void'(blks[blk_].set_coverage(is_on));
   end

   return this.cover_on;
endfunction: set_coverage


// sample_values

function void uvm_reg_block::sample_values();
   foreach (regs[rg_]) begin
      regs[rg_].sample_values();
   end

   foreach (blks[blk_]) begin
      blks[blk_].sample_values();
   end
endfunction


// XsampleX

function void uvm_reg_block::XsampleX(uvm_reg_addr_t addr,
                                      bit            is_read,
                                      uvm_reg_map    map);
   sample(addr, is_read, map);
   if (parent != null) begin
      // ToDo: Call XsampleX in the parent block
      //       with the offset and map within that block's context
   end
endfunction


function uvm_reg_cvr_t uvm_reg_block::build_coverage(uvm_reg_cvr_t models);
   build_coverage = UVM_NO_COVERAGE;
   void'(uvm_reg_cvr_rsrc_db::read_by_name({"uvm_reg::", get_full_name()},
                                           "include_coverage",
                                           build_coverage, this));
   return build_coverage & models;
endfunction: build_coverage


// add_coverage

function void uvm_reg_block::add_coverage(uvm_reg_cvr_t models);
   this.has_cover |= models;
endfunction: add_coverage


// has_coverage

function bit uvm_reg_block::has_coverage(uvm_reg_cvr_t models);
   return ((this.has_cover & models) == models);
endfunction: has_coverage


// get_coverage

function bit uvm_reg_block::get_coverage(uvm_reg_cvr_t is_on = UVM_CVR_ALL);
   if (this.has_coverage(is_on) == 0) return 0;
   return ((this.cover_on & is_on) == is_on);
endfunction: get_coverage


//----------------
// Run-Time Access
//----------------


// reset

function void uvm_reg_block::reset(string kind = "HARD");

   foreach (regs[rg_]) begin
     regs[rg_].reset(kind);
   end

   foreach (blks[blk_]) begin
     blks[blk_].reset(kind);
   end
endfunction


// needs_update

function bit uvm_reg_block::needs_update();
   needs_update = 0;

   foreach (regs[rg_]) begin
     if (regs[rg_].needs_update())
       return 1;
   end
   foreach (blks[blk_]) begin
     if (blks[blk_].needs_update())
       return 1;
   end
endfunction: needs_update


// update

task uvm_reg_block::update(output uvm_status_e  status,
                           input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                           input  uvm_sequence_base  parent = null,
                           input  int                prior = -1,
                           input  uvm_object         extension = null,
                           input  string             fname = "",
                           input  int                lineno = 0);
   status = UVM_IS_OK;

   if (!needs_update()) begin
     `uvm_info("RegModel", $sformatf("%s:%0d - RegModel block %s does not need updating",
                    fname, lineno, this.get_name()), UVM_HIGH)
      return;
   end
   
   `uvm_info("RegModel", $sformatf("%s:%0d - Updating model block %s with %s path",
                    fname, lineno, this.get_name(), path.name ), UVM_HIGH)

   foreach (regs[rg_]) begin
      if (regs[rg_].needs_update()) begin
         regs[rg_].update(status, path, null, parent, prior, extension);
         if (status != UVM_IS_OK && status != UVM_HAS_X) begin
           `uvm_error("RegModel", $sformatf("Register \"%s\" could not be updated",
                                        regs[rg_].get_full_name()))
           return;
         end
      end
   end

   foreach (blks[blk_]) begin
     blks[blk_].update(status,path,parent,prior,extension,fname,lineno);
   end
endtask: update


// mirror

task uvm_reg_block::mirror(output uvm_status_e       status,
                           input  uvm_check_e        check = UVM_NO_CHECK,
                           input  uvm_door_e         path = UVM_DEFAULT_DOOR,
                           input  uvm_sequence_base  parent = null,
                           input  int                prior = -1,
                           input  uvm_object         extension = null,
                           input  string             fname = "",
                           input  int                lineno = 0);
   uvm_status_e final_status = UVM_IS_OK;

   foreach (regs[rg_]) begin 
      regs[rg_].mirror(status, check, path, null,
                parent, prior, extension, fname, lineno);
      if (status != UVM_IS_OK && status != UVM_HAS_X) begin
         final_status = status;
      end
   end

   foreach (blks[blk_]) begin
      blks[blk_].mirror(status, check, path, parent, prior, extension, fname, lineno);
      if (status != UVM_IS_OK && status != UVM_HAS_X) begin
         final_status = status;
      end
   end
   
endtask: mirror


// write_reg_by_name

task uvm_reg_block::write_reg_by_name(output uvm_status_e   status,
                                      input  string              name,
                                      input  uvm_reg_data_t      data,
                                      input  uvm_door_e     path = UVM_DEFAULT_DOOR,
                                      input  uvm_reg_map      map = null,
                                      input  uvm_sequence_base   parent = null,
                                      input  int                 prior = -1,
                                      input  uvm_object          extension = null,
                                      input  string              fname = "",
                                      input  int                 lineno = 0);
   uvm_reg rg;
   this.fname = fname;
   this.lineno = lineno;

   status = UVM_NOT_OK;
   rg = this.get_reg_by_name(name);
   if (rg != null)
     rg.write(status, data, path, map, parent, prior, extension);

endtask: write_reg_by_name


// read_reg_by_name

task uvm_reg_block::read_reg_by_name(output uvm_status_e  status,
                                     input  string             name,
                                     output uvm_reg_data_t     data,
                                     input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                                     input  uvm_reg_map     map = null,
                                     input  uvm_sequence_base  parent = null,
                                     input  int                prior = -1,
                                     input  uvm_object         extension = null,
                                     input  string             fname = "",
                                     input  int                lineno = 0);
   uvm_reg rg;
   this.fname = fname;
   this.lineno = lineno;

   status = UVM_NOT_OK;
   rg = this.get_reg_by_name(name);
   if (rg != null)
     rg.read(status, data, path, map, parent, prior, extension);
endtask: read_reg_by_name


// write_mem_by_name

task uvm_reg_block::write_mem_by_name(output uvm_status_e  status,
                                          input  string             name,
                                          input  uvm_reg_addr_t     offset,
                                          input  uvm_reg_data_t     data,
                                          input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                                          input  uvm_reg_map     map = null,
                                          input  uvm_sequence_base  parent = null,
                                          input  int                prior = -1,
                                          input  uvm_object         extension = null,
                                          input  string             fname = "",
                                          input  int                lineno = 0);
   uvm_mem mem;
   this.fname = fname;
   this.lineno = lineno;

   status = UVM_NOT_OK;
   mem = get_mem_by_name(name);
   if (mem != null)
     mem.write(status, offset, data, path, map, parent, prior, extension);
endtask: write_mem_by_name


// read_mem_by_name

task uvm_reg_block::read_mem_by_name(output uvm_status_e  status,
                                         input  string             name,
                                         input  uvm_reg_addr_t     offset,
                                         output uvm_reg_data_t     data,
                                         input  uvm_door_e    path = UVM_DEFAULT_DOOR,
                                         input  uvm_reg_map     map = null,
                                         input  uvm_sequence_base  parent = null,
                                         input  int                prior = -1,
                                         input  uvm_object         extension = null,
                                         input  string             fname = "",
                                         input  int                lineno = 0);
   uvm_mem mem;
   this.fname = fname;
   this.lineno = lineno;

   status = UVM_NOT_OK;
   mem = get_mem_by_name(name);
   if (mem != null)
     mem.read(status, offset, data, path, map, parent, prior, extension);
endtask: read_mem_by_name


// readmemh

task uvm_reg_block::readmemh(string filename);
   // TODO
endtask: readmemh


// writememh

task uvm_reg_block::writememh(string filename);
   // TODO
endtask: writememh


//---------------
// Map Management
//---------------

// create_map

function uvm_reg_map uvm_reg_block::create_map(string name,
                                               uvm_reg_addr_t base_addr,
                                               int unsigned n_bytes,
                                               uvm_endianness_e endian,
                                               bit byte_addressing=1);

   uvm_reg_map  map;

   map = uvm_reg_map::type_id::create(name,,this.get_full_name());
   map.configure(this,base_addr,n_bytes,endian,byte_addressing);

   add_map(map);
   
   return map;
endfunction


// add_map

function void uvm_reg_block::add_map(uvm_reg_map map);

   if (this.locked) begin
      `uvm_error("RegModel", "Cannot add map to locked model")
      return;
   end

   if (this.maps.exists(map)) begin
      `uvm_error("RegModel", {"Map '",map.get_name(),
                 "' already exists in '",get_full_name(),"'"})
      return;
   end

   this.maps[map] = 1;
   if (maps.num() == 1)
     default_map = map;

endfunction: add_map


// get_map_by_name

function uvm_reg_map uvm_reg_block::get_map_by_name(string name);
   uvm_reg_map maps[$];

   this.get_maps(maps);

   foreach (maps[i])
     if (maps[i].get_name() == name)
       return maps[i];

   foreach (maps[i]) begin
      uvm_reg_map submaps[$];
      maps[i].get_submaps(submaps, UVM_HIER);

      foreach (submaps[j])
         if (submaps[j].get_name() == name)
            return submaps[j];
   end
      

   `uvm_warning("RegModel", {"Map with name '",name,"' does not exist in block"})
   return null;
endfunction


// set_default_map

function void uvm_reg_block::set_default_map(uvm_reg_map map);
  if (!maps.exists(map))
   `uvm_warning("RegModel", {"Map '",map.get_full_name(),"' does not exist in block"})
  default_map = map;
endfunction


// get_default_map

function uvm_reg_map uvm_reg_block::get_default_map();
  return default_map;
endfunction

// get_default_door

function uvm_door_e uvm_reg_block::get_default_door();

   if (this.default_path != UVM_DEFAULT_DOOR)
      return this.default_path;

   if (this.parent != null)
      return this.parent.get_default_door();

   return UVM_FRONTDOOR;

endfunction

// set_default_door

function void uvm_reg_block::set_default_door(uvm_door_e door);

   this.default_path = door;
   
endfunction

// Xinit_address_mapsX

function void uvm_reg_block::Xinit_address_mapsX();
   foreach (maps[map_]) begin
      uvm_reg_map map = map_;
      map.Xinit_address_mapX();
   end
      //map.Xverify_map_configX();
endfunction


//----------------
// Group- Backdoor
//----------------

// set_backdoor

function void uvm_reg_block::set_backdoor(uvm_reg_backdoor bkdr,
                                          string               fname = "",
                                          int                  lineno = 0);
   bkdr.fname = fname;
   bkdr.lineno = lineno;
   if (this.backdoor != null &&
       this.backdoor.has_update_threads()) begin
      `uvm_warning("RegModel", "Previous register backdoor still has update threads running. Backdoors with active mirroring should only be set before simulation starts.")
   end
   this.backdoor = bkdr;
endfunction: set_backdoor


// get_backdoor

function uvm_reg_backdoor uvm_reg_block::get_backdoor(bit inherited = 1);
   if (backdoor == null && inherited) begin
     uvm_reg_block blk = get_parent();
     while (blk != null) begin
       uvm_reg_backdoor bkdr = blk.get_backdoor();
       if (bkdr != null)
         return bkdr;
       blk = blk.get_parent();
     end
   end
   return this.backdoor;
endfunction: get_backdoor



// clear_hdl_path

function void uvm_reg_block::clear_hdl_path(string kind = "RTL");

  if (kind == "ALL") begin
    hdl_paths_pool = new("hdl_paths");
    return;
  end

  if (kind == "")
    kind = get_default_hdl_path();

  if (!hdl_paths_pool.exists(kind)) begin
    `uvm_warning("RegModel",{"Unknown HDL Abstraction '",kind,"'"})
    return;
  end

  hdl_paths_pool.delete(kind);
endfunction


// add_hdl_path

function void uvm_reg_block::add_hdl_path(string path, string kind = "RTL");

  uvm_queue #(string) paths;

  paths = hdl_paths_pool.get(kind);

  paths.push_back(path);

endfunction


// has_hdl_path

function bit  uvm_reg_block::has_hdl_path(string kind = "");
  if (kind == "") begin
    kind = get_default_hdl_path();
  end
  return hdl_paths_pool.exists(kind);
endfunction


// get_hdl_path

function void uvm_reg_block::get_hdl_path(ref string paths[$], input string kind = "");

  uvm_queue #(string) hdl_paths;

  if (kind == "")
    kind = get_default_hdl_path();

  if (!has_hdl_path(kind)) begin
    `uvm_error("RegModel",{"Block does not have hdl path defined for abstraction '",kind,"'"})
    return;
  end

  hdl_paths = hdl_paths_pool.get(kind);

  for (int i=0; i<hdl_paths.size();i++)
    paths.push_back(hdl_paths.get(i));

endfunction


// get_full_hdl_path

function void uvm_reg_block::get_full_hdl_path(ref string paths[$],
                                               input string kind = "",
                                               string separator = ".");

   if (kind == "")
      kind = get_default_hdl_path();

   paths.delete();
   if (is_hdl_path_root(kind)) begin
      if (root_hdl_paths[kind] != "")
         paths.push_back(root_hdl_paths[kind]);
      return;
   end

   if (!has_hdl_path(kind)) begin
      `uvm_error("RegModel",{"Block does not have hdl path defined for abstraction '",kind,"'"})
      return;
   end
   
   begin
      uvm_queue #(string) hdl_paths = hdl_paths_pool.get(kind);
      string parent_paths[$];

      if (parent != null)
         parent.get_full_hdl_path(parent_paths, kind, separator);

      for (int i=0; i<hdl_paths.size();i++) begin
         string hdl_path = hdl_paths.get(i);

         if (parent_paths.size() == 0) begin
            if (hdl_path != "")
               paths.push_back(hdl_path);

            continue;
         end
         
         foreach (parent_paths[j])  begin
            if (hdl_path == "")
               paths.push_back(parent_paths[j]);
            else
               paths.push_back({ parent_paths[j], separator, hdl_path });
         end
      end
   end
  
endfunction


// get_default_hdl_path

function string uvm_reg_block::get_default_hdl_path();
  if (default_hdl_path == "" && parent != null)
    return parent.get_default_hdl_path();
  return default_hdl_path;
endfunction


// set_default_hdl_path

function void uvm_reg_block::set_default_hdl_path(string kind);

  if (kind == "") begin
    if (parent == null) begin
      `uvm_error("RegModel",{"Block has no parent. ",
           "Must specify a valid HDL abstraction (kind)"})
    end
    kind = parent.get_default_hdl_path();
  end

  default_hdl_path = kind;
endfunction


// set_hdl_path_root

function void uvm_reg_block::set_hdl_path_root (string path, string kind = "RTL");
  if (kind == "")
    kind = get_default_hdl_path();

  root_hdl_paths[kind] = path;
endfunction


// is_hdl_path_root

function bit  uvm_reg_block::is_hdl_path_root (string kind = "");
  if (kind == "")
    kind = get_default_hdl_path();

  return root_hdl_paths.exists(kind);
endfunction


//----------------------------------
// Group- Basic Object Operations
//----------------------------------

// do_print
function void uvm_reg_block::do_print (uvm_printer printer);
  super.do_print(printer);

  foreach(blks[i]) begin
     uvm_object obj = blks[i];
     printer.print_object(obj.get_name(), obj);
  end

  foreach(regs[i]) begin
     uvm_object obj = regs[i];
     printer.print_object(obj.get_name(), obj);
  end

  foreach(vregs[i]) begin
     uvm_object obj = vregs[i];
     printer.print_object(obj.get_name(), obj);
  end

  foreach(mems[i]) begin
     uvm_object obj = mems[i];
     printer.print_object(obj.get_name(), obj);
  end

  foreach(maps[i]) begin
     uvm_reg_map m = i;
     uvm_object obj = m;
     printer.print_object(obj.get_name(), obj);
  end
  
endfunction



// clone

function uvm_object uvm_reg_block::clone();
  `uvm_fatal("RegModel","RegModel blocks cannot be cloned")
  return null;
endfunction

// do_copy

function void uvm_reg_block::do_copy(uvm_object rhs);
  `uvm_fatal("RegModel","RegModel blocks cannot be copied")
endfunction


// do_compare

function bit uvm_reg_block::do_compare (uvm_object  rhs,
                                        uvm_comparer comparer);
  `uvm_warning("RegModel","RegModel blocks cannot be compared")
  return 0;
endfunction


// do_pack

function void uvm_reg_block::do_pack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel blocks cannot be packed")
endfunction


// do_unpack

function void uvm_reg_block::do_unpack (uvm_packer packer);
  `uvm_warning("RegModel","RegModel blocks cannot be unpacked")
endfunction


// convert2string

function string uvm_reg_block::convert2string();
   string image;
   string maps[];
   string blk_maps[];
   bit         single_map;
   uvm_endianness_e endian;
   string prefix = "  ";

`ifdef TODO
   single_map = 1;
   if (map == "") begin
      this.get_maps(maps);
      if (maps.size() > 1) single_map = 0;
   end

   if (single_map) begin
      $sformat(image, "%sBlock %s", prefix, this.get_full_name());

      if (map != "")
        $sformat(image, "%s.%s", image, map);

      endian = this.get_endian(map);

      $sformat(image, "%s -- %0d bytes (%s)", image,
               this.get_n_bytes(map), endian.name());

      foreach (blks[i]) begin
         string img;
         img = blks[i].convert2string({prefix, "   "}, blk_maps[i]);
         image = {image, "\n", img};
      end

   end
   else begin
      $sformat(image, "%Block %s", prefix, this.get_full_name());
      foreach (maps[i]) begin
         string img;
         endian = this.get_endian(maps[i]);
         $sformat(img, "%s   Map \"%s\" -- %0d bytes (%s)",
                  prefix, maps[i],
                  this.get_n_bytes(maps[i]), endian.name());
         image = {image, "\n", img};

         this.get_blocks(blks, blk_maps, maps[i]);
         foreach (blks[j]) begin
            img = blks[j].convert2string({prefix, "      "},
                                    blk_maps[j]);
            image = {image, "\n", img};
         end

         this.get_subsys(sys, blk_maps, maps[i]);
         foreach (sys[j]) begin
            img = sys[j].convert2string({prefix, "      "},
                                   blk_maps[j]);
            image = {image, "\n", img};
         end
      end
   end
`endif
   return image;
endfunction: convert2string
