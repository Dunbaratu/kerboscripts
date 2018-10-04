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
global burn_seconds_msg_cooldown is 0.
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
  local ISP is isp_calc().

  // From rocket equation, and definition of ISP:
  return (g0*ISP*m0/F)*( 1 - e^(-dv_mag/(g0*ISP)) ).
}


// Perform a burn of a given deltaV vector at given utime
// warning: function does not return until burn is done.
function do_burn_with_display {
  parameter
    uTime, // desired universal time to start burn.
    want_dV,  // desired deltaV (as a vector or maneuver node).
    col, // desired location to print message.
    row, // desired location to print message.
    ullage_time is -999.

  if ullage_time <> -999 
    persist_set("ullage_time", ullage_time).

  local engs is 0.
  list engines in engs.
  local want_steer is want_dV.
  if want_dv:istype("node")
    local want_steer is want_dv:deltaV.
  local remember_sas is sas.
  lock steering to lookdirup(want_steer,ship:facing:topvector).
  sas off.
  until time:seconds >= uTime {
    print  "Burn Start in " + round(uTime-time:seconds,0) + " seconds  " at (col,row).
    stager(engs, true).
    local prev_top is ship:facing:topvector.
    local prev_fore is ship:facing:forevector.
    wait 0.01.
  }.
  local start_vel is ship:velocity:orbit.
  local dv_to_go is 9999999.

  // Throttle at max most of the way, but start throttling
  // back when it seems like there's about 1.2 seconds left to thust:
  local avail_accel is ship:availablethrust / ship:mass.
  lock mythrot to min(1, 0.01 + dv_to_go/(1.2*avail_accel)).

  local dv_burnt is 0.

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
  if want_dv:istype("node")
    local want_dv is want_dv:deltaV.

  // Start Real burn:
  lock throttle to mythrot.
  set ship:control:fore to 0.
  set rcs to remember_RCS.

  print  "Burn dV remaining:         m/s" at (col,row).
  local prev_dv_to_go is dv_to_go + 1.
  local prev_sec is time:seconds.
  local sec is 0.
  local prev_vel is ship:velocity:orbit.
  local dv is 0.
  local dv_grav to 0.
  list engines in engs.
  until dv_to_go <= 0 or (dv_to_go >= prev_dv_to_go) {
    print round(dV_to_go,1) + "m/s     " at (col+19,row).
    print "dv_burnt: " + round(dv_burnt,2) + "m/s    " at (col+19,row+1).
    print "mythrot: " + round(mythrot,2) + "    " at (col+19,row+2).
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
    set prev_sec to sec.
    set prev_vel to ship:velocity:orbit.
    wait 0.0.
    set dv_to_go to want_dv:mag - dv_burnt.
  }
  lock mythrot to 0.
  lock throttle to 0.
  unlock steering.
  set sas to remember_sas.
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
    p_ullage_time is -999, // parameter ullage time.
    p_spool_time is -999.  // parameter spool time.

  if p_ullage_time <> -999 
    persist_set("ullage_time", p_ullage_time).
  if p_spool_time <> -999
    persis_set("spool_time", p_spool_time).

  until quit_condition:call() {
    clearscreen.
    print "Aiming at sun for panels.".
    lock steering to sun:position.
    lock throttle to 0.
    print "Type 'P' for precise node editor.".
    print "Type 'E' for Engine stats change.".
    print "Type 'S' for Max Stopping Time Change.".
    if not hasnode {
      hudtext("Waiting for a node to exist...", 10, 2, 30, red, false).
      until hasnode or quit_condition:call() {
        wait 0.
        just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@).
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
      just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@).
      wait 0.2. // Don't re-calculate burn_seconds() more often than needed.
    }
    if hasnode { // just in case the user deleted the node - don't want to crash.
      set warp to 0.
      hudtext("Execution of node now set in stone.", 5, 2, 30, red, false).
      wait 0.
      local n is nextnode.
      local utime is time:seconds + n:eta - lead_time.
      do_burn_with_display(utime, n, 5, 15, persist_get("ullage_time")).
      hudtext("Node done, removing node.", 10, 5, 20, red, false).
      remove(n).
    }
    just_obey_p_check(node_edit, do_engine_edit@, do_max_stopping_edit@).
  }
}

function draw_block {
  parameter dv_mag, full_burn_length, half_burn_length, ullage_time, spool_time, lead_time.

  print "Dv: " + round(dv_mag,2) + " m/s  " at (0,6).
  print "Est Full Dv Burn: " + round(full_burn_length,1) + " s  " at (0,7).
  print "  Est Half Dv Burn: " + round(half_burn_length,1) + " s  " at (0,9).
  print "+  Est Ullage time: " + round(ullage_time,1) + " s  " at (0,10).
  print "+   Est Spool time: " + round(spool_time,1) + " s  " at (0,11).
  print "---------------------------------------" at (0,12).
  print "   Total lead time: " + round(lead_time,1) + " s " at (0,13).
}

function just_obey_p_check {
  parameter
    node_edit, // a delegate to call when P is hit.
    eng_edit, // a delegate to call when E is hit.
    mxstop_edit. // a delegate to call when S is hit.

  if node_edit:istype("Delegate") {
    if terminal:input:haschar {
      local ch is terminal:input:getchar().
      if ch = "p" {
        node_edit:call().
      }
      if ch = "e" {
        eng_edit:call().
      }
      if ch = "s" {
        mxstop_edit:call().
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
