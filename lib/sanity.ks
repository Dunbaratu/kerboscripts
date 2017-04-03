// cause steering manager settings to go back to reasonable defaults.
function sane_steering {
  local did_something is false.
  if steeringmanager:RollControlAngleRange > 5 {
    set steeringmanager:RollControlAngleRange to 5.
    set did_something to true.
  }
  if steeringmanager:yawpid:Kp = 0 {
    set steeringmanager:yawpid:Kp to 1.
    set steeringmanager:yawpid:Ki to 0.0001.
    set steeringmanager:yawpid:Kd to 0.1.
    set did_something to true.
  }
  if steeringmanager:pitchpid:Kp = 0 {
    set steeringmanager:pitchpid:Kp to 1.
    set steeringmanager:pitchpid:Ki to 0.0001.
    set steeringmanager:pitchid:Kd to 0.1.
    set did_something to true.
  }
  if steeringmanager:rollpid:Kp = 0 {
    set steeringmanager:rollpid:Kp to 1.
    set steeringmanager:rollpid:Ki to 0.0001.
    set steeringmanager:rollpid:Kd to 0.1.
    set did_something to true.
  }
  if did_something {
    print "STEERINGMANAGER SETTINGS WERE NOT SANE.".
    print "JUST SET THEM TO SOMETHING THAT MAY WORK?".
  }
}

// Do not proceed if the craft isn't aimed upward.
function sane_upward {
  print "THIS IS SANE_UPWARD:  VANG is " + VANG(ship:facing:vector, ship:up:vector).
  until VANG(ship:facing:vector, ship:up:vector) < 45 {
    hudtext( "PROBE ORIENTATION NOT UPWARD!! PLEASE FIX IT.", 2, 1, 25, white, true).
    getvoice(1):play(list(slidenote(400,500,0.5),slidenote(500,400,0.5))).
    wait 4.
  }
}
