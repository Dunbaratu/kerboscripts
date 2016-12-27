run once "/lib/land".
run once "/lib/song".
run once "/songs/happy".

parameter safety_margin is 5.

local first_aim is true.

set burn_now to false.
sas off.
lock steering to srfretrograde.
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

until burn_now {

  set result to sim_land_spot(
    ship:body:mu,
    ship:body:position,
    ship:availablethrust,
    isp_calc(),
    ship:mass,
    ship:velocity:surface,
    0.5,
    false).

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
local initial_twr is ship:availablethrust / (ship:mass * ship:body:mu / (ship:body:radius+ship:altitude)^2).
lock throttle to 1.
wait until verticalspeed > -2.0.
set descendPID to pidloop(0.08, 0.04/initial_twr, 0.02, 0,1).
lock throttle to descendPID:update(time:seconds, verticalspeed+descentSpeed()).
lock steering to retro_or_up().
wait until status="LANDED" or status="SPLASHED".
brakes on.
unlock steering.
unlock throttle.
SAS on.
set vd1 to 0.
wait until ship:velocity:surface:mag < 0.1. 
lights on.

if hasLas {
  lasMod:setfield("Enabled", false).
  lasMod:setfield("Visible", false).
}


clearscreen.
print "====== Landed!!  Celebration Music! ======" at (2, terminal:height/2).
playsong(song_happy).
wait 10.
SAS off.

// =================== END OF MAIN - START OF FUNCTIONS =============================

function descentSpeed {

  local twr is ship:availablethrust / (ship:mass * ship:body:mu / (ship:body:radius+ship:altitude)^2).
  local up_accel is (twr-1)/ship:mass.
  return max(1.5, (alt:radar - safety_margin)*up_accel/10).
}

// Return retrograde or up vectors depending on
// whether we're going so slowly that retrograde
// might flip upside down soon:
function retro_or_up {
  if ship:verticalspeed > -0.2
    return lookdirup(ship:up:vector, ship:facing:topVector).
  else
    return lookdirup(srfretrograde:vector, ship:facing:topvector).
}

// True if there's still a safe margin of distance.
// False if the suicide burn MUST start NOW.
function has_safe_distance {
  parameter pos, deltaT.

  local safe is false.
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
      set compare_dist to dist - (safety_margin+ship:velocity:surface:mag*deltaT*2.5).
      set test_dist to pos:mag.
      set label_prefix to "Margin (laser measured): ".
    }
  }
  if use_fallback {
    local groundPos to ship:body:geopositionof(pos):position.
    set test_dist to (safety_margin+abs(verticalspeed)*deltaT*2.5).
    set compare_dist to vdot(pos-groundPos,ship:up:vector).
    set label_prefix to "Margin (terrain database guess): ".
  }
  if test_dist < compare_dist { // try to start the burn just a few ticks early
    set safe to true.
    set vd1 to vecdraw(v(0,0,0),pos, green, label_prefix + round(compare_dist-test_dist,1)+"m", 1, true).
  } else {
    set vd1 to 0.
  }

  return safe.
}

