// routines for docking

// This handles only the docking translation, and assumes
// you've already done a LOCK STEERING to the right direction
// to align to the target:
function do_dock {
  parameter from_part, to_part.
  local from_part_module is 0.
  if not from_part:istype("Part") {
    print "Source 'from part' needs to be a part.  Plese fix that.".
    return.
  }
  until abs(steeringmanager:angleerror) < 1 and abs(steeringmanager:rollerror) < 1 {
    print "Waiting for orientation to match direction of the port.".
    wait 2.
  }
  clearscreen.
  print "Approaching port".
  local old_rcs_value is RCS.
  RCS on.

  local fore_control_pid         is PIDLoop( 4, 0.05, 0.5, -1, 1 ).
  local top_want_speed_pid       is PIDLoop( 0.2, 0.0001, 0.03, -4, 4 ).
  local top_control_pid          is PIDLoop( 1, 0.003, 0.2, -1, 1 ).
  local starboard_want_speed_pid is PIDLoop( 0.2, 0.0001, 0.03, -4, 4 ).
  local starboard_control_pid    is PIDLoop( 1, 0.003, 0.2, -1, 1 ).

  lock steering to lookdirup( -get_facing(to_part):vector, get_facing(to_part):topvector).
  local steering_locked is true.

  // Track when the part count goes up: if it goes up that must mean the two ships
  // have merged, right?

  local original_length is ship:parts:length.
  until ship:parts:length > original_length {

    // Make sure to grab all physical world readings right at the
    // start of a physics tick.  All other math can come later and
    // be safely interrupted by a tick boundary, but this stuff can't:
    wait 0.
    local rel_spd is from_part:ship:velocity:orbit - to_part:ship:velocity:orbit.
    local rel_port_pos is from_part:position - to_part:position.
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
    if get_state(from_part)  = "Ready" { // do NOT do this when the docking magnets are pulling
      set ship:control:fore to fore_control_pid:UPDATE( now, (rel_spd_fore - wanted_approach_speed(rel_port_pos)) ).
      set top_want_speed to top_want_speed_pid:UPDATE( now, rel_pos_top).
      set ship:control:top to top_control_pid:UPDATE( now, rel_spd_top - top_want_speed).
      set starboard_want_speed to starboard_want_speed_pid:UPDATE( now, rel_pos_starboard ).
      set ship:control:starboard to starboard_control_pid:UPDATE( now, rel_spd_star - starboard_want_speed).
    }

    print "Rel Pos:" at (10,6).
    print "FORE: " + round(rel_pos_fore,2) + " m " at (20,6).
    print " TOP: " + round(rel_pos_top,2) + " m " at (20,7).
    print "STAR: " + round(rel_pos_starboard,2) + " m " at (20,8).
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
    
    print "Docking port status: " + get_state(from_part) + "       " at (10,22).
    
    if get_state(from_part) = "Acquire" {
      print "PORTS MAGNETICALLY PULLING - RELEASING CONTROL." at (5,23).
      set ship:control:neutralize to true.
      unlock steering.
      set steering_locked to false.
      // stop the integral windup that happens due to "doing nothing" for a while.
      fore_control_pid:RESET().
      top_want_speed_pid:RESET().
      top_control_pid:RESET().
      starboard_want_speed_pid:RESET().
      starboard_control_pid:RESET().
    } else if (not steering_locked) and get_state(from_part) = "Ready" {
      lock steering to lookdirup(- get_facing(to_part):vector, get_facing(to_part):topvector).
      set steering_locked to true.
    }
  }

  print "Port magnetism taking over. Letting go of controls.".
  unlock steering.
  set ship:control:neutralize to true.
  set RCS to old_rcs_value.

  if from_part:ISTYPE("DOCKINGPORT") {
    until from_part:STATE = "Docked (docker)" or
    from_part:STATE = "Docked (dockee)" or
    from_part:STATE = "Docked (same vessel)" {
      print "Waiting for dock.".
      wait 1.
    }
  }
  print "Docked!".
  rcs off.
}

function get_facing {
  parameter a_part.

  if a_part:istype("DOCKINGPORT")
    return a_part:portfacing.
  else
    return a_part:facing.
}

function get_state {
  parameter a_part.

  if a_part:istype("DOCKINGPORT")
    return a_part:state.
  else
    return "Ready". // fake docking port "state" when it's not really a docking port.
}

function wanted_approach_speed {
  parameter rel_pos_vector.

  local dist is - vdot(rel_pos_vector, ship:facing:forevector).
  if dist > 0 {
    local side_dist is vxcl(ship:facing:forevector, rel_pos_vector). // the more side dist there is, the less forward speed we want.
    set dist to dist / max(1,side_dist:mag). // pretend there's less dist, effectively slowing down.
  }
  local spd is min(0.1 + dist*(0.05), 5).
  return spd.
}
