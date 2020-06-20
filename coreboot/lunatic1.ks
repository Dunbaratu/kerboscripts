parameter nextCore. // The next core upward I should signal before I decouple from it.

clearscreen.
HUDTEXT("Lunatic1 script Starting.", 6, 4, 24, yellow, true).

lock steering to prograde.
rcs on.
wait until stage:ready. wait 1.
print "Pushing RCS forward for ullage.".
stage.
set ship:control:fore to 1.
wait until stage:ready. wait 2.
print "Staging main engine.".
lock throttle to 1.
stage.
wait 1.
set ship:control:fore to 0.
rcs off. // engine gimbal can do all the steering now.

local targetAp is moon:apoapsis.
local Pe is 999999999.
local prevPe is Pe + 1.
until Pe > prevPe {
  print "PrevPe = " + round(prevPe,0) + "m  " at (0,terminal:height -2).
  print "    Pe = " + round(    Pe,0) + "m  " at (0,terminal:height -1).
  if ship:obt:hasnextpatch {
    set prevPe to Pe.
    set Pe to ship:obt:nextpatch:periapsis.
  }
  wait 0.
}
print "Stopping, as Pe was starting to grow.".
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
unlock steering.
wait 0.5.
unlock throttle.
print "Script ending".
