parameter dest, speed, jump_protect is false, prox is 10, offpitch is 0, save_dist is 5000, ocean_check is "".

run once "/lib/rover".

local point is latlng(0,0).
local do_it is true.
if dest:istype("vessel") or dest:istype("waypoint") {
  set point to dest:geoposition.
} else if dest:istype("part") {
  set point to body:geopositionof(dest:position).
} else if dest:istype("geocoordinates") {
  set point to dest.
} else {
  print "I don't know how to work with a dest type = " + dest:typename.
  set do_it to false.
}
if do_it {
  drive_to(point, speed, jump_protect, prox, offpitch, save_dist, ocean_check).
}
