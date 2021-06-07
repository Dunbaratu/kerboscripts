// infinitely restartable but does have the ability to
// throttle it down.  Can work with engines with min TWR > 1.0.

run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".
run once "/songs/sad".
run once "/lib/sanity".
run once "/lib/ro".

parameter do_gui is false.
parameter margin is "FIND".
parameter ullage is engine_ullage_secs(). // presumed time to wait for RCS ullage before engine start.
parameter spool is 0. // presumed spool-up time of engines in seconds.
parameter minThrot is engine_minthrot(). // min throttle in RO for the landing engine.
parameter throt_predict_mult is 0.8. // predict landing as if throttle is only this much, for adjustable margin.
parameter land_spot is 0. // set to a geoposition to make it try to aim to land there.
parameter skycrane is false.
parameter upside_down is false.

local aborting is false.
local gui_box is 0.
clearscreen.
if do_gui {
  if not(exists("/lib/land_it_gui.ks")) {
    set do_gui to false.
  } else {
    run once "/lib/land_it_gui.ks".
    set gui_box to create_land_it_gui(
      true, quit_script@, margin, ullage, spool, minThrot, throt_predict_mult, land_spot, skycrane
      ).
    wait until gui_box["COMMIT"]:pressed or aborting.
    set gui_box["COMMIT"]:enabled to false.

    set margin to gui_box["MARGIN"]:text:toscalar().
    set ullage to gui_box["ULLAGE"]:text:toscalar().
    set spool to gui_box["SPOOL"]:text:toscalar().
    set minThrot to gui_box["MINTHROT"]:text:toscalar().
    set throt_predict_mult to gui_box["PREDICTTHROT"]:text:toscalar().
    set skycrane to gui_box["skycrane"]:pressed.
    if gui_box["GEO_ENABLED"]:pressed {
      set land_spot to LATLNG(gui_box["LAT"]:text:toscalar(), gui_box["LNG"]:text:toscalar()).
    } else {
      set land_spot to 0.
    }
  }
}

if land_spot:hassuffix("geoposition") {
  // for any of the types that have a geoposition (vessel, waypoint, etc), use that:
  set land_spot to land_spot:geoposition.
}

// Did script say "find bottom for me?" if so, use
// new BOUNDS from kOS 1.1.9.0 to do it.
if margin:isType("string") or margin = "FIND" {
  local ver is core:version.
  local pass is ver:major >= 2.
  if not(pass) and ver:major >= 1 {
    set pass to ver:minor >= 2.
    if not(pass) and ver:minor >= 1 {
      set pass to ver:patch >= 9.
    }
  }
  if not(pass) {
    HUDTEXT("Needs to be kOS v1.1.9.0 or higher to use 'FIND' parameter.", 15, 2, 20, yellow, false).
  }
  set margin to find_margin().
}


if config:ipu < 800 {
  // BIG WARNING:
  local vv is getvoice(0).
  set vv:volume to 1.
  set vv:wave to "sawtooth".
  set vv:attack to 0.
  set vv:decay to 0.
  set vv:sustain to 1.
  set vv:release to 0.
  set vv:loop to true.
  vv:play(LIST(NOTE(0,0.3), SLIDENOTE(600,700,0.3,0.2),SLIDENOTE(600,700,0.3,0.2),SLIDENOTE(600,700,0.3,0.2))).


  clearscreen.
  print "=== NO NO NO NO NO NO, YOU IDIOT ===".
  print "THIS SCRIPT NEEDS FASTER CALCULATION".
  print "------------------------------------".
  print "You Will DIE if you use this program".
  print "with such a low CONFIG:IPU.".
  print " ".
  print "INCREASE IT TO ABOVE 800 AND I'LL CONTINUE".

  wait until config:ipu > 800.
  set vv:loop to false.
  vv:play(NOTE(0,0.1)). // silence the song.
  wait 0.1. // KSP doesn't calc isp right if you don't do this.
}

if ship:availablethrust <= 0 {
  // BIG WARNING:
  local vv is getvoice(0).
  set vv:volume to 1.
  set vv:wave to "sawtooth".
  set vv:attack to 0.
  set vv:decay to 0.
  set vv:sustain to 1.
  set vv:release to 0.
  set vv:loop to true.
  vv:play(LIST(NOTE(0,0.3), SLIDENOTE(600,700,0.3,0.2),SLIDENOTE(600,700,0.3,0.2),SLIDENOTE(600,700,0.3,0.2))).


  clearscreen.
  print "=== NO NO NO NO NO NO, YOU IDIOT ===".
  print "  THERE ARE NO THRUSTABLE ENGINES!  ".
  print "------------------------------------".
  print "You Will DIE if you use this program".
  print "without any engines that can thrust!".
  print " ".
  print "I WILL CONTINUE IF YOU ACTIVATE AN ENGINE!".

  wait until ship:availablethrust > 0.
  set vv:loop to false.
  vv:play(NOTE(0,0.1)). // silence the song.
  wait 0.1. // KSP doesn't calc isp right if you don't do this.
}

