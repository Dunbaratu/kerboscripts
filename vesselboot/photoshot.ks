clearscreen.
print "Finding which engine to check for ignition.".
local checkEngines is ship:partstagged("Check Ignition").
if checkEngines:LENGTH = 0 {
  print "PLEASE TAG YOUR STAGE 1 ENGINES WITH 'Check Ignition' for this script!!".
  print "CTRL-C to quit script.  Tag engines and re-run".
  wait 999999999.
}
lock east to vcrs(up:vector, north:vector).
lock projFace to vxcl(up:vector, ship:facing:vector).
lock nosign_comp to vang(north:vector, projFace).
lock comp to CHOOSE nosign_comp if vdot(projFace,east) > 0 else (360 - nosign_comp).
when true then {
  print "COMP = " + round(comp,1) + "deg" at (0,0).
  print "---------------" at (0,1).
  preserve.
}

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
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
lock steering to heading(185, 80).
wait 15.
ag1 on.
lock steering to HEADING(comp, 85 - 35*(sqrt(ship:velocity:surface:mag/1000))).
when apoapsis > 195_000 then {
  print "KILLING THROTTLE BECAUSE APO IS HIGH.".
  lock throttle to 0.
  unlock steering.
}
// print "Waiting for solids to end.".
// wait until stage:PSPC < 1.
// print "Decoupling solids.".
// stage.
print "Waiting for Apo or leaving atmo.".
wait until altitude > 140_000 or eta:apoapsis < 1.
unlock steering.
stage.
print "Unlocked steering. Tumbling helplessly. Script over.".
