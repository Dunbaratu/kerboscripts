function which_prograde {
  if altitude < 100_000
    return srfprograde.
  else
    return prograde.
}
clearscreen.
print "Finding which engine to check for ignition.".
local checkEngines is ship:partstagged("Check Ignition").
if checkEngines:LENGTH = 0 {
  print "PLEASE TAG YOUR STAGE 1 ENGINES WITH 'Check Ignition' for this script!!".
  print "CTRL-C to quit script.  Tag engines and re-run".
  wait 999999999.
}
lock east to vcrs(up:vector, north:vector).
lock nosign_comp to vang(north:vector, which_prograde():vector).
lock comp to CHOOSE nosign_comp if vdot(ship:facing:vector,east) > 0 else (360 - nosign_comp).
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
lock steering to HEADING(90, 80).
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
lock steering to HEADING(comp, max(-3, 85 - 38*(sqrt(ship:velocity:surface:mag/1000)))).
print "waiting for First Stage engines to die.".
wait until maxthrust = 0.
print "Staging First solid ullagers.".
stage.
wait 0.5.
wait until stage:ready.
print "Staging Second solid ullagers.".
stage.
wait 0.5.
wait until stage:ready.
print "Staging Second stage engine.".
stage.
print "Will stage fairing when above karman line.".
when altitude > 100_000 then {stage.}.
print "Waiting for second stage engine to die.".
wait until maxthrust = 0.
lock throttle to 0.
print "Waiting till 60 seconds before Apoapsis.".
wait until eta:apoapsis < 60.
set warp to 0.
wait 1.
wait until kuniverse:timewarp:issettled.
rcs on.
print "Staging and putting RCS blocks on".
stage.
set ship:control:fore to 1.
wait 3.
lock throttle to 1. wait 0.
stage.
wait 2.
set ship:control:fore to 0.
rcs off.
print "now just thrusting till done.".
wait until maxthrust = 0.
lock steering to sun:position.
wait 60.
unlock steering.
print "script over.".
