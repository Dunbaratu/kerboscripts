// A program to add and edit manuever nodes using the terminal
// and lib/menu.

@lazyglobal off.

run once "lib/menu".

{
  if not hasnode {
    add(node(time:seconds + 60*60,0,0,0)).
  }
  
  local eta_menu is make_knob_menu(
    "eta, seconds",
    { return nextnode:eta. },
    { parameter val. set nextnode:eta to val. },
    { print "ETA secs: " + round(nextNode:eta,2) + "   " at (terminal:width - 25, terminal:height - 3). }
    ).
  local pro_menu is make_knob_menu(
    "(retro/pro)grade",
    { return nextnode:prograde. },
    { parameter val. set nextnode:prograde to val. },
    { print "Prograde: " + round(nextNode:prograde,2) + "   " at (terminal:width - 25, terminal:height - 2). }
    ).
  local normal_menu is make_knob_menu(
    "(anti)normal",
    { return nextnode:normal. },
    { parameter val. set nextnode:normal to val. },
    { print "  Normal: " + round(nextNode:normal,2) + "   " at (terminal:width - 25, terminal:height - 1). }
    ).
  local radial_menu is make_knob_menu(
    "radial (in/out)",
    { return nextnode:radialout. },
    { parameter val. set nextnode:radialout to val. },
    { print "  Radial: " + round(nextNode:radialout,2) + "   " at (terminal:width - 25, terminal:height - 0). }
    ).

  local node_menu is make_menu(3,3,40,10, "Adjust Node",
    LIST(
      LIST( "ETA", eta_menu),
      LIST( "PROGRADE", pro_menu),
      LIST( "NORMAL", normal_menu),
      LIST( "RADIAL", radial_menu)
      )
    ).

  node_menu["start"]().

}

function make_knob_menu {
  parameter
    name,   // name of this knob.
    getter, // UserDelegate for getting the value of the knob
    setter, // UserDelegate for setting the value of the knob
    drawer. // UserDelegate for doing a redraw of the value of the knob

    local submenu is make_menu(0, 0, 20, 15, name, 
      LIST(
        LIST( "+1000", { setter:call(getter:call() + 1000). drawer:call(). } ),
        LIST( "+ 100", { setter:call(getter:call() + 100). drawer:call(). } ),
        LIST( "+  10", { setter:call(getter:call() + 10). drawer:call(). } ),
        LIST( "+   1", { setter:call(getter:call() + 1). drawer:call(). } ),
        LIST( "+   0.1", { setter:call(getter:call() + 0.1). drawer:call(). } ),
        LIST( "+   0.01", { setter:call(getter:call() + 0.01). drawer:call(). } ),
        LIST( "-   0.01", { setter:call(getter:call() - 0.01). drawer:call(). } ),
        LIST( "-   0.1", { setter:call(getter:call() - 0.1). drawer:call(). } ),
        LIST( "-   1", { setter:call(getter:call() - 1). drawer:call(). } ),
        LIST( "-  10", { setter:call(getter:call() - 10). drawer:call(). } ),
        LIST( "- 100", { setter:call(getter:call() - 100). drawer:call(). } ),
        LIST( "-1000", { setter:call(getter:call() - 1000). drawer:call(). } )
        )
      ).

  return submenu.
}
