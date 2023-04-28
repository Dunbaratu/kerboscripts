print "type a key". terminal:input:getchar().
print "GO!".
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


wait until stage:resourceslex["Aniline37"]:amount < 10 and stage:ready.
print "hot staging.".
stage.
wait 0.5.

// now decouple after hotstage started.
wait until stage:ready.
print "shutting off first stage engines.".
for eng in engs_first_stage { eng:shutdown. }
print "decoupling hot stage.".
stage. //declamp.

wait 10.
stage.
