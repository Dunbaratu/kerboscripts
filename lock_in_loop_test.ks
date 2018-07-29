// testing locking throttle during a loop.

print "Will have to ctrl-C to quit this.".
print "Let this run a bit and then check the log.".

for i in range(0,1000000) {
  lock throttle to 1.
  wait 0.
}