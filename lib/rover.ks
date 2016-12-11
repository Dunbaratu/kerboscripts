run once "/lib/terrain". // for laser terrain usage.

// These locals are really in global namespace.  Some day I need
// to come back here and fix that so it can't interfere
// with other libraries:

// Make your rover have a tuple of at least 3 parallel lasers facing forward-ish
// (and a little down by a few degrees if you like) that can be used to see the
// terrain slope in front of the vessel.
// Give them all this same tag name:
local forward_lasers_name is "obstacle detector".

// Make your rover also have a tuple of at least 3 parallel lasers facing downward
// at the terrain just under it.  They are used to make the rover try to rotate
// to level with the terrain if it gets bounced up and starts flipping.  Give
// those terrain level detecting lasers this tag name:
local downward_lasers_name is "level detector".

local has_obstacle_lasers is false.
local has_leveler_lasers is false.
local obstacle_lasers is 0.
local leveler_lasers is 0.
local battery_full is 0.
local debug is false.

on abort {
  brakes on.
  unlock wheelthrottle.
  unlock wheelsteering.
  print "deliberate error to quit.".
  print 1 / 0.
}


// Given a location, drive there.
// stop when you get there.
function drive_to {
  parameter geopos, cruise_spd, proximity_needed is 10, offset_pitch is 0.

  local steer_pid is PIDLOOP(0.010, 0.0001, 0.005, -1, 1).
  local throttle_pid is PIDLOOP(0.5, 0.01, 0.2, -1, 1).
  
  local steering_off_timestamp is 0.
  local steering_backup_timestamp is 0.
  local collision_eta is 0.
  local collision_steer_sign is 1.

  if debug {
    set debug_drawnorm to vecdraw(v(0,0,0), ship:up:vector, white, "collision_norm", 1, true).
  }

  list resources in reses.
  for res in reses {
    if res:name = "ElectricCharge" {
      set battery_full to res:capacity.
    }
  }

  set obstacle_lasers to get_terrain_lasers(forward_lasers_name).
  if obstacle_lasers:length > 0 {
    set has_obstacle_lasers to true.
    for las in obstacle_lasers { las:setfield("enabled",true). }
  }
  set leveler_lasers to get_terrain_lasers(downward_lasers_name).
  if leveler_lasers:length > 0 {
    set has_leveler_lasers to true.
    for las in leveler_lasers { las:setfield("enabled",true). }
  }
  
  if has_leveler_lasers { 

    // If we are going to use locked steering to muck about
    // with telling it to level itself, then make sure that
    // doesn't interfere with the ability to steer in the
    // yaw axis when ship:control:wheelsteer is set to nonzero values:
    set steeringmanager:RollControlAngleRange to 180.
    local yawkiller to steeringmanager:yawpid.
    set yawkiller:Kp to 0.
    set yawkiller:Kd to 0.
    set yawkiller:Ki to 0.
    // Trick it into thinking it has way more torque than it does, so it
    // will only issue very nerf'ed inputs that are wimpy:
    set steeringManager:yawts to 999999999.
  }

  brakes off.

  local battery_panic is false.

  until geo_dist(geopos) < proximity_needed {
    local use_bearing is  rotated_bearing( geopos, offset_pitch, cruise_spd, collision_eta ).
    local use_wheelsteer is steer_pid:update(time:seconds, use_bearing).
    local battery_ratio is ship:electriccharge / battery_full.
    if battery_ratio < 0.1 {
      set battery_panic to true.
    }
    local speed_diff is 0.
    set speed_diff to forward_speed(offset_pitch) - wanted_speed(geopos, cruise_spd, offset_pitch, battery_panic).
    local use_wheelthrottle is throttle_pid:update(time:seconds, speed_diff).
    if speed_diff > 5 { brakes on.  } else { brakes off. }
    if battery_ratio < 0.02 {
      brakes on.
    }
    if battery_panic and battery_ratio > 0.5 { set battery_panic to false. }
    
    if is_upsidedown(offset_pitch) {
      flip_me(offset_pitch).
      unlock steering.
      steer_pid:reset().
      throttle_pid:reset().
    }
    if has_leveler_lasers {
      lock steering to level_orientation(leveler_lasers).
    }
    if has_obstacle_lasers {
      set collision_eta to collision_danger(obstacle_lasers).
      local abs_collision_eta to abs(collision_eta).
      if abs_collision_eta > 0 and abs_collision_eta < 20 or
         time:seconds < steering_backup_timestamp {
        set steering_off_timestamp to time:seconds + 2.
        // If really close, then panic and actually try to back up straight.
        if abs_collision_eta > 0 and abs_collision_eta < 0.2 or
           time:seconds < steering_backup_timestamp {
          set use_wheelthrottle to -1.
          set use_wheelsteer to 0.
          // Force it to keep going backward for several seconds ignoring all other factors,
          // unless it's already in the midst of doing that:
          if time:seconds > steering_backup_timestamp {
            set steering_backup_timestamp to time:seconds + 2.
          }
        }
      }
    }
    set ship:control:wheelsteer to use_wheelsteer.
    set ship:control:wheelthrottle to use_wheelthrottle.

    clearscreen.
    print "aiming toward bearing " + round(use_bearing, 1) + "    ".
    print "spd is " + round(ship:groundspeed, 2) + "    ".
    print "current control:wheelthrottle is " + round(ship:control:wheelthrottle,2).
    print "current control:wheelsteer is " + round(ship:control:wheelsteer,3).
    print "brakes on? " + brakes + ". ".
    print "forward_speed is " + round(forward_speed(offset_pitch), 3).
    print "wanted_speed is  " + round(wanted_speed(geopos,cruise_spd, offset_pitch, battery_panic),3).
    print "geodist to target is " + round(geo_dist(geopos),2).
    print "LASERS: obstacle detect: " + has_obstacle_lasers + ", leveler: " + has_leveler_lasers.
    if time:seconds < steering_off_timestamp {
      print "NOW IN COLLISION AVOIDANCE MODE!".
      if collision_eta < 0 {
        print "FORCING AIM TO THE LEFT.".
      } else if collision_eta > 0 {
        print "FORCING AIM TO THE RIGHT.".
      } else {
        print "CENTERING AIM.".
      }
    }
    if battery_panic { print "BATTERY LOW PANIC MODE.". }
    wait 0.001.
  }
  set ship:control:wheelthrottle to 0.
  brakes on.
  if has_obstacle_lasers {
    for las in obstacle_lasers {
      las:SETFIELD("Enabled", false).
    }
  }
}

