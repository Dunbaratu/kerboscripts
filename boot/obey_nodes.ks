wait until ship:unpacked.
core:doevent("open terminal").
wait 2. // need to let Remote tech find itself.
print "waiting for Remote Tech to find itself.".
wait 2.
if homeconnection:isconnected {
  print "Just loading the necessary code for just_obey_nodes.".
  if not exists("1:/lib/")
    createdir("1:/lib/").
  copypath("0:/just_obey_nodes.ks", "1:/").
  copypath("0:/lib/burn.ks", "1:/lib/").
  copypath("0:/lib/isp.ks", "1:/lib/").
  copypath("0:/lib/ro.ks", "1:/lib/").
  copypath("0:/lib/persist.ks", "1:/lib/").
  copypath("0:/consts.ks", "1:/").
  copypath("0:/stager.ks", "1:/").
  // Only run these last two if there's room in the drive:
  copypath("0:/lib/menu.ks", "1:/lib/").
  copypath("0:/precise_node.ks", "1:/").
} else {
  print "skipping update - no connection to home.".
}
run just_obey_nodes.
