run once "/lib/sanity".
run once "/lib/burn". // for predicting circularization burn time.
run once "stager".
run once "/lib/ro".

function countdown {
  parameter count.

  // when we are using a countdown -let's sanity check for
  // launch conditions:
  sane_upward().

  from { local i is count. } until i = 0 step { set i to i - 1. } do {
    hudtext( "T minus " + i + "s" , 1, 1, 25, white, true).
    wait 1.
  }
}

local target_eta_spd is 0.
local target_eta_apo is 0.

function launch {
  parameter dest_compass. // not exactly right when not 90.
  parameter dest_pe. // first destination apoapsis.
  parameter do_circ is true.
  parameter eta_apo is 120.
  parameter eta_spd is 1500.
  parameter TWR_for_launch is 1.2.
  parameter solid_thrust is 0.
  parameter second_dest_ap is -1. // second destination apoapsis.
  parameter second_dest_long is -1. // second destination longitude.
  parameter atmo_end is ship:body:atm:height.
  parameter ignitions is 2.

 
  if second_dest_ap < 0 { set second_dest_ap to dest_pe. }


  local full_thrust_over is false.
  set target_eta_apo to eta_apo.
  set target_eta_spd to eta_spd.
  local circ_speed is sqrt(ship:body:mu / (dest_pe+ship:body:radius)).
  local kick_speed is circ_speed / 25.
  if not(ship:body:atm:exists) {
    set kick_speed to kick_speed / 3. // not much need for kick when launching without air.
  }

  local all_fairings is ship:modulesnamed("ModuleProceduralFairing").
  local fairings is LIST().
  for f_mod in all_fairings {
    if f_mod:hasevent("deploy") {
      if f_mod:part:tag:contains("manual") {
        print "Will *NOT* Deploy fairing part: " + f_mod:part:name.
      } else {
        fairings:add(f_mod).
      }
    }
  }
  if fairings:length > 0 {
    print fairings:length + " Part(s) needing fairing deployment found.".
    print "Will engage fairings at high altitude.".
  }

  sane_upward().

  print "Staging until there is an active engine".
  local actives is LIST().
  lock throttle to 0.
  until actives:length > 0 {
    stage.
    wait 1.
    set actives to all_active_engines().
  }
  print "Now there is an active engine".

  print "Waiting for engine TWR > " + TWR_for_launch.
  lock throttle to 1.
  local g is body:mu / (body:radius+altitude)^2.
  local twr_measured is 0.
  until twr_measured > TWR_for_launch {
    set twr_measured to (solid_thrust + current_thrust(actives)) / (ship:mass * g).
    print "TWR " + round(twr_measured,2). // maybe eraseme and make into a readout?
    wait 0.
  }
  print "Now TWR is > " + TWR_for_launch.

  print "Staging until accel > " + round((TWR_for_launch - 1) / 0.8,0.2) + " m/s^2:".
  local tPrev is time:seconds.
  local vPrev is verticalspeed.
  local acc_measured is 0.
  local acc_threshold is (TWR_for_launch - 1) * 0.8.
  until acc_measured > acc_threshold {
    wait 0.5.
    local tNow is time:seconds.
    local vNow is verticalspeed. // use vertical-only speed so sideways shaking doesn't give false positives.
    set acc_measured to (vNow - vPrev) / (tNow - tPrev).
    set tPrev to tNow.
    set vPrev to vNow.
    if acc_measured < acc_threshold { 
      stage. 
    }
    print "Accel now " + round(acc_measured,3) + " m/s^2".
  }

  print "We are now moving.".
  lock steering to lookdirup(heading(dest_compass, 89.9):forevector, -ship:up:vector).
  print "Waiting for speed over " + kick_speed + " m/s to start kick.".
  until ship:velocity:surface:mag > kick_speed {
    info_block().
    wait 0.
  }


  print "Starting kickover toward " + dest_compass + " degree heading".

  // To aim roof at ground, I'm aiming at opposite compass, with pitch > 90 to pitch the roof on its back:
  lock steering to lookdirup(heading(dest_compass, 80):forevector, -ship:up:vector).
  wait 0.5.
 
  print "Waiting for prograde to match steering within 2 degreees.".
  until vang(steering:forevector, ship:velocity:surface) < 2 {
    info_block().
    wait 0.
  }

  // Kick has started, initial direction has started, so now just follow prograde as-is and
  // adjust pitch and throttle by ETA:apoapsis.

  print "Letting heading go where it wants.  Adjusting only pitch and throttle by ETA Apoapsis.".
  local want_pitch_off is 0.
  local coast_circular is false.
  lock steering to lookdirup(which_vel():normalized + clamp_abs((wanted_eta_apo(coast_circular)-signed_eta_ap())*0.5/wanted_eta_apo(coast_circular),0.15)*ship:up:vector, -ship:up:vector).
  lock throttle to throttle_func(coast_circular).

  // This was the old steering logic: need something new:
  // local alt_divisor is atmo_end*(6.0/7.0).
  // if atmo_end = 0 {
  //   set alt_divisor to dest_pe / 3.
  // }
  // lock steering to heading(dest_compass, clamp_pitch(90 - 90*(use_alt()/alt_divisor)^(2/5), true)).
  // lock throttle to 1.
  //  
  // // Flip steering to use whatever current prograde heading is once
  // // the ship has been going a while:
  // local launch_start is time:seconds.
  // when time:seconds > launch_start + 30 then {
  //   print "Now aiming at whatever direction velocity already is.".
  //   lock steering to heading(compass_of_vel(ship:velocity:surface), clamp_pitch(90 - 90*(altitude/alt_divisor)^(2/5), true)).
  // }

  local done is false.
  local engs is 0.
  list engines in engs.
  local allow_zero is ignitions > 1. // allow zeroing throttle only if we area allowing multiple ignitions to orbit.
  local still_in_atmo is true.
  local min_throt is 0.01.
  local throttle_was_zero is false.
  until done {

    // Stager logic - if no thrust, stage until there is:
    
    if stager(engs, true) {
      until ship:availablethrustat(0) > 0 {
        local orig_RCS is RCS.
        set ship:control:fore to 1. RCS on. // RCS push if needed.  If not needed then no biggie.
        local actives is all_active_engines().
        wait until ullage_status(actives).
        stager(engs, true).
        set ship:control:fore to 0. lock throttle to throttle_func(coast_circular, min_throt).
        set RCS to orig_RCS.
      }
      lock throttle to throttle_func(coast_circular, min_throt).
    }

    if throttle = 0 {
      set throttle_was_zero to true.
    }

    if still_in_atmo {
      if altitude > atmo_end {
        set still_in_atmo to false.
        if allow_zero {
          set coast_circular to true.
          if not(throttle_was_zero) {
            set min_throt to 0.
            hudtext("Entering coast-to-AP mode.", 8, 2, 20, green, true).
          }
        } 
      }
    }

    // Once the throttle was coasting and turns back on again,
    // from then on we want to keep it on to circularize, not
    // try to circularize in little spurts that consume lots of
    // ignitions:
    if throttle_was_zero and throttle > 0 {
      set min_throt to 0.01.
    }

  // TODO: Incorporate this into it somehow:
  //     if full_thrust_over and low_atmo_pending and ship:Q < 0.003 and ship:altitude > atmo_end/2 {
  //       set low_atmo_pending to false. // Never execute this again.
  //       if full_thrust_over {
  //         print "LOW DYNAMIC PRESSURE AND FULL THROTTLE FINISHED:  Activating AG 1.".
  //         set AG1 to true. wait 0.
  //         if fairings:length > 0 {
  //           for fairing in fairings {
  //             if fairing:hasevent("deploy") {
  //               print "!!Deploying a fairing part!!".
  //               fairing:doevent("deploy").
  //             }
  //           }
  //           set fairings to LIST().  // Make it empty so it won't re-trigger this.
  //         }
  //       }
  // 

    if coast_circular {
      if periapsis > atmo_end and (ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270) {
        hudtext("Now closer to Pe than Ap, so stopping.", 8, 2, 20, green, true).
        set done to true.
      }
    }
    else if periapsis > dest_pe {
      hudtext("Launch Script Over because periapsis > " + dest_pe + ".", 8, 2, 20, green, true).
      set done to true.
    } else if apoapsis > dest_pe * 1.2 and signed_eta_pe() > -20 and signed_eta_pe() < 20 {
      hudtext("Launch Script Over we are at Pe and cannot raise it.", 8, 2, 20, yellow, true).
      hudtext("You probably need to correct this orbit.", 10, 2, 20, rgb(1,0.5,0), true).
      set done to true.
    }
    
    if verticalspeed < -5 and still_in_atmo {
      abort on.
      hudtext("INVOKING ABORT ACTION!!! BECAUSE FALLING.", 15, 2, 30, red, true).
      set done to true.
    }

    info_block(coast_circular).
  }

  lock throttle to 0.  set ship:control:pilotmainthrottle to 0.
  unlock steering.
  wait 0.
  print "DONE".

}

