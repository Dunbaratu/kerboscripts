CLEARSCREEN.
PRINT "Vessel Comms Station Server Running.".
lock steering to v(0,0,0).
unlock steering.



local message_handlers is lexicon (
  "DOCKWANTED", process_dockwanted@,
  "UNKNOWN", process_unknown@
).


ag10 off. wait 0.
until ag10 {
  WAIT UNTIL NOT SHIP:MESSAGES:EMPTY or ag10.
  if not ag10 {
    local msg is SHIP:MESSAGES:POP.
    process_msg(msg).
    wait 0.001.
  }
}

function process_msg {
  parameter msg.

  local data is msg:content.
  if not data:ISTYPE("LEXICON") or
     not data:HASKEY("TYPE") or
     not message_handlers:HASKEY(data["TYPE"])
  {
    message_handlers["UNKNOWN"]:call(msg).
  }
  else
  {
    message_handlers[data["TYPE"]]:call(msg).
  }
}

function process_dockwanted {
  parameter msg.
  local data is msg:content.
  print data["TYPE"] + ": " +msg:sender + ", nodetype: " + data["NODETYPE"].
  local other_ves is msg:sender.
  print "Checking to find a docking port of the requested type with a tag name.".
  local found_part is 0.
  local did_find is false.
  for p in ship:parts {
    if  p:ISTYPE("DOCKINGPORT") and
        p:NODETYPE = data["NODETYPE"] and
        (p:STATE = "Disabled" or p:STATE = "Ready") and
        p:tag <> "" {
      set found_part to p.
      set did_find to true.
    }
  }
  if did_find {
    local port_name is found_part:TAG.
    other_ves:connection:sendMessage(LEXICON("TYPE", "DOCKALLOWED", "TAG", port_name)).
    print "Found a suitable docking port: " + found_part.


    if found_part:hasmodule("ModuleAnimateGeneric") {
      local mod is found_part:getmodule("ModuleAnimateGeneric").
      if mod:hasevent("open shield") {
        mod:doevent("open shield").
        print "Opening Shield for the port.".
      }
      if mod:hasevent("open") {
        mod:doevent("open").
        print "Opening Shield for the port.".
      }
    }


    local light_name is port_name + "_light".
    local indicator_lights is ship:partstagged(light_name).
    light_change( indicator_lights, yellow, true ).


    print "Orienting port to face client. Color will turn green when ready.".
    found_part:CONTROLFROM().
    lock steering to orient_to_client(found_part, other_ves).

    wait 0.001.
    wait 0.001.


    wait until abs(steeringmanager:angleerror) < 1 and abs(steeringmanager:rollerror) < 1.
    light_change( indicator_lights, green, true ).

    set old_steering to orient_to_client(found_part, other_ves).
    lock steering to old_steering.

    other_ves:connection:sendMessage(LEXICON("TYPE", "DOCKREADY", "TAG", port_name)).
    print "Waiting for dock to happen.".
    until found_part:STATE = "Docked (docker)" or
          found_part:STATE = "Docked (dockee)" or
          found_part:STATE = "Docked (same vessel)" {
      set new_steering to orient_to_client(found_part, other_ves).
      if VANG(new_steering, old_steering) < 2 {
        set old_steering to new_steering.
      }
      wait 0.0001.
    }
    print "Dock Happened.".
    light_change( indicator_lights, red, false ).
    unlock steering.
    set ship:control:neutralize to true.
  } else {
    print "Could not find a docking port of that size that had a name tag.".
    print "  - Refusing dock request.".
    other_ves:connection:sendMessage(LEXICON("TYPE", "DOCKDENIED")).
  }
}

function process_unknown {
  parameter msg.
  print "DEBUG: GOT UNKNOWN CLIENT REQUEST " + msg.
  print "DEBUG: CONTENTS: " + msg:content.

}





function light_change {
  parameter light_list, light_color, enable.

  for L in light_list {
    local has_kOS_light_mod is L:HASMODULE("kOSLightModule").
    local has_light_mod is L:HASMODULE("ModuleLight").
    if has_kOS_light_Mod {
      local mod is L:GETMODULE("kOSLightModule").
      mod:SETFIELD("LIGHT R", light_color:R).
      mod:SETFIELD("LIGHT G", light_color:G).
      mod:SETFIELD("LIGHT B", light_color:B).
    }
    if has_light_mod {
      local mod is L:GETMODULE("ModuleLight").
      if enable {

        if (mod:HASEVENT("Lights On")) { mod:doevent("Lights On"). }
      } else {

        if (mod:HASEVENT("Lights Off")) { mod:doevent("Lights Off"). }
      }
    }
  }
}

function orient_to_client {
  parameter port, clientship.


  local positionVec is clientship:position - ship:position.
  return positionVec.
}