SAS off.
set steeringmanager:maxstoppingtime to 5.
set steeringmanager:pitchpid:Kd to 1.
set steeringmanager:yawpid:Kd to 1.
gear on.

set theColor to rgb(0,0.6,0).
local vd_show_msg_cooldown is time:seconds.
local hasLas is false.
local vd1 is 0.
local vd_off is 0.
local prev_time is time:seconds.
local deltaT is 0.1. // how long an iteration is *actually* taking, measured.
local calced_isp is isp_calc(0). // WARNING: by pre-calcing, this is wrong for atmo situations where it changes.
local mu is ship:body:mu.
local bodRad is ship:body:radius.
local athrust is ship:availablethrust.
local landed is false.
local pos is v(0,0,0).
local eta_end is 9999.
local active_engs is all_active_engines().
local dist is 0.

// Output of throt_pid is a value to add/subtract from the predcited throttle
// in throt_predict_mult:
// The clamp range is not 0 to 1 becasue it's not centered at zero but at throt_predict_mult:
local pid_min is minThrot - throt_predict_mult.  // i.e. if predict = .8, go as low as -0.8 (plus min throt).
local pid_max is pid_min + 1.
local throt_pid is PIDloop(1, 0, 0, pid_min, pid_max).
// output of pitch_pid is a deflection above srfretrograde in degrees.
// Adjust the min/max deflection allowed based on how much leeway our
// throttle gives to correct for burning too low:
local max_pitch_up is arccos(throt_predict_mult)/3.
local max_pitch_down is arccos(throt_predict_mult)/4. // pitching down is less safe.
local max_yaw_off is arccos(throt_predict_mult)/3.
local pitch_pid is PIDloop(1, 0, 0, -max_pitch_down, max_pitch_up).
local yaw_pid is PIDloop(1, 0, 0, -max_yaw_off, max_yaw_off).
local pitch_off is 0. // The output of pitch_pid
local yaw_off is 0. // The output of yaw_pid
local bias is -2. // The bias factor in the PID making negative errors more severe than positive ones.
local stop_deflecting is false. // set to true when giving up on deflecting landing site.
local started_descending is false. // True once it passes Apoapsis and started going down.

pid_tune(999999). // 999999 = dummy start value until the predictions start being calculated.

set cnt_before to ship:parts:length.
set timeslice_size to 2.0.

local prev_vspeed is verticalspeed.

// Need to notice a touchdown immediately whenever
// it happens because if it bounces it might be 
// landed for only 1 brief tick and thus it might
// not get to the top of the loop to do the check in time:
local stop_burn is false.
local burn_started is false.

lock steering to aim_direction().

when status = "LANDED" or status = "SPLASHED" then {
  set stop_burn to true.
}

if not(do_gui) {
  info_block_header().
}


local throt_is_locked is false.
local real_throt is 0.

