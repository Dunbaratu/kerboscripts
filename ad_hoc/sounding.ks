createdir("/lib").
copypath("0:/lib/science.ks","/lib/").
run once "lib/science".
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
until maxthrust > 1 { stage. wait 1. }
lock steering to heading(0, 90 - 90*sqrt(altitude/130_000)).
wait until stage:Aniline < 50.
unlock steering. set ship:control:roll to 1.
stage.
wait until stage:Aniline < 10. stage.
set ship:control:neutralize to true.
wait until verticalspeed < 5.
unlock steering.
do_all_science_things().
stage. wait 1. stage. wait 1. stage.
wait until verticalspeed < 300 and alt:radar < 5_000.
stage. wait 1. stage. wait 1. stage.
wait until verticalspeed < 240.
stage. wait 1. stage. chutes on.
