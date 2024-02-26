# Accellera Universal Verification Methodology (UVM, IEEE 1800.2-2020)

# Scope

This kit provides a Systemverilog library matching the requirements of [IEEE 1800.2-2020](https://ieeexplore.ieee.org/document/9195920). 
See details in the Library Release Description below.

**Note:** The implementation provided deviates from the 1800.2-2020 standard, see [DEVIATIONS.md](./DEVIATIONS.md) for additional details.

# Kit version

1800.2 2020.3.0

# License

The UVM kit is licensed under the Apache-2.0 license.  The full text of
the Apache license is provided in this kit in the file [LICENSE.txt](./LICENSE.txt).

# Copyright

All copyright owners for this kit are listed in [NOTICE.txt](./NOTICE.txt).

All Rights Reserved Worldwide

# Contacts and Support

If you have questions about this implementation and/or its application to verification environments, please visit the
[Accellera UVM (IEEE 1800.2) - Methodology and BCL Forum](https://forums.accellera.org/forum/43-uvm-ieee-18002-methodology-and-bcl-forum/) or 
contact the Accellera UVM Working Group (uvm-wg@lists.accellera.org).

# Bug Fixes

The following errata were fixed in 2020.3.0.

| Mantis Number | Description |
| ------------- | ----------- |
| [Mantis_7944](https://accellera.mantishub.io/view.php?id=7944) | `uvm_compat_packer` works wrong for `unpack_object` method |
| [Mantis_7915](https://accellera.mantishub.io/view.php?id=7915) | Compatibility: `uvm_resource#(T)::get_by_name` and `get_by_type` missing in 2020-2.0 |
| [Mantis_8224](https://accellera.mantishub.io/view.php?id=8224) | TLM GP Buffer overflow during unpack operation |
| [Mantis_7879](https://accellera.mantishub.io/view.php?id=7879) | All classes should derive from `uvm_void` |
| [Mantis_7932](https://accellera.mantishub.io/view.php?id=7932) | `UVM_ENABLE_DEPRECATED` in 1800.2-2020 2.0 library |
| [Mantis_7916](https://accellera.mantishub.io/view.php?id=7916) | Compat: UVM Messaging macros introduce unnecessary dependency on `uvm_report_object` |
| [Mantis_7696](https://accellera.mantishub.io/view.php?id=7696) | Poll API using Simulator callback |
| [Mantis_7933](https://accellera.mantishub.io/view.php?id=7933) | `uvm_tlm_fifo::flush` uses bit instead of int for `mailbox::try_get` return value |
| [Mantis_7919](https://accellera.mantishub.io/view.php?id=7919) | LINT: one-line if/else statements should use `begin...end` |
| [Mantis_7935](https://accellera.mantishub.io/view.php?id=7935) | Add a process guard class |
| [Mantis_6745](https://accellera.mantishub.io/view.php?id=6475) | Jumping to extract phase results in extract executing twice |
| [Mantis_5315](https://accellera.mantishub.io/view.php?id=5315) | No arbitration to protect the `rw_info` of front door sequence from being accessed by multiple threads simultaneously |

# Installing the kit

Installation of UVM requires first unpacking the kit in a convenient
location.

```
    % mkdir path/to/convenient/location
    % cd path/to/convenient/location
    % gunzip -c path/to/UVM/distribution/tar.gz | tar xvf -
```

Follow the installation instructions provided by your tool vendor for
using this UVM installation and tool version dependencies.

# Prerequisites

- IEEE1800 compliant SV simulator. Please check with your tool vendor for exact tool version requirements.
- C compiler to compile the DPI code (if not otherwise provided by tool vendor)


# Library Release description

Each class and method in the standard is annotated in the implementation, allowing tools to identify the corresponding section in the standard. 

Example:
```
// @uvm-ieee 1800.2-2020 auto 16.5.3.2
extern virtual function void get_packed_bits (ref bit unsigned stream[]);
```

In addition to the APIs described in the standard, the Library includes the following categories of extra API:

1. APIs that are being considered for contribution to the IEEE by Accellera.  They are identified by the following annotation:
```
// @uvm-contrib Potential Contribution to 1800.2
```
2. APIs that are not being considered for contribution to the IEEE.  Generally these are provided for debug purposes.  They are identified by the following annotation:
```
// @uvm-accellera Accellera Implementation-specific API
```
3. API that are provided purely for backward-compatibility with older UVM versions.  Documentation on such API will be found only in the older version where they were supported.  They are identified by the following annotation:
```
// @uvm-compat
```
4. APIs used within the library that are not intended to be directly used outside of the implementation.

**Note:** While the Accellera UVM Working Group supports the APIs described in (1), (2) and (3) above, these APIs are technically not a part of the 1800.2 standard.  As such, any code which leverages these APIs may not be portable to alternative 1800.2 implementations.

# Optional Regular Expression Optimization

This version of the UVM reference implementation includes an optional regular expression optimization.  The optimization caches the result of regex operations, potentially providing a significant performance increase in environments gated by large numbers accesses to the resource database, usually caused by very large component or register hierarchies. 

Unfortunately, the optimization can cause issues in environments using save/restore mechanisms, as the cached objects in the DPI calls may not be saved properly.  The optimization is therefore disabled by default and must be enabled explicitly by defining `UVM_ENABLE_RE_MATCH_CACHE` before compiling UVM.

# Field Macro / apply\_config\_settings Optimization

This version of the UVM reference implementation includes an optimization for `apply_config_settings` which changes the default implementation to only search the Config DB for field_names that are declared in `` `uvm_field_* `` macros.

This is technically a violation of the 1800.2 LRM, however Accellera is planning to contribute the changed behavior to the next revision of the 1800.2 standard.  Should the 1800.2 behavior be desired, the library may be compiled with `+define+UVM_COMPONENT_CONFIG_MODE_DEFAULT=CONFIG_STRICT`.  More information is available in the documentation, under `uvm_component::apply_config_settings_mode`.

# Optional Register Block search Optimization

This version of UVM reference implementaion includes an optional register block search by name optimization. The optimization if enabled caches the results of uvm_reg_block::find_blocks() function to avoid repeated searching of entire register model in case the same name is searched for multiple times. The cache is flushed out if the register model is unlocked to account for any naming or structural change in the register model.

The optimization will significantly benefit tests which repeatedly use uvm_reg_block::find_blocks() and/or uvm_reg_block::find_block() with same argument but might unfortunatly create a minor memory overhead of the cache otherwise. Therefore the optimization is disabled by default and must be enabled explicitly on per testrun basis by setting `+UVM_ENABLE_REG_LOOKUP_CACHE` runtime test plusarg.

# Register lookup by name Optimization

This version of UVM reference implementaion includes register lookup by name optimizations. The optimization caches the full name and its corresponding object handle for all uvm_reg_field, uvm_reg and uvm_reg_block objects in the register model to enable significant faster searching by name. The optimization avoid iterative search of entire register model each time a register object is searched by name via functions like get_reg_by_name(), get_field_by_name() and get_block_by_name().

In addition, the library now provides new functions to seach by full name of the register objects for and even faster O(1) rather than O(n) time complexity search. Users can use uvm_reg_field::get_field_by_full_name(), uvm_reg::get_reg_by_full_name() and uvm_reg_block::get_block_by_full_name() static functions to get the handle to a field, register or block respectively.

# Sequencer "disable recording" macro
The 1800.2 standard has deprecated the use of a `UVM_DISABLE_RECORDING` macro in `uvm_sequencer_base`.  This library disables automatic item recording in `uvm_sequencer_base` when `UVM_DISABLE_AUTO_ITEM_RECORDING` (a more explicit macro name) is defined or, for backward compatibility, when `UVM_DISABLE_RECORDING` is defined.

# Migration instructions

Unlike 1.2 or prior 1800.2 releases, no code has been deprecated in this version.  No special steps should be required to migrate from an earlier 1800.2 version.

Additionally, all features from prior versions that _can_ be supported are supported in this version.  Many deprecated features that were removed in previous versions have been reintroduced to ease the burden of migrating to the latest version.

**NOTE:** Such features are still considered "deprecated", and are not recommended for use.  It is highly recommended that the user update their code to LRM compliance after migrating to the latest library.

## Migrating from 1.1c (or earlier)

To migrate from a library version of 1.1c or earlier, we recommend migrating to version 1.1d first.  The sections below are valid for users migrating from either 1.1d or 1.2.

## Potential changes that apply exclusively to 1.1d

The following changes may apply to users migrating from library version 1.1d, depending on what features of the library are in use.

### `uvm_default_recorder` global field has been removed

In 1.1d, uvm\_object\_globals.svh has:
```
// Variable: uvm_default_recorder
//
// The default recording policy. Used when calls to <uvm_object::record>
// do not specify a recorder policy.

uvm_recorder uvm_default_recorder = new();
```
The recorder implementation was rearchitected in 1.2, and it no longer makes sense to have a global default.  If code relies on the specific implementation of `uvm_recorder` in 1.1d, then it will have to be changed to use the new recorder scheme. Please see `uvm_text_recorder` as an example of the user API.

## Potential changes that apply to both 1.1d and 1.2

The following changes may apply to users migrating from library versions 1.1d or 1.2, depending on what features of the library are in use.

### `uvm_tree_printer::newline` field

In 1.1d and 1.2, `uvm_tree_printer` used to have a field:

```
   string newline = "\n";
```

This field was not documented but if a user implemented `format_row()` by copying and modifying the library code, they could have working code using that field.  In that case, the user should explicitly add this field to their extension of `uvm_tree_printer`.

### `uvm_driver` now gives a warning if `seq_item_port` is not connected

The `uvm_driver` class is intended to be used as one half of a pair of classes, the other half being a `uvm_sequencer` with a matching `seq_item_export`.  To make sure `uvm_driver` is correctly connected, 1800.2 releases have added a check that `seq_item_port` is connected.

If the user extends `uvm_driver` without intending to use the `seq_item_port`, they may wish to disable this check via:

```
  set_report_severity_id_action( UVM_WARNING, "DRVCONNECT", UVM_NO_ACTION );
```

This method may be called called any time prior to the `end_of_elaboration` phase.

### Changes to the undocumented `rtab` and `ttab` members of `uvm_resource_pool`.

The types for the undocumented `rtab` and `ttab` members of the `uvm_resource_pool` have been changed from `uvm_queue#(uvm_resource_base)` to `uvm_shared#(uvm_resource_base[$])`.  This change was part of a larger effort to improve the overall performance of the UVM resource database and associated logic.

If user code was accessing these undocumented variables, then setting the compile-time define `UVM_DISABLE_RESOURCE_POOL_SHARED_QUEUE` will revert to the previous implementation.


### field macros will support old semantics with warning.

Before 1800.2 libraries, the field macros would behave as if `UVM_ALL_ON` had been bitwise-ORed with the FLAG that the user passes.  For example, if the user specifies

```
   `uvm_field_object(cfg,UVM_REFERENCE)
```

the older libraries will include the cfg object in printing, comparing, etc.  The LRM, however, specifies that only the features explicitly enabled are supported.  If the user wants the previously supported semantics, then the define `UVM_LEGACY_FIELD_SEMANTICS` should be set.  If the library sees a field macro call that does not explictly enable any feature, then a warning with id "UVM/FIELDS/NO_FLAG" will be issued.  The text of the warning says that it will be treated as an implicit `UVM_ALL_ON` if the define is set or that it will be treated as a NO-OP if the define is not set.  The ideal solution is to modify the source code to provide an explicit `UVM_ALL_ON`, e.g.

```
   `uvm_field_object(cfg,UVM_ALL_ON|UVM_REFERENCE)
```

Note that this explicit form is compatible with all releases of the UVM library (1.1d, 1.2, and 1800.2).

Alternatively, assuming that the LRM-defined behavior is acceptable, the warning may be disabled with

```
  set_report_severity_id_action( UVM_WARNING, "UVM/FIELDS/NO_FLAG", UVM_NO_ACTION );
```

### Sequence getting response after termination now gives a warning

If a response is returned for a sequence after that sequence has terminated, the libraries before 1800.2 would print an info message

```
   Dropping response for sequence %0d, sequence not found.  Probable cause: sequence exited or has been killed
```

In the 1800.2 libraries, this has been changed to a warning to make users more aware that the response is being ignored.  Users may downgrade this warning if they do not want to be made aware of this situation.

### `uvm_port_base::get_provided_to()` argument has changed type

In libraries before 1800.2, `uvm_port_base` had an API `get_provided_to()` whose argument was `ref uvm_port_list list`.  In 1800.2, that argument was changed to `ref uvm_port_base #IF) list[string])`.

Code that was calling `get_provided_to()` now must call `get_comp()`, which returns a value of type `uvm_port_component_base`, and then call `get_provided_to` from that return instead.

For example:
```
//old
export.get_provided_to(list);
```
```
//new
begin
  uvm_port_component_base port_comp;
  port_comp = export.get_comp();
  port_comp.get_provided_to(list);
end
```
### `uvm_packer` stream contents have changed

If data is packed to a stream and then that stream is unpacked, all library versions produce identical unpack output, but the contents of the stream are different between 1800.2 versions and pre-1800.2 versions.  If the exact stream contents must be maintained, then the recommendation is to use the uvm_compat_packer.  Please refer to the compatibility package [README](./compat/README.md) for details.

### `uvm_sequence_base` and `uvm_sequence#()` are now abstract classes

Prior to 1800.2 versions, user code could create an instance of uvm_sequence_base or uvm_sequence#(), but because these are abstract in 1800.2, they may no longer be instanced.  The recommendation is to use the uvm_compat_sequence_proxy_sequence#().  Please refer to the compatibility package [README](./compat/README.md) for details.

## Polling mechansim.
The Polling mechanism is a new feature under development. Hence the API may change. It is experimental and feedback is welcome. 
To use this feature, add the define UVM_ENABLE_EXPERIMENTAL_POLLING_API to include the polling API in your compilation. This is in addition to other defines described below which select options within the polling API.

The  Polling API is a mechansim to observe signal changes in the DUT by using a signal name instead of a cross module reference. 
The class is used for a number of reasons
1. Waiting on value change of a register / field 
2. Polling a signal for a specific value  <
3. Performing a user-defined action upon each value change of a field in a register 
4. Monitoring volatile fields (changed by HW) and performing prediction and transaction logging  

Note that this class is implemented with VPI functions in a corresponding .c file which must be enabled via some additional flags. 
You can avoid using VPI by extending the provided `uvm_polling_backdoor` class and registering it.


Signal changes can be observed by one of 2 mechanisms:
- The `wait_for_change` task blocks until the signal changes.
- The `uvm_hdl_polling_cbs::do_on_path_change` callback is automatically called on signal changes.

You can either enable a uvm_callback once the signal changes or use the builtin task to wait for a signal change.

Use model:
To use the polling API, you must first decide if you wish to use the built-in VPI polling mechansim or a backdoor polling mechansim.

The VPI mechanism uses VPI and DPI calls to monitor the signal, and you need to turn on the appropriate 
switches for your simulator to enable this mechansim.  You will also need to add an additional define to your simulator to use this mode.

Using a backdoor mechanism does not require you to use VPI and you can mix and match both VPI and backdoor mechansims, but be aware that having even a single VPI polling mechansim will require additional
switches to your simulator.  

The VPI polling mechanism is easier to use but the backdoor mechanism is more performant.  

Steps to use the polling mechansim:

Step 1:
	Determine if you are going to use the inbuilt VPI polling mechansim or tthe backdoor mechanism.
	if you choose the VPI mechansim, add the define UVM_POLLING_API_SV to your compler switches.

Step 2:
	Declare Instances of the `uvm_hdl_polling` class in your class. 
```
	uvm_hdl_polling  poll1;
        uvm_hdl_polling  poll2;
```
Step 3:
	Build these instances in the build_phase:
```
	poll1 = uvm_hdl_polling::type_id::create("poll1");
	poll2 = uvm_hdl_polling::type_id::create("poll2");`
```

Step 4:
	Register the signal which you want to monitor.  The arguments to the register_hdl_path method is a string with the fully qualified path to the signal.
```
	poll1.register_hdl_path("top.child1.sub1.signal3");
    	poll2.register_hdl_path("top.child2.sub2.signal3");`
```
Step 5:
	Monitor the signal change using either a task or a callback. 
	To wait for a signal change within a forked process:
```
		uvm_poll_status_e status;
      		 uvm_poll_data_t val;
		 ...
                 poll2.wait_for_change(status,val);`
```

To use a callback mechanism, extend the callback class and implement your handler there:

```
	class my_signal_callback extends uvm_hdl_polling_cbs;

	  virtual function void do_on_path_change(string hdl_path, uvm_poll_data_t val, int size); 
        ...
	endfunction
	...
	// Usual constructor and other macros
	...
	endclass`
```
The callback registration is as usual:  you can add this to all the signals or a specific instance.
Example:

```
	` uvm_callbacks #(uvm_hdl_polling,my_signal_callback)::add(poll1,my_signal_callback_inst1);`
```

User defined Backdoor mechansim to impove performance.

	The default VPI implementation of the polling API uses 
	a VPI mechansim to register a value change callback and hence access to the signals in the simulator. It also uses
	a VPI mechanism to signal a Notifier bit in the uvm_hdl_polling_pkg. 
	
	Consequently, you will need to turn on VPI read access to the specific design signals in your design and write access to the bit in the uvm_polling_pkg. 
	Please consult your simulator vendor documentation for specifics of how to do so.

	if you are sensitive to performance considerations, consider using the backdoor api. While this is more work, you will not suffer a loss of performance.

	Step 1: Create a backdoor class.
	Example:
	
```
		class signal2_backdoor extends uvm_polling_backdoor;
		   `uvm_object_utils(signal2_backdoor)
		   function new(string name="signal2_backdoor"); 
		      super.new(name);
		   endfunction 
		   // actions to be taken when polling bit changes
		   virtual task poll_bkdr_wait_for_hdl_change(ref uvm_poll_status_e status, ref uvm_poll_data_t val);
			// This is a task which will return when the signal changes. The mechansim by which it obtains a handle
			// to the signal is user-defined. 
			// is up tp
		   endtask
		   virtual function hdl_read(ref uvm_poll_status_e status, ref uvm_poll_data_t val);
			// you must populate the value of the return value with the value read from the signal
			// if you cannot read the value, you must return UVM_POLL_NOT_OK otherwise, status must be set to UVM_POLL_OK. 
		   endfunction 
		   virtual function int get_signal_size();
			// Return the actual value of the signal as an integer.
		   endfunction
		   virtual function bit create_backdoor_probe(int key, string fullname, bit enable = 1);
			// You must ensure you can access the signal that is dicated by **fullname** in this method to be
			// sure that you can detect value changes. 
			// For example:
			// This may mean that in case you use an interface, you get a virtual interface handle or 
			// register a simulator specific Cross reference.	
		      return 1; 
		   endfunction
		endclass 
		

```
	// Signal2 is similar.		
		      
	Step 2: Add backdoor to the test	
	Example:
	
```
	virtual task main_phase(uvm_phase phase);	
  	  signal1_backdoor signal1;
	  signal2_backdoor signal2;
      

	  signal1 = signal1_backdoor::type_id::create("signal1");
          signal2 = signal2_backdoor::type_id::create("signal2");
	use 
	  poll1.set_backdoor(signal1);
	  poll2.set_backdoor(signal2);
	or 
      	$cast(poll1._bkdr, signal1);
      	$cast(poll2._bkdr, signal2);
	

```
## Simple Polling task interfaces
You could choose to use the simple Task interface if you are just monitoring a few signals in your testbench.
The `uvm_get_poll("Pathname")` method can create a poll instance for you. Consult the documentation for the API
Example:

```
initial begin
      uvm_hdl_polling my_poll;
      my_poll = uvm_get_poll("path to signal"); 
      begin
         uvm_poll_status_e status;
         uvm_poll_data_t val;
         forever begin
            my_poll.uvm_wait_for_hdl_change(status,val);
            `uvm_info(...)
         end

      end
   end

```

You may also extend the uvm_hdl_polling class and embed your own handler and use the `uvm_set_poll(instance_name,"unique_name")` method. Consult the documentation for the API.
This unique_name can actually be the signal name if you wish or any other string. It is used as a key index inside the implementation and allows the mechansim to work.

```
	class my_signal_watcher extends uvm_hdl_polling;
	... // implement backdoors or other handlers or attach callbacks if you wish
	endclass


	initial begin
 		my_signal_watcher my_sigwa;
      	my_sigwa = my_signal_watcher::type_id::create("my_sigwa");
      	...
      	void'(uvm_set_poll(my_sigwa,"simple_name")); // Not showing how my_sigwa registers what signals it can see etc
      	...
      	run_test();
	end


```	

Save and Restore:
	Special considerations may be required when using the PLI-Based backend with 'Save and Restore' semantics. Please consult your simulation vendor for more information.

# Git details

The following information may be used for tracking the version of this file.  Please see
[DEVELOPMENT.md](./DEVELOPMENT.md) for more details.

```
$File$
$Rev$
$Hash$
```
