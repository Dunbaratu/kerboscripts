parameter
  comp, // compass to initially aim at
  pit, // pitch to imitially aim at
  sec. // seconds to hold that before following srfprograde

set launchsite to LATLNG(ship:latitude, ship:longitude).
set first_engs to ship:partstagged("engine 1").
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
  set totThr to 0.
  for eng in first_engs {
    set totThr to totThr + eng:thrust.
  } 
  set twr to totThr / (mass*(body:mu/(body:radius+altitude)^2)).
  print "TWR = " + round(twr,2).
  wait 0.1.
}
print "Declamping.".
stage.
wait 1.
set cPit to 90.
lock steering to heading(comp,cPit).
print "Gently pitching down over time.".
set start to  time:seconds.
until time:seconds > start + sec {
  set elapsed to time:seconds - start.
  set cPit to 90 - ((90 - pit)*(elapsed/sec)).
  clearscreen.
  print "Pitching to " + round(cPit,1) + " (goal="+pit+")".
  wait 0.
}
print "just following prograde.".
lock steering to srfprograde.
print "Waiting for liquid stage to end.".
wait until maxthrust = 0.
print "Decoupling from booster.".
stage.
wait 2.
stage.
wait until verticalspeed < 0.
brakes on.
unlock steering.
print "wait for chute.".
wait until altitude < 2000.
stage.
print "script over".
