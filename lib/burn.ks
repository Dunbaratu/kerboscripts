// Methods to help you do burns.
@LAZYGLOBAL off.

run once consts.
run once stager.
run once "/lib/isp".
run once "/lib/ro".
run once "/lib/persist".

// How many seconds will it take to perform the
// given burn (given as a delta V scalar magnitude)
// If we assume all the following:
//   It will all occur using the current active stage.
//   The current mass is the mass it will start with.
//   It's going to be done by the current SHIP.
//   You aren't going to change the thrust limiters from current setting.
//   All engines active right now are the same ISP.
local burn_seconds_msg_cooldown is 0.

// What program to boot to on power-out-restart:
local obey_node_boot_name is "".

function burn_seconds {
  parameter dv_mag.  // delta V magnitude (scalar)

  // Both force and mass are in 1000x units (kilo-),
  // so the 1000x multiplier cancels out:
  local F is SHIP:AVAILABLETHRUST.  // Force of burn.
  local m0 is SHIP:MASS. // starting mass
  local g0 is 9.802. 
  
  // IF no thrust, return bogus value until there is thrust.
  if F = 0 {
    if time:seconds > burn_seconds_msg_cooldown {
      clearscreen.
      getvoice(0):play(slidenote(250,300,1)).
      hudtext("NO ACTIVE ENGINE - CAN'T Calc BURN seconds", 2, 2, 20, white, false).
      set burn_seconds_msg_cooldown to time:seconds + 3.
    }
    return 0.
  } else if burn_seconds_msg_cooldown > 0 { // clear the message if we had been showing it.
    set burn_seconds_msg_cooldown to 0.
    clearscreen.
  }

  // The ISP of first engine found active:
  // (For more accuracy with multiple differing engines,
  // some kind of weighted average would be needed.)
  local ISP is isp_calc(999999). // "infinite" altitude for assuming vacuum.

  // From rocket equation, and definition of ISP:
  return (g0*ISP*m0/F)*( 1 - e^(-dv_mag/(g0*ISP)) ).
}


