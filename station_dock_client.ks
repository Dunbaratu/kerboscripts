parameter param_tgt is 0.

local tgt is param_tgt.

CLEARSCREEN.

if tgt = 0 {
  PRINT "FIRST SELECT A REMOTE VESSEL AS YOUR TARGET VESSEL.".
}

PRINT "Clearing out any pending old messages:".
ship:messages:clear().

local thePorts is ship:partstagged("fromport").
if thePorts:LENGTH = 0 {
  PRINT "Now assign a docking port with nametag 'fromport' please.".
}
until thePorts:LENGTH > 0 {
  set thePorts to ship:partstagged("fromport").
  wait 0.001.
}
local thePort is thePorts[0].

local msg to LEXICON(
  "TYPE", "DOCKWANTED",
  "NODETYPE", thePort:NODETYPE,
  "TAG", thePort:TAG
).

local worked is false.
until worked {
  if tgt = 0 {
    set tgt to TARGET.
    wait 0.01.
  }
  print "Target is: " + tgt.
  local con is tgt:connection.
  set worked to con:sendmessage(msg).
  if worked {
    print "Message was sent successfully.".
        
    print "Waiting for reply.".
    wait until not SHIP:MESSAGES:EMPTY.
    local msg is SHIP:MESSAGES:POP.
    if msg:sender:name = tgt:name {
      print "Got Reply from target ship.".
      print "Message body:" + msg:content.

      if msg:content:ISTYPE("LEXICON") and msg:content:HASKEY("TYPE") {

        if msg:content["TYPE"] = "DOCKDENIED" { 
          print "Remote side refused to allow me to dock. Sorry.".

        } else if msg:content["TYPE"] = "DOCKALLOWED" {

          print "Remote side said I should dock with '"+msg:content["TAG"]+"' port.".
          local tgt_port is tgt:partstagged( msg:content["TAG"] )[0].
          lock steering to lookdirup(-tgt_port:portfacing:vector, tgt_port:portfacing:topvector).

          print "Controlling from my port".
          thePort:controlfrom().

          if thePort:hasmodule("ModuleAnimateGeneric") {
            local mod is thePort:getmodule("ModuleAnimateGeneric").
            if mod:hasevent("open shield") {
              print "Opening shield for my port.".
              mod:doevent("open shield").
            }
          }

          print "Waiting for remote to tell me it's okay to start docking.".
          local wait_over is false.
          until wait_over {
            if not ship:messages:empty {
              local reply is ship:messages:pop.
              if  reply:sender:istype("Vessel") and reply:sender = tgt and
              reply:content:istype("Lexicon") and reply:content:haskey("TYPE") and
              reply:content["TYPE"] = "DOCKREADY" {
                local tgt_port_again is tgt:partstagged( reply:content["TAG"] )[0].
                if tgt_port <> tgt_port_again {
                  print "Error in protocol: Server changed the target port on me.".
                } else {
                  do_dock(thePort, tgt_port).
                }
              } else  {
                print "Got an unexpected message: ignoring: " + reply.
              }
            }
            wait 1.
          }

        }
      }
    }
  } else {
    print "Message was not sent successfully, trying again in 1 second.".
  }
  wait 1.
}

