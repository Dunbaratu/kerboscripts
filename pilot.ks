parameter
  system is "Stock",
  draw_arg is false,      // true = draw vectors, false = don't.
  preset is "GUI",  // string: use preset name for known flight mode.
  reverse is False,
  final_spd is 80.

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


set yokePull to 0.
set yokeRoll to 0.
set shipRoll to 0.
set shipCompass to 0.
local user_pitch_pid_adjust is 0.
local user_roll_pid_adjust is 0.

clearscreen.
print "Pitch(U/D ARROW): Smooth <_______________> Tight.".
print " Roll(L/R ARROW): Smooth <_______________> Tight.".
print "  -/+ = raise/lower current speed:".
print "   V  = toggle hide/show aim vectors.".
print "   G  = toggle gui editing panel.".
print "   S  = sea mode (no gear).".
print "Action Group 10 = quit, give player control".
print " ".
display_user_pid_adjust().
sas off.
brakes off.

local nav_list is LIST().
local gui_exists is false.
local cur_aim_i is -1.
local sync_new_cur_aim_i is cur_aim_i.
local sync_new_nav_list is nav_list.
local sea_mode is false.

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
  print "     Bank = " + round(shipRoll,1) + "   " at (col,row+1).
  print "yoke Roll = " + round(yokeRoll,3) + "   " at (col,row+2).
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
  parameter index, geo, alti, radius, sea_mode, col,row.

  print "Aiming at nav_list["+index+"]" at (col,row).
  print "Aiming at LAT=" + round(geo:lat,2) + " LNG=" + round(geo:lng,2) + ", ALT " + round(alti,0) + "m" at (col,row+1).
  local d is geo:altitudeposition(alti):mag.
  print "Dist to aim point " + round(d,0) + "m (radius=" +radius+"m) " at (col,row+2).
  print "          Cur ALT " + round(ship:altitude,0) + "m" at (col,row+3).
  print "SEA MODE: " + sea_mode + "  " at (col,row+4).
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
local pitch_base_Kd is 0.03.
function init_pitch_pid {
  return PIDLOOP(pitch_base_Kp, pitch_base_Ki, pitch_base_Kd, -1, 1).
}
local roll_base_Kp is 0.005.
local roll_base_Ki is 0.0001.
local roll_base_Kd is 0.003.
function init_roll_pid {
  return PIDLOOP(roll_base_Kp, roll_base_Ki, roll_base_Kd, -1, 1).
}
function init_bank_pid {
  return PIDLOOP(3, 0.00, 5, -45, 45).
}
function init_wheel_pid {
  return PIDLOOP(0.003, 0.0001, 0.001, -1, 1).
}
function init_throt_pid {
  return PIDLOOP(0.02, 0.002, 0.05, -0.5, 0.5).
}

set pitchPID to init_pitch_pid().
set bankPID to init_bank_pid().
set rollPID to init_roll_pid().
set throtPID to init_throt_pid().
set wheelPID to init_wheel_pid().



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
    } else if ch = "s" {
      set sea_mode to not sea_mode.
    } else if ch = TERMINAL:INPUT:DOWNCURSORONE {
      set user_pitch_pid_adjust to max(-7, user_pitch_pid_adjust - 1).
      display_user_pid_adjust().
    } else if ch = TERMINAL:INPUT:UPCURSORONE {
      set user_pitch_pid_adjust to min(7, user_pitch_pid_adjust + 1).
      display_user_pid_adjust().
    } else if ch = TERMINAL:INPUT:LEFTCURSORONE {
      set user_roll_pid_adjust to max(-7, user_roll_pid_adjust - 1).
      display_user_pid_adjust().
    } else if ch = TERMINAL:INPUT:RIGHTCURSORONE {
      set user_roll_pid_adjust to min(7, user_roll_pid_adjust + 1).
      display_user_pid_adjust().
    }
  }
}

function display_user_pid_adjust {
  print "_______________" at (26,0).
  print "|" at (33 + user_pitch_pid_adjust, 0).
  print "_______________" at (26,1).
  print "|" at (33 + user_roll_pid_adjust, 1).
}


