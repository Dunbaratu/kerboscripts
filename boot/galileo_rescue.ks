print "Program to try to Rescue a Kerbal in Kerbin orbit.".

wait until ship:unpacked.

switch to 1.
if not exists("1:/lib")
  createdir("1:/lib/").
copypath("0:/lib/launch","/lib/").
copypath("0:/lib/burn","/lib/").
copypath("0:/lib/prediction","/lib/").
copypath("0:/launch","").
copypath("0:/rendezvous","").
copypath("0:/match_inc","").
copypath("0:/consts","").
copypath("0:/stager","").
// copypath("0:/station_dock_server","").
// copypath("0:/station_dock_client","").


// Only run lauch portion when launching, not when reloading vessel already
// in space:
if ship:periapsis < 100 and ship:body:name = "Gael" and (status = "LANDED" or status = "PRELAUNCH") {

  hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).

  if not hastarget {
    hudtext("Please pick the intended rescue-ee as the target.",
            5, 2, 45, green, true).
    wait until hastarget.
  }

  hudtext( "Please start engines to begin the launch program.", 5, 2, 45, green, true).

  local time_to_go is false.
  until time_to_go {
    list engines in engs.
    for eng in engs {
      if eng:ignition {
        set time_to_go to true.
      }
    }
    wait 0.
  }

  run launch( 90, target:periapsis, 0).
  lock steering to north.
  wait 15.
  unlock steering.
  panels on.
  print "launch done.".
}

if status = "ORBITING" {
  local destination_ves is target.

  print "Running match_inc.".
  run match_inc(destination_ves).

  print "Running rendezvous.".
  run rendezvous(destination_ves,0).

  print "Holy cow it all worked.".
}
