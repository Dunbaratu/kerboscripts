wait until ship:unpacked. wait 1.
core:doevent("Open Terminal").
print "Booting Airplane Pilot Software.".
copypath("0:/pilot.ks","/").
copypath("0:/lib/navpoint.ks","/lib/navpoint.ks").
run pilot(false,"GUI").
