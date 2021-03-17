parameter dest, speed, segway is false, jump_protect is false, prox is 10, offpitch is 0, save_dist is 5000, ocean_check is "", cheat_terrain is false.

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
  geopos_sanity(point).
  drive_to(point, speed, segway, jump_protect, prox, offpitch, save_dist, ocean_check, cheat_terrain).
}

function geopos_sanity {
  parameter pos.

  if pos:body <> ship:body {
    getvoice(0):play(list(slidenote(200,350,0.75),slidenote(200,350,0.75))).
    wait until not(getvoice(0):isplaying).
    local is_planet is (pos:body:body = Sun).
    print " ".
    print " ".
    print "HEY I CAN'T DRIVE TO ANOTHER " +
      (choose "PLANET" if is_planet else "MOON") + ", DUMMY!.".
    print " ".
    print "Bombing out on purpose.".
    print " ".
    print 1/0.
  }
}