function level_orientation {
  parameter leveler_lasers.
  local norm is get_laser_normal(leveler_lasers).

  return lookdirup(ship:facing:forevector, norm).
}

// Use forward facing collision lasers to detect the slope ahead of us.  If it's
// very steep, then call it an obstacle in need of avoiding:
// Returns 0 if no danger, or number of seconds ETA to collision if there is a danger:
// This is a fuzzy heuristic - it will pretend the ETA is shorter than it really is if
// the distance is slow and we aren't going fast.
// If number of seconds is returned as a negative, then that's a signal that means "turn left".
// If number of seconds is returned as a positive, then that's a signal that means "turn right".
//
// Warning: causes a one-tick wait 0 to ensure reasonable readings.
function collision_danger {
  parameter obstacle_lasers.
  // call it an obstacle if the lasers hit something who's gradient shows a slope > 55 deg.
  local dist is obstacle_lasers[0]:GETFIELD("Distance").
  // If a hit detected on something within a distance ahead (bigger distance if going faster):
  if dist >= 0 and dist < 5 + 8*vdot(ship:velocity:surface,obstacle_lasers[0]:part:facing:vector) {
    // Then see if the hit is for something with a quite vertical slope.  If so, call it an obstacle:
    wait 0.
    local norm is get_laser_normal(obstacle_lasers).

    // If Norm aims away from me, force it to aim at me instead (I want the front side of
    // the obstacle, not its backside, otherwise I can't figure out if I should go left or
    // right properly):
    if vang(norm,ship:facing:forevector) < 90
      set norm to -norm.

    if debug {
      set debug_drawnorm:start to obstacle_lasers[0]:part:position + dist*obstacle_lasers[0]:part:facing:vector.
      set debug_drawnorm:vec to 10*norm.
    }
    local angle is vang(norm, ship:up:vector).
    // if normal is sideways rather than vertical
    if angle > 55 and angle < (180 - 55) {
      local aim_right is (vang(norm, ship:facing:starvector) < 90).
      if dist > 2 {
        if aim_right 
          return dist / max(ship:groundspeed,4).// pretend speed is significant when it's not.
        else 
          return - dist / max(ship:groundspeed,4). 
      } else {
        // fake it and pretend collision is imminent when close, even if it's not:
        if aim_right 
          return 0.1.
        else
          return -0.1.
      }
    }
  }
  return 0. // turn off collision complaining when no hit seen.
}

function geo_dist {
  parameter geo_spot.

  local ship_geo is ship:body:geopositionof(ship:position).

  return (geo_spot:position - ship_geo:position):mag.
}