// Main program:
until stop_burn or aborting {

  // Measure how long the loop is taking per iteration in sim time:
  set deltaT to time:seconds - prev_time.
  set prev_time to time:seconds.
  set prev_vspeed to verticalspeed.

  local partial_throttle_thrust is (minThrot + (throt_predict_mult * (1 - minThrot))) * athrust.
  local ullage_safe is ullage_status(active_engs).

  set result to sim_land_spot(
    mu,
    ship:body:position,
    partial_throttle_thrust,
    calced_isp,
    ship:mass,
    ship:drymass,
    ship:velocity:surface,
    timeslice_size,
    false,
    spool+ullage).

  set pos to result["pos"].
  set eta_end to result["seconds"].
  set dist to terrain_distance(pos, eta_end).
  if time:seconds > vd_show_msg_cooldown {
    set vd_show_msg_cooldown to vd_show_msg_cooldown + 15.
    HUDTEXT("Action Group 10 hides/shows prediction vector.", 5, 3, 18, rgb(0,0.4,0), false).
  }
  if vd1:istype("Vecdraw") {
    set vd1:show to ag10.
  }

  if dist > margin {
    set theColor to rgb(0,0.6,0).
  } else {
    set theColor to rgb(1,0.4,0).
  }

  if land_spot:istype("GeoCoordinates") {
    update_steer_offsets().
  }

  set real_throt to throt_predict_mult + throt_pid:update(time:seconds, signbias(dist-margin,bias)). 
  if dist-margin < 0 and not(burn_started) {
    set burn_started to true.
    throt_pid:reset(). // Erase the integral wind up from all the time it said "I don't need to throttle".
    set real_throt to throt_predict_mult. // temp value for the first time through before the PID control starts reacting.
  }

  // NOTE: It's vital that throt_pid NEVER return a result that sets real_throt below minThrot because
  // of the check below.  That's why throt_pid's min value is what it is (see pid_min waay above):
  if burn_started and real_throt > minThrot {
    // Account for RO's screwy throttle scaling, and don't
    // let throttle reach 0 entirely:
    if ullage_safe {
      if ship:control:fore > 0 {
        set ship:control:fore to 0.
        print "Ullage RCS thrust ending.".
      }

      // Adjust PID tuning as we go depending on TWR:
      pid_tune(eta_end).

      // Make sure it only executes the lock statement once, not each iteration:
      if not(throt_is_locked) {
        lock throttle to throt_formula(real_throt, minThrot).
        set throt_is_locked to true.
      }
      // From now on the engine stays on - so take these times out of the prediction:
      set spool to 0.  set ullage to 0.
    } else {
      rcs on. set ship:control:fore to 1.
      print "Ullage RCS thrusting".
    }
  }
  wait 0.

  // If each iteration is taking a long time, use a more coarse timeslice
  // for the prediction.  If each iteration is going fast, use a tighter timeslice:
  if deltaT > 0 { // skip the first time when we haven't measured a proper deltaT yet.
    set timeslice_size to (0.02 + deltaT)*4.
  }

  // A second stop condition is if we are about to start going up when we were
  // going down a moment before: (stop at a negative speed just shy of 0, so the
  // steering doesn't try to follow srfretorgrade as it swings quickly around.)
  if not(started_descending) and verticalspeed < -0.25 {
    set started_descending to true.
  }
  if started_descending and verticalspeed > -0.25  {
    set stop_burn to true.
  }

  if do_gui {
    update_land_it_gui(burn_started, real_throt, throt_pid, bias, dist, margin, throt_predict_mult, timeslice_size).
  } else {
    info_block_update(burn_started, real_throt, throt_pid, bias, dist, margin, throt_predict_mult, timeslice_size).
  }
}

if aborting {
  unlock throttle.
  unlock steering.
} else {
  lock throttle to 0.

  brakes on.
  if skycrane {
    // stage the skycrane away before cutting throttle.
    print "SkyCrane Staging Event!".
    stage.
    lock throttle to 1.
    lock steering to (choose -up:vector if upside_down else up:vector) + north:vector*0.2.
    wait 1.5.
  }
  lock throttle to 0.
  sane_steering().
  lock steering to lookdirup(
    (choose -up:vector if upside_down else up:vector),
    ship:facing:topvector).
  set ship:control:pilotmainthrottle to 0.
  lock throttle to 0.
  wait 0.
  unlock throttle.
  set vd1 to 0.
  set vd_off to 0.
  //clearscreen.
  print "program cut off at alt:radar = " + round(alt:radar,1) + " (desired margin = " + round(margin,1)+").".
  print "Waiting for landed state.".
  wait until status = "LANDED" or status = "SPLASHED".

  local cnt_after is ship:parts:length.
  local played is false.
  if cnt_before <> cnt_after {
    print "====== Oh Noes!! Something Broke!! ======" at (2, terminal:height/2).
    playsong(song_sad).
    set played to true.
  }
  lights on.


  // Give things time to blow up if they're going to:
  wait 0.5.
  // Count parts to see if any blew up:
  local cnt_after is ship:parts:length.

  if cnt_before = cnt_after {
    print "====== Landed!!  Celebration Music! ======" at (2, terminal:height/2).
    playsong(song_happy).
  } else if not played {
    print "====== Oh Noes!! Something Broke!! ======" at (2, terminal:height/2).
    playsong(song_sad).
  }

  // consume anything buffered:
  until not(terminal:input:haschar()) {
    terminal:input:getchar().
  }

  // wait for any key before letting go:
  print "PRESS ANY KEY IN TERMINAL TO LET GO STEERING.".
  lock throttle to 0. // just to prevent user error of throttling up while steering locked.
  until terminal:input:haschar() or aborting.
  // consume anything buffered:
  until not(terminal:input:haschar()) {
    terminal:input:getchar().
  }
  unlock steering.
  unlock throttle.
  wait 0.
  sas on.
}

