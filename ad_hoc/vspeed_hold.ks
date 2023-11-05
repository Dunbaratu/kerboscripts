clearscreen.
print "Cheezy Program to just control vSpeed".
print "With elevator only.".
print "--------------------------------------".
print " ".
print " ".
print " ".
print " ".
print " ".
print " ".
print "Type (') to increase target vSpeed.".
print "Type (/) to decrease target vSpeed.".
print "Type (;) to Tighten pid tuning.".
print "Type (.) to Loosen pid tuning.".
print "Type ([) to Bank more left.".
print "Type (]) to Bank more right.".
print "Type (q) to Quit.".
set tuning to 0.005.

// Start at whatever attitude the plane is doing when the script began:
// At least to the nearest even number so the scripts +/- 2 adjustments
// can "land on" zero.
set tgt_v_spd to round(verticalspeed/2)*2. // nearest even number.
set tgt_bank to round(get_bank()/2)*2. // nearest even number.

set p_pid to pidloop(tuning, tuning/10, tuning/3, -1, 1).
set r_pid to pidloop(tuning, tuning/10, tuning/3, -1, 1).

tune_pid(). // make initial values take hold.

set done to false.
until done {
  set ship:control:pilotpitchtrim to p_pid:update(time:seconds,verticalspeed).
  set ship:control:pilotrolltrim to r_pid:update(time:seconds,get_bank()).

  do_print().
  if terminal:input:haschar {
    local ch is terminal:input:getchar().
    if ch = "'" {
      set tgt_v_spd to tgt_v_spd + 2.
      tune_pid().
    } else if ch = "/" {
      set tgt_v_spd to tgt_v_spd - 2.
      tune_pid().
    } else if ch = ";" {
      set tuning to tuning + 0.001.
      tune_pid().
    } else if ch = "." {
      set tuning to tuning - 0.001.
      tune_pid().
    } else if ch = "[" {
      set tgt_bank to tgt_bank - 2.
      tune_pid().
    } else if ch = "]" {
      set tgt_bank to tgt_bank + 2.
      tune_pid().
    } else if ch = "q" {
      set done to true.
    }
  }
  if status="LANDED" or status="SPLASHED" {
    set tgt_v_spd to 0.
    tune_pid().
  }
  wait 0.
}
set ship:control:pilotpitchtrim to 0.
set ship:control:pilotrolltrim to 0.
set ship:control:neutralize to true.
print "DONE.".

function do_print {
  print "TARGET VSPD = " + tgt_v_spd + " m/s " at (0,4).
  print "       Vspd = " + round(verticalspeed,2) + " m/s  " at (0,5).
  print " Pitch Trim = " + round(ship:control:pilotpitchtrim,3) + "   " at (0,6).
  print "  tgtBank = " + tgt_bank + " deg " at (25,4).
  print "     Bank = " + round(get_bank(),2) + " deg  " at (25,5).
  print "Roll Trim = " + round(ship:control:pilotrolltrim,3) + "  " at (25,6).
  print " PID Tuning = " + 
    round(p_pid:Kp,4) + ", " + 
    round(p_pid:Ki,4) + ", " +
    round(p_pid:kD,4) + "     " at (0,7).
}

function tune_pid {
  set p_pid:Kp to tuning.
  set p_pid:Ki to tuning / 10.
  set p_pid:Kd to tuning / 3.
  set p_pid:setpoint to tgt_v_spd.

  set r_pid:Kp to tuning.
  set r_pid:Ki to tuning / 10.
  set r_pid:Kd to tuning / 3.
  set r_pid:setpoint to tgt_bank.
}

function get_bank {
  return VANG(facing:starvector, up:vector) - 90.
}
