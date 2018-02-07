// land_it to use when you have an engine that might not be
// infinitely restartable but does have the ability to
// throttle it down.  Can work with engines with min TWR > 1.0.

run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".
run once "/songs/sad".
run once "/lib/sanity".
run once "/lib/ro".

parameter margin is 5.
parameter ullage is 2. // presumed time to wait for RCS ullage before engine start.
parameter spool is 1. // presumed spool-up time of engines in seconds.
parameter minThrot is 0. // min throttle in RO for the landing engine.
parameter throt_predict_mult is 0.8. // predict landing as if throttle is only this much, for adjustable margin.
parameter land_spot is 0. // set to a geoposition to make it try to aim to land there.
parameter skycrane is false.

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
local prev_time is time:seconds.
local deltaT is 0.1. // how long an iteration is *actually* taking, measured.
local calced_isp is isp_calc(). // WARNING: by pre-calcing, this is wrong for atmo situations where it changes.
local mu is ship:body:mu.
local bodRad is ship:body:radius.
local athrust is ship:availablethrust.
local landed is false.
local pos is v(0,0,0).
local eta_end is 9999.
local active_engs is all_active_engines().

// Output of throt_pid is a value between min throt and max throt, for throttle.
local throt_pid is PIDloop(1, 0, 0, minThrot, 1).
// output of pitch_pid is a deflection above srfretrograde in degrees.
local pitch_pid is PIDloop(1, 0, 0, -5, 5).
local pitch_off is 0. // The output of pitch_pid
// output of yaw_pid is a deflection right of srfretrograde in degrees.
local yaw_pid is PIDloop(1, 0, 0, -5, 5).
local yaw_off is 0. // The output of yaw_pid

pid_tune(altitude).

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
// A second stop condition is if we start going up when we were
// going down a moment before:  (The check for sign change prevents
// this from triggering if we are just coasting to Ap before the
// initial drop.)
when verticalspeed > 0 and
     prev_vspeed * verticalspeed < 0 // true IFF +/- sign changed
     then {
  set stop_burn to true.
}

