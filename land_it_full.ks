// land_it script to use when you have infinitely restartable,
// yet still throttle locked at 100%, engines.
//
parameter margin is 5. // height (could be replaced with bounds check).
parameter spool is 1. // presumed spool-up time of engines in seconds.
parameter skycrane is false.
// The following two are for fixing it if the
// probe core isn't oriented right
parameter off_pitch is 0.
parameter off_yaw is 0.
parameter lib_vol is 1. //which volume has the lib dir?
parameter songs_vol is 1. //which volume has the songs dir?
parameter fudge is 0.95. // fudge factor for thrust prediction.
parameter altitude_start is 0. // when to begin the algorithm.

runoncepath(lib_vol+":/lib/land").
runoncepath(lib_vol+":/lib/song").
runoncepath(songs_vol+":/songs/happy").
runoncepath(songs_vol+":/songs/sad").
runoncepath(lib_vol+":/lib/sanity").
runoncepath(lib_vol+":/lib/ro").

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

if config:ipu < 800 {
  print "Setting IPU to min of 800 because this script needs it.".
  set config:ipu to 800.
}

if altitude_start > 0 {
  print "Waiting until alt < "+altitude_start+" to begin program.".
  wait until altitude < altitude_start.
}


local first_aim is true.

SAS off.
lock steering to rot_core(srfretrograde, off_pitch, off_yaw).
gear on.

local hasLas is false.

local prev_time is time:seconds.
local deltaT is 2.
local simSlice is 3.
local landed is false.
until landed {
  local burn_now is false.
  local calced_isp is isp_calc(0). // WARNING: by pre-calcing, this is wrong for atmo situations where it changes.
  local mu is ship:body:mu.
  local athrust is ship:availablethrust * fudge.
  until burn_now {
    set landed to (status = "LANDED" or status = "SPLASHED").
    if landed
      break.

    set result to sim_land_spot(
      mu,
      ship:body:position,
      athrust,
      calced_isp,
      ship:mass,
      ship:drymass,
      ship:velocity:surface,
      simSlice,
      false,
      spool).

    set pos to result["pos"].
    if has_safe_distance(pos, deltaT) {
      set theColor to green.
    } else {
      set theColor to red.
      set burn_now to true.
    }

    if not burn_now
      wait 0.
    
    set deltaT to time:seconds - prev_time.
    set prev_time to time:seconds.
  }

  print "Now in suicide burn.".
  lock throttle to 1.
  set cnt_before to ship:parts:length.
  wait until verticalspeed > -3.0 or status = "LANDED" or status = "SPLASHED".
  lock throttle to 0.
  set ship:control:pilotmainthrottle to 0.

  set margin to margin/4. // try again from here, with a smaller margin.
  set simSlice to simSlice/2.
  wait 0.5. // give it time to notice the landed state.
}
brakes on.
unlock steering.
if skycrane {
  // stage the skycrane away before cutting throttle.
  print "SkyCrane Staging Event!".
  stage.
  wait 0.1.
}
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
wait until ship:velocity:surface:mag < 0.1. 
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
// Rotates a given steering direction to
// compensate for a poorly mounted probe core.
function rot_core {
  parameter dirIn, pitchRot, yawRot.

  // Adjust for pitch, then yaw:
  local dirOut is dirIn:forevector.
  set dirOut to 
    angleaxis(yawRot, ship:facing:topvector) *
    angleaxis(pitchRot, ship:facing:starvector) *
    dirOut.

  return lookdirup(dirOut, ship:facing:topvector).
}

// If alt:radar is > altitude then you're seeing the
// ocean floor under the water, so return the
// sea level instead of the terrain altitude:
function alt_radar_or_sea {
  return min(altitude, alt:radar).
}

// True if there's still a safe margin of distance.
// False if the suicide burn MUST start NOW.
function has_safe_distance {
  parameter pos, deltaT.

  local safe is false.
  local use_fallback is true.
  local dist is 0.
  local test_dist is 0.
  local label_prefix is "".

  if use_fallback {
    local groundPos is ship:body:geopositionof(pos):position.
    local seaPos is ship:body:geopositionof(pos):altitudeposition(0).
    set test_dist to (margin+abs(verticalspeed)*deltaT*2).
    set dist_ground to vdot(pos-groundPos,ship:up:vector).
    set dist_sea to vdot(pos-seaPos,ship:up:vector).
    set dist to min(dist_ground, dist_sea).
    set label_prefix to "Margin (terrain database guess): ".
  }
  if test_dist < dist { // try to start the burn just a few ticks early
    set safe to true.
    set vd1 to vecdraw(v(0,0,0),pos, green, label_prefix + round(dist-test_dist,1)+"m", 1, true).
  } else {
    set vd1 to 0.
  }

  return safe.
}

