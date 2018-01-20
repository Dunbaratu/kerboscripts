parameter tgt_ap.  // target apo
print "capture at Pe.".
wait until eta:periapsis < 90.
rcs on. sas off.
lock steering to retrograde.
print "waiting until pointing retro-ish.".
wait until vang(ship:facing:forevector, ship:velocity:orbit) > 175.
print "capture burn - waiting for apo < " + tgt_ap.
lock throttle to 1.
wait until ship:apoapsis > 0 and ship:apoapsis < tgt_ap.
lock throttle to 0.
wait 0.
unlock throttle. unlock steering.
print "done".