// Ketris - a falling block game

set ketris_stick_piece to
  LIST( // the drawing in boxy pixels
    LIST(true, true, true, true)
  ).
set ketris_box_piece to
  LIST(
    LIST(true, true),
    LIST(true, true)
  ).
set ketris_S_piece to
  LIST(
    LIST(false, true, true),
    LIST(true,  true, false)
  ).
set ketris_inverse_S_piece to
  LIST(
    LIST(true,  true, false),
    LIST(false, true, true)
  ).
set ketris_T_piece to
  LIST(
    LIST(true,  true, true),
    LIST(false, true, false)
  ).
set ketris_L_piece to
  LIST(
    LIST(true, false, false),
    LIST(true, true,  true)
  ).
set ketris_inverse_L_piece to
  LIST(
    LIST(true, true,  true),
    LIST(true, false, false)
  ).

// An array of pieces in their 4 orientations:
set pieces to
  LIST(
    LIST(
      rotated_shape(ketris_stick_piece,0),
      rotated_shape(ketris_stick_piece,1),
      rotated_shape(ketris_stick_piece,2),
      rotated_shape(ketris_stick_piece,3)
      ),
    LIST(
      rotated_shape(ketris_box_piece,0),
      rotated_shape(ketris_box_piece,1),
      rotated_shape(ketris_box_piece,2),
      rotated_shape(ketris_box_piece,3)
      ),
    LIST(
      rotated_shape(ketris_S_piece,0),
      rotated_shape(ketris_S_piece,1),
      rotated_shape(ketris_S_piece,2),
      rotated_shape(ketris_S_piece,3)
      ),
    LIST(
      rotated_shape(ketris_inverse_S_piece,0),
      rotated_shape(ketris_inverse_S_piece,1),
      rotated_shape(ketris_inverse_S_piece,2),
      rotated_shape(ketris_inverse_S_piece,3)
      ),
    LIST(
      rotated_shape(ketris_T_piece,0),
      rotated_shape(ketris_T_piece,1),
      rotated_shape(ketris_T_piece,2),
      rotated_shape(ketris_T_piece,3)
      ),
    LIST(
      rotated_shape(ketris_L_piece,0),
      rotated_shape(ketris_L_piece,1),
      rotated_shape(ketris_L_piece,2),
      rotated_shape(ketris_L_piece,3)
      ),
    LIST(
      rotated_shape(ketris_inverse_L_piece,0),
      rotated_shape(ketris_inverse_L_piece,1),
      rotated_shape(ketris_inverse_L_piece,2),
      rotated_shape(ketris_inverse_L_piece,3)
      )
  ).

// A list of how each piece needs to be offset
// when rotated into positions 0,1,2,or 3 (only the stick really needs this).
// This list must match indeces with the pieces list.
set center_offsets to
  LIST(
    LEX("x", LIST(-1, 1, -1, 1), "y", LIST(1, -1, 1, -1)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0)),
    LEX("x", LIST(0, 0, 0, 0), "y", LIST(0, 0, 0, 0))
  ).

// A list of which characters to draw for which piece type,
// to emulate the piece color concept of Tetris.
// This list must match indeces with the pieces list.
set draw_chars to
  LIST(
    "@",
    "0",
    "%",
    "X",
    "O",
    "&",
    "#"
  ).

// Make playfield be a 20x10 array to hold the playing field of chars:
// -------------------------------------------------------------------
set play_empty_row to LIST(" ", " ", " ", " ", " ", " ", " ", " ", " ", " ").
set playfield to LIST().
for r in range(0,20) { 
  playfield:add( play_empty_row:COPY() ).
}

set playfield_left to 5.
set playfield_top to 4.

// ===================== MAIN ===========================
global original_IPU is CONFIG:IPU.
if original_IPU < 1000 { set CONFIG:IPU to 1000. }

draw_initial_screen().
global ch is " ".
global xpos is playfield[0]:LENGTH/2.
global ypos is 1. // starts one spot down so there's room to rotate the long stick.
global new_xpos is 0.
global new_ypos is 0.
global new_pNum is 0.
global pNum is floor(RANDOM()*pieces:LENGTH).
global orient is floor(RANDOM()*4).
global next_pNum is floor(RANDOM()*pieces:LENGTH).
global next_orient is floor(RANDOM()*4).


// Game progress variables:
global game_tempo is 1.
global game_rows_done is 0.
global game_score is 0.
global rows_per_speedup is 5. // tempo increases every this many finished rows.
global prev_drop_timestamp is time:seconds. // when did the game last move the piece down?
global game_rows_this_tempo is 0. // How many rows since we had a speedup?
global prev_row_wipe_timestamp is time:seconds.

