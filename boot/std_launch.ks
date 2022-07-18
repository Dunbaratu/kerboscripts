
wait until ship:unpacked.
core:doevent("open terminal").
// Only run boot when launching, not when reloading vessel already
// in space:
if ship:periapsis < 100 and (status = "LANDED" or status = "PRELAUNCH") {
  wait 4. // need to let Remote tech find itself.

  hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).
  switch to 1.
  if not exists("/lib/") {
    createdir("/lib/").
  }
  copypath("0:/lib/launch","/lib/").
  copypath("0:/launch","/").
  copypath("0:/lib/isp","lib/").
  copypath("0:/lib/ro","lib/").
  copypath("0:/lib/sanity","lib/").

 if Volume():CAPACITY > 40000 {
   copypath("0:/precise_node","/").
   copypath("0:/lib/menu","lib/").
   copypath("0:/just_obey_nodes.ks","/").
   copypath("0:/lib/burn","/lib/").
   copypath("0:/lib/persist","/lib/").
 } else {
   hudtext("LOW CAPACITY DISK!  NOT LOADING OBEY_NODES.", 10, 2, 25, white, true).
 }
  //copypath("0:/rendezvous","").
  //copypath("0:/match_inc","").
  copypath("0:/consts","/").
  copypath("0:/stager","/").
  //copypath("0:/station_dock_server","").
  //copypath("0:/station_dock_client","").
  //copypath("0:/lib/land.ks","").
  //copypath("0:/land_it.ks","").
  //copypath("0:/ca_land.ks","").
  //copypath("0:/lib_rover.ks","").
  //copypath("0:/use_rover.ks","").

  set core:bootfilename to "".
  set global_scrubbed to false.
  run launch( 90, 80000).
  if not(global_scrubbed) {
    lock steering to north.
    wait 15.
    unlock steering.
    //panels on.
    hudtext("WARNING: DEPLOYING SOLAR PANELS DISABLED.  DEPLOY MANUALLY.", 10, 2, 25, yellow, true).  getvoice(0):play(list(slidenote(300,350,0.5),note(0,0.5),slidenote(300,350,0.5))).
    lights on.
    print "launch done.".
  }
}
