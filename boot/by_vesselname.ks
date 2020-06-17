if not(defined(bootcopied)) {
  copypath("0:/boot/by_vesselname.ks","/boot/").
  set bootcopied to true.
  run "boot/by_vesselname".
} else {
  wait until ship:unpacked.
  core:doevent("Open Terminal").
  print "Begin Boot Script? (y/n)".
  local ch is terminal:input:getchar().
  if ch = "y" {
    print "Booting script called " + ship:name + " from vesselboot.".
    copypath("0:/vesselboot/"+ship:name+".ks", "1:/").
    runpath("1:/"+ship:name+".ks").
  } else {
    print "QUITTTING AT USER REQUEST.".
  }
}
