//
//------------------------------------------------------------------------------
// Copyright 2010-2022 AMD
// Copyright 2012 Accellera Systems Initiative
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2012-2018 Cisco Systems, Inc.
// Copyright 2022 Intel Corporation
// Copyright 2021-2022 Marvell International Ltd.
// Copyright 2007-2011 Mentor Graphics Corporation
// Copyright 2012-2022 NVIDIA Corporation
// Copyright 2014 Semifore
// Copyright 2010-2018 Synopsys, Inc.
// Copyright 2017-2021 Verific
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
//
// CLASS -- NODOCS -- uvm_root
//
// The ~uvm_root~ class serves as the implicit top-level and phase controller for
// all UVM components. Users do not directly instantiate ~uvm_root~. The UVM
// automatically creates a single instance of <uvm_root> that users can
// access via the global (uvm_pkg-scope) variable, ~uvm_top~.
//
// (see uvm_ref_root.gif)
//
// The ~uvm_top~ instance of ~uvm_root~ plays several key roles in the UVM.
//
// Implicit top-level - The ~uvm_top~ serves as an implicit top-level component.
// Any component whose parent is specified as ~null~ becomes a child of ~uvm_top~.
// Thus, all UVM components in simulation are descendants of ~uvm_top~.
//
// Phase control - ~uvm_top~ manages the phasing for all components.
//
// Search - Use ~uvm_top~ to search for components based on their
// hierarchical name. See <find> and <find_all>.
//
// Report configuration - Use ~uvm_top~ to globally configure
// report verbosity, log files, and actions. For example,
// ~uvm_top.set_report_verbosity_level_hier(UVM_FULL)~ would set
// full verbosity for all components in simulation.
//
// Global reporter - Because ~uvm_top~ is globally accessible (in uvm_pkg
// scope), UVM's reporting mechanism is accessible from anywhere
// outside ~uvm_component~, such as in modules and sequences.
// See <uvm_report_error>, <uvm_report_warning>, and other global
// methods.
//
//
// The ~uvm_top~ instance checks during the end_of_elaboration phase if any errors have
// been generated so far. If errors are found a UVM_FATAL error is being generated as result
// so that the simulation will not continue to the start_of_simulation_phase.
//

//------------------------------------------------------------------------------

typedef class uvm_cmdline_processor;
typedef class uvm_component_proxy;
typedef class uvm_top_down_visitor_adapter;
typedef class uvm_report_message;
typedef class uvm_report_object;
typedef class uvm_report_handler;
typedef class uvm_default_report_server;
typedef class uvm_cmdline_verbosity;

// Class: uvm_root
// 
// Implementation of the uvm_root class, as defined in
// 1800.2-2020 Section F.7 with the following additional API

class uvm_root extends uvm_component;

	// Function -- NODOCS -- get()
	// Static accessor for <uvm_root>.
	//
	// The static accessor is provided as a convenience wrapper
	// around retrieving the root via the <uvm_coreservice_t::get_root>
	// method.
	//
	// | // Using the uvm_coreservice_t:
	// | uvm_coreservice_t cs;
	// | uvm_root r;
	// | cs = uvm_coreservice_t::get();
	// | r = cs.get_root();
	// |
	// | // Not using the uvm_coreservice_t:
	// | uvm_root r;
	// | r = uvm_root::get();
	//

	extern static function uvm_root get();

	uvm_cmdline_processor clp;

	virtual function string get_type_name();
		return "uvm_root";
	endfunction


	//----------------------------------------------------------------------------
	// Group -- NODOCS -- Simulation Control
	//----------------------------------------------------------------------------


	// Task -- NODOCS -- run_test
	//
	// Phases all components through all registered phases. If the optional
	// test_name argument is provided, or if a command-line plusarg,
	// +UVM_TESTNAME=TEST_NAME, is found, then the specified component is created
	// just prior to phasing. The test may contain new verification components or
	// the entire testbench, in which case the test and testbench can be chosen from
	// the command line without forcing recompilation. If the global (package)
	// variable, finish_on_completion, is set, then $finish is called after
	// phasing completes.

	extern virtual task run_test (string test_name="");


	// Function -- NODOCS -- die
	//
	// This method is called by the report server if a report reaches the maximum
	// quit count or has a UVM_EXIT action associated with it, e.g., as with
	// fatal errors.
	//
	// Calls the <uvm_component::pre_abort()> method
	// on the entire <uvm_component> hierarchy in a bottom-up fashion.
	// It then calls <uvm_report_server::report_summarize> and terminates the simulation
	// with ~$finish~.

	virtual function void die();
	  uvm_report_server l_rs;

          // Only die once...
          if (get_core_state() inside {UVM_CORE_PRE_ABORT,UVM_CORE_ABORTED})
            return;
          
          l_rs = uvm_report_server::get_server();
	  // do the pre_abort callbacks
          
          m_uvm_core_state.push_front(UVM_CORE_PRE_ABORT);
          
          
	  m_do_pre_abort();
          
    	  uvm_run_test_callback::m_do_pre_abort();
          
          m_do_cmdline_checks();
          
	  l_rs.report_summarize();
          
          m_uvm_core_state.push_front(UVM_CORE_ABORTED);
          
	  $finish;
	endfunction


	// Function -- NODOCS -- set_timeout
	//
	// Specifies the timeout for the simulation. Default is <`UVM_DEFAULT_TIMEOUT>
	//
	// The timeout is simply the maximum absolute simulation time allowed before a
	// ~FATAL~ occurs.  If the timeout is set to 20ns, then the simulation must end
	// before 20ns, or a ~FATAL~ timeout will occur.
	//
	// This is provided so that the user can prevent the simulation from potentially
	// consuming too many resources (Disk, Memory, CPU, etc) when the testbench is
	// essentially hung.
	//
	//

	extern function void set_timeout(time timeout, bit overridable=1);

	// Variable -- NODOCS -- finish_on_completion
	//
	// If set, then run_test will call $finish after all phases are executed.
  //@uvm-compat , for compatibility with 1.2
  bit finish_on_completion = 1;

  // Function -- NODOCS -- get_finish_on_completion
  
  virtual  function bit get_finish_on_completion();
     return finish_on_completion;
  endfunction : get_finish_on_completion

  // Function -- NODOCS -- set_finish_on_completion

  virtual  function void set_finish_on_completion(bit f);
     finish_on_completion = f;
  endfunction : set_finish_on_completion
   
