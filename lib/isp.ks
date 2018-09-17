// Code copied directly from viewer nuggreat during the stream at
// Time mark 4min 40sec of the twitch stream for 2016-12-27:
// ----------------------------------------------------------------
local isp_calc_prev_partcount is -9999.
local isp_calc_prev_maxthrust is -9999.
local isp_calc_prev_availablethrust is -9999.
local isp_calc_prev_isp is -9999.

function isp_calc {     //-----calculates the average isp of all of the active engins on the ship-----

  local need_recalc is false.
  // Check to see if there's a reason to bother realculating anything:
  // If not, then just return the prev value:
  if ship:parts:length <> isp_calc_prev_partcount {
    set need_recalc to true.
    set isp_calc_prev_partcount to ship:parts:length.
  } else if maxthrust <> isp_calc_prev_maxthrust {
    set need_recalc to true.
    set isp_calc_prev_maxthrust to maxthrust.
  } else if availablethrust <> isp_calc_prev_availablethrust {
    set need_recalc to true.
    set isp_calc_prev_availablethrust to availablethrust.
  }

  if need_recalc {
    LIST ENGINES IN engineList.
    LOCAL totalFlow IS 0.
    LOCAL totalThrust IS 0.
    FOR engine IN engineList {
      IF engine:IGNITION AND NOT engine:FLAMEOUT {
        local seaPres is ship:body:atm:altitudePressure(0).
        local avail is engine:availablethrustat(seaPres).
        // the 9.802 term is wrong?: SET totalFlow TO totalFlow + (engine:AVAILABLETHRUST / (engine:ISP * 9.802)).
        SET totalFlow TO totalFlow + (avail / engine:ISPAT(seaPres)).
        SET totalThrust TO totalThrust + avail.
      }
    }
    IF MAXTHRUST = 0 {
      SET totalThrust TO 1.
      SET totalFlow TO 1.
    }

    set isp_calc_prev_isp to (totalThrust / totalFlow).
  }
  RETURN isp_calc_prev_isp.
}


