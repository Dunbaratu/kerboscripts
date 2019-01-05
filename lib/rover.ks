run once "/lib/terrain". // for laser terrain usage.

// These locals are really in global namespace.  Some day I need
// to come back here and fix that so it can't interfere
// with other libraries:

// Make your rover have a tuple of at least 3 parallel lasers facing forward-ish
// (and a little down by a few degrees if you like) that can be used to see the
// terrain slope in front of the vessel.
// Give them all this same tag name:
local left_lasers_name is "left obstacle detector".
local right_lasers_name is "right obstacle detector".

// Make your rover also have a tuple of at least 3 parallel lasers facing downward
// at the terrain just under it.  They are used to make the rover try to rotate
// to level with the terrain if it gets bounced up and starts flipping.  Give
// those terrain level detecting lasers this tag name:
local downward_lasers_name is "level detector".

local has_left_lasers is false.
local has_right_lasers is false.
local has_leveler_lasers is false.
local left_lasers is 0.
local right_lasers is 0.
local leveler_lasers is 0.
local battery_full is 0.
local debug is false.
local leveler_deadzone is 3. // don't let leveler steering get integral windup for sitting unlevel.
local g_left_slope is 0.
local g_right_slope is 0.
local g_dist is 0.
local yaw_enabled is true.
local twarp is kuniverse:timewarp.
local suppress_control is false.

on abort {
  brakes on.
  unlock wheelthrottle.
  unlock wheelsteering.
  set ship:control:neutralize to true.
  steeringmanager:resettodefault().
  print "deliberate error to quit.".
  print 1 / 0.
}