// Return either orbital or surface vel depending on altitude:
function which_vel {
  // switch modes at about 4/7 of atmo height:
  if altitude > body:atm:height * 4 / 7 {
    return ship:velocity:orbit.
  }
  return ship:velocity:surface.
}

// Return the given value as-is, or rounded to zero if the given value's
// magnitude is smaller than the epislon chosen:
function nullzone {
  parameter val, epsilon.
  if abs(val) < epsilon
    return 0.
  return val.
}

// Clamp a value to no higher than a given magnitude, either in + or - direction.
function clamp_abs {
  parameter val, clamp_val.

  if val > clamp_val
    return clamp_val.
  if val < -clamp_val
    return -clamp_val.

  return val.
}

function wanted_eta_apo {
  parameter coast_circular is false. // true if we are in the part where we're coasting to circularize

  if coast_circular {
    return 10.
  } else {
    local formula_eta is target_eta_apo * ship:velocity:surface:mag / target_eta_spd. 
    local min_wanted is target_eta_apo/5.
    local max_wanted is target_eta_apo.
    return max(min(max_wanted, formula_eta), min_wanted).
  }
}

function throttle_func {
  parameter coast_circular is false. // true if we are in the part where we're coasting or circularizing
  parameter min_throt is 0.01.

  // TODO: make this a PID?  Right now it's P-only:
  local wanted is wanted_eta_apo(coast_circular).
  local throt is 0.5+(wanted-signed_eta_ap())*5/wanted.
  return max(throt, min_throt).
}

