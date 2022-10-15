run once "/lib/sanity".
run once "stager".
run once "/lib/ro".

global global_min_throt is 0.001.

function countdown {
  parameter count.

  // when we are using a countdown -let's sanity check for
  // launch conditions:
  sane_upward().

  sane_avionics().

  from { local i is count. } until i = 0 step { set i to i - 1. } do {
    hudtext( "T minus " + i + "s" , 1, 1, 25, white, true).
    wait 1.
  }
}

local target_eta_spd is 0.
local target_eta_apo is 0.
local vertoff_allow is CHOOSE 0.15 if body:atm:exists else 0.3.
local payload_cut_pe is 0.
local payload_cut_yet is false.
local roll_angle is 180.

function launch {
  parameter
    dest_compass, // not exactly right when not 90.
    dest_pe, // first destination apoapsis.
    do_circ is true,
    eta_apo is 120,
    eta_spd is 1500,
    TWR_for_launch is 1.2,
    solid_thrust is 0,
    second_dest_ap is -1, // second destination apoapsis.
    second_dest_long is -1, // second destination longitude.
    atmo_end is ship:body:atm:height,
    goto_bod is "",
    bod_pe is -1,
    kick_limit is 40,
    ignitions is 2,
    use_ag1 is false,
    set_roll is false.

  clearscreen. for x in range (0,10) print " ".

  if second_dest_ap < 0 { set second_dest_ap to dest_pe. }

  if body:atm:exists {
    set payload_cut_pe to body:atm:height/3.0. // cutoff at 1/3 of atmo so KSP will delete it.
  } else {
    set payload_cut_pe to 0.
  }
  set payload_cut_yet to false.

  set roll_angle to set_roll.

  local dest_sma is (body:radius*2 + dest_pe + second_dest_ap)/2.
  local dest_rad is ship:body:radius + dest_pe.
  local dest_spd is sqrt( body:mu*(2/dest_rad - 1/dest_sma) ).
  local min_throt is global_min_throt.
  local coast_circular is false.
  local maintain_ap_mode is false.

  local full_thrust_over is false.
  set target_eta_apo to eta_apo.
  set target_eta_spd to eta_spd.
  local circ_speed is sqrt(ship:body:mu / (dest_pe+ship:body:radius)).
  local kick_speed is circ_speed / 25.
  // if not(ship:body:atm:exists) {
  //   set kick_speed to kick_speed/2. // need to go a up bit first not *as* important in vacuum.
  // }

  sane_upward().
  sane_avionics().

  print "Staging until there is an active engine".
  lock throttle to 0.
  local actives is all_active_engines().
  until actives:length > 0 {
    wait until stage:ready.
    stage.
    set actives to all_active_engines().
  }
  print "Now there is an active engine".
  SAS OFF.
  print "SAS TURNED OFF. kOS is steering.".

  print "Waiting for engine TWR > " + TWR_for_launch.
  lock_throt_for_launch().
  local g is body:mu / (body:radius+altitude)^2.
  local twr_measured is 0.
  until twr_measured > TWR_for_launch {
    set twr_measured to (solid_thrust + current_thrust(actives)) / (mass_no_clamps() * g).
    print "TWR " + round(twr_measured,2) + ". Type G to Go Anyway, A to Abort.".
    wait 0.
    if terminal:input:haschar() { 
      local ch is terminal:input:getchar().
      if ch = "g" break.
      if ch = "a" {
        lock throttle to 0. set ship:control:pilotmainthrottle to 0. print "done. " + (1/0).
      }
    }
  }
  print "Now TWR is > " + TWR_for_launch.

  // Test to see if it's really accelerating up.  If not then keep staging
  // until we are (assumes launch clamps is the reason we're not.)
  print "Staging until accelerating up.".
  local consistently_up is false.
  wait 0.5. // get around buggy landing legs that "stick" for a moment.
  local tPrev is time:seconds.
  local vPrev is verticalspeed.
  until consistently_up {
    // Prove it's actually acellerating upward and not just
    // oscillating on springy launch clamps on the pad:
    set consistently_up to true.
    for measures in range(0,4) {
      wait 0.2.
      local tNow is time:seconds.
      local vNow is verticalspeed. // use vertical-only speed so sideways shaking gets ignored.
      local acc_measured is (vNow - vPrev) / (tNow - tPrev).
      print "  measured vertical accel = "+round(acc_measured,3)+" m/s^2".
      set tPrev to tNow.
      set vPrev to vNow.
      if acc_measured <= 0 {
        set consistently_up to false.
      }
    }
    if not(consistently_up) { 
      print "   Not consistently accelerating up,".
      print "     so, assuming launch clamp needs staging.".
      stage. 
    }
  }

  print "We are now moving.".
  local TWR_avail is AVAILABLETHRUST/(MASS*g).
  set kick_speed to kick_speed / (2*TWR_avail).
  lock steering to lookdirup(heading(dest_compass, 89.9):forevector, roll_vector()).
  print "Waiting for speed over " + round(kick_speed,1) + " m/s to start kick.".
  until ship:velocity:surface:mag > kick_speed {
    info_block().
    wait 0.
  }


  print "Starting kickover toward " + dest_compass + " degree heading".

  // To aim roof at ground, I'm aiming at opposite compass, with pitch > 90 to pitch the roof on its back:
  local slow_kick_amount is 1.
  until slow_kick_amount = 10 {
    set TWR_avail to AVAILABLETHRUST/(MASS*g).
    lock clamp_pitch_down to min(kick_limit-5, max(0.5, slow_kick_amount*TWR_avail)).
    lock steering to lookdirup(heading(dest_compass, 85-clamp_pitch_down):forevector, roll_vector()).
    // kick over more slowly when there's atmosphere:
    if atmo_end = 0 
      wait 0.1.
    else 
      wait 1. 
    set slow_kick_amount to slow_kick_amount+1.
    print "TWR=" + TWR_avail + " steerpitch= " + (85-clamp_pitch_down).
  }
 
  print "Waiting for prograde to match steering close enough.".
  local heading_err is 999.
  local remember_min_throt is min_throt.
  local off_vert is 999.
  local off_vec is v(1,0,0).
  local remember_compass is dest_compass.
  // It's more okay to be off vertically than horizontally here, thus the two different check values:
  // Note they're not using the same system.  off_vert and heading_err are measured in degrees.
  // proportions of a unit vector:
  until abs(heading_err) < 0.5 and off_vert < 10 {
    local srf_vel_unit is ship:velocity:surface:normalized.
    set off_vec to steering:forevector:normalized - srf_vel_unit.
    local lower is vdot(ship:up:vector, off_vec) > 0. //true if error is off in the "too low" direction.
    set off_vert to vang(steering:forevector:normalized, srf_vel_unit).
    // dummy check for if it's near enough to be in tolerance, but in the wrong direction past the up vector:
    local steer_project is vxcl(ship:up:vector, steering:forevector:normalized). // steering projected to flat plane.
    local vel_project is vxcl(ship:up:vector, ship:velocity:surface:normalized). // velocity projected to flat plane.
    local remember_heading is heading(remember_compass,0).
    set heading_err to vang(remember_heading:vector,vel_project).
    local desired_starboard is remember_heading:starvector.
    if vdot(desired_starboard, vel_project - remember_heading:vector) < 0 {
      set heading_err to -heading_err.
    }
    // Give a sign to the off vertical angle:
    if lower
      set off_vert to -off_vert.
    // Next line will aim a bit left or right of desired heading if it starts off
    // really far off - which only happens when launching on low grav moons from a
    // badly tllted terrain angle:
    // clamped to +/-45 deg so it doesn't circle round the compass to the wrong way.
    set dest_compass to remember_compass - max(-45,min(45,2*heading_err)).

    // Prevent throttle from being too weak while we're trying to force heading to change:
    local g is body:mu / (body:radius+altitude)^2.
    local twr is ship:availablethrust / (g*ship:mass).
    set min_throt to 3 / max(twr, 0.01).

    info_block().
    do_keys().
    print "--- Off Horiz deg = " + round(heading_err,2) + ", Off Vert deg = " + round(off_vert,3) + " ---" at (0,30).
    wait 0.
  }
  set dest_compass to remember_compass.
  set min_throt to remember_min_throt.

  // Kick has started, initial direction has started, so now just follow prograde as-is and
  // adjust pitch and throttle by ETA:apoapsis.

  print "Letting heading go where it wants.  Adjusting only pitch and throttle by ETA Apoapsis.".
  local want_pitch_off is 0.
  lock steering to lookdirup(which_vel():normalized + clamp_abs((wanted_eta_apo(coast_circular,dest_spd)-signed_eta_ap())*0.5/wanted_eta_apo(coast_circular,dest_spd),vertoff_allow)*ship:up:vector, roll_vector()).

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
  local still_must_thrust is true.
  local throttle_was_zero is false.
  local allow_stager is true.
  local msg1_happened is false.
  local msg2_happened is false.
  local msg3_happened is false.
  local msg4_cooldownstamp is 0.
  lock_throt_for_launch().

  until done {
    wait 0. // make sure recent throttle changes take effect before checking thrust for staging.
    // Stager logic - if no thrust, stage until there is:
    if allow_stager and stager(engs, false) {
      wait 0.2.
      until ship:availablethrustat(0) > 0 {
        wait 0.2.
        push_rcs_until_ullage_ok(engs, 10, true).
        stager(engs, false).
        lock_throt_for_launch().
      }
      lock_throt_for_launch().
    }

    if throttle = 0 {
      set throttle_was_zero to true.
    }

    if still_must_thrust {
      if apoapsis > second_dest_ap or apoapsis < 0 {
        if altitude > atmo_end {
          if allow_zero and engines_last_ignition() {
            if time:seconds > msg4_cooldownstamp {
              hudtext("Not coasting to AP on an engine that can't be re-ignited.",5,2,20, yellow, true).
              set msg4_cooldownstamp to time:seconds + 10.
              // Don't try to stage while we're suppressing the coast, as that would consume limited
              // ignitions in RealFuels engines pointlessly:
              set allow_stager to false.
            }
          } else {
            set allow_stager to true.
            set maintain_ap_mode to false.
            set still_must_thrust to false.
            if allow_zero {
              set coast_circular to true.
              if not(throttle_was_zero) {
                set min_throt to 0.

                do_fairings().

                // Wait 10s, but allow that wait to prematurely stop if near ap:
                local wait_start is time:seconds.
                wait until time:seconds > wait_start + 10 or eta:apoapsis < 15.
                
                print "Start mild time warp coast to Ap.".
                set kuniverse:timewarp:mode to "rails".
                set kuniverse:timewarp:rate to 10. // whatever rate gives you 10x warp.
              }
            }
          } 
        } else {
          set maintain_ap_mode to true.
          set min_throt to global_min_throt.
          do_fairings().
        }
      } else if altitude > atmo_end { // out of atmo on an atmo world, yet apoapsis still not high enough.
        if atmo_end > 0 and apoapsis < 0.8*second_dest_ap and min_throt < 0.5 {
          set min_throt to 0.5. // force it to keep thrusting a lot.
          if not(msg2_happened) {
            hudtext("Escaped Atmo but Ap still way too low - upping throttle.",8,2,20, green, true).
            set msg2_happened to true.
          }
        } else if
            ship:velocity:surface:mag > 5 and // don't trigger when not really taken off yet.
            apoapsis < dest_pe and
            vang(ship:velocity:surface:normalized, ship:up:vector) > 85 {
          set min_throt to 0.5. // force it to keep thrusting a lot.
          if not(msg1_happened) {
            hudtext("Aiming horizontally so keeping throt low for ETA is dumb, forcing throttle up.", 8, 2, 20, green, true).
            set msg1_happened to true.
          }
        }
      } else if periapsis > 0 and apoapsis < atmo_end {
        set min_throt to max(min_throt,0.2).
        if not(msg3_happened) {
          hudtext("Trying to circularize inside atmospere.  Forcing throttle up.", 8, 2, 20, green, true).
          set msg3_happened to true.
        }
      }
    }

    // Once the throttle was coasting and turns back on again,
    // from then on we want to keep it on to circularize, not
    // try to circularize in little spurts that consume lots of
    // ignitions:
    if throttle_was_zero and throttle > 0 {
      if kuniverse:timewarp:mode = "RAILS" set warp to 0. // come off rails to let the engine work:
      wait until kuniverse:timewarp:issettled. // let it finish de-warping.
      if min_throt = 0 {
        local ull_engs is all_active_engines().
        push_rcs_until_ullage_ok(ull_engs, 10, true).
        set min_throt to global_min_throt.
      } else {
        set min_throt to global_min_throt. // perfectly circular isn't important, so still keep at least 10% to prevent boredom waiting for circularizing.
      }
    }

    if coast_circular {
      if periapsis >= dest_pe {
        hudtext("Pe above requested, so done now.", 8, 2, 20, green, true).
        set done to true.
      }
      else if periapsis > atmo_end and (ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270) {
        if apoapsis >= second_dest_ap and kuniverse:timewarp:mode <> "RAILS" {
          hudtext("Ap high enough and now closer to Pe than Ap, so stopping.", 8, 2, 20, green, true).
          set done to true.
        }
      }
    }
    else if periapsis > dest_pe and apoapsis >= second_dest_ap {
      hudtext("Launch Script Over because periapsis > " + dest_pe + ".", 8, 2, 20, green, true).
      set done to true.
    } else if ignitions = 1 and apoapsis > dest_pe * 1.2 and signed_eta_pe() > -20 and signed_eta_pe() < 20 and apoapsis >= second_dest_ap {
      hudtext("Launch Script Over we are at Pe and cannot raise it.", 8, 2, 20, yellow, true).
      hudtext("You probably need to correct this orbit.", 10, 2, 20, rgb(1,0.5,0), true).
      set done to true.
    } else if goto_bod <> "" and orbit:hasnextpatch and orbit:nextpatch:body:name = goto_bod {
      
      // Need to do this check as a fast trigger because an unthrottle-able
      // engine will blow past the sweet spot in like one loop iteration
      // unless IPU is super high:
      print "Encounter with " + goto_bod + "happening - waiting for Pe="+bod_pe.
      when orbit:nextpatch:periapsis < bod_pe then {
        print "pe now = "+ orbit:nextpatch:periapsis +" so ending.".
        lock throttle to 0.
        wait 0. // force throttle to have an effect right away.
        set allow_zero to true.
        set min_throt to 0.
        set done to true.
      }
    }
    
    if verticalspeed < -5 and still_must_thrust {
      abort on.
      hudtext("INVOKING ABORT ACTION!!! BECAUSE FALLING.", 15, 2, 30, red, true).
      set done to true.
    }
    if periapsis >= payload_cut_pe {
      // If Pe >= payload cutoff point, and some parts are
      // still attached to the ship with the "payload cutoff"
      // tag, then stage until that's not true anymore:
      if not(payload_cut_yet) {
	local cut_parts_list is ship:partstagged("payload cutoff"). // expensive walk - don't do it too much.
	if cut_parts_list:length > 0 {
	  if allow_zero
            lock throttle to 0. // suppress while staging parts.
	  wait 1.
	  until cut_parts_list:length = 0 {
	    hudtext("Pe above " + round(payload_cut_pe) + "m.  Decoupling until payload cutoff parts gone", 6, 2, 20, green, true).
	    wait until stage:ready.
	    stage.
	    set cut_parts_list to ship:partstagged("payload cutoff"). // expensive walk - don't do it too much.
	  }
          if allow_zero // put it back now that staging is done.
            lock_throt_for_launch().
	}
	set payload_cut_yet to true.
      }
    }

    info_block(coast_circular).
    do_keys().
  }

  wait 0.
  lock throttle to 0.
  set ship:control:pilotmainthrottle to 0.
  unlock steering.
  wait 0.

  deploy_launch_done_code().
  print "DONE".

  // This command gets re-run every time we temporarily suppressed
  // throttle then need to set it back again:
  function lock_throt_for_launch {
      lock throttle to throttle_func(coast_circular, min_throt, dest_spd, dest_pe, maintain_ap_mode).
      // RP-1's avionics throttle lockout rule locks out autopilot ignition when
      // it should be only locking throttle variation.  This gets around it by using
      // user throttle instead of autopilot throttle to igninte engines:
      set ship:control:pilotmainthrottle to throttle.
  }

  function roll_vector {
    return 
      choose up:vector if (roll_angle = 0) else
        choose north:vector if (roll_angle = 90) else
          choose -up:vector if (roll_angle = 0) else
            facing:topvector. // dont-care.
  }

  // Print some useful info in a block during this function:
  function info_block {
    parameter coast_circular is false.
    print " ================================================" at (0,0).
    print "| CURRENT | APO:          m  ETA:      s | Max   |" at (0,1).
    print "|         | PER:          m              | Voff  |" at (0,2).
    print "|         | SPD:          m/s            | (V,v) |" at (0,3).
    print "|         |                              |       |" at (0,4).
    print "| ---------------------------------------|       |" at (0,5).
    print "| WANTED  | APO:          m  ETA:      s | Min   |" at (0,6).
    print "|         | PER:          m              | Throt |" at (0,7).
    print "|         | SPD:          m/s            | (T,t) |" at (0,8).
    print "|         |                              |       |" at (0,9).
    print " ================================================" at (0,10).
    print "      " at (17,1).
    print round(apoapsis) at (17,1).
    print "      " at (33,1).
    print round(signed_eta_ap,1) at (34,1).
    print "        " at (17,2).
    print round(periapsis) at (17,2).
    print "       " at (17,3).
    print round(which_vel():mag) at (17,3).
    print "      " at (17,6).
    print second_dest_ap at (17,6).
    print "      " at (34,6).
    print round(wanted_eta_apo(coast_circular,dest_spd),1) at (34,6).
    print "      " at (17,7).
    print dest_pe at (17,7).
    print "      " at (17,8).
    print round(dest_spd) at (17,8).
    print "    " at (43,4).
    print round(vertoff_allow,2) at (43,4).
    print "     " at (43,9).
    print round(global_min_throt,3) at (43,9).
  }

  // Terminal input keys can change some parameters:
  function do_keys {
    local global_min_t_inc is choose 0.05 if global_min_throt >= 0.05 else 0.01.
    if not(terminal:input:haschar())
      return.
    local ch is terminal:input:getchar().
    // must use unchar to get case-sensitive checks.
    if unchar(ch) = unchar("V") {
      set vertoff_allow to vertoff_allow + 0.01.
    } else if unchar(ch) = unchar("v") {
      set vertoff_allow to max(vertoff_allow - 0.01, 0).
    } else if unchar(ch) = unchar("T") {
      set global_min_throt to global_min_throt + global_min_t_inc.
      if min_throt < global_min_throt
        set min_throt to global_min_throt.
      lock_throt_for_launch().
    } else if unchar(ch) = unchar("t") {
      set global_min_throt to global_min_throt - global_min_t_inc.
      if min_throt > global_min_throt
        set min_throt to global_min_throt.
      lock_throt_for_launch().
    }
  }

}

