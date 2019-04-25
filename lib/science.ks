parameter do_all is false, transmit_all is false, filter_tag is "".

if do_all {
  do_all_science_things().
  wait 5.
}
if transmit_all {
  transmit_all_science_things().
}

function do_all_science_things {
  local all_sci_mods is ship:modulesnamed("ModuleScienceExperiment").
  for sci in all_sci_mods {
    if filter_tag = "" or sci:part:tag = filter_tag {
      if sci:hasdata and sci:rerunnable {
        sci:reset().
        wait 0.5.
      }
      if not(sci:hasdata) {
        sci:deploy().
      }
    }
  }
}

function transmit_all_science_things {
  local all_sci_mods is ship:modulesnamed("ModuleScienceExperiment").
  for sci in all_sci_mods {
    if filter_tag = "" or sci:part:tag = filter_tag {
      if sci:hasdata {
        sci:transmit().
      }
    }
  }
}
