function roll_for {
  parameter ves.

  local raw is vang(ves:up:vector, - ves:facing:starvector).
  if vang(ves:up:vector, ves:facing:topvector) > 90 {
    if raw > 90 {
      return raw - 270.
    } else {
      return raw + 90.
    }
  } else {
    return 90 - raw.
  }
}.

clearscreen.
set launchsite to LATLNG(ship:latitude, ship:longitude).
set cooldown to time:seconds.
lock east to vcrs(up:vector, north:vector).
lock nosign_comp to vang(north:vector, ship:facing:vector).
lock comp to CHOOSE nosign_comp if vdot(ship:facing:vector,east) > 0 else (360 - nosign_comp).
print "|".
print "|".
print "|".
// Display printing runs in interrupts in BG:
when time:seconds > cooldown then {
  print "Dist from Launch: " + round(launchsite:distance/1000,1) + "km  " at (2,0).
  print "Apo: " + round(apoapsis/1000,1) + "km   " at (2,1).
  print "Comp: " + round(comp,1) + "deg   " at (2,2).
  set cooldown to time:seconds + 1.
  return TRUE.
}
print "Set launchsite to " + launchsite.

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
lock steering to HEADING(Comp, 85 - 43*(sqrt(ship:velocity:surface:mag/1000)), roll_for(ship)).
print "Starting engine.".
stage.
wait 1.8.
print "Declamping.".
stage.
wait 1.
print "Waiting for solids to end.".
wait until stage:PSPC < 1.
print "Decoupling solids.".
stage.
print "Waiting for stage 1 to die out.".
wait until stage:HTP < 1.4.
print "Hotstage stage 2.".
stage.
wait 1.
print "Decoupling Stage 2.".
stage.
wait until stage:Furfuryl < 1.4.
print "Hotstage stage 3.".
stage.
wait 1.
print "Decoupling Stage 3.".
stage.
print "Waiting to leave atmo.".
wait until altitude > 140_000.
unlock steering.
print "Unlocking steering. Pre-staging for chutes.".
stage. wait 1. stage.
print "Waiting to re-enter atmo.".
wait until altitude < 140_000.
print "Tumbling helplessly.".
wait until altitude < 10_000.
stage.
print "Script over.".
