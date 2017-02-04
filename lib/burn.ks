// Methods to help you do burns.
@LAZYGLOBAL off.

run once consts.
run once stager.
run once "/lib/isp".

// How many seconds will it take to perform the
// given burn (given as a delta V scalar magnitude)
// If we assume all the following:
//   It will all occur using the current active stage.
//   The current mass is the mass it will start with.
//   It's going to be done by the current SHIP.
//   You aren't going to change the thrust limiters from current setting.
//   All engines active right now are the same ISP.
function burn_seconds {
  parameter dv_mag.  // delta V magnitude (scalar)

  // Both force and mass are in 1000x units (kilo-),
  // so the 1000x multiplier cancels out:
  local F is SHIP:AVAILABLETHRUST.  // Force of burn.
  local m0 is SHIP:MASS. // starting mass
  local g0 is 9.802. 
  
  // The ISP of first engine found active:
  // (For more accuracy with multiple differing engines,
  // some kind of weighted average would be needed.)
  local ISP is isp_calc().

  // From rocket equation, and definition of ISP:
  return (g0*ISP*m0/F)*( 1 - e^(-dv_mag/(g0*ISP)) ).
}


// Perform a burn of a given deltaV vector at given utime
// warning: function does not return until burn is done.
function do_burn_with_display {
  parameter
    uTime, // desired universal time to start burn.
    want_dV,  // desired deltaV (as a vector).
    col, // desired location to print message.
    row. // desired location to print message.


  local want_steer is want_dV.
  lock steering to lookdirup(want_steer,ship:up:vector).
  until time:seconds >= uTime {
    print  "Burn Start in " + round(uTime-time:seconds,0) + " seconds  " at (col,row).
    stager().
    local prev_top is ship:facing:topvector.
    local prev_fore is ship:facing:forevector.
    wait 0.01.
  }.
  local start_vel is ship:velocity:orbit.
  local dv_to_go is 9999999.

  // Throttle at max most of the way, but start throttling
  // back when it seems like there's about 1.2 seconds left to thust:
  local avail_accel is ship:availablethrust / ship:mass.
  lock mythrot to min(1, 0.01 + dv_to_go/(1.2*avail_accel)).
  lock throttle to mythrot.

  print  "Burn dV remaining:         m/s" at (col,row).
  local prev_dv_to_go is dv_to_go + 1.
  local dv_burnt is 0.
  local prev_sec is time:seconds.
  local sec is 0.
  until dv_to_go <= 0 or (dv_to_go >= prev_dv_to_go) {
    set prev_dv_to_go to dv_to_go.
    set sec to time:seconds.
    set dv_burnt to dv_burnt + (sec-prev_sec)*(ship:availablethrust*mythrot / ship:mass).
    set prev_sec to sec.
    wait 0.01.
    set dv_to_go to want_dv:mag - dv_burnt.
    print round(dV_to_go,1) + "m/s     " at (col+19,row).
    print "dv_burnt: " + round(dv_burnt,2) + "m/s    " at (col+19,row+1).
    print "mythrot: " + round(mythrot,2) + "    " at (col+19,row+2).
    stager().
    until ship:availablethrust > 0 {
      set prev_dv_to_go to 99999999.
      stager().
    }
  }
  lock mythrot to 0.
  lock throttle to 0.
  unlock steering.
}

// Go into a mode where it will obey all future maneuver nodes you may put in
// it's way:
function obey_node_mode {
  parameter
    quit_condition,  // pass in a delegate that will return boolean true when you want it to end.
    node_edit is "n/a".       // pass in a delegate that will edit precise nodes if called.

  until quit_condition:call() {
    clearscreen.
    print "Type 'P' for precise node editor.".
    if not hasnode {
      hudtext("Waiting for a node to exist...", 10, 2, 30, red, true).
      until hasnode or quit_condition:call() {
        wait 0.
        just_obey_p_check(node_edit).
      }
    }
    hudtext("I See a Node.  Waiting until just before it's supposed to burn.", 5, 2, 30, red, true).

    // The user will be fiddling with the node just after adding it,
    // so this has to keep re-calculating whether or not it's time to 
    // drop from time warp based on the new changes the user is doing:
    local half_burn_length is 0.
    local full_burn_length is 0.
    local dv_mag is 0.
    until (not hasnode) // escape early if the user deleted the node
          or
          (nextnode:eta < 120 + half_burn_length) {
      set dv_mag to nextnode:deltaV:mag.
      set half_burn_length to burn_seconds(dv_mag/ 2).
      set full_burn_length to burn_seconds(dv_mag).
      print "Dv: " + round(dv_mag,2) + " m/s  " at (0,7).
      print "Est Full Dv Burn: " + round(full_burn_length,1) + " s  " at (0,8).
      print "Est Half Dv Burn: " + round(half_burn_length,1) + " s  " at (0,9).
      just_obey_p_check(node_edit).
      wait 0.2. // Don't re-calculate burn_seconds() more often than needed.
    }
    if hasnode { // just in case the user deleted the node - don't want to crash.
      set warp to 0.
      hudtext("Execution of node now set in stone.", 5, 2, 30, red, true).
      wait 0.
      local n is nextnode.
      local utime is time:seconds + n:eta - half_burn_length.
      do_burn_with_display(utime, n:deltav, 5, 10).
      hudtext("Node done, removing node.", 10, 5, 20, red, true).
      remove(n).
    }
    just_obey_p_check(node_edit).
  }
}
function just_obey_p_check {
  parameter node_edit. // a delegate to call when P is hit.

  if node_edit:istype("Delegate") {
    if terminal:input:haschar {
      if terminal:input:getchar() = "p" {
        node_edit:call().
      }
    }
  }
}
