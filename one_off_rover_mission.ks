local base_name is "Sector RJ5CG ".
local sitenames is LIST("Delta", "Beta", "Gamma", "Epsilon").
set steeringmanager:pitchpid:kd to 0.1.
set steeringmanager:rollpid:kd to 0.1.

for sitename in sitenames {
  local site is waypoint(base_name + sitename).
  print "Starting " + sitename + " in 3".
  wait 1.
  print "Starting " + sitename + " in 2".
  wait 1.
  print "Starting " + sitename + " in 1".
  wait 1.
  run use_rover(site:geoposition,20).
  local module is
    ship:partstagged("use me")[0]:getmodule("ModuleScienceExperiment").
  if module:hasdata {
    module:reset().
    print "Clearing old data.".
    wait 1.
  }
  print "Taking new data.".
  module:deploy().
}