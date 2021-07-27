// runs use_rover multiple times for a contract.

// one waypoint base name without the alpha, beta, gamma, etc part,
// OR a LIST() of such names if doing more than one nearby contract:
parameter wp_inputted is "None".
// Speed you want the rover to drive at:
parameter want_speed is 15.
// Only do the science instruments with this tag name:
parameter filter_tag is "".

wait until ship:unpacked.

if homeconnection:isconnected {
  copypath("0:/lib/science","/lib/").
  copypath("0:/lib/rover","/lib/").
  copypath("0:/use_rover","/").
}

runoncepath("lib/science", false, false, filter_tag).

if wp_inputted ="None" {
  err_sound().
  PRINT "THIS PROGRAM NEEDS 1 PARAMETER:".
  PRINT " - The name (string) of a waypoint or waypoint cluser to visit.".
} else {
  local wp_input_names is list().
  if wp_inputted:isType("LIST") {
    for name in wp_inputted { wp_input_names:add(name). }
  } else {
    wp_input_names:add(wp_inputted).
  }
  local visited_wp_names is list().
  local wp_list is generate_wp_list(wp_input_names, visited_wp_names).

  if wp_list:length = 0 {
    err_sound().
    PRINT "COULD NOT FIND ANY WAYPOINTS WITH THE NAME(S) GIVEN.".
  } else {
    until wp_list:length = 0 {
      // wp_list is now all the waypoints with the name (i.e. alpha, beta, etc).
      local which_point is 0.
      // find which waypoint is closest:
      for i in range(0,wp_list:length) {
        if wp_list[i]:position:mag < wp_list[which_point]:position:mag {
          set which_point to i.
        }
      }
      print "WAYPOINT " + wp_list[which_point]:name + " IS CLOSEST.".
      run use_rover(wp_list[which_point], want_speed).
      sas off. // use_rover ends by turning it on.
      print "DONE DRIVING TO POINT, DOING ALL SCIENCE.".
      do_all_science_things().
      print "TRANSMIT SCIENCE? (y/n) (you have 10 seconds to answer.)".
      local now is time:seconds.
      local done is false.
      until done or terminal:input:haschar() or time:seconds > now + 10 {
        if terminal:input:haschar() {
          local ch is terminal:input:getchar().
          if ch = "y" {
            transmit_all_science_things().
            set done to true.
          }
        }
        wait 0.
      }
      wp_visited_list:add(which_point:name).
      wp_list:remove(which_point).
      set wp_list to generate_wp_list(wp_input_names, visited_wp_names).
    }
  }
}

// Remake List after each contract in case the contract
// is one of those that adds new waypoints one at a time
// only when you complete the previous waypoint:
function generate_wp_list {
  parameter prefix_names, visited.

  local the_list is list().
  for wp in allwaypoints() {
    for prefix in prefix_names {
      if wp:name:startswith(prefix) {
        if not(visited:contains(wp:name))
          the_list:add(wp).
      }
    }
  }
  return the_list.
}

function err_sound {
  set getvoice(5):wave to "sawtooth".
  getvoice(5):play(slidenote(400,300,0.3)).
}
