print "waiting for remote tech to find itself.".
wait 3.
// pilot control.
if HOMECONNECTION:ISCONNECTED {
  if not(exists("1:/lib")) {
    createdir("1:/lib/").
  }
  copypath("0:/lib/navpoint.ks", "1:/lib/").
}

run once "lib/navpoint".

parameter
  draw_arg,      // true = draw vectors, false = don't.
  preset is "",  // string: use preset name for known flight mode.
  reverse is False,
  final_spd is 80.

set yokePull to 0.
set yokeRoll to 0.
set shipRoll to 0.
set shipCompass to 0.

clearscreen.
print "Terminal Keys:".
print "  -/+ = raise/lower current speed:".
print "   V  = toggle hide/show aim vectors.".
print "   G  = toggle gui editing panel.".
print "Action Group Abort = quit, give player control".
sas off.
brakes off.

local nav_list is LIST().
local gui_exists is false.
local cur_aim_i is -1.
local sync_new_cur_aim_i is cur_aim_i.
local sync_new_nav_list is nav_list.

// A callback delegate the gui will use to tell us it changed the
// course list or course index in some way:
function list_change_new_sync_val {
  parameter new_i, new_list.

  set sync_new_cur_aim_i to new_i.
  set sync_new_nav_list to new_list.
}

// When the gui told us it changed the course list or course index,
// this will sync us to it.  This is delayed to only happen once
// per main loop iteration so we don't use the new changed list halfway
// through (which could cause runtime errors like "index out of range" when
// they got edited mid-loop by the GUI triggers.)
function sync_new_gui_list {
  set cur_aim_i to sync_new_cur_aim_i.
  set nav_list to sync_new_nav_list.
}

if preset = "GUI" {
  set nav_list to (gui_edit_course( -1, list_change_new_sync_val@)):COPY.
  set gui_exists to true.
}
else if preset <> "" {
  set nav_list to make_landing_points(preset, reverse, final_spd).
  print "MAKE LANDING POINTS RAN".
  print "nav_list now has " + nav_list:LENGTH + " things.".
} else {
  nav_list:add(points).
}

function displayPitch {
  parameter col,row.

  print "Want Vspd = " + round(wantClimb,1) + "   " at (col,row).
  print "     Vspd = " + round(ship:verticalspeed,1) + " m/s   " at (col,row+1).
  print "yoke pull = " + round(yokePull,2) + "   " at (col,row+2).
}

function displayRoll {
  parameter col,row.

  print "Want Bank = " + round(wantBank,1) + "   " at (col,row).
  print "     Bank = " + round(shipRoll,1) + " m/s   " at (col,row+1).
  print "yoke Roll = " + round(yokeRoll,3) + "    " at (col,row+2).
}

function displayCompass {
  parameter col,row.

  local dispCompass is wantCompass.
  if dispCompass < 0 
    set dispCompass to dispCompass + 360.
  print "Want Comp = " + round(dispCompass,0) + " deg  " at (col,row).
  print "     Comp = " + round(shipCompass,0) + " deg  " at (col,row+1).
}

function displaySpeed {
  parameter col,row.

  print "Want Spd = " + round(wantSpeed,0) + " m/s  " at (col,row).
  print "airSpeed = " + round(ship:airspeed,0) + " m/s  " at (col,row+1).
  print "curthrot = " + round(scriptThrottle,2) + "   " at (col,row+2).
}

function displayOffset {
  parameter col,row,off.

  print "line offset angle = " + round(off,0) + " deg  " at (col,row).
}

function displayProgress {
  parameter index, geo, alti, radius, col,row.

  print "Aiming at nav_list["+index+"]" at (col,row).
  print "Aiming at LAT=" + round(geo:lat,2) + " LNG=" + round(geo:lng,2) + ", ALT " + round(alti,0) + "m" at (col,row+1).
  local d is geo:altitudeposition(alti):mag.
  print "Dist to aim point " + round(d,0) + "m (radius=" +radius+"m) " at (col,row+2).
  print "          Cur ALT " + round(ship:altitude,0) + "m" at (col,row+3).
}

function roll_for {
  parameter ves.

  local raw is vang(ves:up:vector, - ves:facing:starvector).
  if vang(ves:up:vector, ves:facing:topvector) > 90 {
    if raw > 90 {
      return raw - 270.
    } else {
      return raw + 90.
    }
  } else {
    return 90 - raw.
  }
}.

