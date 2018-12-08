parameter capture_pe is -999.

if capture_pe = -999 {
  print "Need 1 parameter: the Pe to be higher than".
} else {
  sas off.
  print "Wait till Mun SoI.".
  wait until ship:body:name = "Mun".
  set warp to 0.
  print "turned off warp.".
  wait 20.
  print "Make sure not hitting mun.".
  if periapsis < capture_pe {
    lock rad_out to vxcl(prograde:vector:normalized, -mun:position:normalized).
    lock steering to rad_out.
    wait 10.
    lock throttle to 0.2.
    wait until periapsis > capture_pe.
    lock throttle to 0.
  }
  print "okay safe now".
  lock steering to sun:position.
  print "waiting for Pe burn".
  wait until eta:periapsis < 20.
  set warp to 0.
  lock steering to retrograde.
  wait 5.
  lock throttle to 1.
  wait until apoapsis > 0.
  print "now in elliptical orbit".
  wait until (apoapsis - altitude) < (altitude - periapsis).
  lock throttle to 0.
  lock steering to sun:position.
  wait 10.
  sas on.
  unlock steering.
  wait 1.
  print "DONE?".
}
