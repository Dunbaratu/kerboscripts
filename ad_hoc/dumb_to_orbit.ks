// A dumb script to orbit, designed to be simple.
// made during twitch stream.

local the_voice is getvoice(0).

// You can ignore this if you dont care about
// silly sounds - this is not needed for most
// users, but it's an example in case you do
// care how it works:
function init_sound {
  set the_voice:wave to "triangle".
  set the_voice:attack to 0.1.
  set the_voice:decay to 0.1.
  set the_voice:sustain to 0.8.
  set the_voice:release to 0.3.
}

function msg {
  parameter text.

  hudtext(text, 4, 2, 22, rgb(1,0.8,0) , true).
  the_voice:play(slidenote(400,420,0.5,0.2)).
}

// This should generically work with most vessel
// designs, even asparagus staging:  Keep calling
// this function again and again while you launch.
// It will keep checking to see if either a flamed out
// engine exist, or zero engines are ignited.  Either
// way it will kick the next stage off:
function stage_if_needed {
  local eng_list is list().
  local num_act is 0.
  list engines in eng_list.
  for eng in eng_list {
    if eng:flameout {
      msg("An engine flamed out, so staging.").
      stage.
      break.
    } else if eng:ignition {
      set num_act to num_act + 1.
    }
  }
  if num_act = 0 {
    msg("Zero active engines, so staging.").
    stage.
  }
}

//   -------------------
//   ------ MAIN -------
//   -------------------

//  COUNTDOWN:

init_sound().

local t0 is time:seconds + 5.
local lastT is floor(time:seconds).
until time:seconds >= t0 {
  if floor(time:seconds) > lastT {
    msg("T " + (floor(time:seconds)-floor(t0)) + " seconds").
    set lastT to floor(time:seconds).
  }
  wait 0.
}

msg("LIFTOFF").
local cur_pitch is 90.

// This lock steering will stay active for most of the launch.
// It locks steering to a compass heading of 90 (east), pitched
// up to whatever the variable cur_pitch is (which starts at 90,
// meaning straight up, but that will change as the launch
// progresses):
lock steering to heading(90,cur_pitch).

lock throttle to 1.
local done is false.
local prev_pitch is cur_pitch.
local cutoff_ap is 80_000.

// This loop does liftoff until coast TO AP:
// This primitive loop doesn't account for
// changes for unusual thrust to weight ratios,
// that often require a more or less agressive
// initial "kickover":
until done {
  stage_if_needed().

  if altitude > 50_000 {
  } else if altitude > 40_000 {
    set cur_pitch to 15.
  } else if altitude > 30_000 {
    set cur_pitch to 25.
  } else if altitude > 25_000 {
    set cur_pitch to 30.
  } else if altitude > 20_000 {
    set cur_pitch to 38.
  } else if altitude > 15_000 {
    set cur_pitch to 45.
  } else if altitude > 10_000 {
    set cur_pitch to 55.
  } else if altitude > 5_000 {
    set cur_pitch to 65.
  } else if altitude > 3_000 {
    set cur_pitch to 70.
  } else if altitude > 1_000 {
    set cur_pitch to 80.
  }

  // Only print message when pitch just changed:
  if cur_pitch <> prev_pitch {
    msg("Pitching to " + cur_pitch).
    set prev_pitch to cur_pitch.
  }

  if apoapsis > cutoff_ap {
    set done to true.
    msg("Cutoff AP of "+cutoff_ap+"m reached.").
  }
  
  wait 0.
}

// Coast up to apoapsis:

msg("Waiting for AP").
lock throttle to 0.
// When out of atmo, lets lightly time warp, till ready for
// the burn:
wait until altitude > 70_000. // out of atmosphere.
msg("Doing light time warp till apoapsis.").
set warp to 2. // 10x in stock no mods.
wait until eta:apoapsis < 30..
set warp to 1. // 5x in stock no mods.
wait until eta:apoapsis < 15.
set warp to 0. // 5x in stock no mods.
msg("Near AP: doing circ burn").
lock throttle to 1.


// This loop does the circularization burn:
set done to false.
until done {
  stage_if_needed().
  local signed_eta is eta:apoapsis.

  // If the Ap is behind us, it will be reported
  // instead as being in our far future, more than
  // half a period in the future.  In that case,
  // convert it to a "negative eta" to apoapsis:
  if signed_eta > ship:obt:period / 2 {
    set signed_eta to signed_eta - ship:obt:period.
  }

  // Pitch up if AP behind us, pitch down if AP ahead of us:
  // for each 2 seconds we are away from eta:apoapsis, pitch
  // one more degree.  (But no more than the range -15 to +15
  // degrees pitch).  This is essentilaly a P controller,
  // without using the PID function to do it:
  set cur_pitch to min(15,max(-15,-(signed_eta/2))).

  if ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270 {
    set done to true.
    msg("Now closer to Pe than Ap, so stopping circ burn.").
  }
}

// done - cleanup:
msg("Aiming at sun for solar panels.").
lock throttle to 0.
lock steering to sun:position.
panels on.

// This wait here is important, because otherwise steeringmanager:anglerror doesn't report the truth:
// (Because the steeringmanager doesn't "see" the steering value has been changed to something new
// until the next "tick"):
wait 0.
wait until abs(steeringmanager:angleerror) < 2.
unlock steering.
unlock throttle.
sas on.
msg("Ad hoc launch script done.").



