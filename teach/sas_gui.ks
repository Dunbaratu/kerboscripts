print "TEST CALL OF THE FUNCTION.".
global calc_gui is 0.  // giving it a dummy value for now.


local results is dv_orb_trans_calc_gui(ship:body, 150000, 200000).

if results:LENGTH > 0 {
   print "RESULTS:".
   print "Burn 1: " + results["BURN1"] + " m/s".
   print "Burn 2: " + results["BURN2"] + " m/s".
   print "TOTAL: " + results["TOTAL"] + " m/s".
}


function dv_orb_trans_calc_gui {
  parameter the_body, alt_low, alt_high.

  local ok is false.
  local cancel is false.
  
  set calc_gui to GUI(300).
  calc_gui:addlabel("<b>ORBIT TRANSFER</b>").
  calc_gui:addlabel("<b>DV CALCULATOR</b>").

  local planet_box is calc_gui:addhbox.
  planet_box:addlabel("PLANET/MOON").
  local planet_field is planet_box:addpopupmenu().
  populate_planets(planet_field).
  // set currnet index position to the position of the passed-in body:
  set planet_field:index to planet_field:options:find(the_body:name).
  set planet_field:onchange to planet_field_changed@.

  local alt_low_box is calc_gui:addhbox.
  alt_low_box:addlabel("LOW ALT").
  local alt_low_field is alt_low_box:addtextfield(alt_low:tostring).
  set alt_low_field:onconfirm to confirm_alt_low_field@.

  local alt_high_box is calc_gui:addhbox.
  alt_high_box:addlabel("HIGH ALT").
  local alt_high_field is alt_high_box:addtextfield(alt_high:tostring).
  set alt_high_field:onconfirm to confirm_alt_high_field@.

  local result_box is calc_gui:addvbox.
  local result_burn1_box is result_box:addhbox.
  local result_burn1_label1 is result_burn1_box:addlabel("BURN 1").
  local result_burn1_field is result_burn1_box:addlabel("--").
  set result_burn1_field:style:align to "RIGHT".
  set result_burn1_field:style:font to "COURIER NEW".
  local result_burn2_box is result_box:addhbox.
  local result_burn2_label1 is result_burn2_box:addlabel("BURN 2").
  local result_burn2_field is result_burn2_box:addlabel("--").
  set result_burn2_field:style:align to "RIGHT".
  set result_burn2_field:style:font to "COURIER NEW".
  local result_total_box is result_box:addhbox.
  local result_burn2_label1 is result_total_box:addlabel("TOTAL").
  local result_total_field is result_total_box:addlabel("--").
  set result_total_field:style:align to "RIGHT".
  set result_total_field:style:font to "COURIER NEW".
  local recalc_button is result_box:addbutton("RECALCULATE").
  set recalc_button:onclick to recalc@.

  local close_box is calc_gui:addhbox.
  // Right now cancel and OK do the same thing:
  set cancel_button to close_box:addbutton("CANCEL").
  set cancel_button:onclick to {set cancel to true.}.
  set ok_button to close_box:addbutton("OK").
  set ok_button:onclick to {set ok to true.}.

  // Make sure initial values at first are shown right:
  recalc().

  calc_gui:show().
  wait until ok or cancel.
  calc_gui:dispose().

  if ok {
    return dV_orb_trans_calc(the_body, alt_low, alt_high).
  } else {
    return LEX(). // empty results.
  }

  function populate_planets {
    parameter field.

    // build the list of planets:
    local bods is LIST().
    LIST BODIES in bods.
    set field:options to LIST().
    for bod in bods {
      field:options:add(bod:name).
    }
  }

  function planet_field_changed {
    parameter str_value.

    set the_body to body(str_value).
  }


  function confirm_alt_low_field {
    parameter alt_string.

    set new_val to alt_string:tonumber(-9999).
    if new_val = -9999 { // bad value - reset to what it used to be:
       set alt_low_field:text to alt_low:tostring().
    } else { // good value, accept it:
       set alt_low to new_val.
    }
  }

  function confirm_alt_high_field {
    parameter alt_string.

    set new_val to alt_string:tonumber(-9999).
    if new_val = -9999 { // bad value - reset to what it used to be:
       set alt_high_field:text to alt_high:tostring().
    } else { // good value, accept it:
       set alt_high to new_val.
    }
  }

  function recalc {
    local result is dV_orb_trans_calc(the_body, alt_low, alt_high).

    set result_burn1_field:TEXT to round(result["BURN1"],1):tostring() + " m/s".
    set result_burn2_field:TEXT to round(result["BURN2"],1):tostring() + " m/s".
    set result_total_field:TEXT to round(result["TOTAL"],1):tostring() + " m/s".
  }
}


// This function returns a LEXICON with these things in it:
// return_val["BURN1"]
// return_val["BURN2"]
// return_val["TOTAL"]
function dV_orb_trans_calc {

  parameter PLANET, alt_low, alt_high.

  clearscreen. print "DELTA V ORBIT TRANSFER CALCULATOR".
  "=============================================".

  Print " ".
  Print " ".

  set Mu to PLANET:MU.
  set rad to PLANET:RADIUS.
  global _alt1 is alt_low*1000+rad. 
  global _alt2 is alt_high*1000+rad. 

  // remove later? print "altitude low = " + round(_alt1,0) + " m".
  // remove later? print "altitude high = " + _alt2 + " m".
  // remove later? Print " ".
  // remove later? print "Mu = " + Mu.

  // BURN 1
  set burn1 to SQRT(Mu/_alt1)*(SQRT(2*_alt2/(_alt1+_alt2))-1).

  //BURN 2
  set burn2 to SQRT(Mu/_alt2)*(1-SQRT(2*_alt1/(_alt1+_alt2))).

  // remove later? Print " ".
  // remove later? Print "BURN 1 = " + round(burn1) + " m/s" + " | BURN 2 = " + round(burn2) + " m/s".
  // remove later? Print " ".
  local result is burn1+burn2.
  // remove later? print "TOTAL DV = " + round(result) + " m/s".
  // remove later? Print " ".
  // remove later? Print " ".
  // remove later? Print " ".

  return LEX("BURN1", burn1, "BURN2", burn2, "TOTAL", result).
}
