parameter run_now is false.

if run_now {
  do_all_science_things().
  wait 5.
  transmit_all_science_things().
}

function do_all_science_things {
  local all_sci_mods is ship:modulesnamed("ModuleScienceExperiment").
  for sci in all_sci_mods {
    if sci:hasdata and sci:rerunnable {
      sci:reset().
      wait 0.5.
    }
    if not(sci:hasdata) {
      sci:deploy().
    }
  }
}

function transmit_all_science_things {
  local all_sci_mods is ship:modulesnamed("ModuleScienceExperiment").
  for sci in all_sci_mods {
    if sci:hasdata {
      sci:transmit().
    }
  }
}