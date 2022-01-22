wait until ship:unpacked.
core:doevent("Open Terminal").
print "About to run The 3000km boot script.".
print "Type [enter] when ready.".
print "Type [q] to quit and abort.".
local ch is "".
until ch = char(13) {
  wait until terminal:input:haschar().
  set ch to terminal:input:getchar().
  if ch = "q" { break. }
}
if ch = char(13) {
  run "0:/ad_hoc/3000km.ks"(90,62,30).
} else {
  print "Aborting.".
}