// Perform a burn of a given deltaV vector at given utime
// warning: function does not return until burn is done.
// If you send a want_Pe or want_Ap, it will not stop the burn
// till that is satisfied even if it thinks it burned enough dV.
// (use "n/a" if don't care and it should just obey the dV value).
// *This is to handle cases where the dV is wrong because the game
// presumes instant burns which you can't do.*
function do_burn_with_display {
  parameter
    uTime, // desired universal time to start burn.
    want_dV,  // desired deltaV (as a vector or maneuver node).
    want_Pe is "n/a",  // desired Pe after burn. "n/a" if not tracking that.
    want_Ap is "n/a",  // deisred Ap after burn. "n/a" if not tracking that.
    // Do NOT set both want_Ap and want_Pe - lib ignores want_Pe if want_Ap set.
    col is 8, // desired location to print message.
    row is 0, // desired location to print message.
    ullage_time is -999.

  local remember_node is want_dv.

  local full_ap_rate is 0.0001. // to avoid a div by zero on first pass.
  local full_pe_rate is 0.0001. // to avoid a div by zero on first pass.

  if ullage_time <> -999 
    persist_set("ullage_time", ullage_time).

  // If using want_Ap or want_Pe, need to know if we are expecting to rise or fall
  // to that value:
  local seek_obt_sign is 1.
  local seek_dir is "larger ".
  local no_pe_ap_reason to "Ap/Pe testing not requested.".
  // Original value of the 'want' thing we're tracking, before we started burning:
  local original_pe_ap is 0.
  if want_Ap:isType("Scalar") {
    set original_pe_ap to apoapsis.
    if is_first_ap_higher(apoapsis, want_Ap) {
      set seek_obt_sign to -1.
      set seek_dir to "smaller".
    }
  } else if want_Pe:isType("Scalar") {
    set original_pe_ap to periapsis.
    if want_Pe < periapsis {
      set seek_obt_sign to -1.
      set seek_dir to "smaller".
    }
  }
  local engs is 0.
  list engines in engs.
  local want_steer is want_dV.
  local node_aim_locked is false.
  if want_dv:istype("node") {
    set want_steer to want_dv:deltaV.
    set node_aim_locked to true.
  } 
  local remember_sas is sas.
  lock steering to lookdirup(want_steer,ship:facing:topvector).
  sas off.
  until time:seconds >= uTime {
    print  "Burn Start in " + round(uTime-time:seconds,0) + " seconds  " at (col,row).
    stager(engs, true).
    local prev_top is ship:facing:topvector.
    local prev_fore is ship:facing:forevector.
    // If below 100km (Kerbin) ref frame rotates and old
    // vector becomes wrong, so keep re-querying it:
    if node_aim_locked {
      set want_steer to remember_node:deltaV.
    }
    wait 0.01.
  }.
  local dv_to_go is 9999999.
  local base_throt is {return dv_to_go.}.
  if want_Ap:isType("Scalar") {
    set base_throt to {
      // use usual dv_to_go until it is negative, then switch
      // to using ratio of done-ness by Ap measure:
      if dv_to_go > 0 {
        return dv_to_go.
      }
      // full throttle until just before being done, then back off:
      return 2* abs(want_Ap-apoapsis) /full_ap_rate.
    }.
  } else if want_Pe:isType("Scalar") {
    set base_throt to {
      // use usual dv_to_go until it is negative, then switch
      // to using ratio of done-ness by Pe measure:
      if dv_to_go > 0 {
        return dv_to_go.
      }
      // full throttle until just before being done, then back off:
      return 2* abs(want_Pe-periapsis) /full_pe_rate.
    }.
  }

  // Throttle at max most of the way, but start throttling
  // back when it seems like there's about 1.2 seconds left to thust:
  local avail_accel is ship:availablethrust / ship:mass.
  lock mythrot to min(1, 0.01 + base_throt()/(1.2*avail_accel)).

  local dv_burnt is 0.
  
  // This list of prev throttle settings is here
  // to smooth out throttle variations to get a
  // measure of average throttle over the last few
  // iterations:
  local prev_throttles is LIST(0,0,0,0,0).
  local throt_i is 0.
  local smoothed_throttle is 0.

  // ullage RCS push, accounting for dv burnt during it:
  print  "Ullage RCS push            "  at (col,row).
  local remember_RCS is rcs.
  rcs on.
  set ship:control:fore to 1.
  
  // In this case we want to ensure we wait *at least* ullage time and don't
  // fire beforehand unless we must:
  wait persist_get("ullage_time").
  local actives is all_active_engines().
  until ullage_status(actives) {
    print  "Propellant still not Stable.  Waiting more." at (col,row).
  }

  // If deltaV is a maneuver node, recalc its dV because the
  // rcs burn will have thrown it off a bit:
  if want_dv:istype("node") {
    set want_dv to want_dv:deltaV.
  }
  // Start Real burn:
  lock throttle to mythrot.
  set ship:control:fore to 0.
  set rcs to remember_RCS.

  print  "Burn dV remaining:         m/s" at (col,row).
  local prev_dv_to_go is dv_to_go + 1.
  local prev_sec is time:seconds.
  wait 0. // force time to pass after prev_sec measured to avoid div by zero when dT=0.
  local sec is 0.
  local prev_vel is ship:velocity:orbit.
  local dv is 0.
  local dv_grav to 0.
  local prev_check_num is -9999.
  local this_check_num is -9999.
  list engines in engs.
  local done is false.
  local prev_ap is apoapsis.
  local prev_pe is periapsis.
  until done {
    print round(dV_to_go,1) + "m/s     " at (col+19,row).
    print "dv_burnt: " + round(dv_burnt,2) + "m/s    " at (col+19,row+1).
    print "mythrot: " + round(mythrot,2) + "    " at (col+19,row+2).
    print "Node Mark Lock? " + node_aim_locked at (col+19,row+3).
    if want_Ap:isType("Scalar") {
      print "Seek " + seek_dir + " Ap " + round(want_Ap) + "m.  " at (col+15, row+4).
      print "    Current  Ap " + round(apoapsis) + "m.  " at (col+15, row+5).
    } else if want_Pe:isType("Scalar") {
      print "Seek " + seek_dir + " Pe " + round(want_Pe) + "m.  " at (col+15, row+4).
      print "    Current  Pe " + round(periapsis) + "m.  " at (col+15, row+5).
    } else {
      print no_pe_ap_reason + " Not testing for Pe/Ap." at (col+0, row+5).
    }
    until ship:availablethrustat(0) > 0 {
      set prev_dv_to_go to 99999999.
      set ship:control:fore to 1. RCS on. // RCS push.
      local actives is all_active_engines().
      wait until ullage_status(actives).
      stager(engs, true).
      set ship:control:fore to 0. lock throttle to mythrot.
    }

    set prev_dv_to_go to dv_to_go.
    set sec to time:seconds.
    // assume all velocity change that wasn't due to gravity is due to burn:
    set dv to ship:velocity:orbit - prev_vel.
    set dv_grav to (sec-prev_sec)*g_here().
    set dv_burnt to dv_burnt + (dv-dv_grav):mag.

    // Sample the throttle from the last few iterations to get a smoothed running average:
    set prev_throttles[throt_i] to throttle.
    set throt_i to mod(throt_i + 1, prev_throttles:length).
    set smoothed_throttle to 0.
    for t in prev_throttles {
      set smoothed_throttle to smoothed_throttle + t.
    }
    set smoothed_throttle to smoothed_throttle / prev_throttles:length.

    // A heuristic guess what the rate of change of pe and ap would be if
    // we were at full throttle right now:
    if smoothed_throttle > 0 { // avoid updating it when updating would div by zero
      set full_ap_rate to max(0.0001, abs(apoapsis - prev_ap)/(sec-prev_sec)) / smoothed_throttle.
      set full_pe_rate to max(0.0001, abs(periapsis - prev_pe)/(sec-prev_sec)) / smoothed_throttle.
    }
    set prev_ap to apoapsis.
    set prev_pe to periapsis.
    set prev_sec to sec.
    set prev_vel to ship:velocity:orbit.
    wait 0.0.
    set dv_to_go to want_dv:mag - dv_burnt.
  
    // If locked to a manuever node, keep adjusting steering
    // node as the node moves, until < 10% left, then hold still
    // so it doesn't spin out at the end:
    if node_aim_locked {
      set want_steer to remember_node:deltaV.
      if dv_to_go/want_dv:mag < 0.1 {
        set node_aim_locked to false.
      }
    }
    set done to (dv_to_go <= 0 or (dv_to_go >= prev_dv_to_go)).

    // If seeking an Ap or Pe and all expected dV burned, keep
    // going anyway till Ap or Pe satisfied.
    if dv_to_go <= 0 {
      if want_Ap:isType("Scalar") {
        set this_check_num to obt:apoapsis.
        if seek_obt_sign > 0 {
          set done to is_first_ap_higher(this_check_num, want_Ap).
          if not(done) and prev_check_num <> -9999 and
             is_first_ap_higher(prev_check_num, this_check_num) {
            set done to true. // now burning in wrong direction - stop.
          }
        } else {
          set done to is_first_ap_higher(want_Ap, this_check_num).
          if not(done) and prev_check_num <> -9999 and
             is_first_ap_higher(this_check_num, prev_check_num) {
            set done to true. // now burning in wrong direction - stop.
          }
        }
        set prev_check_num to this_check_num.
      } else if want_Pe:isType("Scalar") {
        set this_check_num to obt:periapsis.
        if seek_obt_sign > 0 {
          set done to this_check_num >= want_Pe.
          if not(done) and prev_check_num <> -9999 and
             prev_check_num > this_check_num {
            set done to true. // now burning in wrong direction - stop.
          }
        } else {
          set done to this_check_num <= want_Pe.
          if not(done) and prev_check_num <> -9999 and
             this_check_num > prev_check_num {
            set done to true. // now burning in wrong direction - stop.
          }
        }
        set prev_check_num to this_check_num.
      }
    }
  }
  lock mythrot to 0.
  lock throttle to 0.
  unlock steering.
  set sas to remember_sas.
}

