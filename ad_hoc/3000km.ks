parameter
  comp, // compass to initially aim at
  pit, // pitch to imitially aim at
  sec. // seconds to hold that before following srfprograde

set launchsite to LATLNG(ship:latitude, ship:longitude).
set first_engs to ship:partstagged("engine 1").
set second_engs to ship:partstagged("engine 2").
clearscreen.
print "|".
print "|".
print "|".
// Display printing runs in interrupts in BG:
when true then {
  print "Dist from Launch: " + round(launchsite:distance/1000,1) + "km  " at (2,0).
  print "Apo: " + round(apoapsis/1000,1) + "km   " at (2,1).
  return 1.
}
tprint( "Set launchsite to " + launchsite).

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
tprint( "Starting engine.").
stage.
tprint( "Waiting for TWR > 1.1").
local twr is 0.
until twr > 1.1 {
  local force is 0.
  for eng in first_engs {
    set force to force + eng:thrust.
  }
  set twr to force / (mass*(body:mu/(body:radius+altitude)^2)).
  tprint( "TWR = " + round(twr,2)).
  wait 0.1.
}
tprint( "Declamping.").
stage.
wait 1.
set cPit to 90.
lock steering to heading(comp,cPit).
tprint( "Gently pitching down over time.").
set start to  time:seconds.
until time:seconds > start + sec {
  set elapsed to time:seconds - start.
  set cPit to 90 - ((90 - pit)*(elapsed/sec)).
  clearscreen.
  tprint( "Pitching to " + round(cPit,1) + " (goal="+pit+")").
  wait 0.
}
tprint( "just following prograde.").
lock steering to srfprograde.
tprint( "Waiting for liquid stage to end.").
wait until maxthrust = 0.
tprint( "Dropping Stage 1 and turning RCS on.").
stage.
wait 1.
wait until stage:ready.
rcs on.
tprint( "RCS pushing for ullage.").
set ship:control:fore to 1.
tprint( "Checking for fuel stability in stage 2 engines:").
local all_ok is false.
until all_ok {
  wait 0.
  set all_ok to true.
  for eng in second_engs {
     tprint( "eng stability = " +eng:fuelstability ).
    if eng:fuelstability < 1
      set all_ok to false.
  }
}
tprint( "Staging stage 2 engines.").
stage.
tprint( "Beginning spin stabalization" ).
set ship:control:roll to 1.
wait 5.
set ship:control:fore to 0.
wait 20.
tprint( "No longer RCS pushing.").
set ship:control:roll to 0.
unlock steering.
tprint( "waiting forever.").
wait until false.

function prograde_unless_dive {
  if vang(up:vector, prograde:vector) < 85 {
    return prograde.
  } else {
    return heading(90,5).
  }
}

function tprint {
  parameter str.
  print round(time:seconds,2) + ": " + str.
}
