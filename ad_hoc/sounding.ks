parameter
  comp, // compass to initially aim at
  pit, // pitch to imitially aim at
  sec. // seconds to hold that before following srfprograde

set launchsite to LATLNG(ship:latitude, ship:longitude).
set first_eng to ship:partstagged("engine 1")[0].
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
print "Set launchsite to " + launchsite.

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
print "Starting engine.".
stage.
print "Waiting for TWR > 1.1".
local twr is 0.
until twr > 1.1 {
  set twr to first_eng:thrust / (mass*(body:mu/(body:radius+altitude)^2)).
  print "TWR = " + round(twr,2).
  wait 0.1.
}
print "Declamping.".
stage.
wait 1.
lock steering to heading(comp,pit).
wait sec.
print "just following prograde.".
lock steering to srfprograde.
print "Waiting for liquid stage to end.".
wait until maxthrust = 0.
print "Waiting for top of trajectory.".
wait until verticalspeed < 0.
unlock steering.
print "Decoupling from booster.".
stage.
print "Waiting until safe for opening chutes.".
wait until alt:radar < 3_000 and verticalspeed < 300 .
stage.
print "Script over.".
