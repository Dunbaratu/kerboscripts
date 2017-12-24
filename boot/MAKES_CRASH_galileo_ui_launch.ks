
wait until ship:unpacked.
wait 2. // need to let Remote tech find itself.
// Only run boot when launching, not when reloading vessel already
// in space:
parameter launchbody is "Gael".
if ship:periapsis < 100 and ship:body:name = launchbody and (status = "LANDED" or status = "PRELAUNCH") {

  hudtext( "Unpacked. Now loading launch software.", 2, 2, 45, green, true).
  switch to 1.
  if not exists("1:/lib")
    createdir("1:/lib/").
  if not exists("1:/songs")
    createdir("1:/songs/").
  copypath("0:/lib/launch","lib/").
  copypath("0:/lib/burn","lib/").
  copypath("0:/lib/isp","lib/").
  copypath("0:/lib/land.ks","lib/").
  copypath("0:/lib/song", "lib/").
  copypath("0:/lib/menu", "lib/").
  copypath("0:/launch","").
  copypath("0:/consts","").
  copypath("0:/stager","").
  copypath("0:/land_it.ks","").
  copypath("0:/just_obey_nodes.ks","").
  copypath("0:/songs/happy", "songs/").

  //copypath("0:/prediction","").
  //copypath("0:/rendezvous","").
  //copypath("0:/match_inc","").
  //copypath("0:/station_dock_server","").
  //copypath("0:/station_dock_client","").
  //copypath("0:/ca_land.ks","").
  //copypath("0:/lib_rover.ks","").
  //copypath("0:/use_rover.ks","").

  run once "/lib/menu".

  local launch_params is get_launch_params().

  if launch_params["go"] {
    set core:bootfilename to "".
    run launch( launch_params["heading"], launch_parames["apoapsis"]).
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
}

function get_launch_params {
  local params is LEX(
    "heading", 90,
    "apoapsis", 80000,
    "go", false
    ).

  local param_menu is make_menu( 2, 2, 30, 10, "Launch Parameters",
      LIST(
        "Heading", make_menu (0, 0, 10, 5, "Heading",
            LIST(
              "+10", { inc_tuple_thing(params, "heading", 10). draw_params(params).  },
              "+1",  { inc_tuple_thing(params, "heading", 1). draw_params(params).   },
              "-1",  { inc_tuple_thing(params, "heading", -1). draw_params(params).  },
              "-10", { inc_tuple_thing(params, "heading", -10). draw_params(params). }
            )
          ),
        "Apoapsis", make_menu (0, 0, 10, 5, "Apoapsis",
            LIST(
              "+100000", { inc_tuple_thing(params, "apoapsis", 100000). draw_params(params).  },
              "+10000",  { inc_tuple_thing(params, "apoapsis", 10000). draw_params(params).   },
              "+1000",   { inc_tuple_thing(params, "apoapsis", 1000). draw_params(params).    },
              "+100",    { inc_tuple_thing(params, "apoapsis", 100). draw_params(params).     },
              "+10",     { inc_tuple_thing(params, "apoapsis", 10). draw_params(params).      },
              "-10",     { inc_tuple_thing(params, "apoapsis", -10). draw_params(params).     },
              "-100",    { inc_tuple_thing(params, "apoapsis", -100). draw_params(params).    },
              "-1000",   { inc_tuple_thing(params, "apoapsis", -1000). draw_params(params).   },
              "-10000",  { inc_tuple_thing(params, "apoapsis", -10000). draw_params(params).  },
              "-100000", { inc_tuple_thing(params, "apoapsis", -100000). draw_params(params). }
            )
          ),
        "GO!", { set params["go"] to true. }
      )
    ).

  param_menu["start"]().
  
  return params.
}

function inc_tuple_thing {
  parameter the_lex, field, amount.

  set the_lex["field"] to the_lex["field"] + amount.
}

function draw_params {
  parameter the_lex.

  print " heading: " + the_lex[ "heading"] + "   " at (terminal:width - 17, 0).
  print "apoapsis: " + the_lex["apoapsis"] + "   " at (terminal:width - 17, 1).
}
