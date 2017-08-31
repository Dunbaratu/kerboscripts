print "re-entry script.".
print "waiting for alt < 140km".
wait until altitude < 140_000.
print "aiming retro".
lock steering to srfretrograde.
print "waiting for slow speed to unlock steering.".
wait until ship:velocity:surface:mag < 1000.
unlock steering.
print "waiting for safe chute deployment".
wait until alt:radar < 3000 and ship:velocity:surface:mag < 250.
print "chute deploy.".
stage. wait 1. stage. wait 1. stage.
print "script done.".
