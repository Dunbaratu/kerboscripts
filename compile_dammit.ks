print "Testing persistence built-ins for opcode speed weighting.".

// Test struction for JSONning:
set jsondata to LEX(
    "some_list_thing", LIST(100,200,300,400,500),
    "just_a_number", 1,
    "another_lex", LEX("A", 1, "B", 2, "C", 3, "D", 4, "E", 5)
    ).
for which_vol in list(0,1) {
  print "========= Testing on Volume " + which_vol + " ========".
  switch to which_vol.
  cd("/").
  // now doing the test:
  for i in range(0,50) {
    print "Iteration " + i.
    if exists("/sub1") {
      deletepath("/sub1").
    }
    cd("/").
    createdir("sub1").
    cd("sub1").
    createdir("sub2").
    cd("sub2").
    createdir("sub3").
    cd("sub3").
    createdir("sub4").
    cd("sub4").

    // The following line will also test string concatenation speed:
    set p1 to path("/sub1" + "/sub2" + "/sub3" + "/sub4").// not doing anything with this - just testing speed.

    set vol to volume(which_vol). // not doing anything with this - just testing speed.
    set sp to scriptpath(). // path of current script - again just testing speed and ignoring result.
    for j in range(0,20) {
      log "String 40 chars length, 20 times repeat." to "/file_in_root.txt".
    }
// Missing stuff is here ----
  }
}

