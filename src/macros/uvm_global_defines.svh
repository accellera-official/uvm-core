//------------------------------------------------------------------------------
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2022 Marvell International Ltd.
// Copyright 2015-2022 NVIDIA Corporation
// Copyright 2014 Synopsys, Inc.
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
`ifndef UVM_GLOBAL_DEFINES_SVH
`define UVM_GLOBAL_DEFINES_SVH

//
// Title: Global Macros 
//------------------------
// Global object Macro definitions can be used in multiple locations
//------------------------
//

// MACRO: `UVM_COMPONENT_CONFIG_MODE_DEFAULT
//
// Defines the default configuration mode used by uvm_component::apply_config_settings_mode.
//
// The default value is CONFIG_CHECK_NAMES.  Note that this is a divergence from 1800.2,
// however the performance increase is drastic.  If the 1800.2 behavior is desired,
// the library can be compiled with `+define+UVM_COMPONENT_CONFIG_MODE_DEFAULT=CONFIG_STRICT`.
//
// @uvm-contrib
`ifndef UVM_COMPONENT_CONFIG_MODE_DEFAULT
 `define UVM_COMPONENT_CONFIG_MODE_DEFAULT CONFIG_CHECK_NAMES
`endif

// MACRO -- NODOCS -- `UVM_MAX_STREAMBITS
//
// Defines the maximum bit vector size for integral types. 
// Used to set uvm_bitstream_t

`ifndef UVM_MAX_STREAMBITS
 `define UVM_MAX_STREAMBITS 4096
`endif


// MACRO -- NODOCS -- `UVM_PACKER_MAX_BYTES
//
// Defines the maximum bytes to allocate for packing an object using
// the <uvm_packer>. Default is <`UVM_MAX_STREAMBITS>, in ~bytes~.

// @uvm-ieee 1800.2-2020 manual B.6.2
`ifndef UVM_PACKER_MAX_BYTES
 `define UVM_PACKER_MAX_BYTES `UVM_MAX_STREAMBITS
`endif

//------------------------
// Group -- NODOCS -- Global Time Macro definitions that can be used in multiple locations
//------------------------

// MACRO -- NODOCS -- `UVM_DEFAULT_TIMEOUT
//
// The default timeout for simulation, if not overridden by
// <uvm_root::set_timeout> or <uvm_cmdline_processor::+UVM_TIMEOUT>
//

`define UVM_DEFAULT_TIMEOUT 9200s

`endif //  `ifndef UVM_GLOBAL_DEFINES_SVH