//----------------------------------------------------------------------------
// Group -- NODOCS -- Topology
//----------------------------------------------------------------------------

        // Variable -- NODOCS -- top_levels
        //
        // This variable is a list of all of the top level components in UVM. It
        // includes the uvm_test_top component that is created by <run_test> as
        // well as any other top level components that have been instantiated
        // anywhere in the hierarchy.

        // @uvm-compat Added for compatibility with uvm-1.2
        uvm_component top_levels[$];

	// Function -- NODOCS -- find

	extern function uvm_component find (string comp_match);

	// Function -- NODOCS -- find_all
	//
	// Returns the component handle (find) or list of components handles
	// (find_all) matching a given string. The string may contain the wildcards,
	// * and ?. Strings beginning with '.' are absolute path names. If the optional
	// argument comp is provided, then search begins from that component down
	// (default=all components).

	extern function void find_all (string comp_match,
		ref uvm_component comps[$],
		input uvm_component comp=null);


	// Function -- NODOCS -- print_topology
	//
	// Print the verification environment's component topology. The
	// ~printer~ is a <uvm_printer> object that controls the format
	// of the topology printout; a ~null~ printer prints with the
	// default output.

	extern function void print_topology  (uvm_printer printer=null);


	// Variable -- NODOCS -- enable_print_topology
	//
	// If set, then the entire testbench topology is printed just after completion
	// of the end_of_elaboration phase.

	bit  enable_print_topology = 0;

    
	// Function: set_enable_print_topology
	//
	// Sets the variable to enable printing the entire testbench topology just after completion
	// of the end_of_elaboration phase.
        //
        // @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2

	extern function void set_enable_print_topology  (bit enable);
		
	// Function: get_enable_print_topology
	//
	// Gets the variable to enable printing the entire testbench topology just after completion of the end_of_elaboration phase..
        //
        // @uvm-accellera The details of this API are specific to the Accellera implementation, and are not being considered for contribution to 1800.2

	extern function bit get_enable_print_topology  ();


	// Variable- phase_timeout
	//
	// Specifies the timeout for the run phase. Default is `UVM_DEFAULT_TIMEOUT


	time phase_timeout = `UVM_DEFAULT_TIMEOUT;


	// PRIVATE members
	extern function void m_find_all_recurse(string comp_match,
		ref uvm_component comps[$],
		input uvm_component comp=null);

	extern protected function new ();
	extern protected virtual function bit m_add_child (uvm_component child);
	extern function void build_phase(uvm_phase phase);
        extern local function void m_do_cl_init();
	extern local function void m_do_verbosity_settings();
        extern local function void m_do_cmdline_checks();
	extern local function void m_do_timeout_settings();
	extern local function void m_do_factory_settings();
	extern local function void m_process_inst_override(string ovr);
	extern local function void m_process_type_override(string ovr);
	extern local function void m_do_config_settings();
	extern local function void m_do_max_quit_settings();
	extern local function void m_do_dump_args();
	extern local function void m_process_config(string cfg, bit is_int, is_bitstream);
	extern local function void m_process_default_sequence(string cfg);
        local string m_uvm_verbosity_settings[$];
        local uvm_cmdline_set_verbosity m_time_settings[$];
	extern function void m_check_verbosity();
	extern function void m_check_uvm_field_flag_size();
	extern virtual function void report_header(UVM_FILE file = 0);
	// singleton handle
	static local uvm_root m_inst;

	// For error checking
	extern virtual task run_phase (uvm_phase phase);


	// phase_started
	// -------------
	// At end of elab phase we need to do tlm binding resolution.
	function void phase_started(uvm_phase phase);
		if (phase == end_of_elaboration_ph) begin
			do_resolve_bindings();
			if (enable_print_topology) print_topology();
			begin
				uvm_report_server srvr;
				srvr = uvm_report_server::get_server();
				if(srvr.get_severity_count(UVM_ERROR) > 0) begin
					uvm_report_fatal("BUILDERR", "stopping due to build errors", UVM_NONE);
				end
			end
		end
	endfunction

	bit m_phase_all_done;

        extern static function uvm_root m_uvm_get_root();
          

	static local bit m_relnotes_done=0;

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_component_proxy p = new("proxy");
		uvm_top_down_visitor_adapter#(uvm_component) adapter = new("adapter");
		uvm_coreservice_t cs = uvm_coreservice_t::get();
		uvm_visitor#(uvm_component) v = cs.get_component_visitor();
		adapter.accept(this, v, p);
	endfunction

endclass

// Note that uvm_top is provided for backwards compatibility, but to avoid
// complications caused by static initialization it can no longer be a
// const value.
   
//@uvm-compat Provided for compatibility with 1.2
/* const */ uvm_root uvm_top;
   
   
//-----------------------------------------------------------------------------
// IMPLEMENTATION
//-----------------------------------------------------------------------------

// get
// ---

function uvm_root uvm_root::get();
	uvm_coreservice_t cs = uvm_coreservice_t::get();
	return cs.get_root();
endfunction

// new
// ---

function uvm_root::new();
  uvm_report_handler rh;
  super.new("__top__", null);

  // For error reporting purposes, we need to construct this first.
  rh = new("reporter");
  set_report_handler(rh);

  // Checking/Setting this here makes it much harder to
  // trick uvm_init into infinite recursions
  if (m_inst != null) begin
    `uvm_fatal_context("UVM/ROOT/MULTI",
                       "Attempting to construct multiple roots",
                       m_inst)
    return;
  end
  m_inst = this;
  clp = uvm_cmdline_processor::get_inst();

  m_do_cl_init();
  m_set_cl_msg_args();

