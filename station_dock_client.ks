parameter param_tgt is 0.

run once "lib/dock".

local tgt is param_tgt.

CLEARSCREEN.

if tgt = 0 {
  PRINT "FIRST SELECT A REMOTE VESSEL AS YOUR TARGET VESSEL.".
}

PRINT "Clearing out any pending old messages:".
ship:messages:clear().

local thePorts is ship:partstagged("fromport").
if thePorts:LENGTH = 0 {
  PRINT "Now assign a docking port with nametag 'fromport' please.".
}
until thePorts:LENGTH > 0 {
  set thePorts to ship:partstagged("fromport").
  wait 0.001.
}
local thePort is thePorts[0].

local msg to LEXICON(
  "TYPE", "DOCKWANTED",
  "NODETYPE", thePort:NODETYPE,
  "TAG", thePort:TAG
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
          lock steering to lookdirup(-tgt_port:portfacing:vector, tgt_port:portfacing:topvector).

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
}
