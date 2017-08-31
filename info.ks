clearscreen. print " ". print " ". print " ". print " ". print " ". print " ".
if not HASTARGET {
  print "No target selected.  Will use body inclination.".
  print "press any key to continue.".
  terminal:input:getchar().
}
local did_fairings to false.
until false {
  if hastarget {
    set myNorm to -1 * VCRS(ship:velocity:orbit,body:position).
    set tNorm to -1 * VCRS(target:velocity:orbit,body:position-target:position).
    set inc to vang(myNorm,tNorm).
    print "inc (without sign) = " + round(inc,3) + " deg    " at (0,0).
  } else {
    set inc to ship:orbit:inclination.
    print "inc (with sign) = " + round(inc,3) + " deg    " at (0,0).
  }
  print "Phase = " + round(vang(ship:position-body:position,target:position-body:position),3) at (0,1).
  print "Per: alt = " + round( ship:periapsis / 1000, 3) + " km    " at (0,2).
  print "Apo: alt = " + round( ship:apoapsis / 1000, 3) + " km    " at (0,3).
  print "Apo: ETA = " + round( ETA:Apoapsis, 2) + " s    " at (0,4).
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