endfunction

// m_uvm_get_root
// internal function not to be used
// get the initialized singleton instance of uvm_root
function uvm_root uvm_root::m_uvm_get_root();
  if (m_inst == null) begin
    uvm_root top;
    top = new();
    uvm_top = top; // backwards compat 
    
    if (top != m_inst)
      // Something very, very bad has happened and
      // we already fatal'd.  Throw out the garbage
      // root.
      return null;
    
    top.m_domain = uvm_domain::get_uvm_domain();
  end // if (m_inst == null)
  if (m_inst != uvm_top) begin
    `uvm_fatal_context("UVM/BAD_TOP", "The uvm_top variable has been overwritten outside of uvm_root!",m_inst)
  end
  return m_inst;
endfunction

  
function void uvm_root::report_header(UVM_FILE file = 0);
	string q[$];
	uvm_report_server srvr;
	uvm_cmdline_processor clp;
	string args[$];

	srvr = uvm_report_server::get_server();
	clp = uvm_cmdline_processor::get_inst();

	if (clp.get_arg_matches("+UVM_NO_RELNOTES", args)) return;

	if (!m_relnotes_done) begin
	  q.push_back("\n  ***********       IMPORTANT RELEASE NOTES         ************\n");
	  m_relnotes_done = 1;

  	  q.push_back("\n  This implementation of the UVM Library deviates from the 1800.2-2020\n");
	  q.push_back("  standard.  See the DEVIATIONS.md file contained in the release\n");
	  q.push_back("  for more details.\n");
          
`ifdef UVM_ENABLE_DEPRECATED_API

	  q.push_back("\n  You are using a version of the UVM library that has been compiled\n");
	  q.push_back("  with `UVM_ENABLE_DEPRECATED_API defined.\n");
	  q.push_back("  See https://accellera.mantishub.io/view.php?id=5072 for more details.\n");
   
`endif

	end // !m_relnotes_done

	q.push_back("\n----------------------------------------------------------------\n");
	q.push_back({uvm_revision_string(),"\n"});
	q.push_back("\n");
        q.push_back("All copyright owners for this kit are listed in NOTICE.txt\n");
        q.push_back("All Rights Reserved Worldwide\n");
	q.push_back("----------------------------------------------------------------\n");

	if(m_relnotes_done)
		q.push_back("\n      (Specify +UVM_NO_RELNOTES to turn off this notice)\n");

	`uvm_info("UVM/RELNOTES",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW)
endfunction



// run_test
// --------

task uvm_root::run_test(string test_name="");
	uvm_report_server l_rs;

	uvm_factory factory;
	bit testname_plusarg;
	int test_name_count;
	string test_names[$];
	string msg;
	uvm_component uvm_test_top;

	process phase_runner_proc; // store thread forked below for final cleanup

  	uvm_run_test_callback::m_do_pre_run_test();

	factory=uvm_factory::get();
        m_uvm_core_state.push_front(UVM_CORE_PRE_RUN);

	testname_plusarg = 0;

	// Set up the process that decouples the thread that drops objections from
	// the process that processes drop/all_dropped objections. Thus, if the
	// original calling thread (the "dropper") gets killed, it does not affect
	// drain-time and propagation of the drop up the hierarchy.
	// Needs to be done in run_test since it needs to be in an
	// initial block to fork a process.
	uvm_objection::m_init_objections();

