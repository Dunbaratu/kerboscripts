createdir("/lib").
copypath("0:/lib/science.ks","/lib/").
run once "lib/science".
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
stage.
wait until verticalspeed > 5.
wait until verticalspeed < 5.
do_all_science_things().
stage.
