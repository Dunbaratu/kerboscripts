// A library of routines to help manage script navpoints
// The script's idea of a navpoint probably doesn't have to match the game's.

// A navpoint in our terms will be a lexicon of these keys:
// "NAME", must exist, just a name for display purposes.
// "GEO", must exist, a geoposition.
// "ALT", must exist, an altitude scalar.
// "AGL", must exist, boolean: true = "alt" is expressed as a radar alt, false = "alt" is sea level alt
// "RADIUS", must exist, a radius (meters) to fly through to hit the point and move on to the next.
// "SPD", optional, a desired m/s speed to approach this navpoint at.
// Note if ALT=0, and AGL=True, then this navpoint is meant to be landed.  

parameter system is "RSS". // set to "STOCK", "BH", "RSS" or "GPP" or "JNSQ"...

// A list of known runways in the universe (stock):
// A runway definition is 2 points - the endpoints.
local known_runways is
LEXICON(
  "KSC",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.0485,
      "LNG", -74.7288,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.0502,
      "LNG", -74.4881,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock")
  ),

  "ISLAND",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -1.5172829,
      "LNG", -71.967756,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -1.516785,
      "LNG", -71.85207,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock")
  ),

  "DESSERT",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.60119674818683,
      "LNG", -144.041126862394,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.44608447853134,
      "LNG", -144.038237420846,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "Stock")
  ),

  "CAPE SPACE SHUTTLE",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 28.65780448914,
      "LNG", -80.71656799316,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 28.6224098205566,
      "LNG", -80.6933135986328,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "WHITE SANDS",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 32.9477,
      "LNG", -106.43398,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 32.9477,
      "LNG", -106.40697,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "KODIAK",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 57.439745,
      "LNG", -152.3611177,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 57.439745,
      "LNG", -152.32065296,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "Kourou",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 5.243848,
      "LNG", -52.780252,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 5.243848,
      "LNG", -52.758152,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "JP - Uchinoura",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 31.2363696,
      "LNG", 131.0750199,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 31.23632494,
      "LNG", 131.101235598,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "Woomera",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", -30.95428,
      "LNG", 136.489997,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", -30.95428,
      "LNG", 136.515143,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "Vandenberg",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 34.58576965,
      "LNG", -120.64112854,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", 34.5857582,
      "LNG", -120.616584778,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "NZ KSC",
  LIST(
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", -39.2559731096646,
      "LNG", 177.848687662757,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS"),
    LEXICON (
      "BODYNAME", "Earth",
      "LAT", -39.2559658896384,
      "LNG", 177.877886147977,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "RSS")
  ),

  "KSC 'Kerbin=Gael'",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 8.68703,
      "LNG", -168.34211,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "GPP"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 8.68749,
      "LNG", -168.1107,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "GPP")
  ),

  "DomRok 'Kerbin=Gael'",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -7.354855,
      "LNG", -114.578911,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "GPP"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -7.353289,
      "LNG", -114.9399995,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "GPP")
  ),

  "KSC 'Kerbin=Rhode'",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 0.0656068,
      "LNG", -48.356986,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "BH"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 0.0608,
      "LNG", -48.0585,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "BH")
  ),

  "JNSQ's KSC",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 0.0177674,
      "LNG", -91.84524,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 0.0178196,
      "LNG", -91.76136,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Boneyard",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.956926,
      "LNG", -92.29402,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.956825,
      "LNG", -92.372215,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Smusgrave",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.62953,
      "LNG", -108.196266,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.629532,
      "LNG", -108.287216,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's MCMcAuliffe",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 10.090280,
      "LNG", -67.303925,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 10.090339,
      "LNG", -67.21456,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Welcome Island",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.411935,
      "LNG", -86.555259,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -0.41205,
      "LNG", -86.466896,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Base S24A N/S",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -24.5992,
      "LNG", -75.9397,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -24.68945,
      "LNG", -75.93967,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Base S24A E/W",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -24.67165,
      "LNG", -75.82216,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -24.67191,
      "LNG", -75.92145,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's Darude Runway",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.51990,
      "LNG", -143.98593,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", -6.51994,
      "LNG", -144.06700,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's N76 N/S",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 76.12236,
      "LNG", 102.23169,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 76.0322418,
      "LNG", 102.23185,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  ),

  "JNSQ's N76 E/W",
  LIST(
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 76.049789,
      "LNG", 102.301422,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ"),
    LEXICON (
      "BODYNAME", "Kerbin",
      "LAT", 76.04951377,
      "LNG", 102.676193,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "SYSTEM", "JNSQ")
  )


).

