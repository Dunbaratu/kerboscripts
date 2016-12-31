clearscreen.
print "This is a program that just obeys whatever manuever nodes you put in front of it.".

run once "lib/burn".

local prev_ag10 is ag10.

print "Toggle action group 10 to quit.".

obey_node_mode(should_quit@, do_precise_node@).

print "just_obey_nodes done.".

function should_quit {
  return ag10 <> prev_ag10.
}

function do_precise_node {
  runpath( "/precise_node" ).
}
