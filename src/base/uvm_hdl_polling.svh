//----------------------------------------------------------------------
// Copyright 2023 Intel Corporation
// Copyright 2023-2024 NVIDIA Corporation
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
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------

`ifndef UVM_HDL_POLLING
 `define UVM_HDL_POLLING
typedef class uvm_hdl_polling_cbs;
typedef class uvm_hdl_polling;
typedef class uvm_polling_backdoor;

 `define UVM_POLL_DATA_WIDTH `UVM_REG_DATA_WIDTH

typedef logic [`UVM_POLL_DATA_WIDTH-1:0] uvm_poll_data_logic_t;

typedef  logic unsigned [`UVM_POLL_DATA_WIDTH-1:0]  uvm_poll_data_t ; 


// DPI routines are pulled in using dpi/uvm_polling_dpi.svh. 
// Errors are handled if UVM_NO_DPI is set in dpi/uvm_polling_dpi.svh

//----------------------------------------------------------
// Statistical Information structure used by each polling signal.

typedef enum {UVM_HDL_POLL_NOT_OK, UVM_HDL_POLL_OK} uvm_poll_status_e;
typedef struct {
   int 	       num_path_cbs;
   int 	       num_obj_val_changes;
   string      full_signal_path;
   int 	       signal_size;
   string      object_name;
} uvm_hdl_poll_data_info;



/* This is a static task which hits a static bit 
 * inside the package to notify the Testbench side 
 * that a change has occurred. 
 */
// Not documented. It's an internal method not used outside the class
task static uvm_hdl_polling_probes_run(input bit backdoor_enable=0);
   bit running;
 `ifdef UVM_PLI_POLLING_ENABLE
   //   bit notifier;  // this is the bit that will be tweaked by VPI application.
   automatic string notifier_signal_name = uvm_polling_pkg::notifier_signal_name;
   if(!running) begin: running_block
      if(!backdoor_enable) begin: running_forever_loop
         running = uvm_polling_setup_notifier(notifier_signal_name);
	 if(running == 1'b0) begin
	    `uvm_error("UVM/HDL/POLLING",$sformatf("failed to register notifier signal %s", notifier_signal_name))
	 end
	 else begin
	    `uvm_info("UVM/HDL/POLLING",$sformatf("register notifier signal %s", notifier_signal_name),UVM_DEBUG)
	 end
	 forever @(uvm_polling_pkg::notifier) begin
	    uvm_polling_process_changelist();
	 end
      end: running_forever_loop
   end: running_block
 `endif
endtask


// Used by the C code to signal to the notifier that a signal has changed. This symbol is exported from 
// SV to the C Side. This is used when you use the VPI mechansim. 
// It's not used when you use the backdoor mechanism. 
// Not documented. It is an internal method.
export "DPI-C" function uvm_polling_value_change_notify;

function void uvm_polling_value_change_notify(int sv_key);

   if((sv_key >= 0) && (sv_key < uvm_hdl_polling::uvm_hdl_polling_instance_count)) begin
      uvm_hdl_polling::probes_by_key[sv_key].m_polling_releaseWaiters();
   end
   else 
     `uvm_error("UVM/HDL/POLL",$sformatf("DPI called uvm_hdl_polling::notify on invalid sv_key %0d", sv_key))
endfunction

// Function: uvm_get_poll 
// simple get function that returns the poll instance for a given path
// If no instance exists, it creates one and returns it. 
// @uvm-accellera The details of this API are specific to the Accellera implementation

function uvm_hdl_polling uvm_get_poll(string pathname); 
   if( uvm_hdl_polling::probes_by_name.exists(pathname)) 
     return  uvm_hdl_polling::probes_by_name[pathname]; 
   else 
     begin
	string poll_instance_name;
	uvm_hdl_polling poll_inst;
	uvm_hdl_polling::uvm_hdl_polling_instance_count ++;
	poll_inst = uvm_hdl_polling::type_id::create($sformatf("uvm_hdl_polling_get_poll_%d",uvm_hdl_polling::uvm_hdl_polling_instance_count));
	void'(poll_inst.register_hdl_path(pathname));
	return poll_inst;
     end
endfunction

// Function: set_poll 
// simple set function that returns the poll instance for a given path
// @uvm-accellera The details of this API are specific to the Accellera implementation

function bit uvm_set_poll(uvm_hdl_polling poll_inst, string pathname); 
   if(poll_inst == null) begin
      `uvm_error("UVM/HDL/POLLING","Polling instance is null. Cannot set poll instance");
      return 0;
   end
   
   else 
     return poll_inst.register_hdl_path(pathname);	
   
