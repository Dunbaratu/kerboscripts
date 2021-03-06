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
lock steering to HEADING(comp, max(-9, 85 - 38*(sqrt(ship:velocity:surface:mag/1000)))).
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
wait 4.
// print "Waiting for solids to end.".
// wait until stage:PSPC < 1.
// print "Decoupling solids.".
// stage.
local engs is list().
local lit is 3.
until lit < 2 {
  set lit to 0.
  list engines in engs.
  for eng in engs {
    if eng:availablethrust > 0
      set lit to lit + 1.
  }
  print "No of lit engines = " + lit.
  wait 0.5.
}
print "Only 1 lit engine left.  Staging.".
stage.
print "Waiting for remaining engine to die.".
wait until maxthrust = 0.
print "Decoupling Stage 2.".
stage.
wait 0.8.
print "igniting second solids.".
stage.
wait 0.8.
print "lighting stage 2.".
stage.
print "Running till engine done.".
wait until maxthrust = 0.
