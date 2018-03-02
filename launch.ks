run once "lib/launch".
parameter
  compass is 90,
  end_alt is 80000,
  count is 5,
  launch_twr is 1.2,
  eta_apo is 120,
  eta_apo_spd is 1500,
  steering_ts is 2,
  solid_thrust is 0,
  second_height is -1,
  second_height_long is -1,
  atmo_end is 70000.

if launch_gui() {

  until count = 0 {
    hudtext("T minus " + count + "s", 2, 2, 45, yellow, true).
    wait 1.
    set count to count - 1.
  }.
  hudtext("Launch!", 2, 2, 50, yellow, true).
  set ship:control:pilotmainthrottle to 0.

  print "Adjusting steering TS's to " + steering_ts+ " for launch.".
  local old_pitch_ts is steeringmanager:pitchts.
  local old_yaw_ts is steeringmanager:yawts.
  local old_roll_ts is steeringmanager:rollts.
  set steeringmanager:pitchts to steering_ts.
  set steeringmanager:yawts to steering_ts.
  set steeringmanager:rollts to steering_ts.

  launch(
    compass,
    end_alt,
    true,
    eta_apo,
    eta_apo_spd,
    launch_twr,
    solid_thrust,
    second_height,
    second_height_long,
    atmo_end).

  set steeringmanager:pitchts to old_pitch_ts.
  set steeringmanager:yawts to old_yaw_ts.
  set steeringmanager:rollts to old_roll_ts.

} else {
  print "LAUNCH SCRUBBED".
}

function launch_gui {
  local exit_val is -1.

  local setting_ui is GUI(400).
  setting_ui:addlabel("== LAUNCH OPTIONS ==").
  setting_ui:addspacing(5).

  local end_alt_box is setting_ui:addhlayout().
  end_alt_box:addlabel("End When Periapais Alt is:").
  local end_alt_field is end_alt_box:addtextfield(end_alt:tostring()).
  set end_alt_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set end_alt_field:text to end_alt_field:text:tonumber():tostring().
  }.

  local compass_box is setting_ui:addhlayout().
  compass_box:addlabel("Initial Compass: ").
  local compass_field is compass_box:addtextfield(compass:tostring()).
  set compass_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set compass_field:text to compass_field:text:tonumber():tostring().
  }.

  local eta_apo_box is setting_ui:addhlayout().
  eta_apo_box:addlabel("Seek ETA:Apoapsis (secs): ").
  local eta_apo_field is eta_apo_box:addtextfield(eta_apo:tostring()).
  set eta_apo_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set eta_apo_field:text to eta_apo_field:text:tonumber():tostring().

  }.

  eta_apo_box:addlabel(" by speed (m/s): ").
  local eta_apo_spd_field is eta_apo_box:addtextfield(eta_apo_spd:tostring()).
  set eta_apo_spd_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set eta_apo_spd_field:text to eta_apo_spd_field:text:tonumber():tostring().
  }.

  local twr_box is setting_ui:addhlayout().
  twr_box:addlabel("TWR before de-clamping?").
  local twr_field is twr_box:addtextfield(launch_twr:tostring()).
  set twr_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set twr_field:text to twr_field:text:tonumber():tostring().
  }.

  local solids_box is setting_ui:addhlayout().
  solids_box:addlabel(
    "Solid Booster Thrust? (For launch TWR calculation " +
    "because solids' thrust cannot be queried.)" ).
  local solids_field is solids_box:addtextfield(solid_thrust:tostring()).
  set solids_field:style:width to 100.
  set solids_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set solids_field:text to solids_field:text:tonumber():tostring().
  }.

  local ts_box is setting_ui:addhlayout().
  ts_box:addlabel( "SteeringManager TS adjust: (higher for heavier rockets):").
  local ts_field is ts_box:addhslider(2, 0.25, 5).
  set ts_field:style:width to 100.
  local ts_show is ts_box:addlabel(ts_field:value:tostring()).
  set ts_show:style:width to 40.
  set ts_field:onchange to {
    parameter val.
    set ts_show:text to round(val,2):tostring().
  }.

  local leave_box is setting_ui:addhbox().
  local cancel_button is leave_box:addbutton("Cancel").
  set cancel_button:onclick to {
    setting_ui:hide().
    set exit_val to false.
  }.
  local launch_button is leave_box:addbutton("Launch").
  set launch_button:onclick to {
    setting_ui:hide().
    set exit_val to true.
  }.

  setting_ui:show().
  wait until exit_val:istype("Boolean"). // will not return until a cancel or launch is clicked.
  set end_alt to end_alt_field:text:tonumber().
  set compass to compass_field:text:tonumber().
  set eta_apo to eta_apo_field:text:tonumber().
  set eta_apo_spd to eta_apo_spd_field:text:tonumber().
  set launch_twr to twr_field:text:tonumber().
  set solid_thrust to solids_field:text:tonumber().
  set steering_ts to ts_field:value.
  return exit_val.
}