endfunction

// Class: uvm_hdl_polling
// Base class for HDL Polling
// functionality when using the uvm_hdl_polling class.   An instance of this class should be created for each monitored signal
// This class implements active monitoring of RTL value change for signals. 
//
// See the README.md for information on how to use this mechanism
//
// An instance of this class should be created for each monitored register/field. 
//
// Assumptions. The largest signal that is being polled will fit inside a register of width uvm_poll_data_t. 
// Users can redefine the MAX_WIDTH of the signal
// @uvm-accellera The details of this API are specific to the Accellera implementation

class uvm_hdl_polling extends uvm_object;
   
   // event used to notify of waiters in for the signal 
   protected event changed;

   // Unchanging properties of a probed signal.  These properties are
   // set up once and for all when a probe is created, and do not
   // change thenceforward.
   //
   //       ~signal_name~ is the signal's full string name, exactly as
   //       supplied to the initialize() function.
   string 	   signal_name;

   //
   //       Properties of the signal, determined by VPI inquiries and
   //       copied once and for all to this object in order to reduce
   //       future need for DPI calls

   //       ~handle~ is a pointer to the C struct representing the
   //       probed signal
   protected        chandle handle;

   protected uvm_callback_iter#(uvm_hdl_polling, uvm_hdl_polling_cbs) cbs_iter;

   local bit 		    hdl_poll_cb_registered;

   static int 		    uvm_hdl_polling_instance_count ;

   // All the statistics of the signal are stored here.
   local uvm_hdl_poll_data_info stat_info;


   // The most recent probe created on each signal name.
   // This array is maintained only to simplify checking for duplicates.
   // In the unlikely event that we want a list of all probes on a
   // given named signal, we would have to search exhaustively through
   // the base class's probes_by_key[] queue.
   static uvm_hdl_polling probes_by_name[string];
   static uvm_hdl_polling  probes_by_key[int];

   // This is the key that is assigned to this object.
   // Useful in Debug and also used by the backdoor if you saved it there.
   // All the probes that have been created.  The index into
   // this list is the probe's unique ID key.
   int 			    key;

   protected static function int next_key();
      return uvm_hdl_polling_instance_count;
   endfunction

   // Backdoor handle. You can use this instead of the provided VPI methods.
   // See README.md on how to use the backdoor API
   uvm_polling_backdoor _bkdr;

   // Function: get_backdoor  
   // simple setter and getter functions for the backdoor mechanism
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function uvm_polling_backdoor get_backdoor(); 
	return _bkdr; 
   endfunction

   // Function: set_backdoor
   // This method registers a backdoor class with the uvm_hdl_polling object.
   // Note that you must implement several methods in the backdoor instead of the built-in methods
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function void set_backdoor(uvm_polling_backdoor backdoor ); 
	_bkdr = backdoor; 
   endfunction

   // factory registration.
   `uvm_object_utils(uvm_hdl_polling)

   // Function: set_hdl_poll_cb_registered
   // This method basically sets an internal variable if a callback has been registered 
   // to this polling object.
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function void set_hdl_poll_cb_registered(bit value);
      hdl_poll_cb_registered = value;
   endfunction

   // Function: get_hdl_poll_cb_registered
   // Accessor method to determine if a callback was registered for this object.
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function bit get_hdl_poll_cb_registered;
      return hdl_poll_cb_registered;
   endfunction
   
   // Function: new
   // Constructor. The callback iterator for the callbacks is also created in this constructor. 
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function new(string name="uvm_hdl_polling");
      super.new(name);
      cbs_iter = new(this);
   endfunction

   // Function: create_probe
   // This method creates a probe. You can choose to disable the probe when
   // you create it.
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function bit create_probe(uvm_hdl_polling p, string fullname, bit enable = 1);
      int 		    key;
      chandle 		    handle;
      if(probes_by_name.exists(fullname)) 
	`uvm_error("UVM/HDL/POLLING",$sformatf("Duplicate signal probe on signal \"%s\"", fullname))

      //if (!started) begin
      //  started = 1;
      //end
      key = next_key();
      uvm_hdl_polling_instance_count ++;
      if(_bkdr == null) begin: no_backdoor_usage
	 handle = uvm_polling_create(fullname, key);
	 if (handle == null) begin
            `uvm_fatal("UVM/HDL/POLLING",$sformatf("create_probe for path %s could not create probe", fullname))
	    return 0;
	 end
	 else  begin
            probes_by_name[fullname] = p;
            probes_by_key[key] = p;
            p.signal_name = fullname;
            p.handle = handle;
            p.set_hdl_poll_cb_registered(enable);
	    uvm_polling_set_enable_callback(handle,enable);
	    p.key = key;
	 end
         fork
 `ifdef UVM_PLI_POLLING_ENABLE
            uvm_hdl_polling_probes_run(0);
 `else
	    `uvm_fatal("UVM/HDL/POLLING","Compile with UVM_PLI_POLLING_ENABLE defined if you want to use the built in VPI mechanism. ")
 `endif
         join_none
      end: no_backdoor_usage
      else begin: backdoor_usage
	 if(_bkdr.create_backdoor_probe(key,fullname,enable) == 0) begin
            `uvm_fatal("UVM/HDL/POLLING",$sformatf("create_probe for path %s could not create probe in User defined Backdoor", fullname))
	    return 0;
	 end
         probes_by_name[fullname] = p;
         probes_by_key[key] = p;
         p.signal_name = fullname;
         p.handle = handle;
         p.set_hdl_poll_cb_registered(enable);
	 fork
	    uvm_hdl_polling_monitor_backdoor();
	 join_none
      end: backdoor_usage
      return 1;
   endfunction

   // Function: register_hdl_path
   // This function registers a VPI value change callback for each RTL path
   // Returns immediately if API callback was already registered 
   // Returns 1 if registration succeeded, 0 otherwise
   //
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function bit register_hdl_path(string hdl_path_name);
      register_hdl_path = 0;
      if (create_probe(this,hdl_path_name)!= 0) // We were able to successfully create a hookup to an RTL Signal
        register_hdl_path = 1; 
      // If we could register the backdoor or the vpi path, register_hdl_path =1. 
      // Update the local statistics.
      if(register_hdl_path == 1) begin : register_hdl_path_chk
         stat_info.num_path_cbs++;
   	 stat_info.full_signal_path = hdl_path_name;
 	 stat_info.object_name = get_full_name();
 	 stat_info.signal_size = (_bkdr==null)? uvm_hdl_signal_size(hdl_path_name):_bkdr.get_signal_size();
         set_hdl_poll_cb_registered(1); // mark that A callback was registered for this object to avoid calling it again                    
	 `uvm_info("UVM/HDL/POLL",$sformatf("Successfully registered a callback in object %s for signal %s.",get_full_name(),hdl_path_name),UVM_DEBUG)
         register_hdl_path = 1; 

      end: register_hdl_path_chk
      else  begin
	 `uvm_fatal("UVM/HDL/POLL",$sformatf("Could not register a path in object %s for signal %s. Check your PLI/Acc capabilities/path or your backdoor methods if you are using the backdoor",get_full_name(),hdl_path_name))
	 register_hdl_path = 0;
      end

   endfunction

   // @uvm-accellera The details of this API are specific to the Accellera implementation
   // If action callbacks are registered, it calls action_cb.do_on_path_change()  
   // NOT Documented. this is an internal method.
   function void hdl_polling_execute_callbacks ();
      uvm_poll_data_logic_t val;
      int    size;
      bit    ret; // throwaway
      if(_bkdr == null ) begin
	 ret= uvm_hdl_read(stat_info.full_signal_path,val);
	 size = uvm_hdl_signal_size(stat_info.full_signal_path);
      end
      else begin
	 uvm_poll_status_e status;
	 size = _bkdr.get_signal_size();
	 _bkdr.hdl_read(status,val);
      end

      for (uvm_hdl_polling_cbs cb = cbs_iter.first(); cb != null; cb = cbs_iter.next()) begin
	 cb.do_on_path_change(stat_info.full_signal_path,  val,size);
      end
   endfunction

   // Function: wait_for_hdl_change
   // if you're using the default VPI implementation
   // Register a value change VPI callback if not already registered 
   // Wait for a value change and then Return the new value  
   // if you're using the backdoor, it will return when the backdoor changes.
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual task wait_for_hdl_change(ref uvm_poll_status_e status, ref uvm_poll_data_t val);
      
      if (!get_hdl_poll_cb_registered()) begin
	 return; 
      end
      if(_bkdr == null) begin // we do it the normal way
	 @changed;
	 stat_info.num_obj_val_changes++;
	 if(uvm_hdl_read(stat_info.full_signal_path,val))  begin
	    status =  UVM_HDL_POLL_OK;
	 end
	 else 
	   status =  UVM_HDL_POLL_NOT_OK;
      end
      else begin
	 _bkdr.poll_bkdr_wait_for_hdl_change(status,val);

      end
   endtask

   // Function: polling_wait_for_value
   // Perform register/field polling. Continue waiting for a value change until the expected value ~exp_val~ is identified
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual task polling_wait_for_value(ref uvm_poll_status_e status, input uvm_poll_data_t exp_val );
      uvm_poll_data_t  val;     
      if (!get_hdl_poll_cb_registered()) begin
	 status = UVM_HDL_POLL_NOT_OK;
	 return; 
      end
      else 
	status = UVM_HDL_POLL_OK;

      // first check the current value
      if(_bkdr == null) 
	void'(uvm_hdl_read(stat_info.full_signal_path,val));
      else 
	_bkdr.hdl_read(status,val);

      while (val != exp_val) begin
	 if(_bkdr == null)  // we have a default backdoor. Use the VPI.
	   wait_for_hdl_change(status,val);
	 else  begin
	    _bkdr.poll_bkdr_wait_for_hdl_change(status,val);
	 end
	 
      end
   endtask

   // Function: set_hdl_path
   // This method returns a summary statistic for the polling classes. 

   function string convert2string();
      return $sformatf("Statistics info:\n  Total Path polling instances = %0d\n   Total path vpi callback registered = %0d\n  Total path value changes = %0d\n  ",get_number_callbacks(),get_value_change_count(), 0)       ;
   endfunction

   // Function: get_number_callbacks
   // This method returns the number of callback paths registered. Should always be 1.

   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function int get_number_callbacks();
      return stat_info.num_path_cbs;
   endfunction
   
   // Function: get_value_change_count
   // This method tells you how many times the value of the signal changed.

   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function int get_value_change_count();
      return stat_info.num_obj_val_changes;
   endfunction

   `uvm_register_cb(uvm_hdl_polling, uvm_hdl_polling_cbs)

   // This is an internal implementation method unblocking wiaters on the poll instance.
   // @uvm-accellera The details of this API are specific to the Accellera implementation
   virtual function void m_polling_releaseWaiters();
      ->changed;
      hdl_polling_execute_callbacks();
   endfunction

   // This is an internal implementation method unblocking wiaters on the poll instance.
   // @uvm-accellera The details of this API are specific to the Accellera implementation
   virtual task uvm_polling_waitForChange();
      @changed;
   endtask

   // Not documented. used under the hood.
   // This task creates a forever loop.
   // It's used in lieu of the backdoor and we need a seperate task 
   // because we could have multiple backdoors, each monitoring seperately and
   // It wont interfere with the VPI one which is default.
   virtual task uvm_hdl_polling_monitor_backdoor();
      uvm_poll_status_e status;
      uvm_poll_data_t val;
      forever begin
	 _bkdr.poll_bkdr_wait_for_hdl_change(status,val);
	 m_polling_releaseWaiters();
      end
   endtask

endclass : uvm_hdl_polling





typedef uvm_callbacks#(uvm_hdl_polling, uvm_hdl_polling_cbs) uvm_hdl_polling_cb;

// Class: uvm_hdl_polling_cbs
//
// A base class for defining polling action callbacks to execute upon HDL path RTL signal value change
//
// @uvm-accellera The details of this API are specific to the Accellera implementation

virtual class uvm_hdl_polling_cbs extends uvm_callback;

   // Function: new
   // Class Constructor
   function new(string name="");
      super.new(name);
   endfunction

   // Function: do_on_hdl_change
   //
   // To be implemented by extended classes to perform an action upon a value change of a register or a field

   // @uvm-accellera The details of this API are specific to the Accellera implementation
   virtual function void do_on_hdl_change(string full_path, int signal_size, uvm_poll_data_t val); endfunction

   // Function: do_on_path_change
   //
   // To be implemented by extended classes to perform an action upon a value change of a path
   // ~hdl_path~ is the path that its value has changed
   // ~val~ is the actual value of the path after it was changed
   // ~size~ is the size in bits of the path's value

   // @uvm-accellera The details of this API are specific to the Accellera implementation
   virtual function void do_on_path_change(string hdl_path, uvm_poll_data_t val, int size); endfunction

endclass : uvm_hdl_polling_cbs

// Class: uvm_polling_backdoor
// Backdoor base class for HDL Polling
// Extend this class and implement the methods in it to obtain backdoor 
// functionality when using the uvm_hdl_polling class.   An instance of this class should be created for each monitored signal

// @uvm-accellera The details of this API are specific to the Accellera implementation

virtual class uvm_polling_backdoor extends uvm_object;

   string hdl_backdoor_path;
   int 	  key;

   `uvm_object_abstract_utils(uvm_polling_backdoor)


   // Function: new
   //
   // Class constructor

   function new(string name="");
      super.new(name);
   endfunction

   
   // Function: create_backdoor_probe
   //
   // This function registers a backdoor probe on the signal.  You must return a 1 in case you're able to
   // access the signal. One approach is to obtain a virtual interface handle and return 1 in case 
   // you are able to get the handle.  You may return 1 if you wish to access the signal by any other method like a direct 
   // cross module reference.
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual function bit create_backdoor_probe(int key, string fullname, bit enable = 1);
      `uvm_fatal("UVM/HDL/POLLING/Backdoor", "uvm_polling_backdoor::create_backdoor_probe() method has not been overloaded")
      return 0;
   endfunction
   
   

   // Task: poll_bkdr_wait_for_hdl_change
   //
   // This task is a hdl monitoring task that returns any time the monitored hdl signal changes its value.
   // This task will read the HDL value and return its value. If it cannot return the value,
   // status must be set to UVM_HDL_POLL_NOT_OK.  If the backdoor can read the value, it must be set to UVM_HDL_POLL_OK
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual task poll_bkdr_wait_for_hdl_change(ref uvm_poll_status_e status, ref uvm_poll_data_t val);
      `uvm_fatal("UVM/HDL/POLLING/Backdoor", "uvm_polling_backdoor::poll_bkdr_wait_for_hdl_change() method has not been overloaded")
   endtask

   
   // Function: hdl_read
   //
   // This function will read the HDL value and return its value. If it cannot return the value
   // The status must be set to UVM_HDL_POLL_NOT_OK.  if the backdoor can read the value, it must be set to UVM_HDL_POLL_OK
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual function void hdl_read(ref uvm_poll_status_e status, ref uvm_poll_data_t val);
      status = UVM_HDL_POLL_NOT_OK;
      `uvm_fatal("UVM/HDL/POLLING/Backdoor", "uvm_polling_backdoor::hdl_read_func() method has not been overloaded")
   endfunction

   // Function: get_signal_size
   // You must implement this function in the backdoor class to give you back the size of the signal
   // @uvm-accellera The details of this API are specific to the Accellera implementation

   virtual function int get_signal_size();
      `uvm_fatal("UVM/HDL/POLLING/Backdoor", "uvm_polling_backdoor::get_signal_size() method has not been overloaded")
      return 0;
   endfunction

   // Function: set_hdl_path
   //
   // You may use this function to cache the full path to the signal. It may be useful in debug
   // but is not functionally necessary.

   // @uvm-accellera The details of this API are specific to the Accellera implementation

   function void set_hdl_path(string path);
      hdl_backdoor_path = path;
   endfunction 

endclass


`endif
