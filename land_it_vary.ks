run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".
run once "/songs/sad".
run once "/lib/sanity".

parameter margin is 5.
parameter ullage is 2. // presumed time to wait for RCS ullage before engine start.
parameter spool is 1. // presumed spool-up time of engines in seconds.
parameter minThrot is 0. // min throttle in RO for the landing engine.
parameter skycrane is false.
// The following two are for fixing it if the
// probe core isn't oriented right



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

local first_aim is true.

SAS off.
lock steering to retro_or_up().
set steeringmanager:maxstoppingtime to 5.
set steeringmanager:pitchpid:Kd to 1.
set steeringmanager:yawpid:Kd to 1.
gear on.

set theColor to rgb(0,0.6,0).

local hasLas is false.

local prev_time is time:seconds.
local deltaT is 0.1.
local calced_isp is isp_calc(). // WARNING: by pre-calcing, this is wrong for atmo situations where it changes.
local mu is ship:body:mu.
local bodRad is ship:body:radius.
local athrust is ship:availablethrust.
local landed is false.
local throt_pid is PIDloop(1,0,0,minThrot,1).
local ullage_end_ts is -1.
local wait_for_fall is true.
set cnt_before to ship:parts:length.

// Need to notice a touchdown immediately whenever
// it happens because if it bounces it might be 
// landed for only 1 brief tick and thus it might
// not get to the top of the loop to do the check in time:
global touched is false.
when status = "LANDED" or status = "SPLASHED" then {
  set touched to true.
}

// Main program:
until touched {

  set result to sim_land_spot(
    mu,
    ship:body:position,
    athrust,
    calced_isp,
    ship:mass,
    ship:drymass,
    ship:velocity:surface,
    0.1, // was 0.5
    false,
    spool+ullage).

  set pos to result["pos"].
  set dist to terrain_distance(pos, deltaT).
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

  set real_throt to throt_pid:update(time:seconds, dist-margin). 
  if real_throt > minThrot {
    set vd1 to 0.
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
      local twr is athrust / (ship:mass * mu / (bodRad+ship:altitude)^2).
      set throt_pid:Kp to 4/twr.
      set throt_pid:Ki to 1/twr.
      set throt_pid:Kd to 0.2/twr.

      lock throttle to (real_throt-minThrot)/(1-minThrot) + 0.001.
      // From now on the engine stays on - so take these times out of the prediction:
      set spool to 0.  set ullage to 0.
      print "real_throt = " + round(real_throt,3) + ", throttle = " + round(throttle,3). // eraseme
    }
  }

  wait 0.

  set deltaT to time:seconds - prev_time.
  if (alt:radar < margin or verticalspeed > -0.2) and not wait_for_fall {
    set margin to margin / 2.
    set wait_for_fall to true.
  }
  if verticalspeed < -0.2 {
    set wait_for_fall to false.
  }
  print "alt:radar = " + round(alt:radar,3) + ", margin = " + round(margin,3). //eraseme
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
wait 0.
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
// might flip upside down soon:
function retro_or_up {
  if ship:verticalspeed > -1.5
    return lookdirup(ship:up:vector, ship:facing:topVector).
  else if ship:verticalspeed > -10
    // Aim at a vector exactly halfway between true surface retro and straight up:
    return lookdirup(ship:up:vector:normalized + srfretrograde:vector:normalized, ship:facing:topVector).
  else
    return lookdirup(srfretrograde:vector, ship:facing:topvector).
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
  parameter pos, deltaT.

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
  set vd1 to vecdraw(v(0,0,0),pos, theColor, label_prefix + round(dist,1)+"m", 1.5, true).
  return dist.


}

