parameter nextCore. // The next core upward I should signal before I decouple from it.

clearscreen.
HUDTEXT("Lunatic2 script Starting.", 6, 4, 24, yellow, true).

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
until Pe > prevPe or Pe < 100_000 {
  print "PrevPe = " + round(prevPe,0) + "m  " at (0,terminal:height -2).
  print "    Pe = " + round(    Pe,0) + "m  " at (0,terminal:height -1).
  if ship:obt:hasnextpatch {
    set prevPe to Pe.
    set Pe to ship:obt:nextpatch:periapsis.
  }
  wait 0.
}
print "Stopping, as Pe was low enough, or starting to grow.".
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
unlock steering.
print "Getting rid of pointless transfer stage.".
stage.
print "Now waiting for 60 seconds shy of Pe.".
wait until eta:periapsis < 300.
if warp > 2 set warp to 2.
wait until eta:periapsis < 60.
if warp > 0 set warp to 0.
lock steering to retrograde. rcs on.
print "waiting for ETA:Periapsis < 12".
wait until eta:periapsis < 12.
wait until kuniverse:timewarp:issettled.
wait until abs(steeringmanager:angleerror) < 2.
print "getting captured with solid engine (I hope).".
lock throttle to 1.
stage.
wait 2.
wait until maxthrust = 0.
print "engine all done.  That's all I can do.".
lock steering to north.
wait until abs(steeringmanager:angleerror) < 0.2.
rcs off.
unlock steering.
