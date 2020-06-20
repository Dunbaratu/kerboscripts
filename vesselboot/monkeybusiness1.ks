clearscreen.

function which_prograde {
  if altitude < 100_000
    return srfprograde.
  else
    return prograde.
}

lock east to vcrs(up:vector, north:vector).
lock nosign_comp to vang(north:vector, vxcl(up:vector,which_prograde():vector)).
lock pro_comp to 
  CHOOSE
    nosign_comp if vdot(which_prograde():vector,east) > 0 else (360 - nosign_comp).

// Hardcode compass if low, after that follow prograde compass:
function which_comp {
  if altitude < 5_000
    return 90.
  else
    return pro_comp.
}

print "Finding which engine to check for ignition.".
local checkEngines is ship:partstagged("Check Ignition").
if checkEngines:LENGTH = 0 {
  print "PLEASE TAG YOUR STAGE 1 ENGINES WITH 'Check Ignition' for this script!!".
  print "CTRL-C to quit script.  Tag engines and re-run".
  wait 999999999.
}

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
print "Starting steering algorithm".
lock steering to HEADING(which_comp(), max(-3, 89 - 45*(sqrt(ship:velocity:surface:mag/1000)))).
print "Starting engine.".
stage.
local tPercent is 0.
until tPercent > 70 {
  local tMax is 0.
  local tCur is 0.
  for eng in checkEngines {
    set tMax to tMax + eng:possiblethrust.
    set tCur to tCur + eng:thrust.
  }
  set tPercent to 100 * tCur / tMax.
  print "Cur Thrust Percent is " + round(tPercent,0) + "% " at (0,1).
}
print "Declamping.".
stage.
wait 10.
print "Waiting for max thrust to drop indicating boosters done.".
local fullmax is maxthrust.
wait until maxthrust < 0.85*fullmax.
print "Staging sides away.".
stage.

print "Setting Trigger for atmo fairing sep.".
when altitude > 120_000 then {AG3 on. wait 0. AG4 on. AG1 on. print "Fairing Sep & Science on..".}
print "Waiting for engine to die.".
wait 3.
wait until maxthrust = 0.
print "Starting next stage with 2 solid seps.".
lock throttle to 1.  stage. wait 1. wait until stage:ready. stage.

wait 3.
print "Waiting for engine to die.".
wait until maxthrust = 0.
print "Wait for AP.".
wait until eta:apoapsis < 60.
set warp to 0. wait 0. wait until kuniverse:timewarp:issettled.
stage.
lock steering to prograde.
set ship:control:fore to 1.
set throttle to 1.
rcs on.
wait 3.
stage.
set ship:control:fore to 0.
print "Waiting for Ap > 1,000,000.".
wait until apoapsis > 1_000_000.
print "orbit barely stable.  Stopping engine.".
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
rcs off.
wait 0.
unlock throttle.
unlock steering.
wait 2.
print "Done.  I quit.".