local course is list(). // list of NAVpoint lexicons currently being used.
local course_index is -1. // position in course (course counts backward, BTW).
local course_update_del is 0. // delegate to call to tell other program the index or course changed.
local g_course is 0. // will be the GUI() for controlling the course.


local g_course_box is 0.
local g_course_buttons is "". // list of radiobuttons for the navpoint lexicons.
function gui_update_course_index {
  parameter new_val.
  set course_index to new_val.
  course_update_del:CALL(course_index, course).
  if not(g_course_buttons:istype("STRING")) {
    if new_val >= 0 {
     set g_course_buttons[(g_course_buttons:length-1)-course_index]:PRESSED to true. // should cause a hook response that remakes the button list.
    }
  }
}
function gui_get_course_index {
  return course_index.
}

function gui_edit_course {
  parameter
    index is -1,
    updater_del is 0.

  set course_index to index.
  set course_update_del to updater_del.


  local done is false.

  set g_course to GUI(300).
  set g_course:style:fontsize to 12.
  local g_titlebox is g_course:addhbox().
  local title is g_titlebox:addlabel("Autopilot Course Chooser").
  set title:style:fontsize to 16.
  set title:style:textcolor to black.
  local close_button is g_titlebox:addbutton("[Close]").

  // --------- Add pre-cooked landing site -------------
  set g_course:addlabel("<b>Pre-Cooked Landing course</b>"):style:align to "CENTER".
  local g_land_box is g_course:addvbox().
  local g_land_box_hor is g_land_box:addhbox().
  local landing_list is g_land_box_hor:addpopupmenu().
  set landing_list:style:width to 200.
  for r_name in known_runways:KEYS {
    // Only put runways in the list if they are part of the system
    // we were called with ("RSS", "Stock", etc):
    if known_runways[r_name][0]["SYSTEM"] = system {

      // Figure runway heading with trig:
      local lat0 is known_runways[r_name][0]["LAT"]. 
      local lat1 is known_runways[r_name][1]["LAT"]. 
      local lng0 is known_runways[r_name][0]["LNG"]. 
      local lng1 is known_runways[r_name][1]["LNG"]. 
      local compass is arctan2(lng1-lng0,lat1-lat0).
      if compass < 5 { set compass to compass + 360. }
      landing_list:addoption(r_name + "("+round(compass/10)+")").
      set compass to arctan2(lng0-lng1,lat0-lat1).
      if compass < 5 { set compass to compass + 360. }
      landing_list:addoption(r_name + "("+round(compass/10)+")").
    }
  }
  local g_land_spd_box is g_land_box_hor:addhbox().
  g_land_spd_box:addlabel("at").
  local g_land_spd is g_land_spd_box:addTextField("70").
  set g_land_spd:style:width to 40.
  g_land_spd_box:addlabel("m/s").
  local g_land_alt_box is g_land_box_hor:addhbox().
  g_land_alt_box:addlabel("gearAlt").
  local g_land_alt is g_land_alt_box:addTextField("10").
  set g_land_alt:style:width to 40.
  g_land_alt_box:addlabel("m").
  local g_land_insert_button is g_land_box_hor:addbutton("Add").
  set g_land_insert_button:onclick to onclick_insert_landing@.
  set close_button:onclick to {set done to true. g_course:hide(). g_course:dispose().}.

  g_course:addspacing(4).

  // --------- Add arbitrary landing location -----------
  set g_course:addlabel("<b>Arbitrary Lat/Lng landing</b>"):style:align to "CENTER".
  local g_landlatlng_box is g_course:addhbox().
  local g_landlatlng_latbox is g_landlatlng_box:addvbox().
  local g_landlatlng_lat is g_landlatlng_latbox:addtextfield("0").
  set g_landlatlng_lat:style:width to 70.
  g_landlatlng_latbox:addlabel("Lat").
  local g_landlatlng_lngbox is g_landlatlng_box:addvbox().
  local g_landlatlng_lng is g_landlatlng_lngbox:addtextfield("0").
  set g_landlatlng_lng:style:width to 70.
  g_landlatlng_lngbox:addlabel("Lng").
  local g_landlatlng_headbox is g_landlatlng_box:addvbox().
  local g_landlatlng_hdg is g_landlatlng_headbox:addtextfield("0").
  set g_landlatlng_hdg:style:width to 30.
  g_landlatlng_headbox:addlabel("Head").
  local g_landlatlng_spdbox is g_landlatlng_box:addvbox().
  local g_landlatlng_spd is g_landlatlng_spdbox:addtextfield("70").
  set g_landlatlng_spd:style:width to 30.
  g_landlatlng_spdbox:addlabel("Spd").
  local g_landlatlng_altbox is g_landlatlng_box:addvbox().
  local g_landlatlng_alt is g_landlatlng_altbox:addtextfield("10").
  set g_landlatlng_alt:style:width to 30.
  g_landlatlng_altbox:addlabel("gearAlt").
  local g_landlatlng_add to g_landlatlng_box:addbutton("Add").
  set g_landlatlng_add:onclick to landlatlng_clicked@.
 
  g_course:addspacing(4).

  // --------- Add Arbitary LAT/LNG -------------
  local g_latlng_box_title is g_course:addlabel("<b>LAT/LNG</b>").
  set g_latlng_box_title:style:align to "CENTER".
  local g_latlng_box is g_course:addvbox().
  local g_latlng_box_name_box is g_latlng_box:addhbox().
  g_latlng_box_name_box:addlabel("Give it a name").
  local g_latlng_box_name_field is g_latlng_box_name_box:addTextField("NAV POINT").
  local g_latlng_box_hor is g_latlng_box:addhbox().
  local g_latlng_box_latlng_box is g_latlng_box_hor:addvbox().
  local g_latlng_box_lat_box is g_latlng_box_latlng_box:addhbox().
  g_latlng_box_lat_box:addlabel("LAT").
  local g_latlng_box_lat is g_latlng_box_lat_box:addtextfield("0").
  set g_latlng_box_lat:style:width to 70.
  local g_latlng_box_lng_box is g_latlng_box_latlng_box:addhbox().
  g_latlng_box_lng_box:addlabel("LNG").
  local g_latlng_box_lng is g_latlng_box_lng_box:addtextfield("0").
  set g_latlng_box_lng:style:width to 70.
  local g_latlng_box_alt_box is g_latlng_box_hor:addvbox().
  local g_latlng_box_alt_box1 is g_latlng_box_alt_box:addhbox().
  g_latlng_box_alt_box1:addlabel("ALT").
  local g_latlng_box_alt is g_latlng_box_alt_box1:addtextfield("0").
  set g_latlng_box_alt:style:width to 70.
  local g_latlng_box_agl_box is g_latlng_box_alt_box:addhbox().
  local g_latlng_box_agl is g_latlng_box_agl_box:addradiobutton("AGL",false).
  set g_latlng_box_agl:style:fontsize to 10.
  local g_latlng_box_asl is g_latlng_box_agl_box:addradiobutton("ASL",true).
  set g_latlng_box_asl:style:fontsize to 10.
  local g_latlng_box_spd_box is g_latlng_box_hor:addvbox().
  g_latlng_box_spd_box:addlabel("SPD m/s").
  local g_latlng_box_spd is g_latlng_box_spd_box:addtextfield("120").
  set g_latlng_box_spd:style:width to 50.
  local g_latlng_box_radius_box is g_latlng_box_hor:addvbox().
  g_latlng_box_radius_box:addlabel("Radius (m)").
  local g_latlng_box_radius is g_latlng_box_radius_box:addtextfield("10000").
  set g_latlng_box_radius:style:width to 60.

  local g_latlng_box_buttons is g_latlng_box:addhbox().
  local g_latlng_box_here_button is g_latlng_box_buttons:addbutton("Set to 'here'").
  set g_latlng_box_here_button:onclick to latlng_here_clicked@.
  local g_latlng_box_waypoint_pick is g_latlng_box_buttons:addpopupmenu().
  set g_latlng_box_waypoint_pick:style:width to 200.
  g_latlng_box_waypoint_pick:addoption("-- Copy a Waypoint").
  for w_point in get_unique_waypoints() {
    if w_point:body = ship:body {
      g_latlng_box_waypoint_pick:addoption(w_point:name).
    }
  }
  set g_latlng_box_waypoint_pick:onchange to latlng_waypoint_picked@.
  local g_latlng_box_add_button is g_latlng_box_buttons:addbutton("Add this").
  set g_latlng_box_add_button:onclick to latlng_add_clicked@.

  g_course:addspacing(4).

  // ----- Draw the list of navpoints ------
  set g_course_list_label to g_course:addlabel("<b>Course List</b>").
  set g_course_list_label:style:align to "CENTER".
  set g_course_buttons to remake_course_box(g_course, course_index).

  if course_update_del:isType("Delegate")
    course_update_del:CALL(course_index, course).
  g_course:show().
  return course.

  function onclick_insert_landing {
    local i is landing_list:index. // which runway.
    local j is mod(landing_list:index,2). // which direction (0 = normal, 1 = reversed).

    local r_name_raw is landing_list:options[i].
    local paren is r_name_raw:indexof("(").
    local r_name_cooked is r_name_raw:substring(0,paren).
    local rway_name is r_name_cooked.
    local reverse is (j = 1).
    local spd is g_land_spd:text:tonumber(70).
    local alti is g_land_alt:text:tonumber(10).
    insert_into_course(make_landing_points(rway_name, reverse, spd, alti)).
    set done to true.
  }

  function remake_course_box {
    parameter parent_box, currentNum.

    if g_course_box:istype("WIDGET")
      g_course_box:dispose().
    set g_course_box to parent_box:addvbox().
    local return_val is list().

    for i in range(course:length-1,-1) {
      set g_course_row to g_course_box:addhbox().

      local remove_item_button is g_course_row:addbutton("x").
      set remove_item_button:style:width to 10.
      set remove_item_button:onclick to remove_course_list_button@:BIND(i).

      local is_on is false.
      if i = course_index {
        set is_on to true.
      }
      local item_txt is course[i]["NAME"].
      if course[i]["AGL"] {
        set item_txt to item_txt + " (AGL " + round(course[i]["ALT"]) + "m, ".
      } else {
        set item_txt to item_txt + " (ASL " + round(course[i]["ALT"]) + "m, ".
      }
      set item_txt to item_txt + "SPD "+ round(course[i]["SPD"]) +"m/s".
      set item_txt to item_txt + "RAD "+ round(course[i]["RADIUS"]) +"m".
      local list_item is g_course_row:addradiobutton(item_txt, is_on).
      set list_item:ONTOGGLE to toggle_course_list_button@:BIND(i).
      set list_item:style:margin:V to 0.
      set list_item:style:padding:V to 1.
      set list_item:style:fontsize to 12.
      return_val:add(list_item).

    }
    set g_course_box:ONRADIOCHANGE to list_changed@.

    return return_val.
  }

  function toggle_course_list_button {
    parameter idx, pressed.

    if not(pressed)
      return.

    set course_index to idx.
    list_changed().
  }

  function remove_course_list_button {
    parameter idx.

    course:remove(idx).
    if course_index > course:length-1 or course_index > idx
      set course_index to course:length-1.
    list_changed().
  }

  function list_changed {
    parameter newVal is "". // ignored

    set g_course_buttons to remake_course_box(g_course, course_index).
    if course_update_del:isType("Delegate")
      course_update_del:CALL(course_index, course).
  }

  function insert_into_course {
    parameter newThings.

    for i in range(newThings:length-1, -1) {
      course:insert(0, newThings[i]).
    }
    list_changed().
    gui_update_course_index(course_index + newThings:length).
  }

  function landlatlng_clicked {
    local near_geo is latlng( 
      g_landlatlng_lat:text:tonumber(0),
      g_landlatlng_lng:text:tonumber(0)
      ).
    local hdg is g_landlatlng_hdg:text:tonumber(0).
    local spd is g_landlatlng_spd:text:tonumber(0).
    local alti is g_landlatlng_alt:text:tonumber(10).
    
    local runway_length is 2000.
    local meters_per_deg is ship:body:radius*2*constant():pi / 360.
    local north_deg is cos(hdg) * runway_length / meters_per_deg.
    local east_deg is sin(hdg) * runway_length / meters_per_deg.
    local far_geo is latlng(near_geo:lat + north_deg, near_geo:lng + east_deg).
    set known_runways["ad-hoc-land"] to LIST(
      LEXICON (
        "BODYNAME", ship:body:name,
        "LAT", near_geo:lat,
        "LNG", near_geo:lng,
        "ALT", 0,
        "AGL", True,
        "SPD", 0 ),
      LEXICON (
        "BODYNAME", ship:body:name,
        "LAT", far_geo:lat,
        "LNG", far_geo:lng,
        "ALT", 0,
        "AGL", True,
        "SPD", 0 )
    ).
    insert_into_course(make_landing_points("ad-hoc-land", false, spd, alti)).
  }

  function latlng_waypoint_picked {
    parameter pickedName.

    if not(pickedName:startswith("--")) {
      local wpoint is waypoint(pickedName).
      set g_latlng_box_name_field:TEXT to wpoint:name.
      set g_latlng_box_lat:TEXT to round(wpoint:geoposition:lat,6):tostring().
      set g_latlng_box_lng:TEXT to round(wpoint:geoposition:lng,6):tostring().
      set g_latlng_box_alt:TEXT to round(wpoint:agl,0):tostring().
      set g_latlng_box_agl:pressed to true.
      set g_latlng_box_waypoint_pick:index to 0.
    }
  }

  function latlng_here_clicked {
    
    set g_latlng_box_lat:TEXT to round(ship:latitude,6):tostring().
    set g_latlng_box_lng:TEXT to round(ship:longitude,6):tostring().
    set g_latlng_box_alt:TEXT to round(ship:altitude,1):tostring().
    set g_latlng_box_asl:pressed to true.
    set g_latlng_box_spd:TEXT to round(ship:velocity:surface:mag,1):tostring().
    set g_latlng_box_radius:TEXT to 10000:tostring().
  }

  function latlng_add_clicked {
    
    local latlng_lat is g_latlng_box_lat:TEXT:TONUMBER(0).
    local latlng_lng is g_latlng_box_lng:TEXT:TONUMBER(0).

    local latlng_point is Lexicon (
      "NAME", g_latlng_box_name_field:TEXT,
      "GEO", LATLNG(latlng_lat, latlng_lng),
      "ALT", g_latlng_box_alt:TEXT:TONUMBER(5000),
      "AGL", g_latlng_box_agl:PRESSED,
      "SPD", g_latlng_box_spd:TEXT:TONUMBER(200),
      "RADIUS", g_latlng_box_radius:TEXT:TONUMBER(10000)
    ).

    insert_into_course(list(latlng_point)).
  }

  // Deal with the fact that the stock game makes duplicate waypoints,
  // by first putting them into a uniqueset list:
  function get_unique_waypoints {
    local r_val is uniqueset().
    for wp in allwaypoints() {
      r_val:add(wp).
    }
    return r_val.
  }

}

