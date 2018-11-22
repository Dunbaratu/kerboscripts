run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".
run once "/songs/sad".
run once "/lib/sanity".

parameter safety_margin is 5.
parameter skycrane is false.
// The following two are for fixing it if the
// probe core isn't oriented right
parameter off_pitch is 0.
parameter off_yaw is 0.

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

clearscreen. print " ". print " ".
local first_aim is true.

SAS off.
lock steering to rotate_for_probe_core(srfretrograde, off_pitch, off_yaw).
gear on.

local lasParts is ship:partstagged("landing laser").
local hasLas is false.
local lasMod is 0.
if lasParts:length > 0 {
  set lasMod to lasParts[0]:getmodule("LaserDistModule").
  set hasLas to true.
  lasMod:setfield("Enabled", true).
  lasMod:setfield("Visible", true).
}

local prev_time is time:seconds.
local deltaT is 0.1.
local burn_done is false.
local burn_start to false.
local burn_continuing to false.
local initial_twr is 9999.
until burn_done {

  set result to sim_land_spot(
    ship:body:mu,
    ship:body:position,
    ship:availablethrust,
    isp_calc(0),
    ship:mass,
    ship:drymass,
    ship:velocity:surface,
    0.5,
    false).

  set pos to result["pos"].
  local safe_dist is get_safe_distance(pos, deltaT).
  print "Safe Dist = " + round(safe_dist,1) + "m" at (5,0).
  if safe_dist >= 0 {
    set theColor to green.
    if burn_start and safe_dist > 500 {
      print "Looks like we burned too soon - back to waiting again.".
      set burn_start to false.
      set burn_continuing to false.
      lock throttle to 0.
    }
  } else {
    set theColor to red.
    set burn_start to true.
  }

  if burn_start {
    if burn_continuing {
      if verticalspeed > -4.0 {
        set burn_done to true.
      }
    } else  {
      print "Now in angled suicide burn.".
      set initial_twr to ship:availablethrust / (ship:mass * ship:body:mu / (ship:body:radius+ship:altitude)^2).
      lock throttle to 1.
      set burn_continuing to true.
    }
  } else {
    wait 0.
  }
  
  set deltaT to time:seconds - prev_time.
  set prev_time to time:seconds.
}

print "Now in final touchdown vertical descent.".
set descendPID to pidloop(1/initial_twr, 0.05/initial_twr, 0.2/initial_twr, 0, 1).
lock throttle to descendPID:update(time:seconds, verticalspeed+descentSpeed()).
lock steering to rotate_for_probe_core(retro_or_up(), off_pitch, off_yaw).
local partCount_before is ship:parts:length.
wait until status="LANDED" or status="SPLASHED".
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
local partCount_after is ship:parts:length.
local already_played_song is false.
if partCount_before <> partCount_after {
  print "====== Oh Noes!! Something Broke!! ======" at (2, terminal:height/2).
  playsong(song_sad).
  set already_played_song to true.
}
wait until ship:velocity:surface:mag < 0.1. 
lights on.

if hasLas {
  lasMod:setfield("Enabled", false).
  lasMod:setfield("Visible", false).
}

// Give things time to blow up if they're going to:
wait 0.5.
// Count parts to see if any blew up:
local partCount_after is ship:parts:length.

if partCount_before = partCount_after {
  print "====== Landed!!  Celebration Music! ======" at (2, terminal:height/2).
  playsong(song_happy).
} else if not already_played_song {
  print "====== Oh Noes!! Something Broke!! ======" at (2, terminal:height/2).
  playsong(song_sad).
}
wait 10.
SAS off.
// =================== END OF MAIN - START OF FUNCTIONS =============================

function descentSpeed {

  local shipWeight is (ship:mass * ship:body:mu / (ship:body:radius+ship:altitude)^2).
  // Bonus Thrust beyond what is needed to fight gravity:
  local bonusThrust is ship:availablethrust - shipWeight.
  // max amount we can deccelerate by:
  local accel is bonusThrust / ship:mass.

  // This formula is supposed to be:
  //    "What speed could I have in which I would be able to stop
  //    in the available distance?" (with a fudge factor of pretending
  //    the engine is only 70% as strong as it really is:).
  local return_val is sqrt( (max(0, 0.7*(alt_radar_or_sea() - 2*safety_margin) ))*(2*accel) ).
  local return_val is max(1.5, return_val).
  print "Desired Spd: " + round(return_val,1) + " m/s   " at (5,terminal:height/2-3).
  print "Current Spd: " + round(abs(verticalspeed),1) + " m/s   " at (5,terminal:height/2-2).
  return return_val. // force it to be sane.
}

// Return retrograde or up vectors depending on
// whether we're going so slowly that retrograde
// might flip upside down soon:
function retro_or_up {
  if ship:verticalspeed > -0.2
    return lookdirup(ship:up:vector, ship:facing:topVector).
  else if ship:verticalspeed > -10
    // Aim at a vector exactly halfway between true surface retro and straight up:
    return lookdirup(ship:up:vector:normalized + srfretrograde:vector:normalized, ship:facing:topVector).
  else
    return lookdirup(srfretrograde:vector, ship:facing:topvector).
}

// Rotates a given steering direction to
// compensate for a poorly mounted probe core.
function rotate_for_probe_core {
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
function get_safe_distance {
  parameter pos, deltaT.

  local use_fallback is true.
  local compare_dist is 0.
  local test_dist is 0.
  local label_prefix is "".

  if   hasLas  // don't use the laser if we don't have one.
       and
       abs(steeringmanager:angleerror) < 1  // don't trust the laser until we are aimed close enough that
                                            // it can be pointed in roughly the right direction.
       and
       warp = 0 // don't believe the laser reading until warp is over.
  {
    aim_laser_at(lasMod, pos).
    if first_aim {
      wait 0. wait 0. // let the laser aim actually happen by waiting 2 ticks.
      set first_aim to false.
    }
    local dist is lasMod:getfield("distance").
    if dist >= 0 {
      set use_fallback to false.
      set compare_dist to dist - (safety_margin+ship:velocity:surface:mag*deltaT*1.5).
      set test_dist to pos:mag.
      set label_prefix to "Margin (laser measured): ".
    }
  }
  if use_fallback {
    local groundPos is ship:body:geopositionof(pos):position.
    local seaPos is ship:body:geopositionof(pos):altitudeposition(0).
    set test_dist to (safety_margin+abs(verticalspeed)*deltaT*1.5).
    set compare_dist_ground to vdot(pos-groundPos,ship:up:vector).
    set compare_dist_sea to vdot(pos-seaPos,ship:up:vector).
    set compare_dist to min(compare_dist_ground, compare_dist_sea).
    set label_prefix to "Margin (terrain database guess): ".
  }
  if test_dist < compare_dist { // try to start the burn just a few ticks early
    set vd1 to vecdraw(v(0,0,0),pos, green, label_prefix + round(compare_dist-test_dist,1)+"m", 1, true).
  } else {
    set vd1 to 0.
  }

  return compare_dist - test_dist.
}