function pid_tune_for_conditions {
  parameter speed, pitchPID, rollPID.

  // Make sure it has a gentle touch at high speed:
  local dampener is 200/(8*speed+50).

  // Tighten when close to ground so it will hurry up and flare:
  local tightener is max(1.0, 0.01*(200 - alt:radar)).

  local user_pitch_pid_coef is 1.5^user_pitch_pid_adjust.
  set pitchPID:Kp to pitch_base_Kp * dampener * tightener * user_pitch_pid_coef.
  set pitchPID:Ki to pitch_base_Ki * dampener * tightener * user_pitch_pid_coef.
  set pitchPID:Kd to pitch_base_Kd * dampener * tightener * user_pitch_pid_coef.

  local user_roll_pid_coef is 1.5^user_roll_pid_adjust.
  set rollPID:Kp to roll_base_Kp * dampener * tightener * user_roll_pid_coef.
  set rollPID:Ki to roll_base_Ki * dampener * tightener. // NOT ^ user_pid_coef
  set rollPID:Kd to roll_base_Kd * dampener * tightener * user_roll_pid_coef.
}

// Start one position back from the end of the waypoint list, so there is
// a phantom "prev" waypoint to help give info how to align the first turn.
set cur_aim_i to nav_list:length-2.

set vd_aimline to vecdraw(v(0,0,0),v(1,0,0),RGBA(1,0,0,2),"waypoint line",1,draw_arg,0.4).
set vd_aimpos to vecdraw(v(0,0,0),v(1,0,0),RGBA(1,1,0,2),"aimpoint",1,draw_arg,0.4).

set user_quit to false.
set need_pid_reinit to false.

on AG10 set user_quit to true.

when alt:radar < 200 then {
  if not gear and not sea_mode {
    gear on.
    hudtext( "GEAR DOWN", 8, 2, 32, WHITE, false).
  }
  preserve.
}
when alt:radar < 200 and warp > 0 then {
  set warp to 0.
  hudtext( "WARP to 1x when near ground.", 8, 2, 32, WHITE, false).
  preserve.
}
when alt:radar > 200 then {
  if gear and not sea_mode {
    gear off.
    hudtext( "GEAR UP", 8, 2, 32, WHITE, false).
  }
  preserve.
}
local has_been_airborne is false.

