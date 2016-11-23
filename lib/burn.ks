// Methods to help you do burns.
@LAZYGLOBAL off.

run once consts.
run once stager.

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
  local a0 is F/m0. // accel at start of burn.
  
  // Getting ISP of first engine found active:
  local ENGLIST is LIST().
  list ENGINES in ENGLIST.
  local ISP is 0.
  for eng in ENGLIST {
    if eng:ISP > 0 {
      set ISP to eng:ISP.
    }
  }
  if ISP = 0 {
    return 999999999.
  }

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
  // back when it seems like there's about 2 seconds left to thust:
  local avail_accel is ship:availablethrust / ship:mass.
  lock mythrot to min(1, 0.05 + dv_to_go/(avail_accel)).
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
  parameter quit_condition.  // pass in a delegate that will return boolean true when you want it to end.

  until quit_condition:call() {
    clearscreen.
    if not hasnode {
      hudtext("Waiting for a node to exist...", 10, 2, 30, red, true).
      wait until hasnode or quit_condition:call().
    }
    hudtext("I See a Node.  Waiting until just before it's supposed to burn.", 5, 2, 30, red, true).

    // The user will be fiddling with the node just after adding it,
    // so this has to keep re-calculating whether or not it's time to 
    // drop from time warp based on the new changes the user is doing:
    local half_burn_length is 0.
    until (not hasnode) // escape early if the user deleted the node
          or
          (nextnode:eta < 120 + half_burn_length) {
      set half_burn_length to burn_seconds(nextnode:deltaV:mag / 2).
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
  }
}

