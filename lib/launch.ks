run once "/lib/sanity".

function countdown {
  parameter count.

  // when we are using a countdown -let's sanity check for
  // launch conditions:
  sane_steering().
  sane_upward().

  from { local i is count. } until i = 0 step { set i to i - 1. } do {
    hudtext( "T minus " + i + "s" , 1, 1, 25, white, true).
    wait 1.
  }
}

function launch {
  parameter dest_compass. // not exactly right when not 90.
  parameter first_dest_ap. // first destination apoapsis.
  parameter do_circ is true.
  parameter second_dest_ap is -1. // second destination apoapsis.
  parameter second_dest_long is -1. // second destination longitude.
  parameter atmo_end is ship:body:atm:height.

  if second_dest_ap < 0 { set second_dest_ap to first_dest_ap. }


  local full_thrust_over is false.
  
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

  sane_steering().
  sane_upward().

  // For all atmo launches with fins it helps to teach it that the fins help
  // torque, which it fails to realize:

  local alt_divisor is atmo_end*(6.0/7.0).
  if atmo_end = 0 {
    set alt_divisor to first_dest_ap / 3.
  }
  lock steering to heading(dest_compass, clamp_pitch(90 - 90*(use_alt()/alt_divisor)^(2/5), true)).
  lock throttle to 1.
   
  // Flip steering to use whatever current prograde heading is once
  // the ship has been going a while:
  local launch_start is time:seconds.
  when time:seconds > launch_start + 30 then {
    print "Now aiming at whatever direction velocity already is.".
    lock steering to heading(compass_of_vel(ship:velocity:surface), clamp_pitch(90 - 90*(altitude/alt_divisor)^(2/5), true)).
  }
  // set staging_on to false to effectively remove this trigger:
  global staging_on is true.
  local low_atmo_pending is true.
  when true then {
    if staging_on {
      preserve.
    }
    list engines in englist.
    local flameout is false.
    for eng in englist { if eng:flameout { set flameout to true. } }
    if full_thrust_over and low_atmo_pending and ship:Q < 0.003 and ship:altitude > atmo_end/2 {
      set low_atmo_pending to false. // Never execute this again.
      if full_thrust_over {
        print "LOW DYNAMIC PRESSURE AND FULL THROTTLE FINISHED:  Activating AG 1.".
        set AG1 to true. wait 0.
        if fairings:length > 0 {
          for fairing in fairings {
            if fairing:hasevent("deploy") {
              print "!!Deploying a fairing part!!".
              fairing:doevent("deploy").
            }
          }
          set fairings to LIST().  // Make it empty so it won't re-trigger this.
        }
      }
    } else if stage:ready and // don't bother checking if still in cooldown of prev staging
              (flameout or maxthrust = 0) {
      stage.
      steeringmanager:resetpids().
    }
  }

  wait until ship:apoapsis > first_dest_ap.

  print "Apoapsis now " + first_dest_ap + ".".
  print "Going into low thrust to just maintain Ap.".
  set full_thrust_over to true.
  lock throttle to (first_dest_ap - ship:apoapsis) / 5000.

  wait until ship:altitude > atmo_end.

  // put controls back now that we're out of atmo:
  set steeringmanager:pitchtorquefactor to 1.
  set steeringmanager:yawtorquefactor to 1.

  print "Coasting to Ap.".
  lock throttle to 0.
  lock steering to heading(compass_of_vel(ship:velocity:orbit), 0).

  wait until eta:apoapsis < 10.

  if do_circ {
    circularize().
  } else {
    print "Circularization not requested.".
  }

  lights on.

  if second_dest_long >= 0 {
    lock steering to prograde.
    print "Waiting for second destination burn start longitude.".
    until abs(ship:longitude - second_dest_long) < 1 {
      print "current long = " + round(ship:longitude,3) + ", desired long = " + round(second_dest_long,3) + "    " at (0,0).
      wait 0.001.
    }
    print "Now starting second destination burn.".
    lock throttle to 0.01 + (second_dest_ap - ship:apoapsis) / 5000.
    print "Now waiting for apoapsis to reach " + second_dest_ap.
    wait until ship:apoapsis >= second_dest_ap.
    print "Now re-circularizing at the new apoapsis...".
    circularize().
  }


  set staging_on to false.
  wait 0.01. // make sure there's one run through the trigger to unpreserve it.
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