// Returns a signed ETA:apoapsis - in other words if
// Apo has just been passed it will return a negative number
// of seconds since Apo, rather than a large positive number
// far in the future like it normally does:
function signed_eta_ap {
  local per is ship:obt:period.
  local future_eta is eta:apoapsis.
  local past_eta is future_eta - per.

  if future_eta > per/2
    return past_eta.
  else 
    return future_eta.
}

// Returns a signed ETA:periapsis - in other words if
// Peri has just been passed it will return a negative number
// of seconds since Apo, rather than a large positive number
// far in the future like it normally does:
function signed_eta_pe {
  local per is ship:obt:period.
  local future_eta is eta:periapsis.
  local past_eta is future_eta - per.

  if future_eta > per/2
    return past_eta.
  else 
    return future_eta.
}

// Given an input pitch, return either the same pitch,
// or a pitch that's been "clamped" to not be too far off
// from prograde, based on Q.
local clamp_pitch_cooldown is 0.
function clamp_pitch {
  parameter in_pitch.
  parameter give_msg is false.

  local cur_pitch is srf_pitch_for_vel(ship).
  local max_off_allow is 2.5 / (ship:Q + 0.001).

  local out_pitch is min(max(in_pitch, cur_pitch - max_off_allow), cur_pitch + max_off_allow).

  if give_msg and in_pitch <> out_pitch and time:seconds > clamp_pitch_cooldown {
    hudtext("Q="+round(ship:q,4)+" Pitch clamping: Want="+round(in_pitch,1)+" Allow="+round(out_pitch,1),
            5, 2, 16, yellow, true).
    set clamp_pitch_cooldown to time:seconds + 6.
  }
  return out_pitch.
}

function use_alt {
  local rad_alt is alt:radar.
  if rad_alt > 0 and rad_alt < 2000 
    return rad_alt.
  else
    return altitude.
}

function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}
// Return eta:apoapsis but with times behind you
// rendered as negative numbers in the past:
function eta_ap_with_neg {
  local ret_val is eta:apoapsis.
  if ret_val > ship:obt:period / 2 {
    set ret_val to ret_val - ship:obt:period.
  }
  return ret_val.
}

function compass_of_vel {
  parameter pointing. // ship:velocity:orbit or ship:velocity:surface
  local east is east_for(ship).

  local trig_x is vdot(ship:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}

function srf_pitch_for_vel {
  parameter ves.

  return 90 - vang(ves:up:vector, ves:velocity:surface).
}

// Print some useful info in a block:
function info_block {
  parameter coast_circular is false.
  print "================================" at (0,0).
  print "| APO:         m  ETA:      s  |" at (0,1).
  print "|      WANTED ETA APO:      s  |" at (0,2).
  print "| PER:         m               |" at (0,3).
  print "| SPD:         m/s             |" at (0,4).
  print "================================" at (0,5).
  print "      " at (7,1).
  print round(apoapsis) at (7,1).
  print "      " at (23,1).
  print round(signed_eta_ap,1) at (23,1).
  print "      " at (23,2).
  print round(wanted_eta_apo(coast_circular),1) at (23,2).
  print "        " at (7,3).
  print round(periapsis) at (7,3).
  print "       " at (7,4).
  print round(which_vel():mag) at (7,4).
}

function circularize {
  print "Circularizing.".
  lock steering to heading(compass_of_vel(ship:velocity:orbit), -(eta_ap_with_neg()/3)).
  print "..Waiting for steering to finish locking in place.".
  local vdraw is vecdraw(v(0,0,0), steering:vector*50, white, "waiting to point here", 1, true).
  wait until
    abs(steeringmanager:yawerror) < 2 and
    abs(steeringmanager:pitcherror) < 2 and
    abs(steeringmanager:rollerror) < 2.
  print "..Steering locked.  Now throttling.".
  set vdraw:show to false.

  lock throttle to 0.02 + (30*ship:obt:eccentricity).

  wait until ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270.

  print "Done Circularlizing.".

  unlock steering.
  unlock throttle.
}
