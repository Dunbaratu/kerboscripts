//KOS
// A function that will detect if there's a need to stage right now.
// Takes no arguments, but returns a boolean:
//
//   false = Staging did not occur.
//   true = Staged because of a flameout.
//
// Call repeatedly in a program's main loop as you are burning.
@LAZYGLOBAL OFF.
function stager {
  parameter stg_eList is 0. // IN/OUT: list of engins on ship.  Edited when staging to remove engines no longer attached.
  parameter zeroThrot is false. // set to true if you want ot zero throttle on staging because RO with ullage.
  local did_stage is false.
  local new_engs is stg_eList.

  // simple dumb - check if nothing active,
  // then stage:
  if ship:maxthrust = 0 {
    print "Staged because ship:maxthrust = 0 when throttle=" + throttle.
    if zeroThrot lock throttle to 0. wait 0.
    wait until stage:ready. stage.
    set did_stage to true.
  } else {
    if new_engs:istype("scalar")
       list engines in new_engs.
    for stg_eng in new_engs { 
      if stg_eng:name <> "sepMotor1" and stg_eng:tag <> "flameout no stage" and (stg_eng:ignition and stg_eng:flameout) {
        print "Staged because engine '" + stg_eng:title + "' flamed out when throttle=" + throttle.
        wait 0.
        // If NO engines, kill throttle while transitioning.
        // If *some* thrust (i.e. we staged a side booster but the core is still going), don't 
        // zero throttle as that would kill the still working engine:
        if zeroThrot and ship:maxthrust = 0 { 
          lock throttle to 0.
          wait 0.
        }
        wait until stage:ready. stage.
        list engines in new_engs.
        set did_stage to true.
        break.
      }.
    }.
  }
  // If we edited the list, edit the caller's list too:
  if did_stage and not stg_eList:istype("scalar") {
    stg_eList:CLEAR().
    for eng in new_engs { 
      stg_eList:ADD(eng).
    }
  }
  return did_stage.
}.
