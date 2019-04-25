// Orbital mechanics routine(s)

// Given a target body or vessel, get the phase angle
// needed to perform a hohmann transfer, and the dV needed
// to do it - dv will be expressed as a negative number if
// the burn needs to be retrograde.
// The two return values will be in a Lexicon with these keys:
// "dV", "phase"
function Hohmann_calc {
  parameter tgt.  // The vessel or body to reach

  local my_T is ship:obt:period.
  local tgt_T is tgt:obt:period.
  
  // Hohmann transfers assume everything is circular to start with,
  // so we don't need to use Semi-Major-Axis but I will anyway.
  local body_r is body:radius. // Hohmann transfers assume both orbits are around the same body.
  local mu is body:mu.
  local my_sma is ship:obt:semimajoraxis.
  local tgt_sma is tgt:obt:semimajoraxis.
  local trans_sma is (my_sma + tgt_sma)/2.

  // Get the vis-viva caculate speed for me and for the transfer at MY altitude:
  // ---------------------------------------------------------------------------

  // NOTE I am assuming I am close enough to cirular not to need to care
  // about the difference between my Pe and my Ap here and that my SMA is close
  // to the plain circ radius at all points.
  local my_spd is sqrt(mu/my_sma). 
  // Transfer orbit will be a my altitude to start with, so get its vis-viva derived speed
  // when its altitude equals mine:
  local trans_spd is sqrt(mu*(2/my_sma - 1/trans_sma)).

  local dV is trans_spd - my_spd.

  // Now get the phase angle between me and target:
  // ----------------------------------------------

  // First what is the period of the transfer orbit?
  local trans_T is 2 * constant:pi * sqrt( trans_sma^3 / mu ).

  // Now, how much angle will the target sweep in half that time, which
  // is the time for me to go Ap to Pe or Pe to Ap of the transfer?
  local tgt_sweep is (trans_T/2) * (360/tgt_T).

  // Phase angle - angle between me and target when I burn:
  local phase is 180 - tgt_sweep.
  if phase < 0 
    set phase to phase + 360.

  return lex("dv", dV, "phase", phase).
}

function make_Hohmann_node {
  parameter tgt.

  local calc is Hohmann_calc(tgt).

  // First, what is my phase angle with the Mun right now:
  local tgt_body_rel_pos is (tgt:position-body:position).
  local my_body_rel_pos is (ship:position-body:position).
  local cur_angle is vang(my_body_rel_pos, tgt_body_rel_pos).
  print "vang gave " + cur_angle. // eraseme
  // If Tgt is behind me, then add 180 to that VANG:
  if vdot(ship:prograde:vector, tgt_body_rel_pos) < 0
    set cur_angle to 360 - cur_angle.
  print "cur_angle is " + cur_angle. // eraseme

  // How many "degrees" of orbit should I wait to make it sync up?
  print "calc['phase'] is " + calc["phase"]. // eraseme
  local deg_spd is 360/ship:obt:period.
  local deg_to_wait is cur_angle - calc["phase"].
  // If it calculated that it's in my past, then move it to my future:
  if deg_to_wait < 0
    set deg_to_wait to deg_to_wait + 360.
  print "deg_to_wait is " + deg_to_wait. // eraseme

  // How fast does the phase angle between me and target change?
  local phase_rate is 360/ship:obt:period - 360/tgt:obt:period.
  // How long does it take me to sweep that many degrees?
  local time_to_wait is deg_to_wait / phase_rate.

  // Burn prograde for the given dV, at that far in the future:
  return node(time:seconds + time_to_wait, 0, 0, calc["dV"]).
}