global game_over is false.
draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
draw_piece( next_pNum, next_orient, 0, 0, draw_chars[next_pNum], true ).

local advance_next_piece is false.

// If some rows need a full-row check, set these values to mark the range to be checked:
local full_check_top is -1.
local full_check_bottom is -1.

until game_over {
  set advance_next_piece to false.
  set full_check_top to -1.
  set full_check_bottom to -1.
  if terminal:input:haschar() {
    set ch to terminal:input:getchar().
    if ch = "q" {
      set game_over to true.
    } else if ch = terminal:input:UPCURSORONE {
      draw_piece( pNum, orient, xpos, ypos, " " ).
      set new_orient to mod(orient + 1, 4).
      set new_xpos to xpos + center_offsets[pNum]["x"][new_orient].
      set new_xpos to shift_for_border(pNum, new_orient, new_xpos).
      set new_ypos to ypos + center_offsets[pNum]["y"][new_orient].
      if not would_collide( pNum, new_orient, new_xpos, new_ypos, true ) {
       set xpos to new_xpos.
       set ypos to new_ypos.
       set orient to new_orient.
      }
      draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
    } else if ch = terminal:input:DOWNCURSORONE {
      draw_piece( pNum, orient, xpos, ypos, " " ).
      set new_ypos to ypos + 1.
      if would_collide( pNum, orient, xpos, new_ypos, true ) {
        set advance_next_piece to true.
        set full_check_top to ypos.
        set full_check_bottom to ypos + pieces[pNum][orient]:LENGTH - 1.
      } else {
        set ypos to new_ypos.
      }
      draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
    } else if ch = terminal:input:LEFTCURSORONE {
      draw_piece( pNum, orient, xpos, ypos, " " ).
      set new_xpos to xpos - 1.
      if not would_collide( pNum, orient, new_xpos, ypos, true ) {
       set xpos to new_xpos.
      }
      draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
    } else if ch = terminal:input:RIGHTCURSORONE {
      draw_piece( pNum, orient, xpos, ypos, " " ).
      set new_xpos to xpos + 1.
      if not would_collide( pNum, orient, new_xpos, ypos, true ) {
       set xpos to new_xpos.
      }
      draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
    }
  }

  // Check to see if the timer says to drop a piece, but
  // allow the timer to pass uneventfully if we were advancing
  // to the next piece already anyway:
  if check_timer() and not advance_next_piece {
    draw_piece( pNum, orient, xpos, ypos, " " ).
    set new_ypos to ypos + 1.
    if would_collide( pNum, orient, xpos, new_ypos, true ) {
      set advance_next_piece to true.
      set full_check_top to ypos.
      set full_check_bottom to ypos + pieces[pNum][orient]:LENGTH - 1.
    } else {
      set ypos to new_ypos.
    }
    draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).
  }

  if advance_next_piece {
    new_piece_sound().

    // see if we have to drop some lines:
    full_row_check(full_check_top, full_check_bottom).

    // Remove prev prevew char:
    draw_piece( next_pNum, next_orient, 0, 0, " ", true ).

    // Set next char to preview char:
    set new_xpos to playfield[0]:LENGTH/2.
    set new_ypos to 0.
    set new_pNum to next_pNum.
    set new_orient to next_orient.

    // Get new preview char:
    set next_pNum to floor(RANDOM()*pieces:LENGTH).
    set next_orient to floor(RANDOM()*4).

    // Check for end of game (new piece appears already collided right away):
    if would_collide( new_pNum, new_orient, new_xpos, new_ypos, true ) {
      set game_over to true.
    } else {
      set pNum to new_pNum.
      set orient to new_orient.
      set xPos to new_xPos.
      set yPos to new_yPos.
    }
    
    // draw new char.
    draw_piece( pNum, orient, xpos, ypos, draw_chars[pNum] ).

    // draw next prevew char:
    draw_piece( next_pNum, next_orient, 0, 0, draw_chars[next_pNum], true ).
  
  }


  draw_score().
}

for i in range(0,26) 
  print " ".
print "GAME OVER:".
print "Score: " + game_score + "  Rows: " + game_rows_done + "  Tempo: " + game_tempo.

set CONFIG:IPU to original_IPU.

// ==================== MAIN END ========================