// dump cmdline args BEFORE the args are being used
	m_do_dump_args();

`ifndef UVM_NO_DPI

	// Retrieve the test names provided on the command line.  Command line
	// overrides the argument.
	test_name_count = clp.get_arg_values("+UVM_TESTNAME=", test_names);

	// If at least one, use first in queue.
	if (test_name_count > 0) begin
		test_name = test_names[0];
		testname_plusarg = 1;
	end

	// If multiple, provided the warning giving the number, which one will be
	// used and the complete list.
	if (test_name_count > 1) begin
		string test_list;
		string sep;
		for (int i = 0; i < test_names.size(); i++) begin
			if (i != 0)
				sep = ", ";
			test_list = {test_list, sep, test_names[i]};
		end
		uvm_report_warning("MULTTST",
			$sformatf("Multiple (%0d) +UVM_TESTNAME arguments provided on the command line.  '%s' will be used.  Provided list: %s.", test_name_count, test_name, test_list), UVM_NONE);
	end

`else

        `uvm_warning("NO_DPI_USED", "We are thinking of removing support for UVM_NO_DPI.  Please try this test without it and evaluate the impact")
	// plusarg overrides argument
	if ($value$plusargs("UVM_TESTNAME=%s", test_name)) begin
		`uvm_info("NO_DPI_TSTNAME", "UVM_NO_DPI defined--getting UVM_TESTNAME directly, without DPI", UVM_NONE)
		testname_plusarg = 1;
	end

`endif

	// if test now defined, create it using common factory
	if (test_name != "") begin

		if(m_children.exists("uvm_test_top")) begin
			uvm_report_fatal("TTINST",
				"An uvm_test_top already exists via a previous call to run_test", UVM_NONE);
			#0; // forces shutdown because $finish is forked
		end
		$cast(uvm_test_top, factory.create_component_by_name(test_name,
				"", "uvm_test_top", null));

		if (uvm_test_top == null) begin
			msg = testname_plusarg ? {"command line +UVM_TESTNAME=",test_name} :
			{"call to run_test(",test_name,")"};
			uvm_report_fatal("INVTST",
				{"Requested test from ",msg, " not found." }, UVM_NONE);
		end
	end

	if (m_children.num() == 0) begin
		uvm_report_fatal("NOCOMP",
			{"No components instantiated. You must either instantiate",
				" at least one component before calling run_test or use",
				" run_test to do so. To run a test using run_test,",
				" use +UVM_TESTNAME or supply the test name in",
				" the argument to run_test(). Exiting simulation."}, UVM_NONE);
		return;
	end

	begin
		if(test_name=="")
			uvm_report_info("RNTST", "Running test ...", UVM_LOW);
		else if (test_name == uvm_test_top.get_type_name())
			uvm_report_info("RNTST", {"Running test ",test_name,"..."}, UVM_LOW);
		else
			uvm_report_info("RNTST", {"Running test ",uvm_test_top.get_type_name()," (via factory override for test \"",test_name,"\")..."}, UVM_LOW);
	end

	// phase runner, isolated from calling process
        // Note: Using a fork here may not be necessary.  If the calling
        // process is disabled, then this process continues,
        // but if the calling process is killed then this
        // process is killed.  
	fork 
          begin
	    // spawn the phase runner task
            uvm_phase_hopper hopper;
            hopper = uvm_phase_hopper::get_global_hopper();
            m_uvm_core_state.push_front(UVM_CORE_RUNNING);
            hopper.run_phases();
	  end
	join

        m_uvm_core_state.push_front(UVM_CORE_POST_RUN);

	l_rs = uvm_report_server::get_server();

        uvm_run_test_callback::m_do_post_run_test();

        m_do_cmdline_checks();
  
	l_rs.report_summarize();

        m_uvm_core_state.push_front(UVM_CORE_FINISHED);
  	if (get_finish_on_completion())
		$finish;

endtask


// find_all
// --------

function void uvm_root::find_all(string comp_match, ref uvm_component comps[$],
		input uvm_component comp=null);

	if (comp==null)
		comp = this;
	m_find_all_recurse(comp_match, comps, comp);

endfunction


// find
// ----

function uvm_component uvm_root::find (string comp_match);
	uvm_component comp_list[$];

	find_all(comp_match,comp_list);

	if (comp_list.size() > 1)
		uvm_report_warning("MMATCH",
			$sformatf("Found %0d components matching '%s'. Returning first match, %0s.",
				comp_list.size(),comp_match,comp_list[0].get_full_name()), UVM_NONE);

	if (comp_list.size() == 0) begin
		uvm_report_warning("CMPNFD",
			{"Component matching '",comp_match,
				"' was not found in the list of uvm_components"}, UVM_NONE);
		return null;
	end

	return comp_list[0];
endfunction


// print_topology
// --------------

function void uvm_root::print_topology(uvm_printer printer=null);

	if (m_children.num()==0) begin
		uvm_report_warning("EMTCOMP", "print_topology - No UVM components to print.", UVM_NONE);
		return;
	end

	if (printer==null)
		printer = uvm_printer::get_default();

	`uvm_info("UVMTOP","UVM testbench topology:",UVM_NONE)
   print(printer) ;

