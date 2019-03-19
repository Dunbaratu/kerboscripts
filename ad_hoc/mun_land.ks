// dumb script to try to land on mun with minimal code.
// dumb vertical landing.

clearscreen.
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print "Pointing srf retrograde.".
lock steering to srfretro_or_up().
wait 0.1.
wait until abs(steeringmanager:angleerror) < 2.
print "Close enough.".
lock throttle to 1.
print "Killing all velocity so we fall straight.".
wait until vdot(velocity:surface:normalized, ship:facing:vector) > 0.
lock throttle to 0.
print "Now falling straight".

until status = "LANDED" {
  local surf_g is body:mu / (body:radius)^2.
  local engine_a is (0.95*availablethrust) / mass.
  local sum_a is (engine_a - surf_g).
  print "Sum Accel upward I can do is: " + round(sum_a,2) +" m/(s^2)." at (5,3).
  local done is false.
  until done or status = "LANDED" {
    wait 0.
    // dist = (1/2)*a*t^2
    local velocity_buttward is vdot(velocity:surface, -ship:facing:vector).
    if velocity_buttward < 0 {
      print "Velocity going forward - not checking.    " at (5,0).
    } else {
      local stop_time is velocity_buttward / sum_a.
      local stop_dist is 0.5*sum_a*stop_time^2.
      print "Est stop dist = " + round(stop_dist,1) + "m             " at (5,0).
      print "    Radar Alt = " + round(alt:radar,1) + "m   " at (5,1).
      if alt:radar <= stop_dist
	set done to true.
    }
  }
  if status = "LANDED"
    break.
  print "Engine ON!" at (5,2).
  lock throttle to 1. 
  wait until status = "LANDED" or vdot(velocity:surface:normalized, ship:facing:vector) > 0.
  lock throttle to 0.
  print "          " at (5,2).
}
print "LANDED".
unlock throttle.
unlock steering.

function srfretro_or_up {
  if verticalspeed > -5 and alt:radar < 100
    return up.
  else
    return srfretrograde.
}
