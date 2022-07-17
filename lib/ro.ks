global LIB_RO is true.

// This will be a library of things specific to realism overhaul.
// All functions in here should have a useful fallback behaviour
// to follow when RO isn't installed so at least they don't break
// a script that tries calling them.

// Returns a status as to whether or not the fuel is stable
// enough for an engine ignition.  This cannot detect if an
// engine will be the one about to fire off on next stage.
// so you must pass in a list of engine parts to perform the
// test on:  If there's more than one engine in the list, then
// any one engine in the list failing to have good ullage will make
// this return false.
function ullage_status {
  parameter engs. // list of engines to check

  for eng in engs {
    if eng:ullage { 
      if not(eng:flameout) and eng:fuelstability < 0.98 { 
        return false.
      }
    }
  }
  return true.
} 

// Return all engines which are currently "active", regardless 
// of whether they are throttled to zero (and thus not "really" ignited
// in RO:
function all_active_engines {
  local engs is list().
  local result is list().
  list engines in engs.
  local i is 0.
  until i >= engs:length {
    if engs[i]:ignition {
      result:add(engs[i]).
    }
    set i to i + 1.
  }
  return result.
}

// Return the actual thrust from summing the current thrust of all the
// engines in the given list.
function current_thrust {
  parameter engs. // list of engines to check

  local result is 0.
  local i is 0.
  until i >= engs:length {
    set result to result + engs[i]:thrust.
    set i to i + 1.
  }
  return result.
}

local steering_mgr_stack is stack().
// Set steeringmanager settings, remembering how to set it back.
function push_steering_mgr_config {
  parameter maxts is 2.
  parameter Kp is 0.
  parameter Ki is 0.
  parameter Kd is 0.

  // remember old settings:
  steering_mgr_stack:push(
    list(
      steeringmanager:pitchts,
      steeringmanager:pitchPid:kp,
      steeringmanager:pitchPid:ki,
      steeringmanager:pitchPid:kd,
      steeringmanager:yawts,
      steeringmanager:YawPid:kp,
      steeringmanager:YawPid:ki,
      steeringmanager:YawPid:kd,
      steeringmanager:rollts,
      steeringmanager:RollPid:kp,
      steeringmanager:RollPid:ki,
      steeringmanager:RollPid:kd
      )
    ).

  set steeringmanager:pitchts to maxts.
  set steeringmanager:pitchPid:kd to Kp.
  set steeringmanager:pitchPid:kd to Ki.
  set steeringmanager:pitchPid:kd to Kd.
  set steeringmanager:yawts to maxts.
  set steeringmanager:YawPid:kd to Kp.
  set steeringmanager:YawPid:kd to Ki.
  set steeringmanager:YawPid:kd to Kd.
  set steeringmanager:rollts to maxts/4.
  set steeringmanager:RollPid:kd to Kp/4.
  set steeringmanager:RollPid:kd to Ki/4.
  set steeringmanager:RollPid:kd to Kd/4.
}
// Set steeringmanager settings the way they were before the last push_steering_mgr_config() call:
function pop_steering_mgr_config {
  local prev_config is steering_mgr_stack:pop().

  set steeringmanager:pitchts to prev_config[0].
  set steeringmanager:pitchPid:kp to prev_config[1].
  set steeringmanager:pitchPid:ki to prev_config[2].
  set steeringmanager:pitchPid:kd to prev_config[3].
  set steeringmanager:yawts to prev_config[4].
  set steeringmanager:YawPid:kp to prev_config[5].
  set steeringmanager:YawPid:ki to prev_config[6].
  set steeringmanager:YawPid:kd to prev_config[7].
  set steeringmanager:rollts to prev_config[8].
  set steeringmanager:RollPid:kp to prev_config[9].
  set steeringmanager:RollPid:ki to prev_config[10].
  set steeringmanager:RollPid:kd to prev_config[11].
}

// Return true if any of the currently active non-flamout engines are on their last ignition
// such that zeroing the throttle means they won't ever be usable again:
function engines_last_ignition {
  local engs is all_active_engines().

  for eng in engs {
    if not(eng:flameout) {
      // If it has no more ignitions or is a solid (which RealFuels doesn't properly flag as
      // having 1 ignition even though in practical terms it does.)
      if eng:ignitions = 0 or not(eng:allowshutdown) {
        return true.
      }
    }
  }
  return false.
}

// Return true if any of the currently active engines have more ignitions,
// regardless of whether they are flamed out or not:
function engines_more_ignitions {
  local engs is all_active_engines().

  for eng in engs {
    // ignitions = -1 if infinity, or >0 if countable ones remain:
    // If engine is a one-shot no stopping engine (i.e. solids usually),
    // RealFuels falsely reports it as having infinite ignitions instead of
    // the correct number of '0'.  Treat it as if it has zero left in that case:
    if eng:ignitions <> 0 and eng:allowshutdown {
      return true.
    }
  }
  return false.
}

// Push RCS until the engines in the list
// have okay fuel stability:
function push_rcs_until_ullage_ok {
  parameter engs.
  parameter give_up is 8. // seconds until giving up on ullage push working.
  parameter do_print is false.

  if do_print { print "Ullage: begin pushing rcs". }
  local rcs_old is rcs.
  local fore_old is ship:control:fore.
  rcs on.
  set ship:control:fore to 1.
  set warp to 0. wait 0. wait until kuniverse:timewarp:issettled. // Because ullage push does nothing if on rails.
  local try_until is time:seconds + give_up. // Be sure to start timer after warp is 0 else it means nothing.
  local reason is "".
  local ok_tick_count is 0.
  until reason <> "" {
    if time:seconds > try_until {
      set reason to "Ullage: gave up after " + give_up + " seconds".
      break.
    }
    // Count how many loop iterations in a row had okay ullage:
    if ullage_status(engs)
      set ok_tick_count to ok_tick_count + 1.
    else 
      set ok_tick_count to 0.
    // Only when ullage has been okay for more than a brief instant do we trust it:
    if ok_tick_count > 3 {
      set reason to "Ullage Ok".
      break.
    }
    wait 0.
  }
  if do_print print reason.

  set ship:control:fore to fore_old.
  set rcs to rcs_old.
}

// Zero throttle, de-activate and active active engines, then put throttle back:
function attempt_reignition {
  parameter engs.

  // Zero throttle a moment, then let it go back to what it was to trigger a
  // new ignition attempt on the engine:
  local pilotthrot_old is ship:control:pilotmainthrottle.
  set ship:control:pilotmainthrottle to 0.
  local suppress_old is config:SUPPRESSAUTOPILOT. // affects lock throttle.
  set config:SUPPRESSAUTOPILOT to TRUE. // zero throttle without clobbering prev lock.
  wait 0. // Let kOS respond to that and actually kill throttle.

  // realfuels won't re-try unless the engine is de-activated and activated again:
  for eng in engs 
    if eng:ignition 
      eng:shutdown().
  wait 0.
  for eng in engs 
    if eng:ignition
      eng:activate().
  wait 0.

  // Put throttle back again to re-attempt:
  set config:SUPPRESSAUTOPILOT to suppress_old.
  set ship:control:pilotmainthrottle to pilotthrot_old.
}