function east_for {
  parameter ves.

  return vcrs(ves:up:vector, ves:north:vector).
}

function compass_for {
  parameter ves.
  parameter mode. // 0,1,2 for 0=facing, 1=orbital vel, 2 = srf vel.

  local pointing is 0.
  if mode = 0 {
    set pointing to ves:facing:forevector.
  } else if mode = 1 {
    set pointing to ves:velocity:orbit.
  } else if mode = 2 {
    set pointing to ves:velocity:surface.
  } else {
    PRINT "ARRGG.. Compass_for was called incorrectly.".
  }

  local east is east_for(ves).

  local trig_x is vdot(ves:north:vector, pointing).
  local trig_y is vdot(east, pointing).

  local result is arctan2(trig_y, trig_x).

  if result < 0 { 
    return 360 + result.
  } else {
    return result.
  }
}.

function angle_off {
  parameter a1, a2. // how far off is a2 from a1.

  local ret_val is a2 - a1.
  if ret_val < -180 {
    set ret_val to ret_val + 360.
  } else if ret_val > 180 {
    set ret_val to ret_val - 360.
  }
  return ret_val.
}

function compass_between_latlngs {
  parameter p1, p2. // latlngs for current and desired position.

  return
    arctan2( sin( p2:lng - p1:lng ) * cos( p2:lat ),
             cos( p1:lat )*sin( p2:lat ) - sin( p1:lat )*cos( p2:lat )*cos( p2:lng - p1:lng ) ).
}

