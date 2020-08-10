parameter nextCore. // The next core upward I should signal before I decouple from it.

function signalNextCore {
  parameter nextCore.
  if nextCore:istype("kOSProcessor") {
    nextCore:connection:sendmessage("go").
    hudtext("Core "+core:tag+" Sent 'go' signal to Core "+nextCore:part:tag+".",
      6, 4, 24, yellow, true).
    print "Godpseed, " + nextCore:tag.
    wait 0. // Make sure the message gets queued before I disconnect from the payload.
  }
}
clearscreen.
set ship:control:pilotmainthrottle to 0.
HUDTEXT("Aragorm TLI script Starting.", 6, 4, 24, yellow, true).
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
set warp to 0.
wait until kuniverse:timewarp:issettled.
print "Staging solid ullage engines.".
wait until stage:ready. wait 0.5. stage.
print "Staging TLI engine.".
lock throttle to 1.
wait 1.5. stage.
print "Waiting until Lunar bypass.".
wait until obt:hasnextpatch and obt:nextpatch:periapsis < 200_000.
lock throttle to 0.
set ship:control:pilotmainthrottle to 0.
wait 1.
unlock throttle.
unlock steering.
signalNextCore(nextCore).
print "script done.".
stage.
