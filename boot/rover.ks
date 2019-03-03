wait until ship:unpacked.
wait until ship:loaded.
print "Waiting 2 seconds for antenna to find themselves.".
wait 2.
brakes on.
print "Attempting to copy relevant files from archive.".
if not(exists("/lib/")) {
  createdir("/lib/").
}
copypath("0:/lib/rover.ks","/lib/").
copypath("0:/lib/terrain.ks","/lib/").
copypath("0:/use_rover.ks","/").
print "Files copied.  Run 'use_rover' to use.".
