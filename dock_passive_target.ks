run once "lib/dock".


CLEARSCREEN.

hudtext_until_condition(
  {wait 0.1. return HASTARGET and not target:istype("Body").}, 8, 0.5, 
  "You need to set target to a vessel, docking port, or asteroid to continue.", 5, 2, 20, red, true).

local tgt is target.

// If targeting a whole vessel, then target its first part instead:
if tgt:ISTYPE("VESSEL") {
  set tgt to tgt:parts[0].
}

// If the part being targetted is a docking port, then lock to its port facing,
// else lock to its normal facing if it's any other kind of part:
if tgt:ISTYPE("DOCKINGPORT") {
  lock steering to lookdirup(- tgt:portfacing:forevector, tgt:portfacing:topvector).
} else {
  print "Target is a docking port.".
  lock steering to lookdirup(- tgt:portfacing:vector, tgt:portfacing:topvector).
} 

local from_parts is ship:partstagged("from here").
hudtext_until_condition(
  {set from_parts to ship:partstagged("from here"). wait 0.1. return from_parts:length = 1.}, 10, 0.2,
  "Choose docking port on this vessel to dock from by giving exactly 1 port the name tag 'from here'.",
  8, 2, 20, yellow, true).


print "DOCKING SCRIPT COMMENCING".
do_dock(from_parts[0], tgt).


// Display a hudtext and a sound if a condition is false, and keep checking the
// condition repeatedly until it becomes true.  Message will repeat occasionally
// during the checking.
// As long as the condition is false, this function will not return.
// (This could be moved into a library perhaps):
function hudtext_until_condition {
  parameter
    condition, // Delegate that returns Boolean True if condition has been met, else returns false.
    repeat_seconds, // duration before redisplay of message (must be > delay arg below).
    sound_severity, // value from 0.0 (silent) to 1.0 (aggressive and annoying) for warning sound severity.
    // The rest of the parameters match exactly to HUDTEXT's parameters:
    msg,    // text passed to hudtext
    delay,  // passed to hudtext, should be < repeat_seconds
    style,  // passed to hudtext
    size,   // passed to hudtext
    colour, // passed to hudtext
    doEcho. // passed to hudtext
    
  local low_note is 0.
  local high_note is 0.
  if sound_severity > 0 {
    set low_note to note(100+500*sound_severity, 0.8*sound_severity, 0.6*sound_severity, 0.7*sound_severity+0.3).
    set high_note to note(100+800*sound_severity, 0.8*sound_severity, 0.6*sound_severity, 0.5*sound_severity+0.5).
    local v0 is getvoice(0).
    set v0:wave to "sawtooth".
    set v0:attack to 0.
    set v0:decay to 0.
    set v0:sustain to 1.
    set v0:release to 0.15.
  }

  until condition:call() {

    if sound_severity > 0 {
      getvoice(0):play( list(low_note, note(0,0.1), high_note) ).
    }

    HUDTEXT(msg, delay, style, size, colour, doEcho).
    
    // Wait until repeat timer is done, or condition is met.
    local stamp is time:seconds.
    wait until time:seconds > stamp + repeat_seconds or condition:call().
  }

}