function do_dock {
  parameter from_port, to_port.
  until abs(steeringmanager:angleerror) < 1 and abs(steeringmanager:rollerror) < 1 {
    print "Waiting for orientation to match direction of the port.".
    wait 2.
  }
  clearscreen.
  print "Approaching port".
  local old_rcs_value is RCS.
  RCS on.

  local fore_control_pid         is PIDLoop( 0.5, 0.001, 0.2, -1, 1 ).
  local top_want_speed_pid       is PIDLoop( 0.5, 0, 0.2, -10, 10 ).
  local top_control_pid          is PIDLoop( 0.3, 0.001, 0.2, -1, 1 ).
  local starboard_want_speed_pid is PIDLoop( 0.5, 0, 0.2, -10, 10 ).
  local starboard_control_pid    is PIDLoop( 0.3, 0.001, 0.2, -1, 1 ).

  until from_port:STATE = "Docked (docker)" or
        from_port:STATE = "Docked (dockee)" or
        from_port:STATE = "PreAttached" or
        from_port:STATE = "ACQUIRE" or
        from_port:STATE = "Docked (same vessel)" {

    // Make sure to grab all physical world readings right at the
    // start of a physics tick.  All other math can come later and
    // be safely interrupted by a tick boundary, but this stuff can't:
    wait 0.
    local rel_spd is from_port:ship:velocity:orbit - to_port:ship:velocity:orbit.
    local rel_port_pos is from_port:position - to_port:position.
    local foreUnit is ship:facing:forevector.
    local topUnit is ship:facing:topvector.
    local starUnit is ship:facing:starvector.
    local now is time:seconds.
    // ^^^ All relevant readings have been taken now.  After this point it's safe to have tick interruptions:

    local rel_spd_fore is vdot(foreUnit, rel_spd).
    local rel_spd_top is vdot(topUnit, rel_spd).
    local rel_spd_star is vdot(starUnit, rel_spd).

    local rel_pos_fore is vdot(foreUnit, rel_port_pos).
    local rel_pos_top is vdot(topUnit, rel_port_pos).
    local rel_pos_starboard is vdot(starUnit, rel_port_pos).

    // Note, this drives the forward part of the RCS thrust vector by
    // our relative SPEED, but drives the top and starboard parts of
    // the RCS thrust vector by our relative POSITIONS:
    set ship:control:fore to fore_control_pid:UPDATE( now, (rel_spd_fore - wanted_approach_speed(rel_port_pos)) ).
    set top_want_speed to top_want_speed_pid:UPDATE( now, rel_pos_top).
    set ship:control:top to top_control_pid:UPDATE( now, rel_spd_top - top_want_speed).
    set starboard_want_speed to starboard_want_speed_pid:UPDATE( now, rel_pos_starboard ).
    set ship:control:starboard to starboard_control_pid:UPDATE( now, rel_spd_star - starboard_want_speed).

    print "Rel Pos:" at (10,6).
    print "FORE: " + round(rel_pos_fore,2) + " m/s " at (20,6).
    print " TOP: " + round(rel_pos_top,2) + " m/s " at (20,7).
    print "STAR: " + round(rel_pos_starboard,2) + " m/s " at (20,8).
    print "Rel Spd:" at (10,10).
    print "FORE: " + round(rel_spd_fore,2) + " m/s " at (20,10).
    print " TOP: " + round(rel_spd_top,2) + " m/s " at (20,11).
    print "STAR: " + round(rel_spd_star,2) + " m/s " at (20,12).
    print "Want Spd: " at (10,14).
    print "FORE: " + "(Not calculated) " + " m/s " at (20,14).
    print " TOP: " + round(top_want_speed,2) + " m/s " at (20,15).
    print "STAR: " + round(starboard_want_speed,2) + " m/s " at (20,16).
    print "Controls: " at (10,18).
    print "FORE: " + round(ship:control:fore,2) + " m/s " at (20,18).
    print " TOP: " + round(ship:control:top,2) + " m/s " at (20,19).
    print "STAR: " + round(ship:control:starboard,2) + " m/s " at (20,20).
  }

  print "Port magnetism taking over. Letting go of controls.".
  unlock steering.
  set ship:control:neutralize to true.
  set RCS to old_rcs_value.

  until from_port:STATE = "Docked (docker)" or
  from_port:STATE = "Docked (dockee)" or
  from_port:STATE = "Docked (same vessel)" {
    print "Waiting for dock.".
    wait 1.
  }
  print "Docked!".
}

function wanted_approach_speed {
  parameter rel_pos_vector.

  local dist is - vdot(rel_pos_vector,ship:facing:forevector).
  local spd is min(0.1 + dist*(0.05), 10).
  return spd.
}
