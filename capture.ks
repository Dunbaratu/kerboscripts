parameter tgt_ap.  // target apo
print "capture at Pe.".
wait until eta:periapsis < 90.
rcs on. sas off.
lock steering to retrograde.
local remember_st is steeringmanager:maxstoppingtime.
local remember_P_Kd is steeringmanager:pitchpid:Kd.
local remember_Y_Kd is steeringmanager:yawpid:Kd.
local remember_R_Kd is steeringmanager:rollpid:Kd.

set steeringmanager:maxstoppingtime to 5.
set steeringmanager:pitchpid:Kd to 1.
set steeringmanager:yawpid:Kd to 1.
set steeringmanager:rollpid:Kd to 1.

print "waiting until pointing retro-ish.".
wait until vang(ship:facing:forevector, ship:velocity:orbit) > 175.

print "pushing rcs forward 10 seconds for ullage.".
rcs on. set ship:control:fore to 1. wait 10.

print "capture burn - waiting for apo < " + tgt_ap.
lock throttle to 1.

set ship:control:fore to 0.

wait until ship:apoapsis > 0 and ship:apoapsis < tgt_ap.
lock throttle to 0.
wait 0.
unlock throttle. unlock steering.
print "done".

set steeringmanager:maxstoppingtime to remember_st.
set steeringmanager:pitchpid:Kd to remember_P_Kd.
set steeringmanager:yawpid:Kd to remember_Y_Kd.
set steeringmanager:rollpid:Kd to remember_R_Kd.
