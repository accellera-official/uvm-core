# Accellera Universal Verification Methodology (UVM, IEEE 1800.2-2020)

# Scope

This kit provides a Systemverilog library matching the requirements of [IEEE 1800.2-2020](https://ieeexplore.ieee.org/document/9195920). 
See details in the Library Release Description below.

**Note:** The implementation provided deviates from the 1800.2-2020 standard, see [DEVIATIONS.md](./DEVIATIONS.md) for additional details.

# Kit version

1800.2-2020 2.0

This kit was generated based upon the following git commit state: c3ac75ad e2de8c73.

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

The following errata were fixed in 2.0.

| Mantis Number | Description |
| ------------- | ----------- |
| [Mantis 4675](https://accellera.mantishub.io/view.php?id=4675) | `uvm_reg_field::is_indv_accessible` looks bogus. | 
| [Mantis 5449](https://accellera.mantishub.io/view.php?id=5449) | The `uvm_reg_predictor` ignored status of bus_op. |
| [Mantis 5648](https://accellera.mantishub.io/view.php?id=5648) | `define_domain` always adds `uvm_sched`, even when it shouldn't | 
| [Mantis 5707](https://accellera.mantishub.io/view.php?id=5707) | `find_override_by_type` causes false errors when called by the user |
| [Mantis 6273](https://accellera.mantishub.io/view.php?id=6273) | `uvm_reg::mirror` task has not released lock when map is NULL |
| [Mantis 6556](https://accellera.mantishub.io/view.php?id=6556) | `uvm_config_db::set` ignores regex in `inst_name` when context is supplied |
| [Mantis 6966](https://accellera.mantishub.io/view.php?id=6966) | Access synchronization issue in `uvm_reg` class | 
| [Mantis 7011](https://accellera.mantishub.io/view.php?id=7011) | `uvm_*_context` macros can result in method chaining |
| [Mantis 7212](https://accellera.mantishub.io/view.php?id=7212) | Null Object Access while frontdoor reading/writing fields with no adapter |
| [Mantis 7240](https://accellera.mantishub.io/view.php?id=7240) | `uvm_reg_field::write()` does not call `set()` method to update the desired value of the field |
| [Mantis 7276](https://accellera.mantishub.io/view.php?id=7276) | Killing a sequence can cause a hang (`get`/`get_next_item`/`peek`) or `TRY_NEXT_BLOCKED` error (`try_next_item`) |
| [Mantis 7279](https://accellera.mantishub.io/view.php?id=7279) | `uvm_recorder` loops indefinitely when recorder encounters an object it has already recorded |
| [Mantis 7280](https://accellera.mantishub.io/view.php?id=7280) | Zero-time race in sequence start status check | 
| [Mantis 7472](https://accellera.mantishub.io/view.php?id=7472) | lock not released in `uvm_reg_field::do_write()`/`do_read()` if `Xcheck_accessX()` call fails. |
| [Mantis 7542](https://accellera.mantishub.io/view.php?id=7542) | Improve `uvm_field_op` flag compatiblity solution |
| [Mantis 7704](https://accellera.mantishub.io/view.php?id=7704) | `uvm_field_object` macro fails when variable name is `state` |
| [Mantis 7715](https://accellera.mantishub.io/view.php?id=7715) | UVM Report Macros don't check action |



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

