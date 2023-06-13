clearscreen.
print "For a sounding rocket with hotstage for stage 2.".

set fuel_name to "IRFNA-III".

print "type a key". terminal:input:getchar().
print "GO!".
print " ".
set ship:control:pilotmainthrottle to 1.

wait until stage:ready.
stage. //start first stage engine.

wait until availablethrust / (mass*9.81) >0.6. //wait for TWR to rise

wait until stage:ready.
stage. //declamp.

local engs_first_stage is list().
list engines in engs.
for eng in engs {if eng:ignition engs_first_stage:add(eng). }

print "first stage engines are : ".
print  engs_first_stage.


local seconds_left is 999.
until seconds_left < 1 {
  set seconds_left to stage_seconds_left("IRFNA-III").
  print round(seconnds_left,1) + " seconds left in stage.   " at (3,20).
}
print "hot staging." at (30,20).
stage.
wait 0.5.

// now decouple after hotstage started.
wait until stage:ready.
print "shutting off first stage engines.".
for eng in engs_first_stage { eng:shutdown. }
print "decoupling hot stage.".
stage. //declamp.


print "now done.".

wait 999999.
local prev_fuel_ts is -1.
local prev_fuel_amount is 0.

// Return how many seconds are left in the current stage before fuel ends,
// guessing based on current fuel usage rate and fuel amount left.
function stage_seconds_left {
  parameter fuel_name.

  wait 0.

  local fuel_amount is stage:resourceslex(fuel_name):amount.
  local fuel_ts is time:seconds.

  local return_val is 999.

  // will div by zero unless we had a prev pass already, so avoid this the first time:
  if (prev_fuel_ts > 0) {
    local fuel_rate is (prev_fuel_amount - fuel_amount) / (fuel_ts - prev_fuel_ts).
    set return_val to fuel_amount / fuel_rate.
  }

  set prev_fuel_amount to fuel_amount.
  set prev_fuel_ts to fuel_ts.
  return return_val.
}
