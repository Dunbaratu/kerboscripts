wait until ship:unpacked.
if core:hasevent("Open Terminal") { core:doevent("Open Terminal"). }

// Only run boot when launching, not when reloading vessel already
// in space:
parameter launchbody is "Gael".
if ship:apoapsis < 500 and ship:body:name = launchbody and (status = "LANDED" or status = "PRELAUNCH") {

  hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).
  switch to 1.
  if not exists("1:/lib")
    createdir("1:/lib/").
  if not exists("1:/songs")
    createdir("1:/songs/").
  copypath("0:/lib/launch","/lib/").
  copypath("0:/lib/burn","/lib/").
  copypath("0:/lib/isp","/lib/").
  copypath("0:/lib/land.ks","/lib/").
  copypath("0:/lib/song", "/lib/").
  copypath("0:/lib/dock", "/lib/").
  copypath("0:/lib/menu", "/lib/").
  copypath("0:/lib/sanity", "/lib/").
  copypath("0:/lib/prediction","/lib").
  copypath("0:/launch","").
  copypath("0:/consts","").
  copypath("0:/stager","").
  copypath("0:/land_it.ks","").
  copypath("0:/just_obey_nodes.ks","").
  copypath("0:/precise_node","").
  copypath("0:/songs/happy", "songs/").
  copypath("0:/songs/sad", "songs/").

  copypath("0:/prediction","").
  copypath("0:/rendezvous","").
  copypath("0:/match_inc","").
  copypath("0:/station_dock_server","").
  copypath("0:/station_dock_client","").
  copypath("0:/dock_passive_target","").
  //copypath("0:/lib_rover.ks","").
  //copypath("0:/use_rover.ks","").
}

run once "/lib/menu".
clearscreen.

local launch_params is get_launch_params().

if launch_params["go"] {
  set core:bootfilename to "".
  run launch(
    launch_params["heading"],
    launch_params["apoapsis"],
    5,
    -1,
    -1,
    launch_params["atmo_end"]
    ).
  lock steering to north.
  wait 15.
  unlock steering.
  panels on.
  lights on.
  print "launch done.".
  set core:bootfilename to "just_obey_nodes.ks".
  print "Rebooting into just obey nodes mode.".
  wait 1.
  reboot.
} else {
  print "Launch Cancelled.  Reboot kOS computer to try again.".
}

function get_launch_params {
  local params is LEX(
    "heading", 90,
    "apoapsis", 80000,
    "atmo_end", 70000,
    "go", false
    ).

  redraw_params(params).

  local param_menu is make_menu( 0, 0, 40, 10, "Launch Parameters",
      LIST(
        LIST( "Heading", make_menu (0, 0, 20, 15, "Heading",
            LIST(
              LIST("+10", inc_tuple_thing@:bind(params, "heading", 10) ),
              LIST("+1",  inc_tuple_thing@:bind(params, "heading", 1)  ),
              LIST("-1",  inc_tuple_thing@:bind(params, "heading", -1) ),
              LIST("-10", inc_tuple_thing@:bind(params, "heading", -10))
            )
          )
        ),
        LIST( "Apoapsis", make_menu (0, 0, 20, 15, "Apoapsis",
            LIST(
              LIST("+100000", inc_tuple_thing@:bind(params, "apoapsis", 100000)  ),
              LIST("+10000",  inc_tuple_thing@:bind(params, "apoapsis", 10000)   ),
              LIST("+1000",   inc_tuple_thing@:bind(params, "apoapsis", 1000)    ),
              LIST("+100",    inc_tuple_thing@:bind(params, "apoapsis", 100)     ),
              LIST("+10",     inc_tuple_thing@:bind(params, "apoapsis", 10)      ),
              LIST("-10",     inc_tuple_thing@:bind(params, "apoapsis", -10)     ),
              LIST("-100",    inc_tuple_thing@:bind(params, "apoapsis", -100)    ),
              LIST("-1000",   inc_tuple_thing@:bind(params, "apoapsis", -1000)   ),
              LIST("-10000",  inc_tuple_thing@:bind(params, "apoapsis", -10000)  ),
              LIST("-100000", inc_tuple_thing@:bind(params, "apoapsis", -100000) )
            )
          )
        ),
        LIST( "Atmo Alt", make_menu (0, 0, 20, 15, "Atmosphere Altitude",
            LIST(
              LIST("+10000",  inc_tuple_thing@:bind(params, "atmo_end", 10000)   ),
              LIST("+1000",   inc_tuple_thing@:bind(params, "atmo_end", 1000)    ),
              LIST("+100",    inc_tuple_thing@:bind(params, "atmo_end", 100)     ),
              LIST("+10",     inc_tuple_thing@:bind(params, "atmo_end", 10)      ),
              LIST("-10",     inc_tuple_thing@:bind(params, "atmo_end", -10)     ),
              LIST("-100",    inc_tuple_thing@:bind(params, "atmo_end", -100)    ),
              LIST("-1000",   inc_tuple_thing@:bind(params, "atmo_end", -1000)   ),
              LIST("-10000",  inc_tuple_thing@:bind(params, "atmo_end", -10000)  )
            )
          )
        ),
        LIST( "GO!", { set params["go"] to true. redraw_params(params). } ),
        LIST( "Abort!", { set params["go"] to false. redraw_params(params). } )
      )
    ).

  param_menu["start"]().
  
  return params.
}

function inc_tuple_thing {
  parameter the_lex, field, amount.

  set the_lex[field] to the_lex[field] + amount.

  redraw_params(the_lex).
}

function redraw_params {
  parameter the_lex.

  print " Heading: " + the_lex[ "heading"] + "   " at (terminal:width - 17, 0).
  print "Apoapsis: " + the_lex["apoapsis"] + "   " at (terminal:width - 17, 1).
  print "Atmo Alt: " + the_lex["atmo_end"] + "   " at (terminal:width - 17, 2).
  if the_lex["go"] {
    print "  Launch is GO! " at (terminal:width - 17, 3).
  } else {
    print " Will Not Launch" at (terminal:width - 17, 3).
  }
}
