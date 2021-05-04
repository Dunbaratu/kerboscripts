// Script for sounding rocket where stage 2 requires hot staging.
local hot_ign is 2.5. // seconds before stage 1 ends to ignite stage 2.
local hot_dec is 0.5. // seconds before stage 1 ends to decouple stage 2.
local launchsite is LATLNG(ship:latitude, ship:longitude).
local first_eng is ship:partstagged("engine 1")[0].
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
wait 2.
print "Measuring fuel burn rate.".
local f1 is stage:LqdOxygen.
local t1 is time:seconds.
wait 1.
local f2 is stage:LqdOxygen.
local t2 is time:seconds.
local flow is (f1-f2)/(t2-t1).
print "Fuel burns at " + round(flow,3) + " LOX/sec.".
print "Waiting for " + hot_ign + " secs before stage 1 done.".
wait until stage:LqdOxygen < (flow*hot_ign).
print "igniting stage 2.".
stage.
wait until stage:LqdOxygen < (flow*hot_dec).
print "ditching stage 1.".
stage.
wait 0.
print "Waiting for stage 2 over or Ap > 200km.".
wait until maxthrust = 0 or apoapsis > 200_000.
set ship:control:pilotmainthrottle to 0.
lock throttle to 0.
print "Waiting for top of trajectory.".
wait until verticalspeed < 0.
print "Waiting until safe for opening chutes.".
wait until alt:radar < 2_000 and verticalspeed < 350 .
stage.
print "Script over.".
