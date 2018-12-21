// Perform the intersection and rendezvous burn, presuming
// inclination alignment is already matched.
parameter other. // i.e. target, vessel("name"), or body("name").
parameter skips. // number of steps to skip over.

run once "lib/prediction".
run once "lib/burn".

set ship:control:pilotmainthrottle to 0.

clearscreen.
print " ".
print " ".
print " ".

set intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 0.01).

if skips = 0 {
  if intersect_ta < 0 {
    print "No intersect point in the orbits yet.".
    print "Waiting for periapsis to correct this.".

    wait until eta:periapsis < 20*(warp+1)^1.5.
    set warp to 0.

    // May have to enlarge or shink the orbit:
    if ship:obt:semimajoraxis < other:obt:semimajoraxis {
      sas off.
      lock steering to prograde.
      print "Will enlarge my orbit when at periapsis.".
    } else {
      sas off.
      lock steering to retrograde.
      print "Will shrink my orbit when at periapsis.".
    }

    wait until ship:obt:trueanomaly >= 0 and ship:obt:trueanomaly < 90.

    print "Waiting until steering has settled in.".
    wait until steeringmanager:angleerror < 5.
    print "Burning until there's a crossing point.".
    lock throttle to 1.

    until intersect_ta >= 0 {
      // using cruder, faster approximation for this repeated check:
      set intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 2).
    }.
    unlock throttle.
    unlock steering.
    // Now use the more precise measure once we know it will work:
    set intersect_ta to orbit_cross_ta(ship:obt, other:obt, 10, 0.01).
  }
}

if skips <= 1 {
  set intersect_eta to eta_to_ta(ship:obt, intersect_ta).
  set intersect_first_utime to time:seconds + intersect_eta.

  set ta_offset_from_other to ta_offset(ship:obt, other:obt).
  set other_intersect_ta to intersect_ta + ta_offset_from_other.
  set other_intersect_eta to  eta_to_ta(other:obt, other_intersect_ta).


  print "intersect_ta is " + round(intersect_ta,1) + " deg    ".
  print "    other_ta is " + round(other_intersect_ta,1) + " deg    ".
  print "intersect_eta is " + round(intersect_eta,0) + " seconds   ".
  print "    other_eta is " + round(other_intersect_eta,1) + " seconds   ".

  // Obtain a list of the next 5 utimes that the target will cross
  // the intersect point:
  set rendezvous_utimes to list().
  local i is 0.
  from {local i is 0.} until i = 4 step {set i to i+1.} do {
    rendezvous_utimes:add(time:seconds + other_intersect_eta + other:obt:period*i).
  }

  print "Now waiting until hitting the intersect point.".
  set wait_left to 99999.
  until wait_left <= 0 {
    set wait_left to intersect_first_utime - time:seconds.
    print "Wait " + round(wait_left,0) + " s   " at (5,0).
    if wait_left < 50 {
      if warp > 0 {
        set warp to 0.
      }
      sas off.
      lock steering to prograde.
    }
    wait 0.
  }

  print "Embiggening orbit until matching a rendezvous time.".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  print " ".
  set rendezvous_tolerance_1 to 500. // (seconds).
  set rendezvous_tolerance_2 to 200. // (seconds).
  set rendezvous_tolerance_3 to 50. // (seconds).
  set rendezvous_tolerance_4 to 3. // (seconds).
  set found to false.
  set my_rendezvous_utime to 0. // will calculate later in the loop.
  set num_orbits to 0. // how many orbits until a hit.
  set burn_start_time to time:seconds.
  lock throttle to 1.
  until found {
    wait 0.1.
    local i is 0.
    until found or i = 4 {
      set my_rendezvous_utime to burn_start_time + ship:obt:period * i.
      print "[" + i + "], my ETA = " + utime_to_eta_time(my_rendezvous_utime,1) + "s  " at (2,15+i).
      local j is 0.
      until found or j = 4 {
        local other_rendezvous_utime is rendezvous_utimes[j].
        local time_diff is my_rendezvous_utime - other_rendezvous_utime.
        print "other ETA = " + utime_to_eta_time(other_rendezvous_utime,1)+"s  " at (30,15+j).
        if abs(time_diff) < rendezvous_tolerance_1 {
          lock throttle to 0.2.
        }
        if abs(time_diff) < rendezvous_tolerance_2 {
          lock throttle to 0.05.
        }
        if abs(time_diff) < rendezvous_tolerance_3 {
          lock throttle to 0.005.
        }
        if abs(time_diff) < rendezvous_tolerance_4 {
          lock throttle to 0.
          set found to true.
          set num_orbits to i.
        }
        set j to j+1.
      }
      set i to i+1.
    }
  }

}

