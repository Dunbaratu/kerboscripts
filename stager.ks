//KOS
// A function that will detect if there's a need to stage right now.
// Takes no arguments, but returns a boolean:
//
//   false = Staging did not occur.
//   true = Staged because of a flameout.
//
// Call repeatedly in a program's main loop as you are burning.
@LAZYGLOBAL OFF.
function stager {
  parameter stg_eList is 0.
  local did_stage is false.

  // simple dumb - check if nothing active,
  // then stage:
  if ship:maxthrust = 0 {
    stage.
    set did_stage to true.
  } else {
    if stg_eList:istype("scalar")
       list engines in stg_eList.
    for stg_eng in stg_eList { 
      if stg_eng:name <> "sepMotor1" and stg_eng:tag <> "flameout no stage" and stg_eng:flameout {
        stage.
        set did_stage to true.
        break.
      }.
    }.
  }
  return did_stage.
}.