function circle_distance {
 parameter
  p1,     //...this point, as a latlng...
  p2,     //...to this point, as a latlng...
  radius. //...around a body of this radius plus altitude.

 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
 
 return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

function get_want_climb {
  parameter ves, // vessel that's doing the climb
            aim_geo, // aim geoposition
            aim_alt. // aim alt (ASL)

  local alt_diff is aim_alt - ves:altitude.
  local dist is circle_distance( ves:geoposition, aim_geo, ves:body:radius+ves:altitude).

  // Get ground speed, but protect against a weird bug in KSP where if 
  // not moving, the tiny surf velocity can be *smaller* than the vertical
  // speed scalar even though this is physically impossible, which breaks
  // the trigonometry math in :groundspeed and makes it return NaN:
  local spd is 0.001.
  if ves:velocity:surface:mag > spd {
    set spd to ves:groundspeed.
  }

  local time_to_dest is dist / spd.

  return alt_diff / time_to_dest.
}

// Made into a separate function calls so that it's possible to re-init them later
// with the same PID gains - used below in the part called "PANIC MODE".
local pitch_base_Kp is 0.03.
local pitch_base_Ki is 0.01.
local pitch_base_Kd is 0.01.
function init_pitch_pid {
  return PIDLOOP(pitch_base_Kp, pitch_base_Ki, pitch_base_Kd, -1, 1).
}
local roll_base_Kp is 0.005.
local roll_base_Ki is 0.00005.
local roll_base_Kd is 0.003.
function init_roll_pid {
  return PIDLOOP(roll_base_Kp, roll_base_Ki, roll_base_Kd, -1, 1).
}
function init_bank_pid {
  return PIDLOOP(3, 0.00, 5, -45, 45).
}
function init_throt_pid {
  return PIDLOOP(0.02, 0.002, 0.05, 0, 1).
}

set pitchPid to init_pitch_pid().
set bankPid to init_bank_pid().
set rollPid to init_roll_pid().
set throtPid to init_throt_pid().



set wantClimb to 0.
set wantBank to 0.
set wantSpeed to 0.

function inc_cur_point_spd {
  parameter inc.
  local thisPoint is nav_list[cur_aim_i].
  local oldSpd is thisPoint["SPD"].
  if inc > 0 and oldSpd >= 100 or inc < 0 and oldSpd > 100 {
    set inc to inc*10.
  } else if inc > 0 and oldSpd >= 500 or inc < 0 and oldSpd > 500 {
    set inc to inc*20.
  }
  set thisPoint["SPD"] to oldSpd + inc.
}

function handle_input_key {
  if terminal:input:haschar {
    local ch is terminal:input:getchar().
    if ch = "+" and nav_list:length > 0 {
      local inc is 1.
      inc_cur_point_spd(inc).
    } else if ch = "-" and nav_list:length > 0 {
      local inc is -1.
      inc_cur_point_spd(inc).
    } else if ch = "v" {
      set vd_aimline:show to not vd_aimline:show.
      set vd_aimpos:show to not vd_aimpos:show.
    } else if ch = "g" {
      set nav_list to (gui_edit_course( cur_aim_i, list_change_new_sync_val@)):COPY.
    }
  }
}

// Start one position back from the end of the waypoint list, so there is
// a phantom "prev" waypoint to help give info how to align the first turn.
set cur_aim_i to nav_list:length-2.

set vd_aimline to vecdraw(v(0,0,0),v(1,0,0),RGBA(1,0,0,2),"waypoint line",1,draw_arg,0.4).
set vd_aimpos to vecdraw(v(0,0,0),v(1,0,0),RGBA(1,1,0,2),"aimpoint",1,draw_arg,0.4).

set user_quit to false.
set need_pid_reinit to false.

on abort set user_quit to true.

when alt:radar < 200 then {
  if not gear {
    gear on.
    set warp to 0.
    hudtext( "GEAR DOWN AND WARP 1x", 8, 2, 32, WHITE, false).
  }
  preserve.
}
when alt:radar > 200 then {
  if gear {
    gear off.
    hudtext( "GEAR UP", 8, 2, 32, WHITE, false).
  }
  preserve.
}
local has_been_airborne is false.

until user_quit or 
      (status="LANDED" and has_been_airborne) {

  wait 0.

  handle_input_key().

  // Let the user change the course index from gui if they did:
  if gui_exists {
    sync_new_gui_list().
  }

  if cur_aim_i < 0 {
    print "WAITING for NAVPOINT." at (10,5).
    // Let the user change the course index from gui if they did:
  } else {
    print "                     " at (10,5).

    local cur_way_geo is nav_list[cur_aim_i]["GEO"].
    local cur_spd_want is nav_list[cur_aim_i]["SPD"].
    local cur_aim_alt is nav_list[cur_aim_i]["ALT"].
    local cur_aim_AGL is nav_list[cur_aim_i]["AGL"].
    local cur_aim_spd is nav_list[cur_aim_i]["SPD"].
    local cur_aim_radius is nav_list[cur_aim_i]["RADIUS"].
    // transform AGL to ASL:
    if cur_aim_AGL {
      set cur_aim_alt to cur_aim_alt + cur_way_geo:terrainheight.
      set nav_list[cur_aim_i]["AGL"] to False.
      set nav_list[cur_aim_i]["ALT"] to cur_aim_alt.
    }

    // Get the previous geo point, or use current ship coord for it
    // if there is no prev geo point yet:
    local prev_aim_geo is 0.
    local prev_aim_alt is 0.
    local prev_aim_agl is False.
    if cur_aim_i < nav_list:length - 1 {
      set prev_aim_geo to nav_list[cur_aim_i+1]["GEO"].
      set prev_aim_alt to nav_list[cur_aim_i+1]["ALT"].
      set prev_aim_AGL to nav_list[cur_aim_i+1]["AGL"].
      set prev_aim_radius to nav_list[cur_aim_i+1]["RADIUS"].
      if prev_aim_AGL {
        set prev_aim_alt to prev_aim_alt + prev_aim_geo:terrainheight.
        set nav_list[cur_aim_i+1]["AGL"] to False.
        set nav_list[cur_aim_i+1]["ALT"] to prev_aim_alt.
      }
    } else {
      set prev_aim_geo to ship:geoposition.
      set prev_aim_alt to ship:altitude.
      set prev_aim_agl to False.
    }

    local prev_aim_pos is prev_aim_geo:altitudeposition(prev_aim_alt).

    local cur_aim_line_pos is cur_way_geo:altitudeposition(cur_aim_alt).

    // Change the cur_aim_geo to a point partway between point i+1 and i,
    // a fraction of the distance from ship to point i, along the line backward from
    // point i to point i+1.  This aims at the line between i+1 and i.
    local dist_to_aim is (cur_aim_line_pos - ship:position):mag.
    local unit_vec_backward is (prev_aim_pos - cur_aim_line_pos):normalized.
    local offset_angle is vang(cur_aim_line_pos-ship:position, -1*unit_vec_backward). // the more off it is, the less to move it.
    local fraction is 0.2+offset_angle/35. // the more off it is, the less to move it.
    set cur_aim_pos to cur_aim_line_pos + fraction*dist_to_aim*unit_vec_backward.
    set cur_aim_geo to ship:body:geopositionof(cur_aim_pos).

    set vd_aimline:start to prev_aim_pos.
    set vd_aimline:vec to cur_aim_line_pos - prev_aim_pos.
    set vd_aimpos:start to ship:position.
    set vd_aimpos:vec to cur_aim_pos - ship:position.

    set wantCompass to compass_between_latlngs(ship:geoposition, cur_aim_geo).
    set wantSpeed to cur_spd_want.

    set wantClimb to get_want_climb(ship, cur_aim_geo, cur_aim_alt).

    // Let the user change the course index from gui if they did:
    if gui_exists {
      sync_new_gui_list().
    }
    // Then we change it if we hit the waypoint.
    if (cur_aim_line_pos - ship:position):mag < cur_aim_radius {
      set cur_aim_i to cur_aim_i - 1.
      if gui_exists {
        gui_update_course_index(cur_aim_i).
      }
    }
      
    set shipSpd to ship:airspeed.
    set scriptThrottle to throtPid:Update(time:seconds, shipSpd - wantSpeed).
    lock throttle to scriptThrottle.

    set shipRoll to roll_for(ship).
    set shipCompass to compass_for(ship,2). // srf vel mode

    set yokePull to pitchPID:Update( time:seconds, ship:verticalspeed - wantClimb ).
    set ship:control:pitch to yokePull.

    // normal desired bank when things are going well:
    set wantBank to bankPid:Update( time:seconds, angle_off(wantCompass, shipCompass) ).
    // override that with a sanity-seeking flat bank when things aren't going well:
    if abs(wantClimb-ship:verticalspeed) > 50 {
      set wantBank to 0.
      if not need_pid_reinit { // first time this happened.
        hudtext( "PANIC MODE - IGNORING COMPASS - JUST LEVELLING", 8, 2, 32, yellow, false).
      }
      set need_pid_reinit to true.
    } else {
      // When we have been overriding the bank this way, need to reinit the PID
      // controller for it so it doesn't "learn" incorrectly from what was happening
      // in the past while its suggested inputs weren't actually being used:
      if need_pid_reinit {
        hudtext( "PANIC MODE OVER - RESUMING NORMAL FLIGHT", 8, 2, 32, white, false).
        set bankPid to init_bank_pid().
        set throtPid to init_throt_pid().
        set rollPid to init_roll_pid().
        set pitchPid to init_pitch_pid().
        set need_pid_reinit to false.
      }
    }
    // Adjust PID tune according to speed of aircraft:
    pid_tune_for_speed(shipSpd, pitchPID, rollPID).
    
    set yokeRoll to rollPID:Update(time:seconds, shipRoll - wantBank ).
    set ship:control:roll to yokeRoll.

    displayCompass(5,8).
    displayRoll(5,12).
    displayPitch(5,16).
    displaySpeed(5,20).
    displayOffset(5,24,offset_angle).
    displayProgress(cur_aim_i, cur_way_geo, cur_aim_alt, cur_aim_radius, 3,27).
    print round(cur_aim_spd,0) + " m/s " at (39,1).

    if (not has_been_airborne) and
       ship:status <> "LANDED" and 
       ship:status <> "PRELAUNCH" {

       set has_been_airborne to true.
    }
  }
}

if user_quit {
  sas on.
  print "QUITTING.. USER ABORT".
  set warp to 0.
} else {
  if status="LANDED" or status="SPLASHED" {
    brakes on.
    print "BRAKES ON.".
    lock throttle to 0.
  }
  // use SAS instead of steering to keep it from doing a ground spin:
  unlock steering.
  SAS on.
  wait until status="LANDED" and groundspeed < 10.
  SAS off.
}
set vd_aimpos to 0.
set vd_aimline to 0.
set ship:control:pilotmainthrottle to 0.
set ship:control:neutralize to true.
if gui_exists
  gui_close_edit_course().

function pid_tune_for_speed {
  parameter speed, pitchPID, rollPID.

  local dampener is 200/(4*speed+50).
  set pitchPID:Kp to pitch_base_Kp * dampener.
  set pitchPID:Ki to pitch_base_Ki * dampener.
  set pitchPID:Kd to pitch_base_Kd * dampener.
  set rollPID:Kp to roll_base_Kp * dampener.
  set rollPID:Ki to roll_base_Ki * dampener.
  set rollPID:Kd to roll_base_Kd * dampener.
}
