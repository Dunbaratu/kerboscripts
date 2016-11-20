clearscreen.
print "This is a program that just obeys whatever manuever nodes you put in front of it.".

run once burn_util.

local prev_ag10 is ag10.

print "Toggle action group 10 to quit.".

obey_node_mode(should_quit@).

print "just_obey_nodes done.".

function should_quit {
  return ag10 <> prev_ag10.
}
