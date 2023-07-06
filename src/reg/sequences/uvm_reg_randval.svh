// 
// -------------------------------------------------------------
// Copyright 2020 NVIDIA Corporation
// Copyright 2004-2009 Synopsys, Inc.
//    All Rights Reserved Worldwide
// 
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
// 

//
// TITLE -- NODOCS -- Register access sequence random value generator
//

//
// class -- NODOCS -- uvm_reg_randval
//
// General register random value generator.
// This class may be instantiated within a register access sequence
// and may be randomized in order to generate a random register value
// based on the context of the sequence's random seed without altering
// the state of other random members of the sequence 

class uvm_reg_randval;

  rand uvm_reg_data_t randval;
    
endclass