// Given a location, drive there.
// stop when you get there.
function drive_to {
  parameter geopos, cruise_spd, jump_detect is false, proximity_needed is 10, offset_pitch is 0.

  local steer_pid is PIDLOOP(0.01, 0.00002, 0.003, -1, 1).
  local throttle_pid is PIDLOOP(0.5, 0.01, 0.2, -1, 1).
  
  local steering_off_timestamp is 0.
  local steering_backup_timestamp is 0.
  local collision_eta is 0.
  local collision_steer_sign is 1.
  local steering_is_locked is false.


  local v1 is getvoice(1).
  set v1:wave to "pulse".
  set v1:volume to 1.
  set v1:attack to 0.1.
  set v1:sustain to 1.
  set v1:release to 0.1.

  if debug {
    set debug_drawnorm to vecdraw(v(0,0,0), ship:up:vector, white, "collision_norm", 1, true).
  }

  local oldSas is SAS.
  SAS off.
  set warp to 0.
  until kuniverse:timewarp:rate = 1 {
    print "Waiting for timewarp rate to come down to 1x before starting.".
    wait 1.
  }

  list resources in reses.
  for res in reses {
    if res:name = "ElectricCharge" {
      set battery_full to res:capacity.
    }
  }

  set left_lasers to get_terrain_lasers(left_lasers_name).
  set has_left_lasers to left_lasers:length > 0.
  set right_lasers to get_terrain_lasers(right_lasers_name).
  set has_right_lasers to right_lasers:length > 0.
  set leveler_lasers to get_terrain_lasers(downward_lasers_name).
  set has_leveler_lasers to leveler_lasers:length > 0.
  all_lasers_toggle(true).
  
  if has_leveler_lasers { 

    // If we are going to use locked steering to muck about
    // with telling it to level itself, then make sure that
    // doesn't interfere with the ability to steer in the
    // yaw axis when ship:control:wheelsteer is set to nonzero values:
    disable_yaw().
  }

  brakes off.

  local battery_panic is false.
  local timestamp_start_okay_speed is time:seconds.
  local timestamp_start_poor_speed is -1.
  local hill_sideways_mode is false.
  local hill_sideways_sign is 0.

  until geo_dist(geopos) < proximity_needed {
    tune_pid(steer_pid).

    local battery_ratio is ship:electriccharge / battery_full.
    if battery_ratio < 0.1 {
      set battery_panic to true.
      all_lasers_toggle(false).
    }
    if battery_ratio < 0.05 {
      set battery_panic to true.
      all_lasers_toggle(false).
      HUDTEXT("ALL CONTROLS OFF FOR HIBERNATION!", 3,2,20,yellow,false).
      brakes on.
      getvoice(1):play(list(note(200,0.3),note(150,0.3),note(130,0.4))).
      set suppress_control to true.
      set ship:control:wheelsteer to 0.
      set ship:control:wheelthrottle to 0.
    }
    local forSpeed is forward_speed(offset_pitch).
    local wSpeed is wanted_speed(geopos, cruise_spd, offset_pitch, battery_panic, jump_detect).
    if hill_sideways_mode {
      set wSpeed to wSpeed*2. // speed will be in "wrong" direction, don't dampen as much as that usually does.
    }
    local speed_diff is forSpeed - wSpeed.
    local achieved_speed_ratio is forSpeed/max(wSpeed,0.1).
    local use_wheelthrottle is throttle_pid:update(time:seconds, speed_diff).
    if not(battery_panic) and (speed_diff > 5 or forSpeed < -4) { brakes on.  } else { brakes off. }

    if achieved_speed_ratio < 0.3 {
      if timestamp_start_poor_speed < 0 {
        set timestamp_start_poor_speed to time:seconds.
        set timestamp_start_okay_speed to -1.
      } else {
        if time:seconds > timestamp_start_poor_speed + 3 {
          if not(hill_sideways_mode) { // only do this message when it first changes:
            HUDTEXT("Too hard to go forward.  Going sideways a bit.",3,2,20,yellow,false).
            getvoice(1):play(list(note(500,0.3),note(450,0.3),note(400,0.4))).
          }
          set hill_sideways_mode to true.
        }
      }
      if timestamp_start_poor_speed > 0 and time:seconds > timestamp_start_poor_speed + 35 {
        HUDTEXT("This deflection doesn't work.  Try the other way.",3,2,20,yellow,false).
        getvoice(1):play(list(note(200,0.5))).
        set hill_sideways_sign to -1 * hill_sideways_sign.
      }
    } else if achieved_speed_ratio > 0.5 {
      if timestamp_start_okay_speed < 0 {
        set timestamp_start_okay_speed to time:seconds.
        set timestamp_start_poor_speed to -1.
      } else {
        if time:seconds > timestamp_start_okay_speed + 20 {
          if hill_sideways_mode { // only do this message when it first changes:
            HUDTEXT("Done going sideways a bit.  Back to forward.",3,2,20,yellow,false).
            getvoice(1):play(list(note(400,0.3),note(450,0.3),note(500,0.4))).
          }
          set hill_sideways_mode to false.
          set hill_sideways_sign to 0.
        }
      }
    }

    local use_bearing is  rotated_bearing( geopos, offset_pitch, cruise_spd, collision_eta ).
    if hill_sideways_mode {
      if hill_sideways_sign = 0 {
        local want_vec is geopos:position:normalized.
        local right_vec is vcrs(ship:up:vector, want_vec).
        local height_right is ship:body:geopositionof(10*(want_vec+right_vec)):terrainheight.
        local height_left is ship:body:geopositionof(10*(want_vec-right_vec)):terrainheight.
        if height_right < height_left 
          set hill_sideways_sign to 1.
        else
          set hill_sideways_sign to -1.
      }
      set use_bearing to use_bearing + hill_sideways_sign*65.
    }
    local use_wheelsteer is steer_pid:update(time:seconds, use_bearing).

    // in battery panic mode once we slow down enough just hit the brakes and hold there.
    if battery_panic and
        (ship:velocity:surface:mag < 0.4 or vang(ship:velocity:surface,ship:facing:forevector) > 50) {
      brakes on.
      set suppress_control to true.
      set ship:control:wheelsteer to 0.
      set ship:control:wheelthrottle to 0.
      set use_wheelthrottle to 0.
      if twarp:mode <> "RAILS" {
        set twarp:warp to 0.
        wait until groundspeed < 0.4.
      }
      set twarp:mode to "RAILS".
      set twarp:WARP to 5.
    }

    if ship:status = "LANDED" or ship:status = "SPLASHED" {
      if yaw_enabled {
        HUDTEXT("Grounded, disabling yawing",3,2,20,yellow,false).
        getvoice(1):play(slidenote(800,600,0.3)).
        disable_yaw().
      }
    } else {
      if not(yaw_enabled) {
        HUDTEXT("Airborne, enabling yawing",3,2,20,yellow,false).
        getvoice(1):play(slidenote(600,800,0.3)).
        enable_yaw().
      }
    }

    if battery_panic and battery_ratio > 0.9 {
      set battery_panic to false. 
      set twarp:WARP to 0.
      wait until twarp:issettled.
      set twarp:mode to "PHYSICS".
      set twarp:WARP to 1.
      set hill_sideways_mode to false.
      set hill_sideways_sign to 0.
      all_lasers_toggle(true).
      steeringmanager:resetpids().
    }
    
    if is_upsidedown(offset_pitch) {
      flip_me(offset_pitch).
      v1:play(list(note(250,0.1), note(200,0.1))).
      unlock steering.
      HUDTEXT("STEERING IS UNLOCKED",3,2,15,yellow,false).
      set steering_is_locked to false.
      steer_pid:reset().
      throttle_pid:reset().
    }
    if has_leveler_lasers and not battery_panic {
      if not(steering_is_locked) {
        lock steering to level_orientation(offset_pitch, leveler_lasers).
        set steering_is_locked to true.
        HUDTEXT("STEERING IS LOCKED",3,2,15,yellow,false).
      }

      // Prevent integral windup that comes from having a rover
      // that doesn't sit level on it's wheels and is always a
      // few degrees off from lined up with the terrain:
      if steeringmanager:angleerror < leveler_deadzone {
        steeringmanager:resetpids().
      }

    }
    if has_left_lasers and has_right_lasers {
      set collision_eta to collision_danger(left_lasers, right_lasers).
      local abs_collision_eta to abs(collision_eta).
      if abs_collision_eta > 0 and abs_collision_eta < 20 or
         time:seconds < steering_backup_timestamp {
        set steering_off_timestamp to time:seconds + 1.
        v1:play(slidenote(300,500,0.3,0.1)).
        // If really close, then panic and actually try to back up straight.
        if abs_collision_eta > 0 and abs_collision_eta < 0.5 or
           time:seconds < steering_backup_timestamp {
          set use_wheelthrottle to -1.
          // Force it to keep going backward for several seconds ignoring all other factors,
          // unless it's already in the midst of doing that:
          if time:seconds > steering_backup_timestamp {
            set steering_backup_timestamp to time:seconds + 1.5. 
          }
        }
      }
    }
    // Whenever we have negative speed, reverse steering:
    if vdot(ship:velocity:surface, rotated_forevector(offset_pitch)) < 0 {
      set use_wheelsteer to -use_wheelsteer.
    }

    // When trying to recharge, stop trying to power the driving as that can keep power pegged at zero and never recharges:
    if suppress_control {
      set use_wheelsteer to 0.
      set use_wheelthrottle to 0.
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
    print "wanted_speed is  " + round(wSpeed,1).
    print "geodist to target is " + round(geo_dist(geopos),2).
    print "USE Abort Action group to kill program and park.".
    print " -------- obstacle detection: --------  ".
    print "LASERS: left: " + has_left_lasers + ", right: " + has_right_lasers + ", leveler: " + has_leveler_lasers.
    if has_left_lasers and has_right_lasers {
      print "  Dist: " + round(g_dist,2)+ "m, L slope: " + round(g_left_slope,2) + ", R slope: " + round(g_right_slope,2).
      print "  Collision ETA: " + round(collision_eta,1) + "s".
    }
    if time:seconds < steering_off_timestamp {
      print "AVOIDING OBSTACLE!!".
      if collision_eta < 0 {
        print "FORCING AIM TO THE LEFT.".
      } else if collision_eta > 0 {
        print "FORCING AIM TO THE RIGHT.".
      } else {
        print "CENTERING AIM.".
      }
    }
    if battery_panic {
      print "BATTERY LOW PANIC MODE.". 
    }
    wait 0.001.
  }
  all_lasers_toggle(false).
  set ship:control:wheelthrottle to 0.
  brakes on.
  enable_yaw().
  roll_reset().
  wait 0.
  set SAS to oldSAS.
}

function lasers_toggle {
  parameter lasers, newState.

  // operates on a list or a single laser.  If a single
  // laser was passed in then make it a list of one thing
  // so the rest of the code can continue the same way:
  if not lasers:ISTYPE("LIST") 
    set lasers to LIST(lasers).

  for las in lasers {
    las:SETFIELD("Enabled", newState).
  }
}

function all_lasers_toggle {
  parameter newState.

  if has_left_lasers {
    lasers_toggle( left_lasers, newState ).
  }
  if has_right_lasers {
    lasers_toggle( right_lasers, newState ).
  }
  if has_leveler_lasers {
    lasers_toggle( leveler_lasers, newState ).
  }
}

// Tune the steering pid to dampen it when in phys warp.
function tune_pid {
  parameter the_pid.

  local phys_warp is 1.
  if kuniverse:timewarp:mode = "PHYSICS" {
    set phys_warp to kuniverse:timewarp:rate.
  }
  set the_pid:KP to 0.01 / phys_warp.
  set the_pid:KI to 0.00002 / phys_warp.
  set the_pid:KD to 0.003 / phys_warp.
}

steeringmanager:resettodefault(). // just in case a previous run of this script left it screwed up.

global yaw_disable_roll_angle_orig is steeringmanager:RollControlAngleRange.

global yaw_disable_Ki_orig is steeringmanager:yawpid:Ki.
global yaw_disable_Kd_orig is steeringmanager:yawpid:Kd.
global yaw_disable_Ts_orig is steeringManager:yawts.
function disable_yaw {
  if not(yaw_enabled)
    return.
  set yaw_enabled to false.
  local yawkiller to steeringmanager:yawpid.
  set yaw_disable_Kp_orig to yawkiller:Kp.
  set yaw_disable_Ki_orig to yawkiller:Ki.
  set yaw_disable_Kd_orig to yawkiller:Kd.
  set yaw_disable_Ts_orig to steeringManager:yawts.
  set yaw_disable_roll_angle_orig to  steeringmanager:RollControlAngleRange.
  set steeringmanager:RollControlAngleRange to 180.
  set yawkiller:Kp to 0.
  set yawkiller:Ki to 0.
  set yawkiller:Kd to 0.
  // Trick it into thinking it has way more torque than it does, so it
  // will only issue very nerf'ed inputs that are wimpy:
  set steeringManager:yawts to 999999999.
}
function enable_yaw {
  if yaw_enabled
    return.
  local yawkiller to steeringmanager:yawpid.
  set yawkiller:Kp to yaw_disable_Kp_orig.
  set yawkiller:Ki to yaw_disable_Ki_orig.
  set yawkiller:Kd to yaw_disable_Kd_orig.
  // Trick it into thinking it has way more torque than it does, so it
  // will only issue very nerf'ed inputs that are wimpy:
  set steeringManager:yawts to yaw_disable_Ts_orig.
  set yaw_enabled to true.
}
function roll_reset {
  set steeringmanager:RollControlAngleRange to yaw_disable_roll_angle_orig.
}

function level_orientation {
  parameter offset_pitch, leveler_lasers.
  local norm is get_laser_normal(leveler_lasers).

  local aim is 0.
  // Aim either at facing (if landed) or at velocity (if in a jump):
  if yaw_enabled {
    set aim to velocity:surface.
  } else {
    set aim to rotated_forevector(offset_pitch).
  }
  return lookdirup(vxcl(norm,aim), norm).
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
  parameter left_lasers, right_lasers.

  wait 0. // ensure the laser caculations happen in the same tick.
  // call it an obstacle if the lasers hit something who's gradient shows a slope > 55 deg.
  local dist_L0 is get_laser_dist(left_lasers[0]).
  local dist_L1 is get_laser_dist(left_lasers[1]).
  local dist_R0 is get_laser_dist(right_lasers[0]).
  local dist_R1 is get_laser_dist(right_lasers[1]).
  set g_dist to min(min(min(dist_L0,dist_L1),dist_R0),dist_R1).

  local return_val is 0.
  set g_left_slope to 0.
  set g_right_slope to 0.

  if g_dist < 500 {
    // get the 4 hits as XYZ positions:
    local left_hitpos0 is left_lasers[0]:part:position + left_lasers[0]:part:facing:vector * dist_L0.
    local left_hitpos1 is left_lasers[1]:part:position + left_lasers[1]:part:facing:vector * dist_L1.
    local right_hitpos0 is right_lasers[0]:part:position + right_lasers[0]:part:facing:vector * dist_R0.
    local right_hitpos1 is right_lasers[1]:part:position + right_lasers[1]:part:facing:vector * dist_R1.

    // These are two unit vectors to map 3D space into a 2D reference frame
    // which is vertically oriented to match the plane the lasers are in.
    // this assumes all 4 lasers are parallel:
    local x_axis is left_lasers[0]:part:facing:vector. //use laser as X direction.
    local y_axis is vxcl(x_axis, ship:up:vector). // up-ish, perpendicular to laser direction.

    //Ensure laser 0 is the top and 1 is the bottom. swap if they're not:
    if vdot(left_hitpos1,x_axis) < vdot(left_hitpos0,x_axis) {
      local temp is left_hitpos0.
      set left_hitpos0 to left_hitpos1.
      set left_hitpos1 to temp.
      set temp to dist_L0.
      set dist_L0 to dist_L1.
      set dist_L1 to temp.
    }
    if vdot(right_hitpos1,x_axis) < vdot(right_hitpos0,x_axis) {
      local temp is right_hitpos0.
      set right_hitpos0 to right_hitpos1.
      set right_hitpos1 to temp.
      set temp to dist_R0.
      set dist_R0 to dist_R1.
      set dist_R1 to temp.
    }

    // Get the slopes in 2D terms of the two basis axis vectors:
    local left_delta_vec is left_hitpos1 - left_hitpos0.
    local left_delta_x is max(0.001, vdot(left_delta_vec, x_axis)). // max to prevent infinite (div by zero) slope.
    local left_delta_y is vdot(left_delta_vec, y_axis).
    set g_left_slope to abs(left_delta_y / left_delta_x).
    local right_delta_vec is right_hitpos1 - right_hitpos0.
    local right_delta_x is max(0.001, vdot(right_delta_vec, x_axis)). // max to prevent infinite (div by zero) slope.
    local right_delta_y is vdot(right_delta_vec, y_axis).
    set g_right_slope to abs(right_delta_y / right_delta_x).

    
    // We now know left/right distances and left/right slopes - make the decision based on that:
    if g_left_slope < 1.7 { // if less than about 60 degree slope
      // terrain hit not obstacle hit so pretend it's really far away:
      set dist_L0 to 500.
      set dist_L1 to 500.
    }
    if g_right_slope < 1.7 { // if less than about 60 degree slope
      // terrain hit not obstacle hit so pretend it's really far away:
      set dist_R0 to 500.
      set dist_R1 to 500.
    }
    // Recalc g_dist after we have altered the distances based on slopes:
    set g_dist to min(min(min(dist_L0,dist_L1),dist_R0),dist_R1).

    // Check again - if both left and right sides are low slope hits then g_dist will now be far
    // and we can safely ignore the hit:
    if g_dist < 500 {
      // ETA is based on the shortest distance:
      set return_val to g_dist / max(0.1, ship:velocity:surface:mag).
      // Now pick a sign for the ETA based on which side is closer:
      if dist_R0 < dist_L0 {
        set return_val to - return_val.
      }
      // Now fake the ETA to be smaller than it really is if the distance is short:
      if g_dist < 2 {
        set return_val to return_val / 100.
      }
    }
  }
  return return_val. // turn off collision complaining when no hit seen.
}

// Return a LaserDist module's distance OR if it's -1, the
// special flag meaning no hit, then return a big number instead:
function get_laser_dist {
  parameter las.
  local reading is las:GETFIELD("Distance").
  if reading < 0 {
    return 999999999.
  } else {
    return reading.
  }
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

local collision_cooldown_timestamp is 0.
local prev_collision_eta is 0.

function rotated_bearing {
  parameter spot, pitch_rot, cruise_spd is 30, collision_eta is 0.

  // This logic is here to force it to keep turning a little while
  // longer after the obstacle isn't detected anymore, so it won't
  // just immediately turn back into the corner of it again:
  if collision_eta = 0 {
    if time:seconds < collision_cooldown_timestamp {
      set collision_eta to prev_collision_eta.
    }
  } else {
    set collision_cooldown_timestamp to time:seconds + 1.
    set prev_collision_eta to collision_eta.
  }

  local project_myFore is vxcl(ship:up:vector, rotated_forevector(pitch_rot)).
  local project_spotVec is vxcl(ship:up:vector, spot:position).

  local abs_angle is vang(project_myFore, project_spotVec).
  if vdot( project_spotVec, ship:facing:starvector ) < 0 
     set abs_angle to -abs_angle.
  if collision_eta <> 0 {
    // Desire steering more off to the side - more severe the longer we've been detecting collision,
    // and sooner we'll hit the object
    set abs_angle to abs_angle + min(90,max(-90, 90*(2/collision_eta))).
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
  parameter jump_detecting.

  if battery_panic { return 0. }
  brakes off.
  set suppress_control to false.
  local bear is rotated_bearing(spot, offset_pitch).
  local return_val is 0.
  if bear = 0 
    set bear to 0.001. // avoid divide-by-zero in next line.

  // Amount to suppress speed to when facing wrong way varies by gravity because it's an anti-flipover measure.
  local grav is ship:body:mu / ship:body:radius^2. 

  set return_val to min( 0.5 + spot:distance / 10, cruise_spd).
  set return_val to min( return_val*abs((grav*2.5)/bear), return_val).

  // If there is an obstacle detector laser, use it.
  if has_left_lasers and jump_detecting {
    local dist is get_laser_dist(left_lasers[0]).
    if dist > 500 {
      set return_val to min(5,return_val). // slow down over a jump unless it was already slower than that.
    }
  }
  return return_val.
}
