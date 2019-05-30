// routines for docking

// I can't thrust less than this anyway,
// so I have to account for that.
local rcs_null_zone is 0.05.

local mode is "Evade".


local wanted_spd_last_val is 0.

// This handles only the docking translation, and assumes
// you've already done a LOCK STEERING to the right direction
// to align to the target:
function do_dock {
  parameter from_part, to_part.
  local from_part_module is 0.

  local original_length is ship:parts:length.

  wait 0.

  if not from_part:istype("Part") {
    print "Source 'from part' needs to be a part.  Plese fix that.".
    return.
  }
  if from_part:istype("DockingPort") {
    from_part:controlfrom().
  } else {
    print "Source 'from part' is not a port.  Using its normal facing.".
  }

  // If terminal is too small, enlarge it.  Leave it alone if big enough already:
  set terminal:width to MAX(40, terminal:width).
  set terminal:height to MAX(30, terminal:height).

  SAS off.
  until abs(steeringmanager:angleerror) < 1 and abs(steeringmanager:rollerror) < 1 {
    print "Waiting for orientation to match direction of the port.".
    wait 2.
  }
  clearscreen.
  print "Approaching port".
  local old_rcs_value is RCS.
  RCS on.

  local fore_control_pid         is PIDLoop( 4, 0.05, 0.5, -1, 1 ).
  local top_want_speed_pid       is PIDLoop( 0.1, 0.0, 0.05, -2, 2 ).
  local top_control_pid          is PIDLoop( 1, 0.0, 0.2, -1, 1 ).
  local starboard_want_speed_pid is PIDLoop( 0.1, 0.0, 0.05, -2, 2 ).
  local starboard_control_pid    is PIDLoop( 1, 0.0, 0.2, -1, 1 ).

  // These track the total accumulation of thrusting that has failed to
  // happen because the RCS nullzone suppressed it.  When they accumulate
  // enough, then it will be time to briefly thrust at nullzone minimum:
  local null_deficit_fore is 0.
  local null_deficit_top is 0.
  local null_deficit_starboard is 0.

  lock steering to lookdirup( -get_facing(to_part):vector, get_facing(to_part):topvector).
  local steering_locked is true.

  // Track when the part count goes up: if it goes up that must mean the two ships
  // have merged, right?

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
    local angle_from_port is vang(get_facing(to_part):vector, rel_port_pos).
    // ^^^ All relevant readings have been taken now.  After this point it's safe to have tick interruptions:

    local rel_spd_fore is vdot(foreUnit, rel_spd).
    local rel_spd_top is vdot(topUnit, rel_spd).
    local rel_spd_star is vdot(starUnit, rel_spd).

    local rel_pos_fore is vdot(foreUnit, rel_port_pos).
    local rel_pos_top is vdot(topUnit, rel_port_pos).
    local rel_pos_starboard is vdot(starUnit, rel_port_pos).

    local rcs_requested_fore is 0.
    local rcs_requested_top is 0.
    local rcs_requested_starboard is 0.

    // Change what we want to do depending on if we are on the 
    // correct side of the vessel or not:
    local leftright_dist is abs( vdot( ship:facing:starvector, rel_port_pos ) ).
    if angle_from_port <= 45 {
      set mode to "Approach".
    } else if angle_from_port < 135 and leftright_dist > 50{
      set mode to "Advance".
    } else {
      set mode to "Evade".
    }

    // Note, this drives the forward part of the RCS thrust vector by
    // our relative SPEED, but drives the top and starboard parts of
    // the RCS thrust vector by our relative POSITIONS:
    if get_state(from_part)  = "Ready" { // do NOT do this when the docking magnets are pulling
      if mode = "Approach" {
	set rcs_requested_fore to fore_control_pid:UPDATE( now, (rel_spd_fore - wanted_approach_speed(rel_port_pos,from_part)) ).

	set top_want_speed to top_want_speed_pid:UPDATE( now, rel_pos_top).

	set starboard_want_speed to starboard_want_speed_pid:UPDATE( now, rel_pos_starboard ).
      } else if mode = "Evade" {
	set rcs_requested_fore to fore_control_pid:UPDATE( now, rel_spd_fore ). // try to kill all fore speed - just go sideways.
	set top_want_speed to 0.
	set starboard_want_speed to 2.0.
      } else if mode = "Advance" {
	set rcs_requested_fore to fore_control_pid:UPDATE( now, rel_spd_fore + 2.0 ). // try to move  -1.5 fore.
	set top_want_speed to 0.
	set starboard_want_speed to 0.
      } else {
        PRINT "HUH?  What Mode is this??". // should't happen.
      }
      set rcs_requested_top to top_control_pid:UPDATE( now, rel_spd_top - top_want_speed).
      set rcs_requested_starboard to starboard_control_pid:UPDATE( now, rel_spd_star - starboard_want_speed).
    }

    // Account for the stock RCS null zone of 5% - by accumulating
    // the amount of failed thrust we wanted but couldn't do because the thrust
    // the PID controller asked for was less than the null zone.  Then thrust
    // at barely above null for a moment and zero the accumulation again:
    // ------------------------------------------------------------
    if abs(rcs_requested_fore) > rcs_null_zone {
      set ship:control:fore to rcs_requested_fore.
      set null_deficit_fore to 0.
    }
    else {
      set null_deficit_fore to null_deficit_fore + rcs_requested_fore.
      set ship:control:fore to 0.
      if abs(null_deficit_fore) > rcs_null_zone {
        set ship:control:fore to null_deficit_fore.
	set null_deficit_fore to 0.
      }
    }

    if abs(rcs_requested_top) > rcs_null_zone {
      set ship:control:top to rcs_requested_top.
      set null_deficit_top to 0.
    }
    else {
      set null_deficit_top to null_deficit_top + rcs_requested_top.
      set ship:control:top to 0.
      if abs(null_deficit_top) > rcs_null_zone {
        set ship:control:top to null_deficit_top.
	set null_deficit_top to 0.
      }
    }

    if abs(rcs_requested_starboard) > rcs_null_zone {
      set ship:control:starboard to rcs_requested_starboard.
      set null_deficit_starboard to 0.
    }
    else {
      set null_deficit_starboard to null_deficit_starboard + rcs_requested_starboard.
      set ship:control:starboard to 0.
      if abs(null_deficit_starboard) > rcs_null_zone {
        set ship:control:starboard to null_deficit_starboard.
	set null_deficit_starboard to 0.
      }
    }


    // READOUTS
    // --------
    print "Rel Pos:" at (0,6).
    print "FORE: " + round(rel_pos_fore,2) + " m " at (10,6).
    print " TOP: " + round(rel_pos_top,2) + " m " at (10,7).
    print "STAR: " + round(rel_pos_starboard,2) + " m " at (10,8).
    print "Rel Spd:" at (0,10).
    print "FORE: " + round(rel_spd_fore,2) + " m/s " at (10,10).
    print " TOP: " + round(rel_spd_top,2) + " m/s " at (10,11).
    print "STAR: " + round(rel_spd_star,2) + " m/s " at (10,12).
    print "Want Spd: " at (0,14).
    print "FORE: " + round(wanted_spd_last_val,2) + " m/s " at (10,14).
    print " TOP: " + round(top_want_speed,2) + " m/s " at (10,15).
    print "STAR: " + round(starboard_want_speed,2) + " m/s " at (10,16).
    print "Controls Requested: " at (0,18).
    print "FORE: Request:" + round(100*rcs_requested_fore) + "%  " at (10,19).
    print " TOP: Request:" + round(100*rcs_requested_top) + "%  " at (10,20).
    print "STAR: Request:" + round(100*rcs_requested_starboard) + "%  " at (10,21).
    print "Controls Actual: " at (0,22).
    print "FORE: Actual:" + round(100*ship:control:fore) + "%  " at (10,23).
    print " TOP: Actual:" + round(100*ship:control:top) + "%  " at (10,24).
    print "STAR: Actual:" + round(100*ship:control:starboard) + "%  " at (10,25).
    
    print "MODE: " + mode + " angle_from_port = " +round(angle_from_port,1)+" lr_dist="+round(leftright_dist,0) at (0,27).
    print "Docking port status: " + get_state(from_part) + "       " at (0,29).
    
    if get_state(from_part) = "Acquire" {
      print "PORTS MAGNETICALLY PULLING - RELEASING CONTROL." at (0,30).
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

  print "Docked or near docked. Letting go of controls.".
  unlock steering.
  set ship:control:neutralize to true.
  set RCS to old_rcs_value.

  if from_part:ISTYPE("DOCKINGPORT") {
    until get_state(from_part) = "Docked (docker)" or
    get_state(from_part) = "Docked (dockee)" or
    get_state(from_part) = "Docked (same vessel)" {
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
  parameter rel_pos_vector, from_part.

  local dist is abs(vdot(rel_pos_vector, get_facing(from_part):forevector)).
  local side_dist is vxcl(get_facing(from_part):forevector, rel_pos_vector). // the more side dist there is, the less forward speed we want.
  set dist to dist / max(1,side_dist:mag). // pretend there's less dist, effectively slowing down.
  set wanted_spd_last_val to min(0.1 + dist*(0.05), 5).
  return wanted_spd_last_val.
}