// True if apoapsis1 is "higher altitude" than apoapsis2, where the
// hyperbolic Ap's are always treated as "higher" than elliptical ones
// despite being negative.
function is_first_ap_higher {
  parameter ap1, ap2.
  if (ap1 < 0 and ap2 > 0)
    return true.
  else if (ap1 > 0 and ap2 < 0)
    return false.
  else
    return (ap1 > ap2).
}

// gravity XYZ accel vector at ship location.
function g_here {
  return (ship:body:mu / ((ship:body:radius + ship:altitude)^2))*ship:body:position:normalized.
}

// Go into a mode where it will obey all future maneuver nodes you may put in
// it's way:
function obey_node_mode {
  parameter
    quit_condition,  // pass in a delegate that will return boolean true when you want it to end.
    node_edit is "n/a",       // pass in a delegate that will edit precise nodes if called.
    boot_name is "", // pass in a name of a boot script.
    p_ullage_time is -999, // parameter ullage time.
    p_spool_time is -999,  // parameter spool time.
    sun_facing is -1. // which side to face at the sun when parking.

  if p_ullage_time <> -999 
    persist_set("ullage_time", p_ullage_time).
  if p_spool_time <> -999
    persist_set("spool_time", p_spool_time).
  if boot_name <> ""
    set obey_node_boot_name to boot_name.
  if sun_facing = -1
    set sun_facing to 0.
  else
    persist_set("sun_facing", sun_facing).

  get_stopping().

  until quit_condition:call() {
    set sun_facing to persist_get("sun_facing").
    lock steering to parked_steering(sun_facing).

    lock throttle to 0.
    draw_menu().
    if not hasnode {
      hudtext("Waiting for a node to exist...", 10, 2, 30, red, false).
      until hasnode or quit_condition:call() {
        wait 0.
        just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@, do_sun_facing_edit@, obey_node_boot_name).
      }
    }
    hudtext("I See a Node.  Waiting until just before it's supposed to burn.", 5, 2, 30, red, false).

    // The user will be fiddling with the node just after adding it,
    // so this has to keep re-calculating whether or not it's time to 
    // drop from time warp based on the new changes the user is doing:
    local half_burn_length is 0.
    local full_burn_length is 0.
    local lead_time is 0.
    local dv_mag is 0.
    until (not hasnode) // escape early if the user deleted the node
          or
          (nextnode:eta < 180 + half_burn_length) {
      set dv_mag to nextnode:deltaV:mag.
      set half_burn_length to burn_seconds(dv_mag/ 2).
      set full_burn_length to burn_seconds(dv_mag).
      set lead_time to half_burn_length + persist_get("ullage_time") + persist_get("spool_time").
      draw_block(dv_mag, full_burn_length, half_burn_length, persist_get("ullage_time"), persist_get("spool_time"), lead_time).
      just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@, do_sun_facing_edit@, obey_node_boot_name).
      wait 0.2. // Don't re-calculate burn_seconds() more often than needed.
    }
    if hasnode { // just in case the user deleted the node - don't want to crash.
      set warp to 0.
      hudtext("Execution of node now set in stone.", 5, 2, 30, red, false).
      wait 0.
      local n is nextnode.
      local utime is time:seconds + n:eta - lead_time.

      local want_Pe is "n/a".
      local want_Ap is "n/a".
      // If burn has a pro or retro component (not just purely normal or radial)
      // Then check if the node is near the periapsis or apoapsis of the predicted
      // orbit patch after the burn.  Choose which side to seek based on that:
      if n:prograde <> 0 {
        if n:obt:trueanomaly > 90 and n:obt:trueanomaly < 270 {
          set want_Pe to n:obt:periapsis.
        } else {
          set want_Ap to n:obt:apoapsis.
        }
      }

      do_burn_with_display(utime, n, want_Pe, want_Ap, 5, 15, persist_get("ullage_time")).
      hudtext("Node done, removing node.", 10, 5, 20, red, false).
      remove(n).
    }
    just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@, do_sun_facing_edit@, obey_node_boot_name).
  }
}

