run once "/lib/ro".
if exists("/lib/menu.ks")
  run once "/lib/menu.ks".

clearscreen.

print "This is a program that just obeys whatever maneuver nodes you put in front of it.".

if not SHIP:UNPACKED {
  print "Waiting for ship to unpack.".
  wait until SHIP:UNPACKED.
  // give it time after unpacking to "really" work:
  wait 0.
  wait 0.
  print "Ship is now unpacked.".
}

run once "lib/burn".

local prev_ag10 is ag10.

print "Toggle action group 10 to quit.".

push_steering_mgr_config(2, 1, 0.02, 0.25).

sas off.

obey_node_mode(should_quit@, do_precise_node@, "just_obey_nodes").

pop_steering_mgr_config().

print "just_obey_nodes done.".

function should_quit {
  return ag10 <> prev_ag10.
}

function do_precise_node {
  if exists("/precise_node") {
    runpath( "/precise_node" ).
  } else {
    hudtext("precise_node script not present.", 5, 2, 20, yellow, true).
  }
}
