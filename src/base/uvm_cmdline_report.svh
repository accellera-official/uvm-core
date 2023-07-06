//
//------------------------------------------------------------------------------
// Copyright 2022 AMD
// Copyright 2007-2009 Cadence Design Systems, Inc.
// Copyright 2007-2009 Mentor Graphics Corporation
// Copyright 2020 NVIDIA Corporation
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

// Command line classes
class uvm_cmdline_setting_base;
  string    arg; // Original command line option
  bit used[uvm_component]; // Usage tracking
endclass : uvm_cmdline_setting_base

class uvm_cmdline_verbosity extends uvm_cmdline_setting_base;
  // Instance Methods/Variables
  int verbosity;
  enum {STANDARD, NON_STANDARD, ILLEGAL} src;
  
  // Static Methods/Variables
  static const string prefix = "+UVM_VERBOSITY=";
  static uvm_cmdline_verbosity settings[$];
  

  // Function --NODOCS-- init
  // Initializes the ~settings~ queue with the command line verbosity settings.
  //
  // Warnings for incorrectly formatted command line arguments are routed through
  // the report object ~ro~.  If ~ro~ is null, then no warnings shall be generated.
  static function void init(input uvm_report_object ro);
    string  setting_str[$];
    int     verbosity;
    int     verb_count;
    string  verb_string;
    bit     skip;
    uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

`ifndef UVM_CMDLINE_NO_DPI
    // Retrieve the verbosities provided on the command line
    verb_count = clp.get_arg_values(prefix, setting_str);
`else
    verb_count = $value$plusargs("UVM_VERBOSITY=%s", verb_string);
    if (verb_count)
      setting_str.push_back(verb_string);