function rotated_shape {
  parameter
    shape, // a 2-D array of the piece's shape.
    orient. // 0,1,2,3 for orientation.
    //RETURNS - a new 2-D array for the piece's shape, after rotation.

  local return_shape is LIST().

  if orient = 0 { // ----- normal orientation: direct copy of contents -----
    for i in range(0, shape:LENGTH) {
      local sublist is LIST().
      for j in range(0, shape[i]:LENGTH) {
        sublist:add(shape[i][j]).
      }
      return_shape:ADD(sublist).
    }
  } else if orient = 1 { // ----- 90 degrees clockwise: invert row.col and count row backward -----
    for i in range(shape[0]:LENGTH-1, -1) {
      local sublist is LIST().
      for j in range(0, shape:LENGTH) {
        sublist:add(shape[j][i]).
      }
      return_shape:ADD(sublist).
    }
  } else if orient = 2 { // ----- 180 degrees clockwise: count row and col backward -----
    for i in range(shape:LENGTH-1, -1) {
      local sublist is LIST().
      for j in range(shape[i]:LENGTH-1, -1) {
        sublist:add(shape[i][j]).
      }
      return_shape:ADD(sublist).
    }
  } else { // ----- 270 degrees clockwise: invert row,col and count col backward -----
    for i in range(0, shape[0]:LENGTH) {
      local sublist is LIST().
      for j in range(shape:LENGTH-1, -1) {
        sublist:add(shape[j][i]).
      }
      return_shape:ADD(sublist).
    }
  }

  return return_shape.
}

function draw_piece {
  parameter
    pNum, // piece number
    orient, // piece orientation
    x, // x pos within the play field of upperleft corner of piece.
    y, // y pos within the play field of upperleft corner of piece.
    paintbrush, // char to draw it with.
    preview is false. // if true the just hardcode the position to the preview window

  local shape is pieces[pNum][orient].
  for i in range(0, shape:LENGTH)
    for j in range(0, shape[i]:LENGTH)
      if shape[i][j] {
        if preview {
          print paintbrush at (playfield_left + playfield[0]:length + 7 + j, playfield_top + 1 + i).
        } else {
          set_playfield( x+j, y+i, paintbrush ).
        }
      }
}

function set_playfield {
  parameter x, y, ch.

  set playfield[y][x] to ch.
  print ch at (playfield_left+x, playfield_top+y).
}

function draw_initial_screen {
  clearscreen.
  local title is "-------======= Ketris =======-------".
  print title at (terminal:width/2-title:length/2,0).
  draw_borders.

  local x_start is playfield_left + playfield[0]:LENGTH + 5.
  local y_start is playfield_top - 1.
  print "+------+                   " at (x_start, y_start +  0).
  print "|      |  -SCORE---------- " at (x_start, y_start +  1).
  print "|      |                   " at (x_start, y_start +  2).
  print "|      |                   " at (x_start, y_start +  3).
  print "|      |  -ROWS DONE------ " at (x_start, y_start +  4).
  print "|      |                   " at (x_start, y_start +  5).
  print "|      |                   " at (x_start, y_start +  6).
  print "+------+  -TEMPO---------- " at (x_start, y_start +  7).
  print "Preview                    " at (x_start, y_start +  8).
  print "                           " at (x_start, y_start +  9).
  print "                           " at (x_start, y_start + 10).
  print "Keys:                      " at (x_start, y_start + 11).
  print "  Move: left & right arrows" at (x_start, y_start + 12).
  print "  Rotate: up arrow         " at (x_start, y_start + 13).
  print "  Drop: down arrow         " at (x_start, y_start + 14).
  print "  Quit: 'Q'                " at (x_start, y_start + 15).
  print "                           " at (x_start, y_start + 16).
  print "  ======================== " at (x_start, y_start + 17).
  print " | Ketris: A block        |" at (x_start, y_start + 18).
  print " |  tesselation training  |" at (x_start, y_start + 19).
  print " |  program.              |" at (x_start, y_start + 20).
  print "  ======================== " at (x_start, y_start + 21).
  print "                           " at (x_start, y_start + 22).
}

function draw_score {
  local x_start is playfield_left + playfield[0]:LENGTH + 5.
  local y_start is playfield_top - 1.

  print game_score+" " at (x_start + 13, y_start + 2).
  print game_rows_done+" " at (x_start + 13, y_start + 5).
  print game_tempo+" " at (x_start + 13, y_start + 8).
}

function draw_borders {
  local bar_string is "-|":PADRIGHT(playfield[0]:LENGTH+2) + "|-".

  // Starting at 1 not zero on purpose. Not drawing the
  // topmost row because it's padding for rotational room:
  for i in range(1, playfield:LENGTH)
    print bar_string at (playfield_left - 2, playfield_top + i).
  local bottom_string is bar_string:replace(" ","^").
  print bottom_string at (playfield_left - 2, playfield_top + playfield:LENGTH).
}