function gui_close_edit_course {
  if g_course:istype("WIDGET")
    g_course:dispose().
}

function geo_from_lex {
  parameter the_lex.
  
  local bod is Body(the_lex["BODYNAME"]).
  return bod:GEOPOSITIONLATLNG(the_lex["LAT"], the_lex["LNG"]).
}

function asl_from_agl {
  parameter geo, agl.
  local a is agl + geo:terrainheight.
  if a < 0 and geo:body:hasocean {
     set a to 0.
  }
  return a.
}

// Return a list of navpoints for aircraft landing between two flags marking a runway:
function make_landing_points {
  parameter which_runway, reverse, spd, landed_alt is 10.

  local near_geo is geo_from_lex(known_runways[which_runway][0]).
  local far_geo is geo_from_lex(known_runways[which_runway][1]).
  if reverse {
    local tmp is near_geo.
    set near_geo to far_geo.
    set far_geo to tmp.
  }

  function runway_vect {
    return (far_geo:position - near_geo:position):normalized.
  }

  local halfway_point to (far_geo:position + near_geo:position) / 2.
  // Altitude of runway at the starting touchdown:
  local runway_alt is asl_from_agl(near_geo,0).

  // Make a list of aiming navpoints:
  local result is list().
  local i is 0.
  local expon is 0.

  // Seed runway waypoints at end of runway, 20 of way down, and at near end:
  result:add(
    lexicon( // far end of runway
      "NAME", which_runway + " Far end",
      "GEO", far_geo,
      "ALT", 0,
      "AGL", True,
      "SPD", 0,
      "RADIUS", 0 // Lastmost landing point should never be satisfied so it won't move to the next (not existing) point.
    )
  ).
  result:add(
    lexicon( // 50% of way down runway
      "NAME", which_runway + " Midpoint",
      "GEO", ship:body:geopositionof(halfway_point),
      "ALT", 0,
      "AGL", True,
      "SPD", spd*0.8,
      "RADIUS", 100
    )
  ).
  result:add(
    lexicon( // near end of runway
      "NAME", which_runway + " Near end",
      "GEO", near_geo,
      "ALT", landed_alt,
      "AGL", True,
      "SPD", spd,
      "RADIUS", 200
    )
  ).
  // seed more waypoints on the way down:
  until i >= 4 {
    local aim_alt is runway_alt+result[2]["ALT"]+4+expon*150.
    local aim_pos is near_geo:altitudeposition(aim_alt) - (50 + 1500*expon)*runway_vect().
    local aim_geo is ship:body:geopositionof(aim_pos).
    local aim_spd is 0. // to be overridden below.
    if i = 0 { 
      set aim_spd to spd*1.1.
    } else if i = 1{
      set aim_spd to spd*1.2.
    } else {
      set aim_spd to spd*1.5.
    }
    result:add( lexicon( 
        "NAME", which_runway + " Approach " + i,
        "GEO", aim_geo,
        "ALT", aim_alt,
        "AGL", False,
        "SPD", aim_spd,
        "RADIUS", (i+1)*250
      )
    ).

    set i to i+1.
    set expon to 2.3^i.
  }

  return result.
}
