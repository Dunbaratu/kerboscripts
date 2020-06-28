parameter nextCore. // The next core upward I should signal before I decouple from it.

print "Waiting until in Moon SoI".
wait until body = Moon.
print "Waiting until 60 seconds shy of Pe".
wait until eta:periapsis < 60.
print "Aiming retro".
lock steering to retrograde. rcs on.
print "Waiting for aim to line up.".
wait until abs(steeringmanager:angleerror) < 1.
print "Engaging Solids for Capture.".
stage.
wait 30.
print "Aiming at sun.".
lock steering to sun:position.
wait until abs(steeringmanager:angleerror) < 0.2.
print "Disk Space is low so manually delete stuff and pull the landing files please.".