function flip_me {
  parameter offset_pitch.
  print "OH NOESSS!!! I'm upside down!!! Flipping over...".
  brakes on.

  local rightlegs is ship:partstagged("rightleg").
  local leftlegs is ship:partstagged("leftleg").
  local toplegs is ship:partstagged("topleg").

  if toplegs:length = 0 or leftlegs:length = 0 or rightlegs:length = 0 {
    print "I don't have my 3 flipping legs.".
    return.
  }

  local rightleg_mod is rightlegs[0]:getmodule("ModuleWheelDeployment").
  local leftleg_mod is leftlegs[0]:getmodule("ModuleWheelDeployment").
  local topleg_mod is toplegs[0]:getmodule("ModuleWheelDeployment").

  until not is_upsidedown(offset_pitch) {
    local mode is 0.
    if topleg_mod:getfield("state") = "Retracted" { 
      set mode to 0.
    } else {
      set mode to 1.
    }
    
    if mode = 0 and topleg_mod:getfield("state") = "Retracted" { 
      toggle_leg(topleg_mod).
    } else if mode = 1 and topleg_mod:getfield("state") = "Deployed" { 
      toggle_leg(topleg_mod).
    }
    if mode = 1 and leftleg_mod:getfield("state") = "Retracted" { 
      toggle_leg(leftleg_mod).
    } else if mode = 0 and leftleg_mod:getfield("state") = "Deployed" { 
      toggle_leg(leftleg_mod).
    }
    if mode = 1 and rightleg_mod:getfield("state") = "Retracted" { 
      toggle_leg(rightleg_mod).
    } else if mode = 0 and rightleg_mod:getfield("state") = "Deployed" { 
      toggle_leg(rightleg_mod).
    }
    wait 2.
  }
  print "Rightside up now I think.".
  print "waiting 5 seconds to let things settle.".
  wait 5.
  
  if topleg_mod:getfield("state") = "Retracted" { 
    toggle_leg(topleg_mod).
  }
  if leftleg_mod:getfield("state") = "Retracted" { 
    toggle_leg(leftleg_mod).
  }
  if rightleg_mod:getfield("state") = "Retracted" { 
    toggle_leg(rightleg_mod).
  }
  brakes off.
}

function toggle_leg {
  parameter legModule.

  if legModule:hasevent("Retract") {
    legModule:doevent("Retract").
  } else if legModule:hasevent("Extend") {
    legModule:doevent("Extend").
  }
}

function rotated_forevector {
  parameter pitch_rot.
  return angleaxis(pitch_rot, ship:facing:starvector) * ship:facing:forevector.
}
function rotated_topvector {
  parameter pitch_rot.
  return angleaxis(pitch_rot, ship:facing:starvector) * ship:facing:topvector.
}

function rotated_bearing {
  parameter spot, pitch_rot, cruise_spd is 30, collision_eta is 0.

  local project_myFore is vxcl(ship:up:vector, rotated_forevector(pitch_rot)).
  local project_spotVec is vxcl(ship:up:vector, spot:position).

  local abs_angle is vang(project_myFore, project_spotVec).
  if vdot( project_spotVec, ship:facing:starvector ) < 0 
     set abs_angle to -abs_angle.
  if collision_eta <> 0 {
    // Desire steering more off to the side - more severe the longer we've been detecting collision,
    // and sooner we'll hit the object
    set abs_angle to abs_angle + 90*(2/collision_eta).
  }
  return abs_angle.
}

function is_upsidedown {
  parameter offset_pitch.
  local topvang is vang( rotated_topvector(offset_pitch), ship:up:vector).
  local starvang is vang( ship:facing:starvector, ship:up:vector).

  local result is topvang > 70 or starvang < 20 or starvang > 160.
  return result.
}

function forward_speed {
  parameter offset_pitch.
  return vdot( ship:velocity:surface, rotated_forevector(offset_pitch)).
}

function wanted_speed {
  parameter spot.
  parameter cruise_spd.
  parameter offset_pitch.
  parameter battery_panic.

  if battery_panic { return 0. }

  local bear is rotated_bearing(spot, offset_pitch).
  local return_val is 0.
  if bear = 0 {
    set return_val to min( 0.5 + spot:distance / 10, cruise_spd).
  } else {
    set return_val to min( abs(90/bear), min( 0.5 + spot:distance / 10, cruise_spd)).
  }
  // If there is an obstacle detector laser, use it.
  if has_obstacle_lasers {
    local dist is obstacle_lasers[0]:GetField("Distance").
    if dist < 0 or dist > 500 {
      set return_val to min(5,return_val). // slow down over a jump unless it was already slower than that.
    }
  }
  return return_val.
}
