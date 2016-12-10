parameter other_thing. // i.e. target, vessel("name"), or body("name").

run once "/lib/prediction".
run once "/lib/burn".


set burn to inclination_match_burn(ship, other_thing:obt).
set utime to burn[0].
set deltaV to burn[1].
set duration to burn_seconds(deltaV:mag).
set lead_time to burn_seconds(deltaV:mag/2).

clearscreen.

print " ----------------------------------- ".
print " burn_vd is the vector to burn.".
print " ----------------------------------- ".

set burn_vd_tail to POSITIONAT(ship, utime).
set burn_vd to
      vecdraw(
        burn_vd_tail,
        500*deltaV,
        blue,
        "dV "+round(deltaV:mag,1)+" m/s, " + round(duration,1) + "s",
        1,
        true).

set burn_done to false.

// Keep updating the vector location in background until burn is done:
when not burn_done then {
  set burn_vd:start to POSITIONAT(ship, utime).
  if not burn_done {
    preserve.
  }
}

do_burn_with_display( uTime - lead_time, deltaV, 5, 10).

set burn_done to true.

set burn_vd to 0.
