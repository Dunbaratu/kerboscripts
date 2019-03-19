createdir("/lib").
copypath("0:/lib/science.ks","/lib/").
run once "lib/science".
lock throttle to 1.
until maxthrust > 1 { stage. wait 0.2. }
wait until maxthrust < 1.
until maxthrust > 1 { stage. wait 0.2. }
wait until verticalspeed < 10.
do_all_science_things().
stage. wait 1. stage. wait 1. stage. chutes on.