function parked_steering {
  parameter sun_facing.

  if sun_facing = 1 // away from sun
    return -sun:position:normalized.
  else if sun_facing = 2 { // solar north.
    local north_or_south is vcrs(solarprimevector, sun:position).
    if vdot(north_or_south, V(0,1,0)) > 0
      return north_or_south.
    else
      return - north_or_south.
  }
  else if sun_facing = 3 { // at next node if it exists, sun otherwise
    if hasnode
      return nextnode:deltav:normalized.
    else
      return sun:position:normalized.
  }
  else // at sun, the default
    return sun:position.
}

function draw_menu {
  clearscreen.
  print "Type 'B' for bootfilename on? Currently "+(core:bootfilename = obey_node_boot_name).
  print "Type 'P' for precise node editor.".
  print "Type 'E' for Engine stats change.".
  print "Type 'F' for Facing when parked (solar panels).".
  print "Type 'S' for Max Stopping Time Change.".
}

function draw_block {
  parameter dv_mag, full_burn_length, half_burn_length, ullage_time, spool_time, lead_time.

  print "Dv: " + round(dv_mag,2) + " m/s  " at (0,7).
  print "Est Full Dv Burn: " + round(full_burn_length,1) + " s  " at (0,8).
  print "  Est Half Dv Burn: " + round(half_burn_length,1) + " s  " at (0,10).
  print "+  Est Ullage time: " + round(ullage_time,1) + " s  " at (0,11).
  print "+   Est Spool time: " + round(spool_time,1) + " s  " at (0,12).
  print "---------------------------------------" at (0,13).
  print "   Total lead time: " + round(lead_time,1) + " s " at (0,14).
}

