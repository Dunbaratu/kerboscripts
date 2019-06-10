// A script to launch and dock with the hotel in orbit.

wait until ship:unpacked.
wait 1.
core:doevent("Open Terminal").

if not(exists("/boot")) createdir("/boot").
if not(exists("/lib")) createdir("/lib").
copypath("0:/boot/std_launch_no_pn.ks","/boot/").
copypath("0:/lib/dock.ks","/lib/").
copypath("0:/dock_passive_target.ks","/").
copypath("0:/boot/rendezvous.ks","/boot/").

print "FIRST WE LAUNCH".
run "/boot/std_launch_no_pn".
clearscreen.
print "NOW THE RENDEZVOUS".
run "/boot/rendezvous".
clearscreen.
print "NOW WE DOCK".
set TARGET to "".
run "dock_passive_target".