endfunction


// set_timeout
// -----------

function void uvm_root::set_timeout(time timeout, bit overridable=1);
	static bit m_uvm_timeout_overridable = 1;
	if (m_uvm_timeout_overridable == 0) begin
		uvm_report_info("NOTIMOUTOVR",
			$sformatf("The global timeout setting of %0d is not overridable to %0d due to a previous setting.",
				phase_timeout, timeout), UVM_NONE);
		return;
	end
	m_uvm_timeout_overridable = overridable;
	phase_timeout = timeout;
endfunction



// m_find_all_recurse
// ------------------

function void uvm_root::m_find_all_recurse(string comp_match, ref uvm_component comps[$],
		input uvm_component comp=null);
	string name;

	if (comp.get_first_child(name))
		do begin
			this.m_find_all_recurse(comp_match, comps, comp.get_child(name));
		end
		while (comp.get_next_child(name));
	if (uvm_is_match(comp_match, comp.get_full_name()) &&
			comp.get_name() != "") /* uvm_top */
		comps.push_back(comp);

endfunction


// m_add_child
// -----------

// Add to the top levels array
function bit uvm_root::m_add_child (uvm_component child);
	if(super.m_add_child(child)) begin
                if(child.get_name() == "uvm_test_top")
                        top_levels.push_front(child);
                else
                        top_levels.push_back(child);
		return 1;
	end
	else
		return 0;
endfunction


// build_phase
// -----

function void uvm_root::build_phase(uvm_phase phase);

  super.build_phase(phase);
  
  m_do_verbosity_settings();
  m_do_timeout_settings();
  m_do_factory_settings();
  m_do_config_settings();
  m_do_max_quit_settings();

endfunction

// m_do_cl_init
// ---------------------
function void uvm_root::m_do_cl_init();
  string values[$];
  string args[$];
  string message;

  uvm_cmdline_set_verbosity::init(this);
  foreach(uvm_cmdline_set_verbosity::settings[i])
    if (uvm_cmdline_set_verbosity::settings[i].phase == "time" && uvm_cmdline_set_verbosity::settings[i].offset != 0)
      m_time_settings.push_back(uvm_cmdline_set_verbosity::settings[i]);

  uvm_cmdline_set_action::init(this);

  uvm_cmdline_set_severity::init(this);

endfunction : m_do_cl_init
  
  
// m_do_verbosity_settings
// -----------------------

function void uvm_root::m_do_verbosity_settings();
  string set_verbosity_settings[$];
  string split_vals[$];
  uvm_verbosity tmp_verb;

  // do time based command line verbosity settings
  fork 
    begin
      time last_time = 0;
      if (m_time_settings.size() > 0)
        m_time_settings.sort() with ( item.offset );
      foreach(m_time_settings[i]) begin
        uvm_component comps[$];
        find_all(m_time_settings[i].comp,comps);
        #(m_time_settings[i].offset - last_time);
        last_time = m_time_settings[i].offset;
        if(m_time_settings[i].id == "_ALL_") begin
          foreach(comps[j]) begin
            m_time_settings[i].used[comps[j]] = 1;
            comps[j].set_report_verbosity_level(m_time_settings[i].verbosity);
          end
        end
        else begin
          foreach(comps[j]) begin
            m_time_settings[i].used[comps[j]] = 1;
            comps[j].set_report_id_verbosity(m_time_settings[i].id, m_time_settings[i].verbosity);
          end
        end
      end
    end 
  join_none // fork begin

endfunction


// m_do_cmdline_checks
// ---------------------
function void uvm_root::m_do_cmdline_checks();
  string dump_args[$];

  uvm_cmdline_set_verbosity::check(this);
  
  if(clp.get_arg_matches("+UVM_DUMP_REPORT_ARGS", dump_args)) begin
    string msgs[$];

