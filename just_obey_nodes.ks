clearscreen.
// TODO: Make these user-tweakable:
global ullage_time is 10. // anticipate pushng RCS forward for this many seconds before engine firing.
global spool_time is 3. // anticipate the engine taking this long to reach full power.

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

obey_node_mode(should_quit@, do_precise_node@, ullage_time, spool_time).

print "just_obey_nodes done.".

function should_quit {
  return ag10 <> prev_ag10.
}

function do_precise_node {
  runpath( "/precise_node" ).
}
