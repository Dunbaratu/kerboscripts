PRINT "THIS IS MY EXAMPLE BOOT PROGRAM.".
wait until ship:unpacked.
PRINT "SHIP IS UNPACKED.  OPENING TERMINAL.".
core:doevent("Open Terminal").

local target_alt is 200.
local hover_pid is PIDLOOP(0.01,0.001,0.01,0,1).
local throt is 0.
lock throttle to throt.
sas on.
stage.
clearscreen.

// print "IN THE TERMINAL, TYPE PLUS(+) or MINUS(-) TO".
// print "CHANGE TARGET ALTITUDE.".
print "SETTING UP GUI FOR HOVER".
local done is false.
local gWin is GUI(300).
gWin:addlabel("TYPE NEW ALTITUDE AND I WILL OBEY.").
local alt_field is gWin:Addtextfield(target_alt:tostring()).
set alt_field:onconfirm to on_alt_change@.
local button is gWin:Addbutton("QUIT").
set button:onclick to { set done to true. }.
gWin:show().

print "going into hover loop".
until done {
  set throt to hover_pid:update(time:seconds,(altitude - target_alt)).
  // input_check(). // if doing the terminal style.
  display().
  wait 0.
}
print "Done.".
gWin:dispose().

// This is the terminal input style:
//function input_check {
//  if not(terminal:input:haschar())
//    return. // only continue when there's input to consume.
//  local ch is terminal:input:getchar().
//  if ch = "+" {
//    set target_alt to target_alt + 5.
//  } else if ch = "-" {
//    set target_alt to target_alt - 5.
//  }
//}

// This is the gui style:
function on_alt_change {
  parameter new_val.

  // Set target to the string val converted to a number.
  // note, if it has an error converting to a number,
  // keep the value as is:
  set target_alt to new_val:tonumber(target_alt).
  // In case we had to undo the bad string, reset the string:
  set alt_field:text to target_alt:tostring().
}

function display {
  print "TARGET ALT = " + round(target_alt) + "m     " at (5, 5).
}
