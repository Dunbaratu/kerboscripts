run once "lib/launch".
parameter
  compass is 90,
  orbit_height is 15000,
  count is 5,
  second_height is -1,
  second_height_long is -1,
  atmo_end is 10000.

until count = 0 {
  hudtext("T minus " + count + "s", 2, 2, 45, yellow, true).
  wait 1.
  set count to count - 1.
}.
hudtext("Launch!", 2, 2, 50, yellow, true).
set ship:control:pilotmainthrottle to 0.

print "Proof I am trying to call launch(). eraseme.".
launch(compass, orbit_height, true, second_height, second_height_long).

