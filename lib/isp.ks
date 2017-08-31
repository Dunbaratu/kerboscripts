// Code copied directly from viewer nuggreat during the stream at
// Time mark 4min 40sec of the twitch stream for 2016-12-27:
// ----------------------------------------------------------------
function isp_calc {     //-----calculates the average isp of all of the active engins on the ship-----

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
    RETURN (totalThrust / totalFlow).
}