function just_obey_p_check {
  parameter
    node_edit, // a delegate to call when P is hit.
    eng_edit, // a delegate to call when E is hit.
    mxstop_edit, // a delegate to call when S is hit.
    sunface_edit, // a delegate to call when F is hit.
    obey_node_boot_name. // filename to boot to on powerup.

  if node_edit:istype("Delegate") {
    if terminal:input:haschar {
      local ch is terminal:input:getchar().
      if ch = "p" {
        node_edit:call().
        draw_menu().
      }
      if ch = "e" {
        eng_edit:call().
      }
      if ch = "s" {
        mxstop_edit:call().
      }
      if ch = "f" {
        sunface_edit:call().
      }
      if ch = "b" {
        if core:bootfilename = obey_node_boot_name {
          set core:bootfilename to "".
        } else {
          set core:bootfilename to obey_node_boot_name.
        }
        draw_menu().
      }
    }
  }
}

function do_max_stopping_edit {
  function draw_stopping_time {
    print "MaxStoppingTime = " + steeringmanager:maxstoppingtime + " " at (30,5).
  }

  function add_with_clamp {
    parameter inc.

    local new_val is steeringmanager:maxstoppingtime + inc.

    if new_val < 1 set new_val to 1.
    if new_val > 10 set new_val to 10.

    set steeringmanager:maxstoppingtime to new_val.
  }

  draw_stopping_time().

  local stopping_menu is make_menu(
    35, 7, 15, 10, "MaxStoppingTime", 
    LIST(
      LIST( "+1", { add_with_clamp(1). draw_stopping_time().}),
      LIST( "-1", { add_with_clamp(-1). draw_stopping_time().})
    )
  ).

  stopping_menu["start"]().
}

function set_stopping {
  parameter new_val.
  persist_set("maxstoptime", new_val).
  set steeringmanager:maxstoppingtime to new_val.
}

function get_stopping {
  local get_val is persist_get("maxstoptime").
  if get_val > 0 {
    set steeringmanager:maxstoppingtime to get_val.
  } else {
    // persist val never got set yet, so initialize to current val:
    persist_set("maxstoptime", steeringmanager:maxstoppingtime).
  }
  return steeringmanager:maxstoppingtime.
}

function do_sun_facing_edit {
  local facing_names is LIST("At Sun", "Away from Sun", "Perp to Sun", "Next Node else Sun").
  local sun_facing is persist_get("sun_facing").

  local sun_facing_menu is make_menu(
    25, 7, 23, 8, "Sun Facing",
    LIST(
      LIST( facing_names[0], { set_sun_facing(0). }),
      LIST( facing_names[1], { set_sun_facing(1). }),
      LIST( facing_names[2], { set_sun_facing(2). }),
      LIST( facing_names[3], { set_sun_facing(3). })
    )
  ).

  if sun_facing > 0 {
    set sun_facing_menu:pick to sun_facing.
    set sun_facing_menu:oldpick to sun_facing.
  }
  sun_facing_menu["start"]().
}

function set_sun_facing {
  parameter new_val.
  persist_set("sun_facing", new_val).
  lock steering to parked_steering(new_val).
}

function do_engine_edit {

  function draw_engine_stats {
    print "Ullage " + persist_get("ullage_time") + "s  " at (35,2).
    print "Spool  " + persist_get("spool_time") + "s  " at (35,3).
  }

  draw_engine_stats().
  local eng_menu is make_menu(
    35, 5, 15, 10, "Ullage, Spool", 
    LIST(
      LIST( "Ullage 0s", { persist_set("ullage_time", 0). draw_engine_stats().}),
      LIST( "Ullage 5s", { persist_set("ullage_time",5). draw_engine_stats().}),
      LIST( "Ullage 10s", { persist_set("ullage_time",10). draw_engine_stats().}),
      LIST( "Spool 0s", { persist_set("spool_time", 0). draw_engine_stats().}),
      LIST( "Spool 3s", { persist_set("spool_time", 3). draw_engine_stats().}),
      LIST( "Spool 6s", { persist_set("spool_time", 6). draw_engine_stats().})
    )
  ).

  eng_menu["start"]().
}
