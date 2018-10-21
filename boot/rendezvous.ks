wait until ship:unpacked.
wait 2. // need to let Remote tech find itself.
// Only run boot when launching, not when reloading vessel already
// in space:
if homeconnection:isconnected {

  hudtext( "Unpacked. Now loading rendezvous software.", 2, 2, 45, green, true).
  switch to 1.
  if not exists("/lib/") {
    createdir("/lib/").
  }
  copypath("0:/lib/burn","/lib/").
  copypath("0:/lib/isp","lib/").
  copypath("0:/lib/ro","lib/").
  copypath("0:/lib/sanity","lib/").

  copypath("0:/rendezvous","/").
  copypath("0:/match_inc","/").
  copypath("0:/lib/prediction","/lib/").
  copypath("0:/lib/persist","/lib/").

  copypath("0:/consts","/").
  copypath("0:/stager","/").
}

clearscreen.
print "Select a ship as target for rendezvous first.".
until hastarget {
  wait 1.
}

run match_inc(target).
run rendezvous(target,0).
