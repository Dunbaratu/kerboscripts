// Provides automated save/load of some values so they survive reboot.

local p_file is "persist.json".
local p_lex is lex().
local p_hud is true.

// Turn on or off the hud text describing that persist library is doing:
function persist_hud {
  parameter newVal.
  set p_hud to newVal.
}

function persist_read {
  
  if p_hud
    hudtext("Reading kOS Persist lib.", 4, 3, 18, white, false).
  if exists(p_file) {
    set p_lex to readjson(p_file).
  }
}

function persist_set {
  parameter name, val.

  if p_hud
    hudtext("Updating "+name+" in kOS Persist lib.", 2, 3, 18, white, false).
  local differs is true.
  if p_lex:haskey(name) {
    local old_val is p_lex[name].
    if val = old_val {
      set differs to false.
    }
  }
  if differs {
    set p_lex[name] to val.
    persist_write().
  }
}

function persist_get {
  parameter name.

  if p_lex:haskey(name)
    return p_lex[name].

  return 0. // fallback so it won't die.
}

function persist_write {

  if exists(p_file) {
    deletepath(p_file).
  }
  if p_hud
    hudtext("Writing kOS persist lib file.", 2, 3, 18, white, false).
  writejson(p_lex, p_file).
}

// -------- "main" ------------------------------------------
// when you "run once" this lib, as you would in a reboot of
// a program that uses it, it will read the old vals:
// ----------------------------------------------------------
persist_read().

