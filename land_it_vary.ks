// land_it to use when you have an engine that might not be
// infinitely restartable but does have the ability to
// throttle it down.  Can work with engines with min TWR > 1.0.

run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".
run once "/songs/sad".
run once "/lib/sanity".

parameter margin is 5.
parameter ullage is 2. // presumed time to wait for RCS ullage before engine start.
parameter spool is 1. // presumed spool-up time of engines in seconds.
parameter minThrot is 0. // min throttle in RO for the landing engine.
parameter throt_predict_mult is 0.8. // predict landing as if throttle is only this much, for adjustable margin.
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
lock steering to aim_direction().
set steeringmanager:maxstoppingtime to 5.
set steeringmanager:pitchpid:Kd to 1.
set steeringmanager:yawpid:Kd to 1.
gear on.

set theColor to rgb(0,0.6,0).
local vd_show_msg_cooldown is time:seconds.
local hasLas is false.
local vd1 is 0.
local cos_aim is 1. // cosine of angle between aim and srfretro, when we're aiming off to try to stop horizontal component.
local prev_time is time:seconds.
local deltaT is 0.1. // how long an iteration is *actually* taking, measured.
local calced_isp is isp_calc(). // WARNING: by pre-calcing, this is wrong for atmo situations where it changes.
local mu is ship:body:mu.
local bodRad is ship:body:radius.
local athrust is ship:availablethrust.
local landed is false.
local pos is v(0,0,0).
local end_angular is 0.
local eta_end is 9999.

local throt_pid is PIDloop(1,0,0,minThrot,1).
pid_tune(altitude).

local ullage_end_ts is -1.
local wait_for_fall is true.
set cnt_before to ship:parts:length.
set timeslice_size to 0.3.

local prev_vspeed is verticalspeed.

// Need to notice a touchdown immediately whenever
// it happens because if it bounces it might be 
// landed for only 1 brief tick and thus it might
// not get to the top of the loop to do the check in time:
local stop_burn is false.
local burn_started is false.

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

  set result to sim_land_spot(
    mu,
    ship:body:position,
    cos_aim * partial_throttle_thrust,
    calced_isp,
    ship:mass,
    ship:drymass,
    ship:velocity:surface,
    timeslice_size,
    false,
    spool+ullage).

  set pos to result["pos"].
  set end_angular to result["angular"].
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
    if ullage_end_ts < 0 {
      set ullage_end_ts to time:seconds + ullage.
      rcs on. set ship:control:fore to 1.
      print "Ullage RCS thrusting".
    }
  }

  // How far off is the predicted landing height, as a ratio of total distance to landing:
  // (so it gets tighter the closer to landing we are).
 // eraseme: local land_dist_err_ratio is (dist-margin)*5/max(5,pos:mag). // max() is there so if pos is near zero it doesn't get stupid.
 // eraseme: set real_throt to throt_pid:update(time:seconds, land_dist_err_ratio). 

  local real_throt to throt_pid:update(time:seconds, dist-margin). 
  print "Kp="+round(throt_pid:Kp,8)+" Ki="+round(throt_pid:Ki,8)+" Kd="+round(throt_pid:Kd,8). // eraseme

  if real_throt > minThrot {
    set burn_started to true.
    // Account for RO's screwy throttle scaling, and don't
    // let throttle reach 0 entirely:
    if ullage_end_ts > 0 and time:seconds < ullage_end_ts {
    }
    else {
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
    }
  } else if burn_started {
      lock throttle to 0.001.
  }

  wait 0.

  if (alt:radar < margin or verticalspeed > -0.2) and not wait_for_fall {
    // TODO : does this condition even happen anymore, now that vertical speed going up
    // makes the loop end entirely?
    set margin to margin / 2.
    set wait_for_fall to true.
  }
  if verticalspeed < -0.2 {
    set wait_for_fall to false.
  }

  // If each iteration is taking a long time, use a more coarse timeslice
  // for the prediction.  If each iteration is going fast, use a tighter timeslice:
  set timeslice_size to (0.02 + deltaT)*2.

  print "alt:radar = " + round(alt:radar,3) + ", margin = " + round(margin,3) + ", timeslice = " + round(timeslice_size,3). //eraseme

}
lock throttle to 0.

brakes on.
unlock steering.
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

  // Adjust PID tuning as we go depending on TWR:
  local twr is athrust / (ship:mass * mu / (bodRad+ship:altitude)^2).
  set throt_pid:Kp to 10/(10+sqrt(burn_dist)*twr).
  set throt_pid:Ki to 1/(sqrt(burn_dist)*twr).
  set throt_pid:Kd to 2/(sqrt(burn_dist)*twr). 
}

function descentSpeed {

  local sweight is (ship:mass * ship:body:mu / (ship:body:radius+ship:altitude)^2).
  // Bonus Thrust beyond what is needed to fight gravity:
  local bonusThrust is ship:availablethrust - sweight.
  // max amount we can deccelerate by:
  local accel is bonusThrust / ship:mass.

  // This formula is supposed to be:
  //    "What speed could I have in which I would be able to stop
  //    in the available distance?" (with a fudge factor of pretending
  //    the engine is only 70% as strong as it really is:).
  local rVal is sqrt( (max(0, 0.7*(alt_radar_or_sea() - 2*margin) ))*(2*accel) ).
  local rVal is max(1.5, rVal).
  print "Desired Spd: " + round(rVal,1) + " m/s   " at (5,terminal:height/2-3).
  print "Current Spd: " + round(abs(verticalspeed),1) + " m/s   " at (5,terminal:height/2-2).
  return rVal. // force it to be sane.
}

// Return retrograde or up vectors depending on
// whether we're going so slowly that retrograde
// might flip upside down soon.  Also predict
// near the end of the flight if we'll be not vertical
// enough and if so then curve it to the ground more.
function aim_direction {
  set cos_aim to 1. // cosine for how far off the aim is from retro.

  print "eta_end = " + round(eta_end,2) + ", end_angular = " + round(end_angular,2). // eraseme
  if burn_started and ship:verticalspeed > -1.5 {
    return lookdirup(ship:up:vector, ship:facing:topVector).
  }
  else if burn_started and ship:verticalspeed > -5 {
    // Aim at a vector exactly halfway between true surface retro and straight up:
    return lookdirup(ship:up:vector:normalized + srfretrograde:vector:normalized, ship:facing:topVector).
  } // Else if within 20 seconds of ending, and it looks like the landing would require an impossibly quick rotation at the end
  else {
    return lookdirup(srfretrograde:vector, ship:facing:topvector).
  }
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

