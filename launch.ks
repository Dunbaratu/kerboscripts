run once "lib/launch".
parameter
  compass is 90,
  end_alt is 80000,
  count is 5,
  launch_twr is 1.2,
  eta_apo is 120,
  eta_apo_spd is 1700,
  steering_ts is 2,
  solid_thrust is 0,
  second_height is -1,
  second_height_long is -1,
  atmo_end is ship:body:atm:height,
  goto_bod is "",
  bod_pe is -1,
  ignitions is 2,
  afterlaunch is "".

if launch_gui() {

  if second_height = "same"
    set second_height to -1.

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
    atmo_end,
    goto_bod,
    bod_pe,
    ignitions).

  set steeringmanager:pitchts to old_pitch_ts.
  set steeringmanager:yawts to old_yaw_ts.
  set steeringmanager:rollts to old_roll_ts.

} else {
  print "LAUNCH SCRUBBED".
  set global_scrubbed to true.
}

if not(global_scrubbed) {
  if afterlaunch <> "" {
    PRINT "TRYING TO COPY "+CHAR(34)+afterlaunch+CHAR(34)+" FROM ARCHIVE TO LOCAL.".
    copypath("0:"+afterlaunch, "1:"+afterlaunch).
    PRINT "SETTING BOOTFILE TO " + afterlaunch.
    set core:bootfilename to afterlaunch.
    wait 1.
    PRINT "REBOOTING.".
    reboot.
  }
}

function launch_gui {
  local exit_val is -1.

  if second_height < 0 
    set second_height to "same".

  local setting_ui is GUI(400).
  set setting_ui:addlabel("  <b>== SCRIPT LAUNCH OPTIONS ==</b>"):style:fontsize to 18.
  set setting_ui:addlabel("  (" + ship:name + ", " + core:tag + ")"):style:fontsize to 18.
  setting_ui:addspacing(5).

  local ignitions_box is setting_ui:addvlayout().
  set ignitions_box:style:hstretch to false.
  ignitions_box:addlabel("Circularization ignitions allowed:").
  ignitions_box:addlabel(" 1 = continuous burn, don't care if circular.").
  ignitions_box:addlabel(" 2 = coast to AP and burn again (try to be circular).").
  local ignitions_radio_box is ignitions_box:addhlayout().
  local one_ignition_button is ignitions_radio_box:addradiobutton("One", false).
  local two_ignition_button is ignitions_radio_box:addradiobutton("Two", true).
  
  local afterlaunch_box is setting_ui:addhlayout().
  set afterlaunch_box:style:hstretch to false.
  set afterlaunch_box_label to afterlaunch_box:addlabel("After Launching, run ").
  set afterlaunch_box_label:style:align to "right".
  local afterlaunch_menu is afterlaunch_box:addpopupmenu().
  set afterlaunch_menu:options to LIST("nothing", "obey nodes", "rendezvous").
  set afterlaunch_menu:index to 0.
  set afterlaunch_menu:onchange to {
    parameter choice. 
    if choice = "obey nodes" {
      set afterlaunch to "/boot/obey_nodes.ks".
    } else if choice = "rendezvous" {
      set afterlaunch to "/boot/rendezvous.ks".
    } else {
      set afterlaunch to "".
    }
  }.  
  
  local end_alt_box is setting_ui:addhlayout().
  end_alt_box:addlabel("End When Periapais Alt >=").
  local end_alt_field is end_alt_box:addtextfield(end_alt:tostring()).
  set end_alt_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set end_alt_field:text to end_alt_field:text:tonumber(end_alt):tostring().
    set end_alt to end_alt_field:text:tonumber().
  }.

  end_alt_box:addlabel("And AP >=").
  local end_ap_field is end_alt_box:addtextfield(second_height:tostring()).
  set end_ap_field:onconfirm to {
    parameter str.
    if str = "same" or str:tonumber(-1) < 0 {
      set second_height to "same".
      return.
    }
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    local default is second_height:tonumber(-1).
    set end_ap_field:text to end_ap_field:text:tonumber(default):tostring().
    set second_height to end_ap_field:text:tonumber().
  }.

  local bod_box is setting_ui:addhlayout().
  bod_box:addlabel("Encounter body:").
  local goto_bod_field is bod_box:addtextfield(goto_bod:tostring()).
  set goto_bod_field:onconfirm to {
    parameter str.
    set goto_bod to str.
  }.
  bod_box:addlabel("at Pe:").
  local bod_pe_field is bod_box:addtextfield(bod_pe:tostring()).
  set bod_pe_field:onconfirm to {
    parameter str.
    set bod_pe to str:tonumber(-1).
    set bod_pe_field:text to bod_pe:tostring().
  }.

  local compass_box is setting_ui:addhlayout().
  compass_box:addlabel("Initial Compass: ").
  local compass_field is compass_box:addtextfield(compass:tostring()).
  set compass_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set compass_field:text to compass_field:text:tonumber(compass):tostring().
    set compass to compass_field:text:tonumber().
  }.

  local eta_apo_box is setting_ui:addhlayout().
  eta_apo_box:addlabel("Seek ETA:Apoapsis (secs): ").
  local eta_apo_field is eta_apo_box:addtextfield(eta_apo:tostring()).
  set eta_apo_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set eta_apo_field:text to eta_apo_field:text:tonumber(eta_apo):tostring().
    set eta_apo to eta_apo_field:text:tonumber().
  }.

  eta_apo_box:addlabel(" by speed (m/s): ").
  local eta_apo_spd_field is eta_apo_box:addtextfield(eta_apo_spd:tostring()).
  set eta_apo_spd_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set eta_apo_spd_field:text to eta_apo_spd_field:text:tonumber(eta_apo_spd):tostring().
    set eta_apo_spd to eta_apo_spd_field:text:tonumber().
  }.

  local twr_box is setting_ui:addhlayout().
  twr_box:addlabel("TWR before de-clamping?").
  local twr_field is twr_box:addtextfield(launch_twr:tostring()).
  set twr_field:onconfirm to {
    parameter str.
    // Set to a number then back to a string, to wipe any non-numeric stuff:
    set twr_field:text to twr_field:text:tonumber(launch_twr):tostring().
    set launch_twr to twr_field:text:tonumber().
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
    set solids_field:text to solids_field:text:tonumber(solid_thrust):tostring().
    set solid_thrust to solids_field:text:tonumber().
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
  if one_ignition_button:pressed { set ignitions to 1. }
  if two_ignition_button:pressed { set ignitions to 2. }
  set end_alt to end_alt_field:text:tonumber().
  set compass to compass_field:text:tonumber().
  set eta_apo to eta_apo_field:text:tonumber().
  set eta_apo_spd to eta_apo_spd_field:text:tonumber().
  set launch_twr to twr_field:text:tonumber().
  set solid_thrust to solids_field:text:tonumber().
  set steering_ts to ts_field:value.
  return exit_val.
}
