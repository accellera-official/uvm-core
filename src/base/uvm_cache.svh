//
//------------------------------------------------------------------------------
// Copyright 2022 Cadence Design Systems, Inc.
// Copyright 2022 Marvell International Ltd.
// Copyright 2022-2023 Mentor Graphics Corporation
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

`ifndef UVM_CACHE_SVH
 `define UVM_CACHE_SVH

//------------------------------------------------------------------------------
//
// CLASS: uvm_cache(KEY_T,DATA_T)
//
//------------------------------------------------------------------------------
// Abstract base class for implementing a key/value pair cache.
//
// A key/value cache is similar in nature to an associative array, however
// there are certain conditions under which a cache may choose to evict an element
// which has been previously stored.  The eviction policy is specific to the
// implementation of the cache.
//------------------------------------------------------------------------------
//
// @uvm-contrib
virtual class uvm_cache#(type KEY_T=int, type DATA_T=int) extends uvm_object;

  // Type: this_type
  // Typedef representing this cache parameterization.
  typedef uvm_cache#(KEY_T, DATA_T) this_type;

  // Type: optional_data
  // The cache can be queried for data at a given key.  If the
  // key exists within the cache then the data can be returned, but
  // if the key does ~not~ exist then the cache needs to return
  // "nothing".
  //
  // The ~optional_data~ type is a simple wrapper around a queue
  // of ~DATA_T~.  If the key is found (ie. hit), then the first
  // (and only) element of the queue stores the value.  If the
  // key is not found (ie. missed), then an empty queue is returned.
  //
  // Note: SystemVerilog uses a similar pattern for the array
  // locator methods.
  typedef DATA_T optional_data[$];

  // Type: optional_keys
  // The optional_keys type is similar to the <optional_data> type,
  // however it stores keys instead of data.  This is generally used
  // by the <keys> method.
  typedef KEY_T optional_keys[$]; 
  
  // Type: size_t
  // An unsigned data type used for size operations on the cache.
  typedef int unsigned size_t;

  `uvm_object_abstract_param_utils(uvm_cache#(KEY_T, DATA_T))
  `uvm_type_name_decl("uvm_cache")

  // Function: new
  // Constructor, initializes the cache.
  //
  // The ~max_size~ argument defines the initial maximum size of
  // the cache.  The default ~max_size~ shall be 256.
  //
  // A ~max_size~ of 0 indicates that the cache is unsized, and will
  // not evict any keys.
  //
  extern function new(string name="unnamed-uvm_cache", size_t max_size = 256);

  // Function: set_max_size
  // Sets the maximum size of the cache to ~max_size~.
  //
  // The default value of ~max_size~ shall be 256.
  //
  // If the new ~max_size~ value is less than the current number of
  // keys stored in the cache, then <evict_to_max> is automatically
  // called.
  //
  // A ~max_size~ of 0 indicates that the cache is unsized, and will
  // not evict any keys.
  //
  extern virtual function void set_max_size(size_t max_size=256);

  // Function: get_max_size
  // Returns the current maximum size of the cache.
  extern virtual function size_t get_max_size();
  
  // Function: size
  // Returns the current number of elements in the cache.
  //
  pure virtual function size_t size();

  // Function: exists
  // Returns true if ~key~ exists in the cache, otherwise returns false.
  //
  pure virtual function bit exists(KEY_T key);

  // Function: get
  // Returns data associated with ~key~.
  //
  // If ~key~ exists within the cache, then the data is returned
  // via <optional_data>.
  //
  // If ~key~ does not existing within the cache, then this operation
  // shall have no effect on the cache, and shall return empty
  // <optional_data>.
  pure virtual function optional_data get(KEY_T key);

  // Function: put
  // Puts ~data~ in cache at index ~key~.
  //
  // If ~key~ exists within the cache, then the data associated
  // ~key~ is updated.  If ~key~ does not exists within the cache,
  // then a new data value is added at ~key~.
  //
  // If putting the key in the cache causes the number of stored
  // keys to exceed <get_max_size>, then the least recently used
  // key shall be evicted via <evict>.
  pure virtual function void put(KEY_T key, DATA_T data);
  
  // Function: evict
  // Removes the data at ~key~ from the cache.
  //
  // If ~key~ exists within the cache, then the data is returned
  // via <optional_data>.
  //
  // If ~key~ does not exist within the cache, then this operation
  // shall have no effect on the cache, and shall return empty
  // optional data.
  //
  pure virtual function optional_data evict(KEY_T key);

  // Function: evict_to_max
  // Hook for evicting all keys greater than maximum size.
  //
  // This method is called by <set_max_size> when the new
  // maximum size exceeds the current size of the cache.
  //
  // If the current size of the cache is less than the
  // maximium size, <evict_to_max> shall have no effect
  // on the cache.
  pure virtual protected function void evict_to_max();
    
  // Function: keys
  // Returns a queue of all keys currently in the cache.
  //
  pure virtual function optional_keys keys();
  
  // Function: flush
  // Evicts all keys from the cache.
  //
  extern virtual function void flush();

  // Implementation Details

  // Maximum size
  protected size_t m_max_size;

  // 

endclass : uvm_cache

// uvm_cache function implementations
  
function uvm_cache::new(string name="unnamed-uvm_cache", uvm_cache::size_t max_size = 256);
  super.new(name);
  this.m_max_size = max_size;
endfunction : new

function void uvm_cache::flush();
  optional_keys m_keys;
  m_keys = keys();
  foreach (m_keys[key])
    void'(evict(m_keys[key]));
endfunction : flush

function void uvm_cache::set_max_size(uvm_cache::size_t max_size=256);
  m_max_size = max_size;
  evict_to_max();
endfunction : set_max_size

function uvm_cache::size_t uvm_cache::get_max_size();
  return m_max_size;
endfunction : get_max_size

`endif //  `ifndef UVM_CACHE_SVH
