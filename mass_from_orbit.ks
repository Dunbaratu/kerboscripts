// Vis-Viva equation.
//    v = sqrt( GM * (2/r - 1/a ) )
// v = speed right now.
// GM = gravatational parameter "mu".
// r = radius to planet center from current pos.
// a = semi-major-axis.

// Solving for M.

//    v = sqrt( GM * (2/r - 1/a ) )
//    v^2 =  GM * (2/r - 1/a )
//    (v^2 / (2/r - 1/a )) =  GM
//    (v^2 / (2/r - 1/a )) / G = M

set vel to ship:velocity:orbit:mag.
set sma to ship:orbit:semimajoraxis.
set r to ship:body:position:mag.
set gravparm to constant:G.

print "vel =" + vel + "m/s".
print "sma =" + sma + "m".
print "  r =" + r + "m".
print "  G =" + gravparm.
print " ---------------".
print "  M = " + ((vel^2) / (2/r - 1/sma)) / gravparm + " kg".
