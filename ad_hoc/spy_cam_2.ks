set first_eng to ship:partstagged("engine 1")[0].
set second_eng to ship:partstagged("engine 2")[0].
set launchsite to LATLNG(ship:latitude, ship:longitude).
clearscreen.
print "|".
print "|".
print "|".
// Display printing runs in interrupts in BG:
when true then {
  print "Dist from Launch: " + round(launchsite:distance/1000,1) + "km  " at (2,0).
  print "Apo: " + round(apoapsis/1000,1) + "km   " at (2,1).
  return true.
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

print "Waiting for stage 1 to end.".
wait until maxthrust = 0.
print "Decoupling stage 1.".
stage.
wait 0.8.
print "ullage spin motors.".
stage.
local stab is 0.
until stab > 0.9 {
  set stab to second_eng:fuelstability.
  print "Second eng fuel Stability = " + stab.
}
wait until stage:ready.
print "starting aerobees.".
stage.

print "Waiting for top of trajectory.".
wait until verticalspeed < 0.
print "Waiting until safe for opening chutes.".
wait until alt:radar < 5_000 and verticalspeed < 350 .
stage.
print "Script over.".