// Return the piece's new X position it would have to
// have in order not to go off the border edge.  Used
// for when rotating a piece would put part of it off
// the edge of the width of the area:
function shift_for_border {
  parameter
    pNum,   // piece type number
    orient, // piece's orientation
    xpos.   // attempted x position to put it.

  local shape is pieces[pNum][orient].

  local new_xpos is xpos.
  if xpos < 0 {
    set new_xpos to 0.
  } else if xpos + shape[0]:LENGTH > playfield[0]:LENGTH {
    set new_xpos to playfield[0]:LENGTH - shape[0]:LENGTH.
  }
  return new_xpos.
}

// Return true if the proposed
// piece position would be superimposed with either
// the edge of the playing field or any drawn boxy pixel
// on the playing field.
function would_collide {
  parameter
    pNum, // piece's number in the pieces array.
    orient, // piece's current orientation
    x, // x pos of piece upper-left corner, relative to playing field.
    y, // y pos of piece upper-left corner, relative to playing field.
    make_sound. // if true, then make a sound if colliding.

  // Test playfield edge bounds:
  local shape is pieces[pNum][orient].
  if x < 0 or
     y < 0 or
     y + shape:LENGTH > playfield:LENGTH or
     x + shape[0]:LENGTH > playfield[0]:LENGTH {
    return true.
  }

  // Test collision with existing playfield data:
  // (Guaranteed to be in bounds at this point, so
  // no need to check for indeces out of range here):
  for i in range(0, shape:length)
    for j in range(0, shape[i]:LENGTH) 
      if shape[i][j] and not(playfield[y+i][x+j] = " ") {
        return true.
      }

  return false.
}

// If the piece should be dropped one row now, returns true.
function check_timer {

  local now is time:seconds.
  // Time between drops gets shorter and shorter as tempo goes up.
  // It starts at slightly under 1 second per drop at tempo 1.
  if (now-prev_drop_timestamp) >= 3 / (3+game_tempo) {
    set prev_drop_timestamp to now.
    return true.
  }
  return false.
}

// See if there's any full rows and if there are then wipe them out.
function full_row_check {
  parameter dirty_top, dirty_bottom. // the top and bottom rows of the dirty section in need of checking.
  
  // Search from bottom to top looking for full rows:
  local y is dirty_bottom.
  local rows_removed is 0.
  until y < dirty_top {
    local is_full is true.
    local row is playfield[y].
    for x in range(0,row:length) {
      if row[x] = " " {
        set is_full to false.
        break.
      }
    }
    if is_full {
      // Shift rows down into this one:
      for shift_y in range (y, 0) {
        set playfield[shift_y] to playfield[shift_y-1].
      }
      // Clear the top row that didn't have anything to shift into it:
      set playfield[0] to play_empty_row:COPY().


      set game_rows_done to game_rows_done + 1.
      set game_score to game_score + floor(max(4,12+time:seconds-prev_row_wipe_timestamp))*2^game_tempo.
      set game_rows_this_tempo to game_rows_this_tempo + 1.
      if game_rows_this_tempo > rows_per_speedup {
        set game_tempo to game_tempo + 1.
        set game_rows_this_tempo to 0.
      }
      set rows_removed to rows_removed + 1.
    } else {
      set y to y - 1. // iterate the loop counter (don't do if we deleted a row because that shifts rows down).
    }
  }
  set prev_row_wipe_timestamp to time:seconds.

  if rows_removed > 0 {
    redraw_playfield().
    row_delete_sound(rows_removed).
  }
}

function redraw_playfield {
  // Inefficiently just redraws everything, but that's
  // still kind of fast given that kOS actually does all the work:
  for r in range(0, playfield:length) {
    local row is playfield[r].
    for c in range(0, row:length) {
      print row[c] at (playfield_left + c, playfield_top + r).
    }
  }
}

function row_delete_sound {
  parameter how_many.

  local effects_voice is getvoice(5).
  set effects_voice:wave to "triangle".
  set effects_voice:attack to 0.02.
  set effects_voice:decay to 0.
  set effects_voice:sustain to 1.
  set effects_voice:release to 0.08.
  set effects_voice:volume to 1.
  local note_list is LIST().
  for i in range(0,how_many)
    note_list:add(note(500+game_tempo*20, 0.15, 0.06)).
  effects_voice:play( note_list ).
}

function new_piece_sound {

  local effects_voice is getvoice(5).
  set effects_voice:wave to "sine".
  set effects_voice:attack to 0.
  set effects_voice:decay to 0.
  set effects_voice:sustain to 1.
  set effects_voice:release to 0.03.
  set effects_voice:volume to 1.
  effects_voice:play( note(200, 0.05, 0.02) ).
}
