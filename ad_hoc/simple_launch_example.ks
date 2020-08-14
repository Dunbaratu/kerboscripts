// A dumb script to orbit, designed to be simple.
// made during twitch stream.

// SHIP DESIGN RULES TO USE THIS SCRIPT::
//
// 1 - LAUNCH CLAMPS - If you have launch clamps, set them up so
//     they let go as the first stage starts (same item in staging list).
// 2 - PAYLOAD_CUT_PE - Set variable in this script: "payload_cut_pe" to the 
//     height you want to detach any parts you'd like to de-orbit just before
//     finishing circularizing.
// 3 - TAG NAMES THAT MEAN SOMETHING:
//     3.1 - "fairing" : Any part tagged "fairing" with ModuleProceduralFairing
//           in it, will be "Deploy"ed when Pe hits payload_cut_pe.
//     3.2 - "payload cutoff" : Any part tagged "payload cutoff" is assumed to
//           be in the "launcher" part of the rocket that must be staged away
//           just before finishing circularlization.  At "payload_cut_pe", the
//           script will stage until all the "payload_cutoff" parts have been
//           detached.  (i.e. tag the decoupler just under the payload with this name).

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
      wait until stage:ready.
      stage.
      wait 0.
      break.
    } else if eng:ignition {
      set num_act to num_act + 1.
    }
  }
  if num_act = 0 {
    msg("Zero active engines, so staging.").
    wait until stage:ready.
    stage.
    wait 0.
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
local min_pe is 70_000. // min safe Pe because of atmo.
local payload_cut_pe is 40_000.
local fairingModName is "ModuleProceduralFairing".


// This loop does liftoff until coast TO AP:
// This primitive loop doesn't account for
// changes for unusual thrust to weight ratios,
// that often require a more or less agressive
// initial "kickover":
until done {
  stage_if_needed().

  set cur_pitch to 85 - 85*(min(70_000,altitude)/70_000)^0.4.

  // Only print message when pitch just changed:
  if cur_pitch <> prev_pitch {
    print "Pitching to "+round(cur_pitch,1)+"deg  " at (terminal:width-25, terminal:height-1).
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
until altitude > min_pe {
  // If drag makes it drop in a bit, push it back up:
  if apoapsis < cutoff_ap - (cutoff_ap - min_pe)/10 {
    lock throttle to 1.
  } else if apoapsis > cutoff_ap {
    lock throttle to 0.
  }
  wait 1.
}
set warp to 0.
wait 2. // Because somtimes KSP doesn't remove the restriction on phys warp right away when hitting vacuum.
set kuniverse:timewarp:mode to "RAILS". // so the warp below works right even if player was phys warping to vacuum.
msg("Doing light time warp till apoapsis.").
set warp to 2. // 10x in stock no mods.
wait until eta:apoapsis < 50..
set warp to 1. // 5x in stock no mods.
wait until eta:apoapsis < 30.
set warp to 0. // 5x in stock no mods.
msg("Near AP: doing circ burn").
lock throttle to 1.


// This loop does the circularization burn:
local done is false.
local payload_cut_yet is false.
local fairing_cut_yet is false.
until done {
  stage_if_needed().
  local signed_eta is eta:apoapsis.

  if periapsis >= payload_cut_pe {
    // If Pe >= payload cutoff point, and the fairing is still
    // attached to the ship, then deploy all fairing parts away:
    if not(fairing_cut_yet) {
      local fairing_parts is ship:partstagged("fairing"). // expensive walk - don't do it too much.
      for p in fairing_parts {
	lock throttle to 0.
	wait 1.
	if p:hasmodule(fairingModName) {
          local fair_module is p:getmodule(fairingModName).
	  fair_module:doevent("Deploy").
	  msg("Pe above " + payload_cut_pe + "m.  Deploying Fairing.").
        }
      }
      set fairing_cut_yet to true.
    }
    // If Pe >= payload cutoff point, and some parts are
    // still attached to the ship with the "payload cutoff"
    // tag, then stage until that's not true anymore:
    if not(payload_cut_yet) {
      local cut_parts_list is ship:partstagged("payload cutoff"). // expensive walk - don't do it too much.
      if cut_parts_list:length > 0 {
	lock throttle to 0.
	wait 1.
	until cut_parts_list:length = 0 {
	  msg("Pe above " + payload_cut_pe + "m.  Decoupling until payload cutoff parts gone").
	  wait until stage:ready.
	  stage.
	  set cut_parts_list to ship:partstagged("payload cutoff"). // expensive walk - don't do it too much.
	}
      }
      set payload_cut_yet to true.
      lock throttle to 1.
    }
  }

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
    until periapsis > min_pe {
      msg("Still thrusting because Pe ("+round(periapsis,0)+") is too low (min="+min_pe+")").
      wait 2.
    }
    msg("Done launnching to orbit.").
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



