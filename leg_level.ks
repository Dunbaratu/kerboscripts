
copypath("0:/lib/leg_level.ks","1:/lib/leg_level.ks").
run once "/lib/leg_level".

// test the lib.
local leg_data is leg_level_init("Leg [0-9]*", "LegLaser [0-9]*").

until false {
  clearscreen.
  print "LEG LEVELER PAUSED. Type any key to resume, (Q) to quit..".
  set ag8 to false.
  wait until terminal:input:haschar().
  if terminal:input:getchar() = "q"
    break.
  clearscreen.
  print "LEG LEVELER RESUMING.  Type any key to pause, (Q) to quit..".
  leg_level_start(leg_data).
  until terminal:input:haschar() {

    if leg_level_update(leg_data)
      break.

    wait 0. // No need to move it too fast.
  }
  if terminal:input:getchar() = "q"
    break.
  leg_level_stop(leg_data).
  wait 0.
}
leg_level_stop(leg_data).
print "DONE.".
