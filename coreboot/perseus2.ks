parameter nextCore. // The next core upward I should signal before I decouple from it.

function signalNextCore {
  parameter nextCore.
  if nextCore:istype("kOSProcessor") {
    nextCore:connection:sendmessage("go").
    hudtext("Core "+core:tag+" Sent 'go' signal to Core "+nextCore:part:tag+".",
      6, 4, 24, yellow, true).
    print "Godpseed, " + nextCore:tag.
    wait 0. // Make sure the message gets queued before I disconnect from the payload.
  }
}

clearscreen.
HUDTEXT("Perseus2 script Starting.", 6, 4, 24, yellow, true).
print "Initial Launch Heading?".
print "(up/down/left/right arrows to change these.  ENTER when done).".
local init_comp is 90.
local ch is "*".
local inp is terminal:input.
local side_stages is 2. // how many separately ditchable side stages?
until ch = inp:RETURN {
  print "   Initial Comp = " + init_comp + " Radial Stages = " + side_stages + " " at (0,3).
  wait until inp:haschar.
  set ch to inp:getchar().
  if      ch = inp:UPCURSORONE   { set init_comp to init_comp + 1.}
  else if ch = inp:DOWNCURSORONE { set init_comp to init_comp - 1.}
  else if ch = inp:LEFTCURSORONE { set side_stages to side_stages - 1.}
  else if ch = inp:RIGHTCURSORONE { set side_stages to side_stages + 1.}
}
print " ".
print " ".

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
    return init_comp.
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
lock steerpitch to max(4, 90 - 45*(sqrt(ship:velocity:surface:mag/1000))).
print "Starting steering algorithm".
lock steering to HEADING(which_comp(), steerpitch).
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
wait 2.
for stg in range(1,side_stages+1) {
  wait 5.
  local maxWithBoost is maxthrust.
  print "Booster set " + stg.
  print "Waiting for drop in Booster thrust".
  print "      ... OR ...".
  print "  you can press SPACE in this terminal to force sep.".
  wait until maxthrust < 0.95*maxWithBoost or
      (terminal:input:haschar and terminal:input:getchar() = " ").
  print "Thrust suddenly dropped. Assuming Boosters over.".
  print "Decoupling Side booster set.".
  stage.
}

print "Setting Trigger for atmo fairing sep.".
when altitude > 120_000 then {AG3 on. wait 1. AG4 on. AG1 on. print "Fairing Sep & Science on..".}
print "Waiting for engine to die.".
wait 3.
wait until maxthrust = 0.
print "Ditching lower stage.".
lock throttle to 1. stage. wait 1. wait until stage:ready.
lock throttle to 1. stage. wait 1. wait until stage:ready.
lock throttle to 1. stage. wait 1. wait until stage:ready.
print "Changing steering algorithm based on trueanomaly.".
// WARNING THIS Assumes we launch from north hemisphere!!!
// The more complex checks for south hemisphere launch are missing:
lock lngCrossEq to mod(360 + 180 + obt:lan - body:rotationangle, 360).
lock lngShy to lngCrossEq - longitude.
lock steerpitch to min(20,max(5,(ship:obt:trueanomaly-(180-lngShy)))). // point up to keep AP on the equator
print "Waiting for engine to die.".
local prev_lngShy is lngShy.
until maxthrust = 0 {
  print "TA = "+round(ship:obt:trueanomaly,1)+"deg" at (terminal:width-10, 0).
  print "lngShy = "+round(lngShy,1)+"deg" at (terminal:width-14, 1).
  wait 0.
}
local shy is 90.
print "Waiting till "+shy+"s shy of APO before starting next stage.".
wait until eta:apoapsis < shy.
print "Perseus 2's Job is over.  Starting payload's program then staging.".
lock throttle to 0.
set ship:control:pilotmainthrottle to 1.
signalNextCore(nextCore).
stage.