print "DONE.".
for i in range(0,10) { getvoice(i):stop(). }

if do_gui {
  end_land_it_gui().
}

// =================== END OF MAIN - START OF FUNCTIONS =============================

function quit_script {
  set aborting to true.
}

function info_block_header {
  clearscreen.
  print "===Throttle Info======  ===Suicide Simulation===".
  print "| throt_lever:      %|  | radar alt:          m|".
  print "| real_throt:       %|  | suicide:            m|".
  print "| KP:                |  | suicide throt:      %|".
  print "| KI:                |  | sim timeslice:      s|".
  print "| KD:                |  ========================".
  print "| Bias:              |".
  print "======================".
}

function info_block_update {
  parameter started, rthrot, throt_pid, bias, dist, margin, sthrot, timeslice.

  print "     " at (15 ,1).
  print round(100*throttle,0) at (15, 1).

  print "     %" at (15, 2).
  if started {
    print round(100*rthrot,0) at (15, 2).
  } else {
    print "ZZZ" at (15, 2).
  }

  print "            " at (6, 3).
  print round(throt_pid:Kp,8) at (6, 3).
  print "            " at (6, 4).
  print round(throt_pid:Ki,8) at (6, 4).
  print "            " at (6, 5).
  print round(throt_pid:Kd,8) at (6, 5).

  print "        " at (8,6).
  print round(bias,5) at (8,6).

  print "         " at (37,1).
  print round(alt:radar,0) at (37,1).

  print "         " at (37,2).
  print round(dist-margin,0) at (37,2).

  print "   " at (41,3).
  print round(100*sthrot,0) at (41,3).

  print "    " at (42,4).
  print round(timeslice,2) at (42,4).
}

function pid_tune {
  parameter burn_time. // how long is the burn to a stop expected to take?

  // Adjust PID tuning as we go depending on TWR and dist to target:
  local twr is athrust / (ship:mass * mu / (bodRad+ship:altitude)^2).
  local dampener is twr*sqrt((1+burn_time)*50).
  set throt_pid:Kp to 3/dampener.
  set throt_pid:Ki to 0.5/dampener.
  set throt_pid:Kd to 1/dampener. 

  set pitch_pid:Kp to 50/dampener.
  set pitch_pid:Ki to 5/dampener.
  set pitch_pid:Kd to 10/dampener. 

  set yaw_pid:Kp to 50/(10+sqrt((10+burn_time)*50)*twr).
  set yaw_pid:Ki to 5/(sqrt((10+burn_time)*50)*twr).
  set yaw_pid:Kd to 10/(sqrt((10+burn_time)*50)*twr). 
}

// Return retrograde or up vectors depending on
// whether we're going so slowly that retrograde
// might flip upside down soon.  Also predict
// near the end of the flight if we'll be not vertical
// enough and if so then curve it to the ground more.
function aim_direction {
  local aim_vec is (choose srfprograde:vector if upside_down else srfretrograde:vector).

  // Stop aiming srfretro and aim vertical if near the end:
  if burn_started and ship:velocity:surface:mag < 1.5 {
    set aim_vec to (choose -up:vector if upside_down else up:vector).
  }
  else if burn_started and verticalspeed > -5 {
    // Aim at a vector exactly halfway between true surface retro and straight up:
    set aim_vec to up:vector:normalized + aim_vec:normalized.
  }

  // Offset based on targetted landing site:
  if pitch_off <> 0 {
    set aim_vec to aim_vec*angleaxis(pitch_off,srfprograde:starvector).
  }
  if yaw_off <> 0 {
    set aim_vec to aim_vec*angleaxis(yaw_off,-srfprograde:topvector).
  }

  return lookdirup(aim_vec, facing:topVector).
}