function deploy_launch_done_code {
  local done_parts is ship:partstaggedpattern("^done:.*").
  if done_parts:length > 0 {
    print "Running done: tags from ship:".
    if exists("tmp_do_this.ks")
      deletepath("tnp_do_this.ks").
    for p in done_parts {
      local cmd is p:tag:remove(0,5) + ".".
      log cmd to "tmp_do_this.ks".
      print "cmd: " + cmd.
    }
    runpath("tmp_do_this.ks").
  }
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
  parameter
    coast_circular is false, // true if we are in the part where we're coasting to circularize
    dest_spd is 2280.

  if coast_circular {
    // IF we assume an upper stage typically has an accelleration of about 0.5 g's,
    // this is how much time is half the time to make orbital speed:
    local rad is altitude + body:radius.
    local g is body:mu / (rad*rad).
    local dV is (dest_spd - velocity:orbit:mag).
    return 0.25 * dV / g.
  } else {
    local formula_eta is target_eta_apo * ship:velocity:surface:mag / target_eta_spd. 
    local min_wanted is target_eta_apo/4.
    local max_wanted is target_eta_apo.
    // Allow higher eta:apo if there's a danger of circularizing inside the atmo:
    if apoapsis < ship:body:atm:height and ship:velocity:orbit:mag > dest_spd*2/3 {
      set max_wanted to max_wanted*5.
    }
    return max(min(max_wanted, formula_eta), min_wanted).
  }
}

