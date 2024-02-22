//
//----------------------------------------------------------------------
// Copyright 2007-2022 Cadence Design Systems, Inc.
// Copyright 2023 Intel Corporation
// Copyright 2007-2011 Mentor Graphics Corporation
// Copyright 2013-2023 NVIDIA Corporation
// Copyright 2011-2022 Synopsys, Inc.
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

`ifndef UVM_PKG_SV
 `define UVM_PKG_SV

 `include "uvm_macros.svh"

 `ifdef UVM_EXPERIMENTAL_POLLING_API
  `ifdef UVM_PLI_POLLING_ENABLE

package uvm_polling_pkg;
   //import uvm_pkg::*;
   static bit notifier;
  `ifndef XCELIUM  
   string     notifier_signal_name = $sformatf("%m.notifier");
  `else // Xcelium handles the notifier bit differently
   string     notifier_signal_name = $sformatf("%m::notifier");
  `endif
endpackage
  `endif // UVM_PLI_POLLING_ENABLE
 `endif // UVM_EXPERIMENTAL_POLLING_API

package uvm_pkg;

 `include "dpi/uvm_dpi.svh"
 `include "base/uvm_base.svh"
 `include "dap/uvm_dap.svh"
 `include "tlm1/uvm_tlm.svh"
 `include "comps/uvm_comps.svh"
 `include "seq/uvm_seq.svh"
 `include "tlm2/uvm_tlm2.svh"
 `include "reg/uvm_reg_model.svh"

 `ifdef UVM_EXPERIMENTAL_POLLING_API
  `include "dpi/uvm_polling_dpi.svh"
  `include "base/uvm_hdl_polling.svh"
 `else
  // This function is exported to simplify C compilation when experimental polling isn't enabled.
  export "DPI-C" function uvm_polling_value_change_notify;
  function void uvm_polling_value_change_notify(int sv_key);
     uvm_report_fatal("UVM_HDL_POLLING",
                      $sformatf("VPI access is disabled. Recompile without +define+UVM_HDL_NO_DPI"));
  endfunction
 `endif

endpackage
`endif

