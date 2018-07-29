local ways is list(
  waypoint("Zone 5-NZ"),
  waypoint("Area GB5DR"),
  waypoint("Sector PCSP"),
  waypoint("Kerbonaut's Bane")
  ).

local done is false.
local tempModule is ship:partstagged("therm")[0]:getmodule(
  "ModuleScienceExperiment").

local cooldown is time:seconds.
until done {
  clearscreen.
  print "AG10 to quit.".
  print "AG9 to fake the zone.".
  for wp in ways {
    local dist is surf_dist(wp).
    local do_it is false.
    if dist < 15000 and time:seconds > cooldown {
      set do_it to true.
    }
    print round(dist/1000,0) +
      "km to " + wp:name + ", " + do_it.
    if do_it or AG9 {
      print "DOING IT".
      getvoice(0):play(list(note(500,0.5))).
      if tempModule:HASDATA() {
        tempModule:RESET().
        wait 1.
        tempModule:RESET().
        getvoice(1):play(list(note(200,0.5))).
      }
      wait 1.
      tempModule:DEPLOY().
      wait 1.
      set cooldown to time:seconds + 20.
    }
  }
  wait 1.
  if ag10 {
    print "action group 10 = true, so quitting".
    set done to true.
  }
}


function surf_dist {
  parameter wpoint.

  local vecdiff is ship:geoposition:position - wpoint:geoposition:position.
  return vecdiff:mag.
}
