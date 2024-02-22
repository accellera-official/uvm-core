# Accellera Universal Verification Methodology Compatiblity Package 

# Purpose

The uvm_compat_pkg is one part of the solution for how user code can be compatible with different versions of the UVM library that have somewhat different API.  If the modified API can co-exist with the original API, then the uvm_pkg can supply both of them, making user code that uses the original API fully compatible with a later version of the library.  However, when the modification is incompatible with the original, a different solution is required.  The uvm_compat_pkg provides the original version of API in a separate package, which allows it to co-exist with the modified version in uvm_pkg.   To use the API in the uvm_compat_pkg, the user code does need to be slightly modified, but once that modification is done, the user code is compatible with the old or new versions.  The uvm_compat_pkg may be used in conjunction with any version of the uvm_pkg as it uses version defines to decide whether to show the uvm_pkg API as-is or to provide a layer on top of new API.  

Note that the uvm_compat_pkg provides compatibility by enabling code based on different library versions to use the older API, not the newer API.  For example, uvm_compat_pkg may enable use of a UVM1.2 API in the context of the UVM-1800.2-2020 library, but it will not enable use of a (updated) UVM-1800.2-2020 API in the context of the UVM1.2 library.

# Kit version

This version of the compatibility package was distributed with %UVM:library% %UVM:version%.

# License

The UVM kit is licensed under the Apache-2.0 license.  The full text of
the Apache license is provided in this kit in the file [LICENSE.txt](../LICENSE.txt).

# Copyright

All copyright owners for this kit are listed in [NOTICE.txt](../NOTICE.txt).

All Rights Reserved Worldwide

# Contacts and Support

If you have questions about this implementation and/or its application to verification environments, please visit the
[Accellera UVM (IEEE 1800.2) - Methodology and BCL Forum](https://forums.accellera.org/forum/43-uvm-ieee-18002-methodology-and-bcl-forum/) or 
contact the Accellera UVM Working Group (uvm-wg@lists.accellera.org).

# Compiling

To use the `uvm_compat_pkg` in simulation, it should be presented to the compiler the same way that `uvm_pkg` is.  For example, if your current compile command has
```
   +incdir+uvm_path/src
   uvm_path/src/uvm_pkg.sv
```
then these lines should be added
```
    +incdir+uvm_compat_path/compat
    uvm_compat_path/compat/uvm_compat_pkg.sv
```
(Note that `uvm_compat_path` will be identical to `uvm_path` if you are using them from the same release, but it works fine to have it be different from `uvm_path` if you want to use the `uvm_compat_pkg` with a `uvm_pkg` from an earlier release.)

# Packer Usage

The `uvm_packer` was re-worked after UVM1.2.  If data is packed and the resulting bit- or byte-stream is subsequently unpacked, the unpack output will match the original data in both old and new versions, however the stream itself can be different between versions.  If the value of the stream is important, the way to get user code compatible with multiple versions is to move to the `uvm_compat_packer`.  As mentioned above, based on version defines, the `uvm_compat_packer` is either a typedef for the library version of `uvm_packer` or a new class that inherits from the library version and modifies functions as required.

How the user code is modified to use `uvm_compat_packer` depends on how the user code currently refers to `uvm_packer`.  If, for example, the user code uses the default packer, then adding these lines to execute before the first usage of the packer will work:
```
   begin
      uvm_compat_pkg::uvm_compat_packer compat_packer = new();
      uvm_packer::set_default(compat_packer);
   end
```

If the user code creates and uses an extension of `uvm_packer`, it should use an extension of uvm_compat_packer instead.  For example, replace
```
   class my_packer extends uvm_packer; 
```
with
```
   class my_packer extends uvm_compat_pkg::uvm_compat_packer; 
```

# Sequence Base Usage

The `uvm_sequence_base` and `uvm_sequence#()` classes were changed to abstract classes after UVM1.2.  This change means that it is no longer allowed to create an instance of these classes.  Any user code that created an instance of these base classes can be changed to instance the `uvm_compat_proxy_sequence#()` class, which extends from `uvm_sequence#()` with no additional functionality.

# Git details

The following information may be used for tracking the version of this file.  Please see
[DEVELOPMENT.md](../DEVELOPMENT.md) for more details.

```
$File$
$Rev$
$Hash$
```
