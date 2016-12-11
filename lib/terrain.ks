@LAZYGLOBAL OFF.

// functions for helping with dealing with terrain readings.

// Given a name tag for some lasers that are meant to aim
// in parallel to each other and hit the ground in a triple,
// return a list of the LaserDistModule's for 3 of them to
// use for terrain detecting.
function get_terrain_lasers {
  parameter partName.

  local parts is ship:partstagged(partName).
  local laser_set is LIST().
  for p in parts {
    local module is p:getmodule("LaserDistModule").
    laser_set:add( module ).
    if laser_set:length >= 3 { break. } // only get the first 3 found.
  }
  return laser_set.
}

// Using a set of lasers returned by set_terrain_lasers,
// return the normal vector of the ground where they hit.
// Returns ship:up:vector if for some reason it can't
// reliably get the laser yet.
// WARNING: adds a single tick WAIT 0 because it needs to ensure
// it has good readings.
function get_laser_normal {
  parameter laser_set.

  local give_up is false.
  local dists is LIST().
  for las in laser_set {
    if not las:getfield("enabled") { las:setfield("enabled", true). set give_up to true. }
  }
  if give_up { return ship:up:vector. }
  wait 0.
  for las in laser_set {
    local dist is las:getfield("distance").
    if dist < 0 { set give_up to true. }
    dists:add(dist).
  }
  if give_up { return ship:up:vector. }
  local points is LIST().
  for i in range(0,3) {
    local hitPos is laser_set[i]:part:position + dists[i]*(laser_set[i]:part:facing:vector).
    points:add(hitPos).
  }
  local norm is VCRS( points[1] - points[0], points[2] - points[0]):normalized.
  if VDOT(norm, ship:up:vector) < 0 { set norm to -norm. }
  return norm.
}