// Main program:
until stop_burn {

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
  set dist to terrain_distance(pos).
  if time:seconds > vd_show_msg_cooldown {
    set vd_show_msg_cooldown to vd_show_msg_cooldown + 15.
    HUDTEXT("Action Group 10 hides/shows prediction vector.", 5, 3, 18, rgb(0,0.4,0), true).
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

  local real_throt is throt_pid:update(time:seconds, dist-margin). 
  print "r="+round(real_throt,3) + " Gains: " + round(throt_pid:Kp,8)+", "+round(throt_pid:Ki,8)+", "+round(throt_pid:Kd,8). // eraseme

  if real_throt > minThrot {
    set burn_started to true.
    // Account for RO's screwy throttle scaling, and don't
    // let throttle reach 0 entirely:
    if ullage_safe {
      if ship:control:fore > 0 {
        set ship:control:fore to 0.
        print "Ullage RCS thrust ending.".
      }

      // Adjust PID tuning as we go depending on TWR:
      pid_tune(pos:mag).

      lock throttle to (real_throt-minThrot)/(1-minThrot) + 0.001.
      // From now on the engine stays on - so take these times out of the prediction:
      set spool to 0.  set ullage to 0.
      print "real_throt = " + round(real_throt,3) + ", throttle = " + round(throttle,3). // eraseme
    } else {
      rcs on. set ship:control:fore to 1.
      print "Ullage RCS thrusting".
    }
  } else if burn_started {
      if ullage_safe {
        lock throttle to 0.001.
      }
  }

  wait 0.

  // If each iteration is taking a long time, use a more coarse timeslice
  // for the prediction.  If each iteration is going fast, use a tighter timeslice:
  set timeslice_size to (0.02 + deltaT)*2.

  print "alt:radar = " + round(alt:radar,3) + ", margin = " + round(margin,3) + ", timeslice = " + round(timeslice_size,3). //eraseme

}
lock throttle to 0.

brakes on.
if skycrane {
  // stage the skycrane away before cutting throttle.
  print "SkyCrane Staging Event!".
  stage.
  wait 0.1.
}
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
wait 0.
unlock throttle.
SAS on.
set vd1 to 0.
clearscreen.
sane_steering().
print "program cut off at alt:radar = " + round(alt:radar,1) + " (desired margin = " + round(margin,1)+").".
print "Waiting for landed state.".
wait until status = "LANDED" or status = "SPLASHED".

unlock steering.

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
wait 10.
SAS off.
// =================== END OF MAIN - START OF FUNCTIONS =============================

function pid_tune {
  parameter burn_dist.

  // Adjust PID tuning as we go depending on TWR and dist to target:
  local twr is athrust / (ship:mass * mu / (bodRad+ship:altitude)^2).
  set throt_pid:Kp to 10/(10+sqrt(burn_dist)*twr).
  set throt_pid:Ki to 1/(sqrt(burn_dist)*twr).
  set throt_pid:Kd to 5/(sqrt(burn_dist)*twr). 

  set pitch_pid:Kp to 50/(10+sqrt(burn_dist)*twr).
  set pitch_pid:Ki to 5/(sqrt(burn_dist)*twr).
  set pitch_pid:Kd to 10/(sqrt(burn_dist)*twr). 

  set yaw_pid:Kp to 50/(10+sqrt(burn_dist)*twr).
  set yaw_pid:Ki to 5/(sqrt(burn_dist)*twr).
  set yaw_pid:Kd to 10/(sqrt(burn_dist)*twr). 
}

// Return retrograde or up vectors depending on
// whether we're going so slowly that retrograde
// might flip upside down soon.  Also predict
// near the end of the flight if we'll be not vertical
// enough and if so then curve it to the ground more.
function aim_direction {
  local aim_vec is srfretrograde:vector.

  // Offset the aim a bit if near the ground:
  if burn_started and verticalspeed > -1.5 {
    set aim_vec to up:vector.
  }
  else if burn_started and verticalspeed > -5 {
    // Aim at a vector exactly halfway between true surface retro and straight up:
    set aim_vec to up:vector:normalized + srfretrograde:vector:normalized.
  }

  // Offset based on targetted landing site:
  if pitch_off <> 0 {
    set aim_vec to angleaxis(pitch_off,srfprograde:starvector)*aim_vec.
  }
  if yaw_off <> 0 {
    set aim_vec to angleaxis(yaw_off,srfprograde:topvector)*aim_vec.
  }

  return lookdirup(aim_vec, facing:topVector).
}

function update_steer_offsets {

  local xyz_off is pos - (land_spot:altitudeposition(land_spot:terrainheight + margin)).

  local xyz_up_spot is (land_spot:position - body:position):normalized.

  // To my "right" as I look down the prograde vector is this:
  local srf_antinorm is vcrs(up:vector, srfprograde:vector).
  // Vectors aligned with ground at landing spot for how far long,
  // or to the right of the landing the current prediction is:
  local horiz_right is vxcl(xyz_up_spot, srf_antinorm).
  local horiz_long is vxcl(xyz_up_spot, srfprograde:vector).

  // Feed those offsets into the PIDs for steering offset:
  set pitch_off to pitch_pid:update(time:seconds, horiz_long:mag).
  set yaw_off to pitch_pid:update(time:seconds, horiz_right:mag).

  print "h_r="+round(horiz_right:mag,2) + " h_l="+round(horiz_long:mag,2) + " p_o=" + round(pitch_off,3) + " y_o=" = round(yaw_off,3).  //eraseme
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
  parameter pos.

  local safe is false.
  local use_fallback is true.
  local dist is 0.
  local label_prefix is "".

  if use_fallback {
    local groundPos is ship:body:geopositionof(pos):position.
    local seaPos is ship:body:geopositionof(pos):altitudeposition(0).
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
    set vd1 to vecdraw(v(0,0,0),pos, theColor, label_prefix + round(dist,1)+"m", 1.5, true).
  }
  return dist.


}

