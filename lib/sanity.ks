// cause steering manager settings to go back to reasonable defaults.
function sane_steering {
  local did_something is false.
  if steeringmanager:RollControlAngleRange > 5 {
    set steeringmanager:RollControlAngleRange to 5.
    set did_something to true.
  }
  if steeringmanager:yawpid:Kp = 0 {
    set steeringmanager:yawpid:Kp to 1.
    set steeringmanager:yawpid:Ki to 0.0001.
    set steeringmanager:yawpid:Kd to 0.1.
    set did_something to true.
  }
  if steeringmanager:pitchpid:Kp = 0 {
    set steeringmanager:pitchpid:Kp to 1.
    set steeringmanager:pitchpid:Ki to 0.0001.
    set steeringmanager:pitchid:Kd to 0.1.
    set did_something to true.
  }
  if steeringmanager:rollpid:Kp = 0 {
    set steeringmanager:rollpid:Kp to 1.
    set steeringmanager:rollpid:Ki to 0.0001.
    set steeringmanager:rollpid:Kd to 0.1.
    set did_something to true.
  }
  if did_something {
    print "STEERINGMANAGER SETTINGS WERE NOT SANE.".
    print "JUST SET THEM TO SOMETHING THAT MAY WORK?".
  }
}

// Do not proceed if the craft isn't aimed upward.
function sane_upward {
  print "THIS IS SANE_UPWARD:  VANG is " + VANG(ship:facing:vector, ship:up:vector).
  until VANG(ship:facing:vector, ship:up:vector) < 45 {
    hudtext( "PROBE ORIENTATION NOT UPWARD!! PLEASE FIX IT.", 2, 1, 25, white, true).
    getvoice(1):play(list(slidenote(400,500,0.5),slidenote(500,400,0.5))).
    wait 4.
  }
}

function sane_avionics {
  local avionics is ship:modulesnamed("ModuleProceduralAvionics").
  for av in ship:modulesnamed("ModuleAvionics") {
    avionics:add(av).
  }
  local av_most is 0.
  if avionics:length > 0 {
    for av in avionics {
      // Both procedural and fixed avionics modules have this field:
      if av:hasfield("controllable") {
        set av_most to max(av_most, av:getfield("controllable")).
      }
    }
    local tonnes is mass_no_clamps().
    if av_most < tonnes {
      hudtext( "SANITY CHECK FAIL! Avioncs " + av_most + "t when " + round(tonnes,1) + "t needed", 2, 1, 25, white, true).
      getvoice(1):play(list(slidenote(400,600,0.5),slidenote(400,600,0.5))).
      print "Continue anyway? y/n?".
      local ch is "".
      until ch = "Y" or ch = "y" or ch = "n" or ch = "N" {
        set ch to terminal:input:getchar().
      }
      if ch <> "Y" and ch <> "y" {
        print "crashing script deliberately.".
        print 1/0.
      }
    }
  }
}

// ship:mass minus the mass of launch clamps:
function mass_no_clamps {
  local m is ship:mass.
  for lc in ship:modulesNamed("LaunchClamp") {
    set m to m - lc:part:mass.
  }
  return m.
}

