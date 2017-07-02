// basic kaputnic launch
print "press any key to start.".
set keypress to terminal:input:getchar().

print "readying engine".
lock throttle to 1.
stage.
wait 2.
print "release clamps".
stage.
wait until num_flameout > 0.
wait 0.1.
print "solid boosters off".
stage.
print "steering angle set".
lock steering to heading(100,50).
print "deploy fairings and wait for re-entry".
wait until altitude > 130_000.
stage.
print "waiting for chute deploy".
wait until altitude < 3000.
print "chute deployment".
chutes on.
wait 5.

function num_flameout {
  local engs is list().
  local count is 0.
  list engines in engs.
  for eng in engs
    if eng:flameout
      set count to count + 1.
  return count.
}