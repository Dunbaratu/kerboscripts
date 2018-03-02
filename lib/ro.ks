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

  local i is 0.
  until i >= engs:length {
    // If this is a stock game, this module isn't there and ullage is always good:
    if engs[i]:hasmodule("ModuleEnginesRF") { 
      local realFuel is engs[i]:getmodule("ModuleEnginesRF").
      // Maybe some engines without Ullage problems don't say this and are okay always?
      if realFuel:hasfield("propellant") {
        local pStat is realFuel:getfield("propellant").
        if pStat <> "Very Stable" and pStat <> "Nominal" {
          return false.
        }
      }
    }
    set i to i + 1.
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
