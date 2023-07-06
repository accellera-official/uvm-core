//
//------------------------------------------------------------------------------
// Copyright 2022 Marvell International Ltd.
// Copyright 2021 NVIDIA Corporation
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

`ifndef UVM_REGEX_CACHE_SVH
 `define UVM_REGEX_CACHE_SVH

//------------------------------------------------------------------------------
//
// CLASS -- NODOCS -- uvm_regex_cache
//
//------------------------------------------------------------------------------
// Extends a uvm_lru_cache to add C-side memory management during eviction.  
//------------------------------------------------------------------------------
//
class uvm_regex_cache extends uvm_lru_cache#(string, chandle);

  `uvm_type_name_decl("uvm_regex_cache")

  // Constructor is protected (singleton)
  protected function new(string name="unnamed-uvm_regex_cache");
    super.new(name);
  endfunction : new

  // Singleton accessor
  static function uvm_regex_cache get_inst();
    static uvm_regex_cache m_inst;
    if (m_inst == null)
      m_inst = new("uvm_regex_cache");
    return m_inst;
  endfunction : get_inst

  // Clear memory after eviction
  virtual function optional_data evict(KEY_T key);
    chandle tmp[$];
    tmp = super.evict(key);
    if (tmp.size() && tmp[0] != null) begin
      uvm_re_free(tmp[0]);
    end
    return tmp;
  endfunction : evict

endclass : uvm_regex_cache
  
`endif //  `ifndef UVM_REGEX_CACHE_SVH