unlock steering.
until user_quit or 
      ((status="LANDED" or status="SPLASHED") and has_been_airborne) {

  wait 0.

  handle_input_key().

  // Let the user change the course index from gui if they did:
  if gui_exists {
    sync_new_gui_list().
  }

  if cur_aim_i < 0 {
    print "WAITING for NAVPOINT." at (10,7).
    // Let the user change the course index from gui if they did:
  } else {
    print "                     " at (10,7).

    local cur_way_geo is nav_list[cur_aim_i]["GEO"].
    local cur_spd_want is nav_list[cur_aim_i]["SPD"].
    local cur_aim_alt is nav_list[cur_aim_i]["ALT"].
    local cur_aim_AGL is nav_list[cur_aim_i]["AGL"].
    local cur_aim_spd is nav_list[cur_aim_i]["SPD"].
    local cur_aim_radius is nav_list[cur_aim_i]["RADIUS"].
    // transform AGL to ASL:
    if cur_aim_AGL and defined(cur_aim_geo) {
      set cur_aim_alt to asl_from_agl(cur_aim_geo, cur_aim_alt).
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
        set prev_aim_alt to asl_from_agl(prev_aim_geo, prev_aim_alt).
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
    local up_at_aim is (cur_aim_line_pos - body:position):normalized. // up vector at the aim point.
    local flat_dist_to_aim is vxcl(up_at_aim, (cur_aim_line_pos - ship:position)):mag. // ignores alt diff.
    local unit_vec_backward is (prev_aim_pos - cur_aim_line_pos):normalized.
    local offset_angle is vang(cur_aim_line_pos-ship:position, -1*unit_vec_backward). // the more off it is, the less to move it.
    local fraction is min(1.0, 0.2+offset_angle/35). // the more off it is, the less to move it.
    set cur_aim_pos to cur_aim_line_pos + fraction*flat_dist_to_aim*unit_vec_backward.
    set cur_aim_geo to ship:body:geopositionof(cur_aim_pos).
    // calculate altitude of the yellow aim point. Can't use vector position
    // because it can be underground if flying across the world:
    local ratio_to_go is flat_dist_to_aim / (cur_aim_line_pos - prev_aim_pos):mag.
    set cur_aim_pos_alt to cur_aim_alt - fraction*ratio_to_go*(cur_aim_alt - prev_aim_alt).

    set vd_aimline:start to prev_aim_pos.
    set vd_aimline:vec to cur_aim_line_pos - prev_aim_pos.
    set vd_aimpos:start to ship:position.
    set vd_aimpos:vec to cur_aim_pos - ship:position.

    set wantCompass to compass_between_latlngs(ship:geoposition, cur_aim_geo).
    set wantSpeed to cur_spd_want.

    set wantClimb to get_want_climb(ship, cur_aim_geo, cur_aim_pos_alt).

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
    set scriptThrottle to 0.5 + throtPID:UPDATE(time:seconds, shipSpd - wantSpeed).
    set ship:control:pilotmainthrottle to scriptThrottle. // DLC rotors ignore lock throttle.

    set shipRoll to roll_for(ship).
    set shipCompass to compass_for(ship,2). // srf vel mode

    // Using :SETPOINT instead of calc error myself makes it transition smoother
    // when setpoint changes - thanks nuggreat for suggesting:
    set pitchPID:SETPOINT to wantClimb.
    set yokePull to pitchPID:UPDATE( time:seconds, ship:verticalspeed ).
    set ship:control:pilotpitchtrim to yokePull.

    // normal desired bank when things are going well:
    local aOff is angle_off(wantCompass,shipCompass).
    set wantBank to bankPID:Update( time:seconds, aOff ).
    // override that with a sanity-seeking flat bank when things aren't going well:
    if abs(wantClimb-ship:verticalspeed)/ship:velocity:surface:mag > 0.2 {
      set wantBank to 0.
      if not need_pid_reinit { // first time this happened.
        hudtext( "PANIC MODE - IGNORING COMPASS - JUST LEVELLING", 8, 2, 32, yellow, false).
      }
      set need_pid_reinit to true.
    } else {
      // When we have been overriding the bank this way, need to reinit the PID
      // controller for it so it doesn't "learn" incorrectly from what was happening
      // in the past while its suggested inputs weren't actually being used:
      if need_pid_reinit and abs(wantClimb-ship:verticalspeed)/ship:velocity:surface:mag < 0.05 {
        hudtext( "PANIC MODE OVER - RESUMING NORMAL FLIGHT", 8, 2, 32, white, false).

        // (comment out pitch reset):
        //  set pitchPID to init_pitch_pid().
        //  ^ Disabled because resetting pitchPID can make it nose dive again if
        //    the plane design needs constant up-elevator to fly level.  (It needs
        //    the "integral windup" to remain for it to keep pulling the elevator up.)

        set bankPID to init_bank_pid().
        set throtPID to init_throt_pid().
        set rollPID to init_roll_pid().
        set wheelPID to init_wheel_pid().
        set need_pid_reinit to false.
      }
    }
    // Adjust PID tune according to needs.
    pid_tune_for_conditions(shipSpd, pitchPID, rollPID).
    
    set yokeRoll to rollPID:Update(time:seconds, shipRoll - wantBank ).
    set ship:control:pilotrolltrim to yokeRoll.

    displayCompass(5,9).
    displayRoll(5,13).
    displayPitch(5,17).
    displaySpeed(5,21).
    displayOffset(5,25,offset_angle).
    displayProgress(cur_aim_i, cur_way_geo, cur_aim_alt, cur_aim_radius, sea_mode, 3,27).
    print round(cur_aim_spd,0) + " m/s " at (39,2).

    if (not has_been_airborne) and
       not(ship:status = "LANDED" or ship:status = "SPLASHED") and 
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
  center_control().
  set ship:control:pilotmainthrottle to 0. // TODO - look for reverse throttle availability?
  // keep straight down the runway while slowing down, using wheels,
  // not rudder:
  set rollPID:Kp to 0.1.  set rollPID:Ki to 0.003.  set rollPID:Kd to 0.03. // temp. on ground.
  lock steering to heading(wantCompass,0).
  until (status="LANDED" or status="SPLASHED") and groundspeed < 2 {
    local aOff is angle_off(wantCompass,compass_for(ship,2)).
    // aOff needs to be negative because wheelsteer is backward.
    set ship:control:wheelsteer to wheelPID:Update(time:seconds, -aOff).
    set ship:control:roll to rollPID:Update(time:seconds, roll_for(ship) - 0 ).
    wait 0.
  }
  unlock steering.
  unlock steering.
  center_control().
  SAS OFF.
}
set vd_aimpos to 0.
set vd_aimline to 0.
set ship:control:pilotmainthrottle to 0.
center_control().
if gui_exists
  gui_close_edit_course().

function center_control {
  local cont is ship:control.
  set cont:neutralize to true.
  set cont:pilotpitchtrim to 0.
  set cont:pilotrolltrim to 0.
  set cont:pilotyawtrim to 0.
}
