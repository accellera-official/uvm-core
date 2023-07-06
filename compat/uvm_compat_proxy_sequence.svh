//
//------------------------------------------------------------------------------
// Copyright 2022 Marvell International Ltd.
// Copyright 2022 NVIDIA Corporation
//
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
//
// CLASS: uvm_compat_proxy_sequence
//
// The uvm_compat_proxy_sequence is provided as a conveience for users
// which need an arbitrary instance of uvm_sequence_base for interacting
// with sequencers/sequence items without having a running sequence.
//
// Prior to 1800.2, it was possible to instance uvm_sequence_base manually
// and then start_item/finish_item on that instance to interact with a
// sequencer.  In 1800.2 the uvm_sequence_base and uvm_sequence#() classes
// were defined as abstract, meaning they can't be arbitrarily instanced.
// 

class uvm_compat_proxy_sequence #(type REQ = uvm_sequence_item,
                                  type RSP = REQ) extends uvm_sequence#(REQ,RSP);
  `uvm_object_param_utils(uvm_compat_proxy_sequence#(REQ,RSP))
  function new(string name="unnamed-uvm_compat_proxy_sequence");
    super.new(name);
  endfunction : new
endclass : uvm_compat_proxy_sequence


