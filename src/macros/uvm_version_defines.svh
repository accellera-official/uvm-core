//----------------------------------------------------------------------
// Copyright 2010 AMD
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2017 Cisco Systems, Inc.
// Copyright 2019-2020 Marvell International Ltd.
// Copyright 2007-2022 Mentor Graphics Corporation
// Copyright 2014-2020 NVIDIA Corporation
// Copyright 2011-2012 Paradigm Works
// Copyright 2010-2013 Synopsys, Inc.
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

`ifndef UVM_VERSION_DEFINES_SVH
`define UVM_VERSION_DEFINES_SVH

   `define UVM_VERSION 2020


// Title --NODOCS-- UVM Version Defines

// Group --NODOCS-- UVM Version Ladder
// The following defines are provided as an indication of 
// how this implementation release relates to previous UVM 
// implementation releases from Accellera.

   `define UVM_VERSION_POST_2017
   `define UVM_VERSION_POST_2017_1_0   
   `define UVM_VERSION_POST_2017_1_1
   `define UVM_VERSION_POST_2020_1_0
   `define UVM_VERSION_POST_2020_1_1
   
// These defines are used in earlier versions of UVM
// They are provided here with mappings relevant to IEEE 1800.2 2020 v2.0  
//@back_compat   
  `define UVM_NAME UVM
  
  `define UVM_MAJOR_REV 2020
  `define UVM_MINOR_REV 2.0
  
  `define UVM_VERSION_STRING uvm_pkg::UVM_VERSION_STRING

  // Defines for `ifdefs
  `define UVM_POST_VERSION_1_1
  `define UVM_POST_VERSION_1_2


`endif // UVM_VERSION_DEFINES_SVH
