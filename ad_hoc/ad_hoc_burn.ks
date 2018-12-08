parameter ta_param is -999.

if ta_param = -999 {
  print "Must give desired true anomaly for burn as parameter".
} else {
  wait until obt:trueanomaly < ta_param.
  wait until obt:trueanomaly > ta_param.
  sas off.
  lock steering to prograde.
  print "readying burn to mun.".
  wait 0.1.
  wait until abs(steeringmanager:angleerror) < 2.
  print "burning".
  lock throttle to 1.
  wait until apoapsis > mun:apoapsis.
  lock throttle to 0.
  print "done with ad - hoc burn - aiming at sun again".
  lock steering to sun:position.
  wait 0.1.
  wait until abs(steeringmanager:angleerror) < 1.
  unlock steering.
  sas on.
  wait 5.
}
