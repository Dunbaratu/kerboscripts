parameter param_tgt is 0.

local tgt is param_tgt.

CLEARSCREEN.

if tgt = 0 {
PRINT "FIRST SELECT A REMOTE VESSEL AS YOUR TARGET VESSEL.".
PRINT "THEN.".
PRINT "Assign a docking port with nametag 'fromport' please.".
}

PRINT "Clearing out any pending old messages:".
ship:messages:clear().

local thePorts is ship:partstagged("fromport").
until thePorts:LENGTH > 0 {
set thePorts to ship:partstagged("fromport").
wait 0.001.
}
local thePort is thePorts[0].

local msg to LEXICON(
"TYPE", "DOCKWANTED",
"NODETYPE", thePort:NODETYPE
).

local worked is false.
until worked {
if tgt = 0 {
set tgt to TARGET.
wait 0.01.
}
print "Target is: " + tgt.
local con is tgt:connection.
set worked to con:sendmessage(msg).
if worked {
print "Message was sent successfully.".
    
print "Waiting for reply.".
wait until not SHIP:MESSAGES:EMPTY.
local msg is SHIP:MESSAGES:POP.
if msg:sender:name = tgt:name {
print "Got Reply from target ship.".
print "Message body:" + msg:content.

if msg:content:ISTYPE("LEXICON") and msg:content:HASKEY("TYPE") {

if msg:content["TYPE"] = "DOCKDENIED" {

print "Remote side refused to allow me to dock. Sorry.".

} else if msg:content["TYPE"] = "DOCKALLOWED" {

print "Remote side said I should dock with '"+msg:content["TAG"]+"' port.".
local tgt_port is tgt:partstagged( msg:content["TAG"] )[0].
lock steering to tgt_port:position.

print "Controlling from my port".
thePort:controlfrom().

if thePort:hasmodule("ModuleAnimateGeneric") {
local mod is thePort:getmodule("ModuleAnimateGeneric").
if mod:hasevent("open shield") {
print "Opening shield for my port.".
mod:doevent("open shield").
}
}

print "Waiting for remote to tell me it's okay to start docking.".
local wait_over is false.
until wait_over {
if not ship:messages:empty {
local reply is ship:messages:pop.
if  reply:sender:istype("Vessel") and reply:sender = tgt and
reply:content:istype("Lexicon") and reply:content:haskey("TYPE") and
reply:content["TYPE"] = "DOCKREADY" {
local tgt_port_again is tgt:partstagged( reply:content["TAG"] )[0].
if tgt_port <> tgt_port_again {
print "Error in protocol: Server changed the target port on me.".
} else {
do_dock(thePort, tgt_port).
}
} else  {
print "Got an unexpected message: ignoring: " + reply.
}
}
wait 1.
}

}
}
}
} else {
print "Message was not sent successfully, trying again in 1 second.".
}
wait 1.
}.

function do_dock {
parameter from_port, to_port.
until abs(steeringmanager:angleerror) < 1 and abs(steeringmanager:rollerror) < 1 {
print "Waiting for orientation to match direction of the port.".
wait 2.
}
print "Approaching port".
local old_rcs_value is RCS.
RCS on.

local fore_control      is PIDLoop( 2, 0.001, 0.5, -1, 1 ).
local top_control       is PIDLoop( 2, 0.001, 0.5, -1, 1 ).
local starboard_control is PIDLoop( 2, 0.001, 0.5, -1, 1 ).

until from_port:STATE = "Docked (docker)" or
from_port:STATE = "Docked (dockee)" or
from_port:STATE = "PreAttached" or
from_port:STATE = "Docked (same vessel)" {

local rel_spd_fore is vdot(ship:facing:forevector,
from_port:ship:velocity:orbit - to_port:ship:velocity:orbit ).
local rel_spd_top is vdot(ship:facing:topvector,
from_port:ship:velocity:orbit - to_port:ship:velocity:orbit ).
local rel_spd_starboard is vdot(ship:facing:starvector,
from_port:ship:velocity:orbit - to_port:ship:velocity:orbit ).


set ship:control:fore to fore_control:UPDATE(
time:seconds, rel_spd_fore - wanted_approach_speed(from_port, to_port) ).


set ship:control:top to top_control:UPDATE(
time:seconds, rel_spd_top ).
set ship:control:starboard to starboard_control:UPDATE(
time:seconds, rel_spd_starboard ).

wait 0.0001.
}

print "Port magnetism taking over. Letting go of controls.".
unlock steering.
set ship:control:neutralize to true.
set RCS to old_rcs_value.

until from_port:STATE = "Docked (docker)" or
from_port:STATE = "Docked (dockee)" or
from_port:STATE = "Docked (same vessel)" {
print "Waiting for dock.".
wait 1.
}
print "Docked!".
}

function wanted_approach_speed {
parameter from_port, to_port.

local dist is (from_port:POSITION - to_port:POSITION):MAG.
local spd is min(0.1 + dist*(0.05), 10).
return spd.
}
