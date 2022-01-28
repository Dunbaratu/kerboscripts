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
  local want_stage is false.
  local new_engs is stg_eList.
  local unused_engs_exist is false.
  local reason is "".

  local ignited_before is get_ignited_set(stg_eList).

  // Maxthrust falsely reads zero sometimes when on rails, making
  // this check stage unnecesarily. Skip check if on rails:
  if (kuniverse:timewarp:mode = "RAILS" and kuniverse:timewarp:warp > 0) or
     not(ship:unpacked) {
    return false.
  }

  // simple dumb - check if nothing active,
  // then stage:
  if ship:availablethrust = 0 {
    set reason to "Staged because availablethrust = 0 when throttle=" + round(throttle,3).
    if zeroThrot lock throttle to 0. wait 0.
    set want_stage to true.
  }
  if new_engs:istype("scalar") {
     local elist is 0.
     list engines in elist.
     for eng in elist {
       new_engs:add(eng).
     }
  }
  for stg_eng in new_engs { 
    if stg_eng:ship = ship { // skip parts in the list no longer attached, if there are any
      if not(probably_sepratron(stg_eng)) {
        if (stg_eng:ignition and stg_eng:flameout) {
          set reason to "Staged because engine '" + stg_eng:title + "' flamed out when throttle=" + throttle.
          wait 0.
          // If NO engines, kill throttle while transitioning.
          // If *some* thrust (i.e. we staged a side booster but the core is still going), don't 
          // zero throttle as that would kill the still working engine:
          if zeroThrot and ship:maxthrust = 0 { 
            lock throttle to 0.
            wait 0.
          }
          set want_stage to true.
        } else { // At least 1 engine exists that is either still running or hasn't been started:
          set unused_engs_exist to true.
        }
      }
    }
  }

  if want_stage and unused_engs_exist {
    wait until stage:ready.
    stage.
    print reason.
    wait 0. // make decoupled engines go away before making list again.
    list engines in new_engs.
    local new_igniteds is get_new_igniteds(new_engs, ignited_before).
    if new_igniteds > 0 {
      print "Stager just ignited " + new_igniteds + " new engine(s).".
      print " |-- Waiting for new engine(s) to spool some thrust up.".
      local startwait is time:seconds.
      until availablethrust > 0 {
        if (time:seconds > startwait + 6) {
          print " |-- ERROR - after 6 seconds still no thrust at all.".
          break.
        }
      }
      print " `-- Done Waiting.".
    }
    set did_stage to true.
  }

  // If we edited the list, edit the caller's list too:
  if did_stage and not stg_eList:istype("scalar") {
    stg_eList:CLEAR().
    for eng in new_engs { 
      stg_eList:ADD(eng).
    }
  }
  return did_stage.

  // How many engines in the list are ignited that weren't in the old list?
  function get_ignited_set {
    parameter eng_list.

    local eng_set is uniqueset().
    for eng in eng_list {
      if eng:ignition
        eng_set:add(eng:UID).
    }
    return eng_set.
  }

  // How many engines in the new list are ignited now that weren't in the old list?
  function get_new_igniteds {
    parameter eng_list, old_ign_set.

    local num is 0.
    for eng in eng_list {
      if eng:ignition and not(old_ign_set:contains(eng:UID)) {
        set num to num + 1.
      }
    }
    return num.
  }

  // Is this flamed-out engine likely just a tiny sepratron and is
  // not actualy a booster in need of decoupling?  This check
  // had to be more complex to handle RP-1 since RP-1 has many
  // little parts that can serve as sepratrons:
  function probably_sepratron {
    parameter eng.
    if eng:name = "sepMotor1" or eng:tag = "flameout no stage" 
      return true.
    // If its direct parent is a decoupler, it has to be a decouple-able
    // booster.  It can't be a sepratron:
    if eng:hasparent and eng:parent:istype("decoupler")
      return false.

    // The above checks should get a trustable answer in most cases.
    // From here down it gets a bit guess-y and heuristic:

    // If it's a small enough size, it's probably(?) a sepratron:
    if eng:mass < 0.1
      return true.

    return false.
  }
  
}