`endif

    foreach(setting_str[i]) begin
      uvm_cmdline_verbosity setting;
      uvm_verbosity temp_verb;
      setting = new();
      setting.arg = setting_str[i];
      setting.src = STANDARD;
      
      if (!uvm_string_to_verbosity(setting_str[i], temp_verb)) begin
        int code;
        code = $sscanf(setting_str[i], "%d", setting.verbosity);
        if (code > 0) begin
          `uvm_info_context("NSTVERB", 
                            $sformatf("Non-standard verbosity value '%s', converted to '%0d'.",
                                      setting_str[i], verbosity),
                            UVM_NONE,
                            ro)
          setting.src = NON_STANDARD;
        end
        else begin
          setting.verbosity = UVM_MEDIUM;
          setting.src = ILLEGAL;
        end
      end // if (!uvm_string_to_verbosity(setting_str[i], verbosity))
      else begin
        setting.verbosity = temp_verb;
      end

      settings.push_back(setting);
    end // foreach (setting_str[i])

  endfunction : init

  // Function --NODOCS-- check
  // Checks the settings queue for unused verbosity settings.
  //
  // Verbosity could be unused because it wasn't first on the command line.
  static function void check(uvm_report_object ro);
    string verb_q[$];
    
    foreach (settings[i]) begin
      if (settings[i].src == ILLEGAL) begin
        `uvm_warning_context("ILLVERB",
                             $sformatf("Illegal verbosity value '%s', converted to default of UVM_MEDIUM.",
                                       settings[i].arg),
                             ro)
      end
      if (i != 0)
        verb_q.push_back(", ");
      verb_q.push_back(settings[i].arg);
    end // foreach (settings[i])
    
    if (settings.size() > 1) begin
      `uvm_warning_context("MULTVERB",
			   $sformatf("Multiple (%0d) +UVM_VERBOSITY arguments provided on the command line.  '%s' will be used.  Provided list: %s.", 
                                     settings.size(),
                                     settings[0].arg, 
                                     `UVM_STRING_QUEUE_STREAMING_PACK(verb_q)),
                           ro);
    end // if (settings.size() > 1)
  endfunction : check

  // Function --NODOCS-- dump
  // Dumps the usage information for the verbosity settings as a string.
  //
  static function string dump();
    string msgs[$];
    int    tmp_verb;

    foreach (settings[i]) begin
      msgs.push_back($sformatf("\n%s%s: ", prefix, settings[i].arg));
      if (i == 0)
        msgs.push_back("Applied");
      else
        msgs.push_back("Not applied (not first on command line)");
      if (settings[i].src == NON_STANDARD)
        msgs.push_back($sformatf(", converted as non-standard to '%0d'", settings[i].verbosity)); 
      else if (settings[i].src == ILLEGAL)
        msgs.push_back(", converted as ILLEGAL to UVM_MEDIUM");
    end // foreach (settings[i])

    return `UVM_STRING_QUEUE_STREAMING_PACK(msgs);
  endfunction : dump

endclass : uvm_cmdline_verbosity


    
class uvm_cmdline_set_verbosity extends uvm_cmdline_setting_base;
  // Instance Methods/Variables
  string    comp;
  string    id;
  int       verbosity;
  string    phase;
  time      offset;

  // Static Methods/Variables
  static const string prefix = "+uvm_set_verbosity="; 
  static uvm_cmdline_set_verbosity settings[$]; // Processed command line settings

  
  // Function --NODOCS-- init
  // Initializes the ~settings~ queue with the command line verbosity settings.
  //
  // Warnings for incorrectly formatted command line arguments are routed through
  // the report object ~ro~.  If ~ro~ is null, then no warnings shall be generated.
  static function void init(input uvm_report_object ro);
    string  setting_str[$];
    uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

    if (clp.get_arg_values(prefix, setting_str) > 0) begin
      uvm_verbosity temp_verb;
      string  args[$];
      string  message;
      bit     skip;
       
      foreach(setting_str[i]) begin
        skip = 0;
        uvm_string_split(setting_str[i], ",", args);
        if (args.size() < 4 || args.size() > 5) begin
          message = "Invalid number of arguments found, expected 4 or 5";
          skip = 1;
        end
        if (args.size() == 5 && args[3] != "time") begin
          message = "Too many arguments found for <phase>, expected only 4";
          skip = 1;
        end
        if (args.size() == 4 && args[3] == "time") begin
          message = "Too few arguments found for <time>, expected 5";
          skip = 1;
        end
        if (!uvm_string_to_verbosity(args[2], temp_verb)) begin
          message = "Invalid verbosity found";
          skip = 1;
        end
        
        if (!skip) begin
          int rt_val;
          uvm_cmdline_set_verbosity setting;
          setting = new();
          setting.arg = setting_str[i];
          setting.comp = args[0];
          setting.id = args[1];
          setting.verbosity = temp_verb;
          setting.phase = args[3];
          if (setting.phase == "time") begin
            rt_val = $sscanf(args[4], "%d", setting.offset);
          end
          else
            setting.offset = 0;
          settings.push_back(setting);
        end // if (!skip)
        else if (ro != null) begin
          `uvm_warning_context("INVLCMDARGS",
                               $sformatf("%s, setting '%s%s' will be ignored.",
                                         message,
                                         prefix,
                                         setting_str[i]),
                               ro)
        end          
      end // foreach (setting_string[i])
    end // if (clp.get_arg_values(prefix, setting_string) > 0)
    
  endfunction : init

  // Function --NODOCS-- check
  // Checks the settings queue for unused verbosity settings.
  //
  // Verbosity could be unused because:
  //   a) It didn't match any components
  //   b) The ~offset~ specified hasn't occurred yet
  //   c) The ~phase~ specified hasn't occurred yet
  static function void check(uvm_report_object ro);
    foreach (settings[i]) begin
      if (settings[i].used.size() == 0) begin
        // Warn if we didn't match any components
        `uvm_warning_context("INVLCMDARGS",
                             $sformatf("\"%s%s\" never took effect due to either a mismatching component pattern.",
                                       prefix,
                                       settings[i].arg),
                             ro)
      end
      else begin
        if (settings[i].phase == "time") begin
          if ($time < settings[i].offset) begin
            // Warn if we haven't hit the time yet
            `uvm_warning_context("INVLCMDARGS",
                                 $sformatf("\"%s%s\" never took effect due to test ending before offset was reached.",
                                           prefix,
                                           settings[i].arg),
                                 ro)
          end
        end
        else begin
          bit hit;
          uvm_cmdline_set_verbosity setting;
          setting = settings[i];
          foreach (setting.used[i]) begin
            if (setting.used[i]) begin
              hit = 1;
              break;
            end
          end // foreach (setting.used[i])
          
          if (!hit) begin
            // Warn if all our matching components never saw ~phase~
            `uvm_warning_context("INVLCMDARGS",
                                 $sformatf("\"%s%s\" never took effect due to phase never occurring for matching component(s).",
                                           prefix,
                                           settings[i].arg),
                                 ro)
          end
        end // else: !if(settings[i].phase == "time")
      end // else: !if(settings[i].used.size() == 0)
    end // foreach (settings[i])
    
  endfunction : check
  
  // Function --NODOCS-- dump
  // Dumps the usage information for the verbosity settings as a string.
  //
  static function string dump();
    string msgs[$];
    uvm_component sorted_list[$];
    foreach (settings[i]) begin
      uvm_cmdline_set_verbosity setting;
      setting = settings[i];
      msgs.push_back($sformatf("\n%s%s", prefix, setting.arg));
      msgs.push_back("\n  matching components:");
      if (setting.used.size() == 0)
        msgs.push_back("\n    <none>");
      else begin
        sorted_list.delete();
        foreach (setting.used[j])
          sorted_list.push_back(j);
        sorted_list.sort() with ( item.get_full_name() );
        foreach (sorted_list[j]) begin
          string full_name;
          full_name = sorted_list[j].get_full_name();
          if (full_name == "")
            full_name = "<uvm_root>";
          msgs.push_back("\n    ");
          msgs.push_back(full_name);
          msgs.push_back(": ");
          if ((setting.phase == "time" && setting.used[sorted_list[j]]) ||
              (setting.phase != "time" && setting.used[sorted_list[j]]))
            msgs.push_back("Applied");
          else begin
            msgs.push_back("Not applied ");
            if (setting.phase == "time")
              msgs.push_back("(component never reached offset)");
            else
              msgs.push_back("(component never saw phase)");
          end
        end // foreach (setting.used[j])
      end // else: !if(setting.used.size() == 0)
    end // foreach (settings[i])

    return `UVM_STRING_QUEUE_STREAMING_PACK(msgs);
  endfunction : dump
    
endclass // uvm_cmdline_set_verbosity

class uvm_cmdline_set_action extends uvm_cmdline_setting_base;
  // Instance Methods/Variables
  string    comp;
  string    id;
  bit       all_sev;
  uvm_severity sev;
  uvm_action action;

  // Static Methods/Variables
  static const string prefix="+uvm_set_action=";
  static uvm_cmdline_set_action settings[$]; // Processed command line settings
  
  // Function --NODOCS-- init
  // Initializes the ~settings~ queue with the command line action settings.
  //
  // Warnings for incorrectly formatted command line arguments are routed through
  // the report object ~ro~.  If ~ro~ is null, then no warnings shall be generated.
  static function void init(input uvm_report_object ro);
    string  setting_str[$];
    uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
    
    if (clp.get_arg_values(prefix, setting_str) > 0) begin
      uvm_action action;
      uvm_severity sev;
      string  args[$];
      string  message;
      bit     skip;

      foreach(setting_str[i]) begin
        skip = 0;
        uvm_string_split(setting_str[i], ",", args);
        if (args.size() != 4) begin
          message = "Invalid number of arguments found, expected 4";
          skip = 1;
        end
        if (args[2] != "_ALL_" && !uvm_string_to_severity(args[2], sev)) begin
          message = $sformatf("Bad severity argument '%s'", args[2]);
          skip = 1;
        end
        if (!uvm_string_to_action(args[3], action)) begin
          message = $sformatf("Bad action argument '%s'", args[3]);
          skip = 1;
        end

        if (!skip) begin
          uvm_cmdline_set_action setting;
          setting = new();
          setting.arg = setting_str[i];
          setting.comp = args[0];
          setting.id = args[1];
          setting.all_sev = (args[2] == "_ALL_");
          setting.sev = sev;
          setting.action = action;

          settings.push_back(setting);
        end // if (!skip)
        else if (ro != null) begin
          `uvm_warning_context("INVLCMDARGS", 
                               $sformatf("%s, setting '%s%s' will be ignored.",
                                         message,
                                         prefix,
                                         setting_str[i]),
                               ro)
        end
      end // foreach (setting_str[i])
    end // if (clp.get_arg_values(prefix, setting_str) > 0)
    
  endfunction : init

  // Function --NODOCS-- check
  // Checks the settings queue for unused action settings.
  //
  // Verbosity could be unused because:
  //   a) It didn't match any components
  static function void check(uvm_report_object ro);
    foreach(settings[i]) begin
      if (settings[i].used.size() == 0) begin
        `uvm_warning_context("INVLCMDARGS",
                             $sformatf("\"%s%s\" never took effect due to a mismatching component pattern",
                                       prefix,
                                       settings[i].arg),
                             ro)
      end
    end
  endfunction : check
  
  // Function --NODOCS-- dump
  // Dumps the usage information for the verbosity settings as a string.
  //
  static function string dump();
    string msgs[$];
    uvm_component sorted_list[$];
    foreach (settings[i]) begin
      uvm_cmdline_set_action setting;
      setting = settings[i];
      msgs.push_back($sformatf("\n%s%s", prefix, setting.arg));
      msgs.push_back("\n  matching components:");
      if (setting.used.size() == 0)
        msgs.push_back("\n    <none>");
      else begin
        sorted_list.delete();
        foreach (setting.used[j])
          sorted_list.push_back(j);
        sorted_list.sort() with ( item.get_full_name() );
        foreach (sorted_list[j]) begin
          string full_name;
          full_name = sorted_list[j].get_full_name();
          if (full_name == "")
            full_name = "<uvm_root>";
          msgs.push_back("\n    ");
          msgs.push_back(full_name);
          msgs.push_back(": Applied");
        end // foreach (setting.used[j])
      end // else: !if(setting.used.size() == 0)
    end // foreach (settings[i])

    return `UVM_STRING_QUEUE_STREAMING_PACK(msgs);
  endfunction : dump

endclass : uvm_cmdline_set_action

class uvm_cmdline_set_severity extends uvm_cmdline_setting_base;
  // Instance Methods/Variables
  string    comp;
  string    id;
  bit       all_sev;
  uvm_severity orig_sev;
  uvm_severity sev;

  // Static Methods/Variables
  static const string prefix="+uvm_set_severity=";
  static uvm_cmdline_set_severity settings[$]; // Processed command line settings
  
  // Function --NODOCS-- init
  // Initializes the ~settings~ queue with the command line severity settings.
  //
  // Warnings for incorrectly formatted command line arguments are routed through
  // the report object ~ro~.  If ~ro~ is null, then no warnings shall be generated.
  static function void init(input uvm_report_object ro);
    string  setting_str[$];
    uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();
    
    if (clp.get_arg_values(prefix, setting_str) > 0) begin
      uvm_severity orig_sev, sev;
      string  args[$];
      string  message;
      bit     skip;

      foreach(setting_str[i]) begin
        skip = 0;
        uvm_string_split(setting_str[i], ",", args);
        if (args.size() != 4) begin
          message = "Invalid number of arguments found, expected 4";
          skip = 1;
        end
        if (args[2] != "_ALL_" && !uvm_string_to_severity(args[2], orig_sev)) begin
          message = $sformatf("Bad severity argument '%s'", args[2]);
          skip = 1;
        end
        if (!uvm_string_to_severity(args[3], sev)) begin
          message = $sformatf("Bad severity argument '%s'", args[3]);
          skip = 1;
        end

        if (!skip) begin
          uvm_cmdline_set_severity setting;
          setting = new();
          setting.arg = setting_str[i];
          setting.comp = args[0];
          setting.id = args[1];
          setting.all_sev = (args[2] == "_ALL_");
          setting.orig_sev = orig_sev;
          setting.sev = sev;
          settings.push_back(setting);
        end // if (!skip)
        else if (ro != null) begin
          `uvm_warning_context("INVLCMDARGS", 
                               $sformatf("%s, setting '%s%s' will be ignored.",
                                         message, 
                                         prefix,
                                         setting_str[i]),
                               ro)
        end
      end // foreach (setting_str[i])
    end // if (clp.get_arg_values(prefix, setting_str) > 0)
  endfunction : init

    
  // Function --NODOCS-- check
  // Checks the settings queue for unused action settings.
  //
  // Verbosity could be unused because:
  //   a) It didn't match any components
  static function void check(uvm_report_object ro);
    foreach(settings[i]) begin
      if (settings[i].used.size() == 0) begin
        `uvm_warning_context("INVLCMDARGS",
                             $sformatf("\"%s%s\" never took effect due to a mismatching component pattern",
                                       prefix,
                                       settings[i].arg),
                             ro)
      end
    end
  endfunction : check
  
  // Function --NODOCS-- dump
  // Dumps the usage information for the verbosity settings as a string.
  //
  static function string dump();
    string msgs[$];
    uvm_component sorted_list[$];
    foreach (settings[i]) begin
      uvm_cmdline_set_severity setting;
      setting = settings[i];
      msgs.push_back($sformatf("\n%s%s", prefix, setting.arg));
      msgs.push_back("\n  matching components:");
      if (setting.used.size() == 0)
        msgs.push_back("\n    <none>");
      else begin
        sorted_list.delete();
        foreach (setting.used[j])
          sorted_list.push_back(j);
        sorted_list.sort() with ( item.get_full_name() );
        foreach (sorted_list[j]) begin
          string full_name;
          full_name = sorted_list[j].get_full_name();
          if (full_name == "")
            full_name = "<uvm_root>";
          msgs.push_back("\n    ");
          msgs.push_back(full_name);
          msgs.push_back(": Applied");
        end // foreach (setting.used[j])
      end // else: !if(setting.used.size() == 0)
    end // foreach (settings[i])

    return `UVM_STRING_QUEUE_STREAMING_PACK(msgs);
  endfunction : dump
    

endclass : uvm_cmdline_set_severity
