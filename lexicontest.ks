
LOCAL map IS LEXICON().  // Node list
LOCAL openset IS LEXICON(). // Open Set
LOCAL closedset IS LEXICON(). // Closed Set
LOCAL fscorelist IS LEXICON().// fscore list
LOCAL fscore IS LEXICON().
LOCAL gscore IS LEXICON().
LOCAL camefrom IS LEXICON().

LOCAL grid IS SHIP:GEOPOSITION.

LOCAL x IS 0.
LOCAL y IS 0.
CLEARSCREEN.

UNTIL map:LENGTH = 2000 {
  LOCAL keyname IS x+","+y.
  SET map[keyname] TO LEXICON(
    "LAT",grid:LAT,
    "LNG",grid:LNG,
    "TERRAINHEIGHT",grid:TERRAINHEIGHT,
    "POSITION",grid:POSITION,
    "FSCORE",0
  ).
  openset:ADD(keyname,TRUE).
  closedset:ADD(keyname,FALSE).
  if fscorelist:HASKEY(y) {
    if fscorelist[y]:HASKEY(keyname) = FALSE {
      fscorelist[y]:ADD(keyname,LIST(x,y)).
    }
  } else {
    fscorelist:ADD(y,LEXICON(keyname,LIST(x,y))).
  }
  fscore:ADD(keyname,keyname).
  gscore:ADD(keyname,keyname).
  camefrom:ADD(keyname,keyname).
  SET x TO x + 1.
  if x = 100 {
    SET y TO y + 1.
    SET x TO 0.
  }
  PRINT map:LENGTH AT(2,2 ).
  PRINT "X : " + x AT (2,4).
  PRINT "Y : " + y AT (2,5).
  SET grid TO LATLNG(grid:LAT+100,grid:LNG+10).
}
