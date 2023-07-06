//
//----------------------------------------------------------------------
// Copyright 2010 AMD
// Copyright 2010-2018 Cadence Design Systems, Inc.
// Copyright 2022 Marvell International Ltd.
// Copyright 2010-2011 Mentor Graphics Corporation
// Copyright 2013-2022 NVIDIA Corporation
// Copyright 2010-2011 Synopsys, Inc.
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

`ifndef UVM_COMPAT_MACROS_SVH
`define UVM_COMPAT_MACROS_SVH

//
// Any vendor specific defines go here.
//


// defines for compatibility
`ifndef UVM_VERSION
   `define uvm_unpack_string_with_size(SIZE=-1) unpack_string(SIZE)
`else
   `define uvm_unpack_string_with_size(SIZE=-1) unpack_string_with_size(SIZE)
`endif

`endif
