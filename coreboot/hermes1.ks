parameter nextCore. // The next core upward I should signal before I decouple from it.
clearscreen.
HUDTEXT("Hermes1 script Starting.", 6, 4, 24, yellow, true).
// Hermes1 - mercury low orbit analog.
// Assumes a launch vehicle has done most of the work and I just have to circularize.

function which_prograde {
  if altitude < 100_000
    return srfprograde.
  else
    return prograde.
}
lock east to vcrs(up:vector, north:vector).
lock nosign_comp to vang(north:vector, vxcl(up:vector,which_prograde():vector)).
lock pro_comp to 
  CHOOSE
    nosign_comp if vdot(which_prograde():vector,east) > 0 else (360 - nosign_comp).
lock steering to heading(pro_comp, min(20,max(0,2*(obt:trueanomaly-175)))).
rcs on.
when periapsis > 20_000 then lock steering to prograde. // when we circ.

print "Waiting till 90s shy of Ap.".
wait until eta:apoapsis < 90.
print "Pushing fore for ullage.".
rcs on. set ship:control:fore to 1.
wait 4.
print "Igniting engine.".
lock throttle to 1.
stage.
wait 2.
set ship:control:fore to 0.
print "Waiting for circ orbit.".
wait until obt:trueanomaly < 90 or obt:trueanomaly > 270.
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
wait 1.
unlock throttle.
unlock steering.
print "script done.".
