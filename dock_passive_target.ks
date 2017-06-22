run once "lib/dock".


CLEARSCREEN.

if not hastarget {
  PRINT "FIRST SELECT A REMOTE VESSEL or docking port AS YOUR TARGET.".
}

local tgt is target.

// If targeting a whole vessel, then target it's first part instead:
if tgt:ISTYPE("VESSEL") {
  set tgt to tgt:parts[0].
}

// If the part being targetted is a docking port, then lock to its port facing,
// else lock to it's part facing if it's any other kind of part:
if tgt:ISTYPE("DOCKINGPORT") {
  print "Target is a docking port.".
  lock steering to lookdirup(- tgt:portfacing:vector, tgt:portfacing:topvector).
} ielse {
  lock steering to tgt:facing.
}

local from_parts is ship:partstagged("from here").
if from_parts:length = 0 {
  print "NOW MAKE SURE YOUR FROM PART IS tagged 'from here'.".
  until from_parts:length > 0 {
     set from_parts to ship:partstagged("from here").
     wait 0.
  }
}

print "DOCKING SCRIPT COMMENCING".
do_dock(from_parts[0], tgt).


