// The gui panel that goes with the land_it scripts
// ------------------------------------------------

run once "lib/land.ks".

// ---
// --- MAIN 
// ---
local land_it_gui is LEX().

// ---
// --- END OF MAIN
// ---

function create_land_it_gui {
  parameter show_now.
  parameter quit_delegate.
  parameter init_margin, init_ullage, init_spool, init_minthrot, init_predict, land_spot, skycrane.

  local window is GUI(400).
  set land_it_gui["GUI"] to window.

  set window:addlabel("<b>LANDING PROGRAM SETUP</b>"):style:align to "CENTER".

  local contents is window:ADDVBOX().

  local engine_outer_box is contents:addvbox().
  engine_outer_box:addlabel("ENGINE VALUES").
  local engine_box is engine_outer_box:addhbox().

  set engine_box:addlabel("Ullage:"):tooltip to
    "(Legal values from 0 to 10) Predict how many seconds at start of suicide burn will " +
    "have to be spent on RCS ullage push before ignition allowed.".
  local ullage is engine_box:addtextfield(init_ullage:tostring()).
  set ullage:style:width to 50.
  set ullage:onconfirm to range_enforce_onconfirm@:BIND( ullage, 0, 10 ).
  set land_it_gui["ULLAGE"] to ullage.

  set engine_box:addlabel("Spool:"):tooltip to
    "(Legal values from 0 to 10) Predict how many seconds of spool-up-time between " +
    "ignition of engine and maxthrust.".
  local spool is engine_box:addtextfield(init_spool:tostring()).
  set spool:style:width to 50.
  set spool:onconfirm to range_enforce_onconfirm@:BIND( spool, 0, 10 ).
  set land_it_gui["SPOOL"] to spool.

  local throt_outer_box is contents:addvbox().
  throt_outer_box:addlabel("THROTTLE VALUES").
  local throt_box is throt_outer_box:addhbox().

  set throt_box:addlabel("Min Throttle:"):tooltip to
    "(Legal values from 0.00 to 1.00) (Only meaningful with RealFuels mod) " +
    "Minimum actual throttle between 0 and 1, of the landing engine. " +
    "(i.e. if the throttle is <b>really</b> at 75% when the indicator is at " +
    "minimum, then put 0.75 here.)".
  local min_throt is throt_box:addtextfield(init_minthrot:tostring()).
  set min_throt:style:width to 50.
  set min_throt:onconfirm to range_enforce_onconfirm@:BIND( min_throt, 0, 1 ).
  set land_it_gui["MINTHROT"] to min_throt.

  set throt_box:addlabel("Predict Landing Throttle:"):tooltip to
    "(Legal values from 0.00 to 1.00) Calculate the suicide burn as if the " +
    "real throttle is here. If you are playing with the RealFuels mod, " +
    "then this expressed in terms of the real throttle you end up with " +
    "after accounting for an engine's min throttle.  (i.e. if you say 0.8 here, it " +
    "means ACTUALLY 80% of max thrust, not 80% of the range between the min and max " +
    "throttle as it would mean if you put the throttle control lever at 80%.) " +
    "Because of this, it is an error to set this lower than the min thrust.".
    
  local predict_throt is throt_box:addtextfield(init_predict:tostring()).
  set predict_throt:style:width to 50.
  set predict_throt:onconfirm to
    range_enforce_onconfirm@:BIND( predict_throt, {return min_throt:text:tonumber(0).}, 1).
  set land_it_gui["PREDICTTHROT"] to predict_throt.

  local margin_outer_box is contents:addhbox().
  set margin_outer_box:addlabel("MARGIN: "):tooltip to
    "(Legal values from 0.0 to 500.0) Height that you want the vessel's root part " +
    "to be above the ground when burn is over and it falls.".
  local margin is margin_outer_box:addtextfield(init_margin:tostring()).
  set margin:style:width to 90.
  set margin:onconfirm to range_enforce_onconfirm@:BIND( margin, 0, 500 ).
  set land_it_gui["MARGIN"] to margin.
  if init_margin:istype("string") and init_margin = "FIND" {
    set margin:text to round(find_margin(), 2):tostring(). 
  }
  
  local margin_calc is margin_outer_box:addbutton("Calculate").
  set margin_calc:onclick to { set margin:text to round(find_margin(), 2):tostring(). }.
  set margin_calc:tooltip to
    "Populate margin field with min safe value calculated from bounding boxes.".

  local spot_outer_box is contents:addhbox().
  local spot_active is spot_outer_box:addcheckbox("Veer toward:", false).
  set spot_active:tooltip to
    "Try to deflect the landing toward this spot. " +
    "Only works well if you set predict throttle well less than 1.0 and " +
    "you get it deorbited roughly close to the right path to start.".
  set spot_active:pressed to not(land_spot:istype("Scalar")).
  set land_it_gui["GEO_ENABLED"] to spot_active.

  local spot_box is spot_outer_box:addvbox().
  local latlng_box is spot_box:addhbox().
  set latlng_box:addLabel("LAT"):style:align to "RIGHT".
  local lat_field is latlng_box:addtextfield("0").
  set land_it_gui["LAT"] to lat_field.
  set lat_field:style:width to 90.
  set latlng_box:addLabel("LNG"):style:align to "RIGHT".
  local lng_field is latlng_box:addtextfield("0").
  set lng_field:style:width to 90.
  set land_it_gui["LNG"] to lng_field.

  local pick_waypoint_box is spot_box:addhbox().
  set pick_waypoint_box:addlabel("Waypoint:"):style:hstretch to false.
  local pick_waypoint is pick_waypoint_box:addpopupmenu().
  set pick_waypoint:options to land_it_waypoint_names().
  set pick_waypoint:style:hstretch to true.
  set pick_waypoint:onchange to {
    parameter newVal.
    if newVal = "<none>" {
      set lat_field:text to "0".
      set lng_field:text to "0".
    } else {
      set lat_field:text to round(waypoint(newVal):geoposition:lat,6):tostring().
      set lng_field:text to round(waypoint(newVal):geoposition:lng,6):tostring().
    }
  }.
  set land_it_gui["WAYPOINT"] to pick_waypoint.

  local pick_vessel_box is spot_box:addhbox().
  set pick_vessel_box:addlabel("Vessel:"):style:hstretch to false.
  local pick_vessel is pick_vessel_box:addpopupmenu().
  set pick_vessel:options to land_it_vessel_names().
  set pick_vessel:style:hstretch to true.
  set pick_vessel:onchange to {
    parameter newVal.
    if newVal = "<none>" {
      set lat_field:text to "0".
      set lng_field:text to "0".
    } else {
      set lat_field:text to round(vessel(newVal):geoposition:lat,6):tostring().
      set lng_field:text to round(vessel(newVal):geoposition:lng,6):tostring().
    }
  }.
  set land_it_gui["VESSEL"] to pick_waypoint.

  // Populate the geo position fields based on this value passed in:
  if land_spot:istype("geoposition") {
    set lat_field:text to round(land_spot:lat,6):tostring().
    set lng_field:text to round(land_spot:lng,6):tostring().
  } else if land_spot:istype("waypoint") {
    for p in range(0,pick_waypoint:options:length) {
      if pick_waypoint:options[p] = land_spot:name {
        set pick_waypoint:index to p.
        break.
      }
    }
    pick_waypoint:onchange:call(land_spot:name).
  } else if land_spot:istype("vessel") {
    for p in range(0,pick_vessel:options:length) {
      if pick_vessel:options[p] = land_spot:name {
        set pick_vessel:index to p.
        break.
      }
    }
    pick_vessel:onchange:call(land_spot:name).
  }

  local buttonbox is contents:addhbox().

  local skycranebut is buttonbox:addcheckbox("Skycrane",skycrane).
  set skycranebut:tooltip to "Hit next-stage after landing to remove skycrane?".
  set land_it_gui["skycrane"] to skycranebut.

  local commit is buttonbox:addbutton("Commit (no takebacks)").
  set commit:tooltip to 
    "Lock in these values and begin the landing script. " +
    "NOTE: The vessel needs to have a sub-orbital path already " +
    "when you start this.  It does not de-orbit burn for you.".
  set land_it_gui["COMMIT"] to commit.
  set land_it_gui["COMMIT"]:toggle to true.

  add_info_panel(contents).

  local abort_button is contents:addbutton("<b><color=#623>END SCRIPT</color></b>").
  set abort_button:onclick to { window:dispose(). quit_delegate:call(). }.

  local tip is window:addtipdisplay().

  if show_now
    window:show().
  return land_it_gui.
}

