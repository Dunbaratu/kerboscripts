createdir("/lib").
copypath("0:/lib/science.ks","/lib/").
run once "lib/science".
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
stage.
wait until verticalspeed > 50.
wait until maxthrust = 0.
stage.
wait until verticalspeed < 5.
do_all_science_things().
wait until altitude < 4000.
stage.
wait 1.
stage.
