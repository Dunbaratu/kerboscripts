parameter
  comp, // compass to initially aim at
  pit, // pitch to imitially aim at
  sec. // seconds to hold that before following srfprograde

local fuel_rate is 0.
local fuel_name is "Ethanol75".

print "Initializing engine.".
set ship:control:pilotmainthrottle to 1.
lock throttle to 1.
stage.
wait 3.
print "Declamping.".
stage.
print "Steering straight up for a few seconds.".
lock steering to heading(comp,90).
wait 5.
print "Steering at heading("+comp+","+pit+")".
lock steering to heading(comp,pit).
wait sec - 5.
print "Steering just at srfprograde now.".
lock steering to srfprograde.

print "Measuring fuel usage rate...".
local fuel_rate is measure_fuel_rate(fuel_name).
print "   Burning "+fuel_name+" at "+round(fuel_rate,2)+" Units/Sec.".

local remain is 999.
local prev_remain is 999.
until remain < 2 {
  set remain to seconds_left(fuel_name, fuel_rate).
  if remain < prev_remain - 1 {
    print "Remaining seconds of fuel = " + round(remain).
    set prev_remain to remain.
  }
}
print "HOT STAGING!".
print "Shutting off existing engines".
for eng in ship:engines {
  if eng:ignition
    eng:shutdown.
}
wait 0.
print "Starting next engines".
stage.
wait 8.
print "Measuring fuel usage rate...".

set fuel_name to "IRFNA-III".
local fuel_rate is measure_fuel_rate(fuel_name).
print "   Burning "+fuel_name+" at "+round(fuel_rate,2)+" Units/Sec.".
local remain is 999.
local prev_remain is 999.
until remain < 2 {
  set remain to seconds_left(fuel_name, fuel_rate).
  if remain < prev_remain - 1 {
    print "Remaining seconds of fuel = " + round(remain).
    set prev_remain to remain.
  }
}
print "HOT STAGING!".
print "Shutting off existing engines".
for eng in ship:engines {
  if eng:ignition
    eng:shutdown.
}
wait 0.
print "Starting next engines".
stage.

print "No longer can steer - spin stabalizer doing everything.".
wait 99999.


function measure_fuel_rate {
  parameter fuel_name.

  local fuel_1 is stage:resourceslex[fuel_name]:amount.
  wait 1. // exactly 1 second.
  local fuel_2 is stage:resourceslex[fuel_name]:amount.
  return fuel_1 - fuel_2.
}

function seconds_left {
  parameter fuel_name, fuel_rate.

  return stage:resourceslex[fuel_name]:amount / fuel_rate.
}