// These will be the GUI labels to keep updating with new data.
local lever_value is 0.
local real_throt_value is 0.
local KP_value is 0.
local KI_value is 0.
local KD_value is 0.
local bias_value is 0.
local radar_alt_value is 0.
local stop_AGL_value is 0.
local predict_throt_value is 0.
local sim_timeslice_value is 0.

function add_info_panel {
  parameter parent_box.

  local info_panel_outer is parent_box:addhbox().
  local throt_outer_box is info_panel_outer:addvbox().
  set throt_outer_box:ADDLABEL("<b>Throttle info</b>"):style:align to "CENTER".
  local throt_inner_box is throt_outer_box:addhbox().

  local throt_labels is throt_inner_box:addvbox().

  set lever_value to throt_labels:addlabel("0").
  set real_throt_value to throt_labels:addlabel("0").
  set KP_value to throt_labels:addlabel("0").
  set KI_value to throt_labels:addlabel("0").
  set KD_value to throt_labels:addlabel("0").
  set bias_value to throt_labels:addlabel("0").


  local sim_outer_box is info_panel_outer:addvbox().
  set sim_outer_box:ADDLABEL("<b>Simulation</b>"):style:align to "CENTER".
  local sim_inner_box is sim_outer_box:addhbox().

  local sim_values is sim_inner_box:addvbox().
  set radar_alt_value to sim_values:addlabel("0").
  set stop_AGL_value to sim_values:addlabel("0").
  set predict_throt_value to sim_values:addlabel("0").
  set sim_timeslice_value to sim_values:addlabel("0").
}

