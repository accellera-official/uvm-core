//
//------------------------------------------------------------------------------
// Copyright 2024 NVIDIA Corporation
// Copyright 2024 Siemens
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

//----------------------------------------------------------------------
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------

// Class: uvm_packer_array_extension
// Extension used to indicate that the packer is operating on an array
// of values.
//
// By default, the packer will ignore the presence of this extension;
// however, a subclass of <uvm_packer> may change the structure of the
// packer state based on the presence of this extension.
class uvm_packer_array_extension extends uvm_object;

    `uvm_object_utils(uvm_packer_array_extension)

    // Function: new
    // Constructor
    extern function new(string name="unnamed-uvm_packer_array_extension");

    // Function: get
    // Singleton accessor
    //
    // The presence of a <uvm_packer_array_extension> within the packer
    // extension list is sufficient to determine whether any actions
    // should be taken by the packer.
    //
    // A singleton instance is provided to avoid the performance impact
    // of continuously constructing new instances.
    extern static function uvm_packer_array_extension get();
endclass

// Implementations

function uvm_packer_array_extension::new(string name="unnamed-uvm_packer_array_extension"); 
    super.new(name); 
endfunction


function uvm_packer_array_extension uvm_packer_array_extension::get();
    static uvm_packer_array_extension singleton;
    if ( singleton == null )
        singleton = new("uvm_packer_array_extension");
    return singleton;
endfunction
