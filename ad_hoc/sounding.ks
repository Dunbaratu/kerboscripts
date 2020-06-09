set launchsite to LATLNG(ship:latitude, ship:longitude).
print "|".
print "|".
print "|".
// Display printing runs in interrupts in BG:
when true {
  print "Dist from Launch: " + round(launchsite:distance/1000,1) + "km  " at (0,2).
  print "Apo: " + round(apoapsis/1000,1) + "km   " at (1,2).
  return 1.
}
print "Set launchsite to " + launchsite.

set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
print "Starting engine.".
stage.
wait 1.5.
print "Declamping.".
stage.
wait 1.
print "Waiting for solids to end.".
wait until stage:PSPC < 5.
print "Decoupling solids.".
stage.
print "Waiting for stage 1 to die out.".
wait until maxthrust = 0.
print "Decoupling and ullaging.".
stage.
wait 0.8.
print "Starting upper stage.".
stage.
print "Waiting to leave atmo.".
wait until altitude > 140_000.
print "Waiting to re-enter atmo.".
wait until altitude < 140_000.
print "Tumbling helplessly.".
wait until altitude < 10_000.
stage.
chutes on.
wait 1.
stage.
print "Script over.".
