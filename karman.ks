print "Karman line sounding rocket.".
print "ignition".
lock throttle to 1.
stage.
wait 0.25.
wait until stage:ready.
print "removing launch clamps".
stage.
lock steering to up.
print "waiting for solid booster flameouts".
wait until count_flameout() > 0.
print "flamed out boosters.  Staging.".
stage.
wait until altitude > 140_000.
print "now out of atmo.  Staging decouplers.".
stage.
wait 1.
stage.
wait 1.
unlock steering.
unlock throttle.

print "now waiting to stage chutes.".
wait until altitude < 1700 and ship:velocity:surface:mag < 290.
print "staging chutes.".
stage.
wait 0.5.
stage.



function count_flameout {
  local eng is list().
  local count is 0.
  list engines in engs.
  for eng in engs {
    if eng:flameout { set count to count +1. }
  }
  return count.
}
