
wait until ship:unpacked.
wait 2. // need to let Remote tech find itself.
// Only run boot when launching, not when reloading vessel already
// in space:
parameter launchbody is "Gael".
if ship:periapsis < 100 and ship:body:name = launchbody and (status = "LANDED" or status = "PRELAUNCH") {

  hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).
  switch to 1.
  if not exists("1:/lib")
    createdir("1:/lib/").
  if not exists("1:/songs")
    createdir("1:/songs/").
  copypath("0:/lib/launch","lib/").
  copypath("0:/lib/burn","lib/").
  copypath("0:/lib/isp","lib/").
  copypath("0:/lib/land.ks","lib/").
  copypath("0:/lib/song", "lib/").
  copypath("0:/launch","").
  copypath("0:/consts","").
  copypath("0:/stager","").
  copypath("0:/land_it.ks","").
  copypath("0:/just_obey_nodes.ks","").
  copypath("0:/songs/happy", "songs/").

  //copypath("0:/prediction","").
  //copypath("0:/rendezvous","").
  //copypath("0:/match_inc","").
  //copypath("0:/station_dock_server","").
  //copypath("0:/station_dock_client","").
  //copypath("0:/ca_land.ks","").
  //copypath("0:/lib_rover.ks","").
  //copypath("0:/use_rover.ks","").


  set core:bootfilename to "".
  run launch( 100, 80000).
  lock steering to north.
  wait 15.
  unlock steering.
  panels on.
  lights on.
  print "launch done.".
  set core:bootfilename to "just_obey_nodes.ks".
  print "Rebooting into just obey nodes mode.".
  wait 1.
  reboot.
}
