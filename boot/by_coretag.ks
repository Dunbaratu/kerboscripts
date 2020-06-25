parameter startWhen is "ask". // "ask", "never", "now"
if not(defined(bootcopied)) {
  copypath("0:/boot/by_coretag.ks","/boot/").
  set bootcopied to true.
  run "boot/by_coretag".
} else {
  wait until ship:unpacked.
  print "BOOT BY CORE TAGNAME.".
  print "Copying script called "+core:tag+" from coreboot.".
  copypath("0:/coreboot/"+core:tag+".ks", "1:/").
  if startWhen = "ask" {
    core:doevent("Open Terminal").
    print "Begin Script?".
    print "(Begins on 'go' signal or pressing 'y' key.)".
    until false {
      if terminal:input:haschar() {
        local ch is terminal:input:getchar().
        if ch = "y" {
          set startWhen to "now".
          break.
        } else {
          print "QUITTTING AT USER REQUEST.".
          set startWhen to "never".
          break.
        }
      } else if not(core:messages:empty) {
        local msg is core:messages:pop().
        local cnt is msg:content.
        if cnt:istype("string") and cnt = "go" {
          hudtext("Core "+core:tag+" received go signal.", 6, 4, 24, yellow, true).
          set startWhen to "now".
          break.
        }
      }
      wait 0.
    }
  }
  if startWhen = "now" {
    local bootMod is findBootableParent(core:part).
    runpath("1:/"+core:tag+".ks", bootMod).
  }
  print "BOOT done for Core "+core:tag.
}
function findBootableParent {
  parameter me.
  until not (me:hasparent) {
    set me to me:parent.
    if me:hasmodule("kOSProcessor") {
      local mod is me:getmodule("kOSProcessor").
      if mod:bootfilename <> "" and mod:bootfilename <> "None" {
        return mod.
      }
    }
  }
  return "nil".
}
