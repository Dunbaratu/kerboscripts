clearscreen.
print "Finding which engine to check for ignition.".
local checkEngines is ship:partstagged("Check Ignition").
if checkEngines:LENGTH = 0 {
  print "PLEASE TAG YOUR STAGE 1 ENGINES WITH 'Check Ignition' for this script!!".
  print "CTRL-C to quit script.  Tag engines and re-run".
  wait 999999999.
}
lock east to vcrs(up:vector, north:vector).
lock nosign_comp to vang(north:vector, ship:facing:vector).
lock comp to CHOOSE nosign_comp if vdot(ship:facing:vector,east) > 0 else (360 - nosign_comp).
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
lock steering to HEADING(comp, 85 - 30*(sqrt(ship:velocity:surface:mag/1000))).
print "Starting engine.".
stage.
local tPercent is 0.
until tPercent > 80 {
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
wait 4.
// print "Waiting for solids to end.".
// wait until stage:PSPC < 1.
// print "Decoupling solids.".
// stage.
local HTP1 is stage:HTP.
wait 1.
local HTP2 is stage:HTP.
local HTPrate is HTP1 - HTP2.
print "Burning HTP at " + HTPrate + " per second.".
print "Waiting for stage 1 to die out.".
wait until stage:HTP < 1.1*HTPRate.
print "Hotstage stage 2.".
stage.
wait 1.
print "Decoupling Stage 2.".
stage.
print "Waiting for Karman.".
wait until altitude > 100_000.
stage.
print "Chutes pre-staged.".
print "Waiting for Apo.".
wait until eta:apoapsis < 5.
unlock steering.
wait 2.
print "Unlocked steering. Tumbling helplessly. Script over.".
