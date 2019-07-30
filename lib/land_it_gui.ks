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
  parameter init_margin, init_ullage, init_spool, init_minthrot, init_predict.

  local window is GUI(400).
  set land_it_gui["GUI"] to window.

  window:addlabel("LANDING PROGRAM SETUP").

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
    "(Legal values from 0.00 to 1.00) (For Realism Overhaul) " +
    "Minimum actual throttle between 0 and 1, of the landing engine. " +
    "(i.e. if the throttle is <b>really</b> at 75% when the indicator is at " +
    "minimum, then put 0.75 here.)".
  local min_throt is throt_box:addtextfield(init_minthrot:tostring()).
  set min_throt:style:width to 50.
  set min_throt:onconfirm to range_enforce_onconfirm@:BIND( min_throt, 0, 1 ).
  set land_it_gui["MINTHROT"] to min_throt.

  set throt_box:addlabel("Predict Landing Throttle:"):tooltip to
    "(Legal values from 0.00 to 1.00) Calculate the suicide burn to use " +
    "this much throttle. " +
    "Should be very high, but not quite 1.0, as that would leave no " +
    "room to adjust for varying conditions on the fly.".
  local predict_throt is throt_box:addtextfield(init_predict:tostring()).
  set predict_throt:style:width to 50.
  set predict_throt:onconfirm to range_enforce_onconfirm@:BIND( predict_throt, 0, 1 ).
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

  local commit is contents:addbutton("Commit (no takebacks)").
  set commit:tooltip to 
    "Lock in these values and begin the landing script. " +
    "NOTE: The vessel needs to have a sub-orbital path already " +
    "when you start this.  It does not de-orbit burn for you.".
  set land_it_gui["COMMIT"] to commit.
  set land_it_gui["COMMIT"]:toggle to true.

  local tip is window:addtipdisplay().

  if show_now
    window:show().
  return land_it_gui.
}

// Call repeatedly, passsing it information to display.
function update_land_it_gui {
}

function end_land_it_gui {
  land_it_gui["GUI"]:dispose().
}

function range_enforce_onconfirm {
  parameter field, min_val, max_val, value.

  local num is value:toscalar.
  set num to min( max_val, max( min_val, num)). // clamp [0..1].
  set field:text to num:tostring().
}
