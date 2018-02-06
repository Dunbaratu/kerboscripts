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