if skips <= 2 {

  // Adjust utime a bit to account for how much deltaV burn.
  set other_predict_V to velocityat(other, my_rendezvous_utime):orbit.
  set my_predict_V to velocityat(ship, my_rendezvous_utime):orbit.
  set deltaV to other_predict_V - my_predict_V.
  set my_rendezvous_pre_time to my_rendezvous_utime - burn_seconds(deltaV:mag/2).

  print "Found a matching time within " + num_orbits + " orbit(s)".
  set rendezvous_eta to 99999.
  until rendezvous_eta <= 0 {
    set rendezvous_eta to my_rendezvous_pre_time - time:seconds.
    print "Wait " + round(rendezvous_eta,0) + " s   " at (5,0).
    if rendezvous_eta < 50 {
      if warp > 0 {
        set warp to 0.
      }
      sas off.
      lock steering to other:velocity:orbit - ship:velocity:orbit.
    }
    wait 0.
  }.

  print "Burning until rel vel killed.".

  lock throttle to 1.
  set      rel_spd to -99999.
  // Burn until either hitting zero rel vel, or rel vel starts
  // getting bigger:
  print "rel spd is now        m/s" at (5,0).
  until rel_spd >= 0 {
    print round(rel_spd,1) + "  " at (20,0).
    wait 0.01.
    set rel_spd to VDOT((ship:velocity:orbit - other:velocity:orbit), ship:facing:vector).
  }.
  lock throttle to 0.
  print "Done".
  unlock steering.
}

if skips <= 3 {
  //
  // Now get close.
  //
  print "Now easing closer to target.".

  set maxAccel to ship:maxthrust / ship:mass.

  local mysteer is other:position+(40*ship:north:vector).
  sas off.
  lock steering to mysteer.
  lock rel_vel to ship:velocity:orbit - other:velocity:orbit.
  until other:position:mag < 350 {
    // Push toward until drifting fast enough at other:
    print "... Pushing toward target faster".
    lock mysteerpoint to other:position+(40*ship:north:vector).
    sas off.
    lock steering to mysteerpoint.
    wait until vang(mysteerpoint, ship:facing:forevector) < 2.
    lock throttle to 1/(0.01*maxAccel).
    wait until vdot(rel_vel,mysteerpoint:normalized) > 4+min(30,(mysteerpoint:mag/200)).
    sas off.
    lock steering to mysteer. // put it back to what it was.

    // While drifting, get ready by aiming retro:
    print "... Drifting toward target, aiming retro now".
    lock throttle to 0.
    set mysteer to -rel_vel.
    wait until vang(rel_vel, other:position) > 80.

    // Kill all speed once angle to target > 70 deg from my velocity.
    set mysteer to - rel_vel:vec.
    lock throttle to rel_vel:mag/(0.05+maxAccel).
    print "... Killing relative speed to zero.".

    wait until vdot(mysteer, rel_vel:normalized) > -0.1.
    lock throttle to 0.

    // Repeat the above step until close enough.
  }
}
print "Rendezvous program ending.".

function utime_to_eta_time {
  parameter utime, decimals is 0.

  return round(utime - time:seconds, decimals).
}
