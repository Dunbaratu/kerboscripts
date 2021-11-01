// Twitch demo script.
@LAZYGLOBAL off.

run consts.

// Get the ETA time to a future True Anomaly point in
// some orbit.
// ----------------------------------------------------
function eta_to_ta {
  parameter
    orbit_in, // orbit to predict for.
    ta_deg.   // true anomaly we're looking for, in degrees.

  local targetTime is time_pe_to_ta(orbit_in, ta_deg).
  local curTime is time_pe_to_ta(orbit_in, orbit_in:trueanomaly).

  local ta is targetTime - curTime.

  // If negative so we already passed it this orbit,
  // then get the one from the next orbit:
  if ta < 0 { set ta to ta + orbit_in:period.  }

  return ta.
}

// The time it takes to get from periapsis to a given true anamoly
// ---------------------------------------------------------------
function time_pe_to_ta {
  parameter
    orbit_in, // orbit to predict for
    ta_deg.   // in degrees

  local ecc is orbit_in:eccentricity.
  local sma is orbit_in:semimajoraxis.
  local e_anom_deg is arctan2( sqrt(1-ecc^2)*sin(ta_deg), ecc + cos(ta_deg) ).
  local e_anom_rad is e_anom_deg * pi/180.
  local m_anom_rad is e_anom_rad - ecc*sin(e_anom_deg).

  return m_anom_rad / sqrt( orbit_in:body:mu / sma^3 ).
}


// Get a unit vector normal to an orbit's plane:
// The normal direction will use the convention that
// a counterclockwise orbit gets a southward normal,
// and a clockwise one gets a northward normal.
// -------------------------------------------
function orbit_normal {
  parameter orbit_in.

  return VCRS( orbit_in:body:position - orbit_in:position,
               orbit_in:velocity:orbit ):NORMALIZED.
}

// Find the ascending node where orbit 1 crosses the plane of orbit 2.
// Answer is returned in the form of true anomaly of orbit 1 (angle from
// orbit 1's periapsis).  To find the descending node, you can flip the
// answer by 180 deg.
// ----------------------------------------------------------------------
function find_ascending_node_ta {
  parameter orbit_1, orbit_2. // orbits to predict for

  local normal_1 is orbit_normal(orbit_1).
  local normal_2 is orbit_normal(orbit_2).

  // unit vector pointing from body's center toward the node:
  local vec_body_to_node is VCRS(normal_1,normal_2).

  // vector pointing from body's center to orbit 1's current position:
  local pos_1_body_rel is orbit_1:position - orbit_1:body:position.

  // how many true anomaly degrees ahead of my current true anomaly:
  local ta_ahead is VANG(vec_body_to_node, pos_1_body_rel).

  local sign_check_vec is VCRS(vec_body_to_node, pos_1_body_rel).

  if VDOT(normal_1,sign_check_vec) < 0 {
    set ta_ahead to 360 - ta_ahead.
  }

  // Add current true anomaly to get the absolute true anomaly:
  return mod( orbit_1:trueanomaly + ta_ahead, 360).
}

// Build a manuever burn that if applied to vessel 1 would match its
// inclination to orbit 2.  Does not actually make a maneuver node to
// the flight plan.
// Returns two items in a list:
//  [0] = Universal Time of the burn.
//  [1] = DeltaV vector.
// TODO: return a manuever node instead after we make
// NODE:DELTAV settable.
// ----------------------------------------------------------------
function inclination_match_burn {
  parameter
    vessel_1, // vessel of the object that will execute the burn
    orbit_2,  // orbit of the object that orbit 1 will match with
    soonest is false. // TRUE means use the soonest node, not highest.

  local normal_1 is orbit_normal(vessel_1:obt).
  local normal_2 is orbit_normal(orbit_2).

  // true anomaly of the ascending node:
  local node_ta is find_ascending_node_ta(vessel_1:obt, orbit_2).

  if soonest {
    // Pick whichever node is in front of me sooner:
    if sin(node_ta - vessel_1:obt:trueanomaly) < 0 {
      set node_ta to mod(node_ta + 180, 360).
    }
  } else {
    // Pick whichever node, An or Dn, is higher altitude
    if node_ta < 90 or node_ta > 270 {
      set node_ta to mod(node_ta + 180, 360).
    }
  }

  // burn's eta, unit vector direction, and magnitude of burn:
  local burn_eta is eta_to_ta(vessel_1:obt, node_ta).
  local burn_ut is time:seconds + burn_eta.
  local burn_unit is (normal_1 + normal_2 ):NORMALIZED.
  local vel_at_eta is VELOCITYAT(vessel_1,burn_ut):ORBIT.
  local burn_mag is -2*vel_at_eta:MAG*COS(VANG(vel_at_eta,burn_unit)).

  return LIST(burn_ut, burn_mag*burn_unit).
}

// Get an orbit's altitude at a given true anomaly angle of it.
// ------------------------------------------------------------
function orbit_altitude_at_ta {
  parameter
    orbit_in,  // orbit to check for.
    true_anom. // in degrees.

  local sma is orbit_in:semimajoraxis.
  local ecc is orbit_in:eccentricity.
  local radius is sma*(1-ecc^2)/(1+ecc*cos(true_anom)).

  return radius - orbit_in:body:radius.
}

// How far ahead is obt1's true_anomaly measures from obt2's, in degrees?
// ----------------------------------------------------------------------
function ta_offset {
  parameter orbit_1, orbit_2.

  // obt 1 periapsis longitude (relative to solar system, not to kerbin).
  local pe_lng_1 is
    orbit_1:argumentofperiapsis +
    orbit_1:longitudeofascendingnode.

  // obt 2 periapsis longitude (relative to solar system, not to kerbin).
  local pe_lng_2 is
    orbit_2:argumentofperiapsis +
    orbit_2:longitudeofascendingnode.

  // how far ahead is obt1's true_anomaly measures from obt2's, in degrees?
  return pe_lng_1 - pe_lng_2.
}

// Get the true anomaly of orbit_1 where it crosses orbit_2's altitude,
// using a "warmer/cooler" algorithm. This is expensive, so don't do
// it repeatedly. Specify the intended max/min epsilon of accuracy.
// Returns -1 as a flag to indicate there is no such crossing point.
// --------------------------------------------------------------------
function orbit_cross_ta {
  parameter
    orbit_1, // orbit to report TA for.
    orbit_2, // orbit to find intersect with.
    max_epsilon, // how coarse to do the search at first - too big and it might miss a hit.
    min_epsilon. // how tight to trim the search before accepting the answer.

  local pe_ta_off is ta_offset( orbit_1, orbit_2 ).

  local incr is max_epsilon.
  local prev_diff is 0.
  local start_ta is orbit_1:trueanomaly. // start search where the ship currently is.
  local ta is start_ta.

  until ta > start_ta+360 or abs(incr) < min_epsilon {
    local diff is orbit_altitude_at_ta(orbit_1, ta) -
                  orbit_altitude_at_ta(orbit_2, pe_ta_off + ta).

    // If pos/neg signs of diff and prev_diff differ and neither are zero:
    if diff * prev_diff < 0 {
      // Then this is a hit, so we reverse direction and go slower
      set incr to -incr/10.
    }
    set prev_diff to diff.

    set ta to ta + incr.
  }

  if ta > start_ta+360 {
    return -1.
  } else {
    return mod(ta,360).
  }
}
