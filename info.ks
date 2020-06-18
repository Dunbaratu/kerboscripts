clearscreen.
print "(Type letter 'c' to quit this and continue.)".
print " ". print " ". print " ". print " ". print " ". print " ".
parameter tgt.
local did_fairings to false.
until false or (terminal:input:haschar and terminal:input:getchar() = "c") {
  if tgt:istype("Body") {
    set myNorm to -1 * VCRS(ship:velocity:orbit,body:position).
    set tNorm to -1 * VCRS(tgt:velocity:orbit,body:position-tgt:position).
    set inc to vang(myNorm,tNorm).
    print "inc (without sign) = " + round(inc,3) + " deg    " at (0,2).
  } else {
    set inc to ship:orbit:inclination.
    print "inc (with sign) = " + round(inc,3) + " deg    " at (0,2).
  }
  print "Phase = " + round(vang(ship:position-body:position,tgt:position-body:position),3) at (0,3).
  print "Per: alt = " + round( ship:periapsis / 1000, 3) + " km    " at (0,4).
  print "Apo: alt = " + round( ship:apoapsis / 1000, 3) + " km    " at (0,5).
  print "Apo: ETA = " + round( ETA:Apoapsis, 2) + " s    " at (0,6).
  if (not did_fairings) and altitude > 100_000 {
    print "time to ditch fairings.".
    local flist is ship:partstagged("fairing").
    if flist:length = 0 {
      print "no parts tagged 'fairing'.".
    }
    for f in flist {
      local m is f:getmodule("proceduralfairingdecoupler").
      m:Doevent("jettison").
    }
    set did_fairings to true.
  }
  wait 0.5.
}