// Call repeatedly, passsing it information to display.
function update_land_it_gui {
  parameter started, rthrot, throt_pid, bias, dist, margin, sthrot, timeslice.

  set lever_value:text to "Lever position: " +round(100*throttle,0):tostring() + "%".

  if not(started) {
    set real_throt_value:text to "Real Throttle: ZZZ".
  } else {
    set real_throt_value:text to "Real Throttle: " + round(100*rthrot,0):tostring() + "%".
  }

  set KP_value:text to "PID KP: " + round(throt_pid:Kp,8):tostring().
  set KI_value:text to "PID KI: " + round(throt_pid:Ki,8):tostring().
  set KD_value:text to "PID KD: " + round(throt_pid:Kd,8):tostring().
  set bias_value:text to "Bias: " + round(bias,5):tostring().

  set radar_alt_value:text to "Radar Alt: " + round(alt:radar,0):tostring() + " m".
  set stop_AGL_value:text to "Pred. Stop Alt: " + round(dist-margin,0):tostring() + " m".
  set predict_throt_value:text to "Pred. real th." + round(100*sthrot,0):tostring() + " %".
  set sim_timeslice_value:text to "sim timeslice " + round(timeslice,2):tostring() + " s".
}

function end_land_it_gui {
  land_it_gui["GUI"]:dispose().
}

function range_enforce_onconfirm {
  parameter field, min_val, max_val, value, places is 3.

  local num is value:toscalar.
  local low_val is choose min_val:call() if min_val:istype("UserDelegate") else min_val.
  local high_val is choose max_val:call() if max_val:istype("UserDelegate") else max_val.
  set num to min( high_val, max( low_val, num)). // clamp [0..1].
  set field:text to round(num, places):tostring().
}

// Generate a list of waypoints that are on the same body as I am orbiting now:
function land_it_waypoint_names {
  local ret_val is LIST("<none>").
  for wp in allwaypoints() {
    if wp:body = ship:body
      ret_val:add(wp:name).
  }
  return ret_val.
}

// Generate a list of vessels that are landed on the same body as I am orbiting now:
function land_it_vessel_names {
  local ret_val is LIST("<none>").
  local targs is LIST().
  LIST targets in targs.
  for tgt in targs {
    if tgt:body = ship:body and tgt:istype("Vessel")
      ret_val:add(tgt:name).
  }
  return ret_val.
}