`ifdef UVM_CMDLINE_NO_DPI
    msgs.push_back("\n!!! UVM_CMDLINE_NO_DPI IS DEFINED !!!");
`endif

    msgs.push_back(uvm_cmdline_verbosity::dump());
    msgs.push_back(uvm_cmdline_set_verbosity::dump());
    msgs.push_back(uvm_cmdline_set_action::dump());
    msgs.push_back(uvm_cmdline_set_severity::dump());
     
    uvm_report_info("REPORTARGS", 
                    $sformatf("\n--- UVM Reporting Argument Summary ---\n%s\n", 
                              `UVM_STRING_QUEUE_STREAMING_PACK(msgs)),
                    UVM_NONE);
  end
  
endfunction // m_do_cmdline_checks
  
// m_do_timeout_settings
// ---------------------

function void uvm_root::m_do_timeout_settings();
	string timeout_settings[$];
	string timeout;
	string split_timeout[$];
	int timeout_count;
	time timeout_int;
	string override_spec;
	timeout_count = clp.get_arg_values("+UVM_TIMEOUT=", timeout_settings);
	if (timeout_count ==  0)
		return;
	else begin
		timeout = timeout_settings[0];
		if (timeout_count > 1) begin
			string timeout_list;
			string sep;
			for (int i = 0; i < timeout_settings.size(); i++) begin
				if (i != 0)
					sep = "; ";
				timeout_list = {timeout_list, sep, timeout_settings[i]};
			end
			uvm_report_warning("MULTTIMOUT",
				$sformatf("Multiple (%0d) +UVM_TIMEOUT arguments provided on the command line.  '%s' will be used.  Provided list: %s.",
					timeout_count, timeout, timeout_list), UVM_NONE);
		end
		uvm_report_info("TIMOUTSET",
			$sformatf("'+UVM_TIMEOUT=%s' provided on the command line is being applied.", timeout), UVM_NONE);
		void'($sscanf(timeout,"%d,%s",timeout_int,override_spec));
		case(override_spec)
			"YES"   : set_timeout(timeout_int, 1);
			"NO"    : set_timeout(timeout_int, 0);
			default : set_timeout(timeout_int, 1);
		endcase
	end
endfunction


// m_do_factory_settings
// ---------------------

function void uvm_root::m_do_factory_settings();
	string args[$];

	void'(clp.get_arg_matches("/^\\+(UVM_SET_INST_OVERRIDE|uvm_set_inst_override)=/",args));
	foreach(args[i]) begin
		m_process_inst_override(args[i].substr(23, args[i].len()-1));
	end
	void'(clp.get_arg_matches("/^\\+(UVM_SET_TYPE_OVERRIDE|uvm_set_type_override)=/",args));
	foreach(args[i]) begin
		m_process_type_override(args[i].substr(23, args[i].len()-1));
	end
endfunction


// m_process_inst_override
// -----------------------

function void uvm_root::m_process_inst_override(string ovr);
	string split_val[$];
	uvm_coreservice_t cs = uvm_coreservice_t::get();
	uvm_factory factory=cs.get_factory();

	uvm_string_split(ovr, ",", split_val);

	if(split_val.size() != 3 ) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid setting for +uvm_set_inst_override=", ovr,
				", setting must specify <requested_type>,<override_type>,<instance_path>"}, UVM_NONE);
		return;
	end

	uvm_report_info("INSTOVR", {"Applying instance override from the command line: +uvm_set_inst_override=", ovr}, UVM_NONE);
	factory.set_inst_override_by_name(split_val[0], split_val[1], split_val[2]);
endfunction


// m_process_type_override
// -----------------------

function void uvm_root::m_process_type_override(string ovr);
	string split_val[$];
	int replace=1;
	uvm_coreservice_t cs = uvm_coreservice_t::get();
	uvm_factory factory=cs.get_factory();

	uvm_string_split(ovr, ",", split_val);

	if(split_val.size() > 3 || split_val.size() < 2) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid setting for +uvm_set_type_override=", ovr,
				", setting must specify <requested_type>,<override_type>[,<replace>]"}, UVM_NONE);
		return;
	end

	// Replace arg is optional. If set, must be 0 or 1
	if(split_val.size() == 3) begin
		if(split_val[2]=="0") replace =  0;
		else if (split_val[2] == "1") replace = 1;
		else begin
			uvm_report_error("UVM_CMDLINE_PROC", {"Invalid replace arg for +uvm_set_type_override=", ovr ," value must be 0 or 1"}, UVM_NONE);
			return;
		end
	end

	uvm_report_info("UVM_CMDLINE_PROC", {"Applying type override from the command line: +uvm_set_type_override=", ovr}, UVM_NONE);
	factory.set_type_override_by_name(split_val[0], split_val[1], replace);
endfunction


// m_process_config
// ----------------

function void uvm_root::m_process_config(string cfg, bit is_int, is_bitstream);
	uvm_bitstream_t v;
	string split_val[$];
	uvm_root m_uvm_top;
	uvm_coreservice_t cs;
	cs = uvm_coreservice_t::get();
	m_uvm_top = cs.get_root();


	uvm_string_split(cfg, ",", split_val);
   
	if(split_val.size() == 1) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid +uvm_set_config command\"", cfg,
				"\" missing field and value: component is \"", split_val[0], "\""}, UVM_NONE);
		return;
	end

	if(split_val.size() == 2) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid +uvm_set_config command\"", cfg,
				"\" missing value: component is \"", split_val[0], "\"  field is \"", split_val[1], "\""}, UVM_NONE);
		return;
	end

	if(split_val.size() > 3) begin
		uvm_report_error("UVM_CMDLINE_PROC",
			$sformatf("Invalid +uvm_set_config command\"%s\" : expected only 3 fields (component, field and value).", cfg), UVM_NONE);
		return;
	end

	if(is_int) begin
	  if(split_val[2].len() > 2) begin
	    string base, extval;
	    base = split_val[2].substr(0,1);
	    extval = split_val[2].substr(2,split_val[2].len()-1);
	    case(base)
	      "'b" : v = extval.atobin();
	      "0b" : v = extval.atobin();
	      "'o" : v = extval.atooct();
	      "'d" : v = extval.atoi();
	      "'h" : v = extval.atohex();
	      "'x" : v = extval.atohex();
	      "0x" : v = extval.atohex();
	      default : v = split_val[2].atoi();
	    endcase
	  end
	  else begin
	    v = split_val[2].atoi();
	  end
	  uvm_report_info("UVM_CMDLINE_PROC", {"Applying config setting from the command line: +uvm_set_config_int=", cfg}, UVM_NONE);
	  uvm_config_int::set(m_uvm_top, split_val[0], split_val[1], v);
	end // if (is_int)
        else if(is_bitstream) begin
	  string base, extval, tmp;
          int    success ;
          bit    is_negative;
          if (split_val[2].len() > 1) begin
            byte char;
            char = split_val[2].getc(0);
            // Optional sign
            if (char == "-") begin
              // Signed, negative
              is_negative = 1;
              tmp = split_val[2].substr(1, split_val[2].len()-1);
            end
            else if (char == "+") begin
              // Signed, positive (just remove the sign)
              tmp = split_val[2].substr(1, split_val[2].len()-1);
            end
            else begin
              // Unsigned
              tmp = split_val[2];
            end
          end // if (split_val[2].len() > 1)
          else begin // !(split_val[2].len() > 1)
            tmp = split_val[2];
          end
          
	  if(tmp.len() > 2) begin
	    base = tmp.substr(0,1);
	    extval = tmp.substr(2,tmp.len()-1);                   
	    case(base)
	      "'b" : success= $sscanf(extval,"%b", v); 
	      "0b" : success= $sscanf(extval,"%b", v); 
	      "'o" : success= $sscanf(extval,"%o", v); 
	      "'d" : success= $sscanf(extval,"%d", v); 
	      "'h" : success= $sscanf(extval,"%x", v); 
	      "'x" : success= $sscanf(extval,"%x", v); 
	      "0x" : success= $sscanf(extval,"%x", v); 
	      default : success = $sscanf(split_val[2],"%d", v); 
	    endcase
	  end
	  else begin
            success = $sscanf(tmp,"%d", v);
	  end // else: !if(tmp.len() > 2)

          if (success == 1) begin
            if (is_negative) begin
              v = -v;
            end
	    uvm_report_info("UVM_CMDLINE_PROC", {"Applying config setting from the command line: +uvm_set_config_bitstream=", cfg}, UVM_NONE);
	    uvm_config_int::set(m_uvm_top, split_val[0], split_val[1], v);
          end
          else begin
          end
        end // if (is_bitstream)
	else begin
	  uvm_report_info("UVM_CMDLINE_PROC", {"Applying config setting from the command line: +uvm_set_config_string=", cfg}, UVM_NONE);
	  uvm_config_string::set(m_uvm_top, split_val[0], split_val[1], split_val[2]);
	end

endfunction

// m_process_default_sequence
// ----------------

function void uvm_root::m_process_default_sequence(string cfg);
	string split_val[$];
	uvm_coreservice_t cs = uvm_coreservice_t::get();
	uvm_root m_uvm_top = cs.get_root();
	uvm_factory f = cs.get_factory();
	uvm_object_wrapper w;

	uvm_string_split(cfg, ",", split_val);
	if(split_val.size() == 1) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid +uvm_set_default_sequence command\"", cfg,
				"\" missing phase and type: sequencer is \"", split_val[0], "\""}, UVM_NONE);
		return;
	end

	if(split_val.size() == 2) begin
		uvm_report_error("UVM_CMDLINE_PROC", {"Invalid +uvm_set_default_sequence command\"", cfg,
				"\" missing type: sequencer is \"", split_val[0], "\"  phase is \"", split_val[1], "\""}, UVM_NONE);
		return;
	end

	if(split_val.size() > 3) begin
		uvm_report_error("UVM_CMDLINE_PROC",
			$sformatf("Invalid +uvm_set_default_sequence command\"%s\" : expected only 3 fields (sequencer, phase and type).", cfg), UVM_NONE);
		return;
	end

	w = f.find_wrapper_by_name(split_val[2]);
	if (w == null) begin
		uvm_report_error("UVM_CMDLINE_PROC",
			$sformatf("Invalid type '%s' provided to +uvm_set_default_sequence", split_val[2]),
			UVM_NONE);
		return;
	end
	else begin
		uvm_report_info("UVM_CMDLINE_PROC", {"Setting default sequence from the command line: +uvm_set_default_sequence=", cfg}, UVM_NONE);
		uvm_config_db#(uvm_object_wrapper)::set(this, {split_val[0], ".", split_val[1]}, "default_sequence", w);
	end

endfunction : m_process_default_sequence


// m_do_config_settings
// --------------------

function void uvm_root::m_do_config_settings();
	string args[$];

	void'(clp.get_arg_matches("/^\\+(UVM_SET_CONFIG_INT|uvm_set_config_int)=/",args));
	foreach(args[i]) begin
		m_process_config(args[i].substr(20, args[i].len()-1), 1, 0);
	end
	void'(clp.get_arg_matches("/^\\+(UVM_SET_CONFIG_BITSTREAM|uvm_set_config_bitstream)=/",args));
	foreach(args[i]) begin
		m_process_config(args[i].substr(26, args[i].len()-1), 0, 1);
	end
	void'(clp.get_arg_matches("/^\\+(UVM_SET_CONFIG_STRING|uvm_set_config_string)=/",args));
	foreach(args[i]) begin
		m_process_config(args[i].substr(23, args[i].len()-1), 0, 0);
	end
	void'(clp.get_arg_matches("/^\\+(UVM_SET_DEFAULT_SEQUENCE|uvm_set_default_sequence)=/", args));
	foreach(args[i]) begin
		m_process_default_sequence(args[i].substr(26, args[i].len()-1));
	end
endfunction


// m_do_max_quit_settings
// ----------------------

function void uvm_root::m_do_max_quit_settings();
	uvm_report_server srvr;
	string max_quit_settings[$];
	int max_quit_count;
	string max_quit;
	string split_max_quit[$];
	int max_quit_int;
        int i;
        string tmp;
	srvr = uvm_report_server::get_server();
	max_quit_count = clp.get_arg_values("+UVM_MAX_QUIT_COUNT=", max_quit_settings);
	if (max_quit_count ==  0)
		return;
	else begin
		max_quit = max_quit_settings[0];
		if (max_quit_count > 1) begin
			string max_quit_list;
			string sep;
			for (int i = 0; i < max_quit_settings.size(); i++) begin
				if (i != 0)
					sep = "; ";
				max_quit_list = {max_quit_list, sep, max_quit_settings[i]};
			end
			uvm_report_warning("MULTMAXQUIT",
				$sformatf("Multiple (%0d) +UVM_MAX_QUIT_COUNT arguments provided on the command line.  '%s' will be used.  Provided list: %s.",
					max_quit_count, max_quit, max_quit_list), UVM_NONE);
		end
		uvm_report_info("MAXQUITSET",
			$sformatf("'+UVM_MAX_QUIT_COUNT=%s' provided on the command line is being applied.", max_quit), UVM_NONE);
		uvm_string_split(max_quit, ",", split_max_quit);
                tmp = split_max_quit[0];
                i = $sscanf(tmp,"%d", max_quit_int);           
		case(split_max_quit[1])
			"YES"   : srvr.set_max_quit_count(max_quit_int, 1);
			"NO"    : srvr.set_max_quit_count(max_quit_int, 0);
			default : srvr.set_max_quit_count(max_quit_int, 1);
		endcase
	end
endfunction

// m_do_dump_args
// --------------

function void uvm_root::m_do_dump_args();
	string dump_args[$];
	string all_args[$];
	string out_string;
	if(clp.get_arg_matches("+UVM_DUMP_CMDLINE_ARGS", dump_args)) begin
		clp.get_args(all_args);
		foreach (all_args[idx]) begin
			uvm_report_info("DUMPARGS", $sformatf("idx=%0d arg=[%s]",idx,all_args[idx]), UVM_NONE);
		end
	end
endfunction


// m_check_verbosity
// ----------------

function void uvm_root::m_check_verbosity();

  int    verbosity = UVM_MEDIUM;
  
  uvm_cmdline_verbosity::init(this);
  uvm_cmdline_verbosity::check(this);
  
  if (uvm_cmdline_verbosity::settings.size() > 0)
    verbosity = uvm_cmdline_verbosity::settings[0].verbosity;
  
  set_report_verbosity_level_hier(verbosity);

endfunction

function void uvm_root::m_check_uvm_field_flag_size();
	if ( (`UVM_FIELD_FLAG_SIZE) < UVM_FIELD_FLAG_RESERVED_BITS ) begin
		uvm_report_fatal( "BAD_FIELD_FLAG_SZ",
			$sformatf(
				"Macro UVM_FIELD_FLAG_SIZE is set to %0d which is less than the required minimum of UVM_FIELD_FLAG_RESERVED_BITS (%0d).",
				`UVM_FIELD_FLAG_SIZE, UVM_FIELD_FLAG_RESERVED_BITS
			)
		);
	end
endfunction

// It is required that the run phase start at simulation time 0
// TBD this looks wrong - taking advantage of uvm_root not doing anything else?
// TBD move to phase_started callback?
task uvm_root::run_phase (uvm_phase phase);
  // check that the commandline are took effect
  uvm_cmdline_set_action::check(this);
  uvm_cmdline_set_severity::check(this);

  if($time > 0)
    `uvm_fatal("RUNPHSTIME", {"The run phase must start at time 0, current time is ",
			      $sformatf("%0t", $realtime), ". No non-zero delays are allowed before ",
			      "run_test(), and pre-run user defined phases may not consume ",
			      "simulation time before the start of the run phase."})
endtask


// Debug accessor methods to access enable_print_topology
function void uvm_root::set_enable_print_topology  (bit enable);
	enable_print_topology = enable;
	
endfunction

// Debug accessor methods to access enable_print_topology
function bit uvm_root::get_enable_print_topology();
	return enable_print_topology;
endfunction
