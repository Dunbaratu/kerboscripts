// example hello world file.

print "Finding bottom engine".
set bottom_eng to ship:partstagged("bottom engine")[0].

print "Throttle Up!".
lock throttle to 1.

print "COUNTDOWN...".
set x to 5.
until x = 0 {
  print x.
  set x to x - 1. 
  wait 1.
}

print "IGNITION".
stage.

print "WAITING FOR SPOOL UP".
wait until bottom_eng:thrust / (ship:mass*9.81) > 1.1.

print "TWR high enough.  DECLAMPING".

// Just in case the TWR got high fast enough that the cooldown
// on staging didn't finish yet:
wait until stage:ready.

stage.

lock pit to 90 - altitude/500.
lock steering to heading(90, pit).
set steering_is_locked to true.

set fuel_type to "Ethanol75".

set time_left to 9999.

until time_left < 1 {
  set rate to get_fuel_rate(fuel_type).
  set fuel_left to stage:resourceslex[fuel_type]:amount.
  set time_left to fuel_left/rate.
  if steering_is_locked and time_left < 8 {
    unlock steering.
    set steering_is_locked to false.
    set ship:control:roll to 1.
  }
  clearscreen.
  print "Seek Pitch of " + round(pit,1) + " degrees".
  print "Altitude = " + round(altitude) + " m".
  print "Consuming " + fuel_type + " at " + round(rate,1) + " units per sec.".  
  print "Estimated " + round(time_left,1) + " seconds fuel left.".
  if (steering_is_locked) {
    print "Steering is locked.".
  } else {
    print "Steering is NOT locked.  Starting Roll.".
  }
  wait 0.
}
print "----HOT STAGING----".
stage.
wait 0.5.
wait until stage:ready.
stage.

print "Program is no longer in control.  Just waiting...".
wait 99999.

function get_fuel_rate {
  parameter fuel_name.

  wait 0.
  local amt1 is stage:resourceslex[fuel_name]:amount.
  local time1 is time:seconds.
  wait 0.1.
  local amt2 is stage:resourceslex[fuel_name]:amount.
  local time2 is time:seconds.

  return (amt1 - amt2) / (time2 - time1).
}