function throttle_func {
  parameter
    coast_circular is false, // true if we are in the part where we're coasting or circularizing
    min_throt is 0.001,
    dest_spd is 2280,
    dest_ap is 80000,
    just_maintain_ap is false.


  // TODO: make this a PID?  Right now it's P-only:
  if just_maintain_ap {
    local throt is (dest_ap - apoapsis)/2000. // 100% throttle if 2km off - scale linearly from there.
    return max(throt,min_throt).
  } else {
    local wanted is wanted_eta_apo(coast_circular,dest_spd).
    local throt is 0.5+(wanted-signed_eta_ap())*5/wanted.
    return max(throt, min_throt).
  }
}

// Returns a signed ETA:apoapsis - in other words if
// Apo has just been passed it will return a negative number
// of seconds since Apo, rather than a large positive number
// far in the future like it normally does:
function signed_eta_ap {
  if apoapsis < 1 { // hyperbolic
    return 9999999999. // bignum not quite infinity.
  }
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
  if apoapsis < 1 { // hyperbolic
    return 9999999999. // bignum not quite infinity.
  }
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

// Deploy all fairings in ths list of partmodules given.
function do_fairings {
  parameter use_ag1 is false.

  // Get all the fairings on the ship except ones tagged "manual":
  local all_fairings is ship:modulesnamed("ModuleProceduralFairing").
  local f_list is LIST().
  for f_mod in all_fairings {
    if f_mod:hasevent("deploy") {
      if f_mod:part:tag:contains("manual") {
        print "Will *NOT* Deploy fairing part: " + f_mod:part:name.
      } else {
        f_list:add(f_mod).
      }
    }
  }
  if f_list:length > 0 {
    print f_list:length + " Part(s) needing fairing deployment found.".
    print "Will engage fairings at high altitude.".
  }


  if f_list:length > 0 {
    for fairing in f_list {
      if fairing:part:ship = ship { // skip if the fairing part decoupled away and is now on a new vessel
        if fairing:hasevent("deploy") {
          print "!!Deploying a fairing part!!".
          fairing:doevent("deploy").
        }
      }
    }
    f_list:clear(). // so it won't trigger again.
  }

  if use_ag1 {
    wait 0. //It complains about deploying stuff in fairing unless time passes after separation.
    toggle AG1.
  }
}

function circularize {
  print "Circularizing.".
  lock steering to heading(compass_of_vel(ship:velocity:orbit), -(signed_eta_ap()/3)).
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