function update_steer_offsets {
  if stop_deflecting { return. } // ignore when we already gave up.

  local target_spot is land_spot:altitudeposition(land_spot:terrainheight + margin).
  local xyz_off is pos - target_spot.

  // Debug that I may remove later:
  if vd_off:istype("Vecdraw") {
    // change existing vecdraw
    set vd_off:start to target_spot.
    set vd_off:vector to xyz_off.
    set vd_off:label to "Landing Site Error " + round(xyz_off:mag,1)+"m".
  } else {
    // make new vecdraw - will update position on next pass through:
    set vd_off to vecdraw(v(0,0,0), v(0,0,0), blue, "Landing Site Error " + round(xyz_off:mag,1)+"m", 1, true, 0.3).
  }
  
  // Conditions to make it stop deflecting:
  // - very close to touchdown, or
  // - bypassed the landing and it's behind us.
  if (eta_end < 10 and xyz_off:mag > 25) or (vdot(target_spot, ship:facing:vector) > 0) {
    set pitch_off to 0.
    set yaw_off to 0.
    set stop_deflecting to true.
    print "Deflecting disabled - just landing straight.".
    return.
  }

  local xyz_up_spot is (land_spot:position - body:position):normalized.

  // To my "right" as I look down the prograde vector is this:
  local srf_antinorm is vcrs(up:vector, srfprograde:vector):normalized.
  // Vectors aligned with ground at landing spot for how far long,
  // or to the right of the landing the current prediction is:
  local horiz_right is vxcl(xyz_up_spot, srf_antinorm):normalized.
  local horiz_overshoot is vxcl(xyz_up_spot, srfprograde:vector):normalized.

  // Get the horiz_right and horiz_long components of xyz_off:
  local overshoot_dist is vdot(xyz_off, horiz_overshoot).
  local right_dist is vdot(xyz_off, horiz_right).

  // Feed those offsets into the PIDs for steering offset:
  set pitch_off to pitch_pid:update(time:seconds, overshoot_dist).
  set yaw_off to yaw_pid:update(time:seconds, right_dist).

}

// Bias the input value on one side of zero more than the other.
// (i.e. treat negative values as twice as big as positive ones).
// example:
//   signbias(10,-2) returns 10, while signbias(-10,-2) returns -20.
//   (the -2 means "make negative values twice as big, leave positive values alone.)
function signbias {
  parameter
    inVal, // value to bias
    bias.  // - or + depending on what side you want biased, magnitude is degree of bias.

  if (inVal<0) = (bias<0) {
    return inVal*abs(bias).
  }
  return inVal.
}

// If alt:radar is > altitude then you're seeing the
// ocean floor under the water, so return the
// sea level instead of the terrain altitude:
function alt_radar_or_sea {
  return min(altitude, alt:radar).
}

// True if there's still a safe margin of distance.
// False if the suicide burn MUST start NOW.
function terrain_distance {
  parameter pos, secs.

  local safe is false.
  local use_fallback is true.
  local dist is 0.
  local label_prefix is "".

  if use_fallback {
    local geo is geopos_later(ship:body:geopositionof(pos), secs).
    local groundPos is geo:position.
    local seaPos is geo:altitudeposition(0).
    set dist_ground to vdot(pos-groundPos,ship:up:vector).
    set dist_sea to vdot(pos-seaPos,ship:up:vector).
    set dist to min(dist_ground, dist_sea).
    set label_prefix to "Margin (terrain database guess): ".
  }
  if vd1:istype("Vecdraw") {
    // change existing vecdraw
    set vd1:vector to pos.
    set vd1:color to theColor.
    set vd1:label to label_prefix + round(dist,1).
  } else {
    // make new vecdraw
    set vd1 to vecdraw(v(0,0,0),pos, theColor, label_prefix + round(dist,1)+"m", 1, true, 0.3).
  }
  return dist.
}

// Given a geoposition, find what that geoposition will become later
// as the body rotates under it x seconds.  Useful for landing on
// rotating bodies that don't have atmo.
function geopos_later {
  parameter geo_in, secs.  // input geoposition, number of seconds to rotate body.

  local bod is geo_in:body.
  if bod:atm:exists // Assume atmo forces locking to surface reference so no rotation happens.
    return geo_in.

  local newlong is geo_in:lng - secs*360/bod:rotationperiod.

  return bod:geopositionlatlng(geo_in:lat, newlong).
}

function engine_ullage_secs {
  local engs is LIST().
  list engines in engs.
  for eng in engs {
    if eng:ignition and not(eng:flameout) and eng:ullage{
      //assumes either 1 engine or at least uniform engines if a cluster.
      return 4.
    }
  }
  return 0.
}

function engine_minthrot {
  local engs is LIST().
  list engines in engs.
  for eng in engs {
    if eng:ignition and not(eng:flameout) {
      //assumes either 1 engine or at least uniform engines if a cluster.
      return eng:minthrottle. 
    }
  }
  return 0.
}

function throt_formula {
  parameter t_real, t_min.
  return (t_real-t_min)/(1-t_min) + 0.001.
}
