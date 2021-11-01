@lazyglobal off.

// lib/menu - library for making a menu system for user picks.

// Returns a menu object which is a lexicon of menu settings and a list of menu picks:
function make_menu {
  parameter topX is 0, topY is 0, maxWidth is 40, maxHeight is 10, title is "MENU", contents is LIST().

  local menu is LEX(
    "topx", topx,
    "topy", topY,
    "maxwidth", maxWidth,
    "maxheight", maxHeight,
    "title", title,
    "contents", contents,
    "pick", 0,
    "oldpick", 0,
    "viewTop", 0,
    "oldviewTop", -1
    ).
  // Calculate some cached values for speed.  Please call it again when you change the menu's contents:
  set menu["recalc"] to MenuRecalcContents@:bind(menu).
  // Calculate some cached values for speed.  Please call it again when you change the menu's contents:
  set menu["erase"] to MenuErase@:bind(menu).
  // Calculate some cached values for speed.  Please call it again when you change the menu's contents:
  set menu["redraw"] to MenuDrawAll@:bind(menu).
  // Call to give control to the menu and let it do it's thing:
  set menu["start"] to MenuTakeCharge@:bind(menu).

  MenuRecalcContents(menu).

  return menu.
}

function MenuRecalcContents {
  parameter menu.

  local width is MenuGetWidth(menu).
  local height is MenuGetHeight(menu).
  set menu["width"] to width.
  set menu["height"] to height.

  // This complex mess turns spaces to percents to protect them for a moment,
  // then pads left and right with spaces, turns those spaces into '=', then
  // turns the original spaces back into spaces instead of percents:
  local titleLen is menu["title"]:length.
  set menu["titlebar"] to ":" +
    menu["title"]:replace(" ","%"):padleft((titleLen+width-1)/2):padright(width-1):replace(" ","="):replace("%"," ") +
    ":" .
  set menu["bottombar"] to "`":padright(width):replace(" ","-")+"'".
  set menu["padrow"] to "|":padright(width) + "|".
}

// Return the current width we will be using: it's the longest
// string in the menu, or the max width if that's too long,
// or the max width that fits on the terminal if the max width
// is too long.
function MenuGetWidth {
  parameter menu.

  local width is 3.
  local maxw is min(menu["maxwidth"],(terminal:width - menu["topx"] - 1)).

  // It's possible the title is the widest thing so start with its width:
  set width to min(max(3+menu["title"]:length, width), maxw).

  for item in menu["contents"] {
    set width to min(max(3+item[0]:length, width), maxw).
  }

  return width.
}

function MenuGetHeight {
  parameter menu.

  local height is 2.
  local maxw is min(menu["maxheight"],(terminal:height - menu["topY"] - 1)).
  set height to min(2+menu["contents"]:length, maxw).

  return height.
}

function MenuTakeCharge {
  parameter menu.

  MenuDrawAll(menu).

  local ti is terminal:input.
  local done is false.

  until done {
    local ch is ti:getchar().

    if ch = ti:DELETERIGHT or ch = ti:BACKSPACE {
      MenuErase(menu).
      set done to true.
    } else if ch = ti:ENTER {
      MenuDoPick(menu).
    } else if ch = ti:UPCURSORONE {
      set menu["pick"] to max(menu["pick"]-1, 0).
      MenuUpdate(menu).
    } else if ch = ti:DOWNCURSORONE {
      set menu["pick"] to min(menu["pick"]+1, menu["contents"]:length-1).
      MenuUpdate(menu).
    } else if ch = ti:PAGEUPCURSOR {
      set menu["pick"] to max(menu["pick"]-menu["height"], 0).
      MenuUpdate(menu).
    } else if ch = ti:PAGEDOWNCURSOR {
      set menu["pick"] to min(menu["pick"]+menu["height"], menu["contents"]:length-1).
      MenuUpdate(menu).
    } else if ch = ti:HOMECURSOR {
      set menu["pick"] to 0.
      MenuUpdate(menu).
    } else if ch = ti:ENDCURSOR {
      set menu["pick"] to menu["contents"]:length-1.
      MenuUpdate(menu).
    }
  }
}

// When the pick location was moved, update the menu display
// presuming the menu display was already right before it moved.
function MenuUpdate {
  parameter menu.

  local pick is menu["pick"].
  local oldpick is menu["oldpick"].
  local height is menu["height"].

  local needDraw is false.
  until pick >= menu["viewTop"] {
    set menu["viewTop"] to max(menu["viewTop"]-1, 0).
    set needDraw to true.
  }
  until pick < menu["viewTop"] + height - 2 {
    set menu["viewTop"] to min(menu["viewTop"]+1, menu["contents"]:length-1).
    set needDraw to true.
  }

  if needDraw {
    MenuDrawContents(menu).
  } else {
    MenuDrawPointer(menu).
  }

  set menu["oldpick"] to pick.
}

// Execute the thing at the menu's current pick.
function MenuDoPick {
  parameter menu.

  local action is menu["contents"][menu["pick"]][1].

  if action:istype("Lexicon") {
    // Presume it's a menu too.  Home it at the location just under the
    // current row and invoke it.
    set action["topX"] to menu["topX"] + 4.
    set action["topY"] to menu["topY"] + 2 + menu["pick"] - menu["viewtop"].
    action["recalc"]().

    // Do the sub-menu.
    action["start"]().

    // Clean up after the old menu is done.
    action["erase"]().
    menu["redraw"]().
  } else if action:istype("Delegate") {
    // Execute it if it's a Delegate.
    action().
  } else {
    print char(7) + "Type of action for menu item " + menu["pick"] + " is bogus.".
  }
}

function MenuErase {
  parameter menu.

  local topX is menu["topX"].
  local topY is menu["topY"].
  local width is menu["width"].
  local height is menu["height"].
  
  local padrow is " ":padright(width+2).
  for i in range(0, height) {
    print padRow at (topX, topY+i).
  }
}

// Draws everything about the menu including its borders and title.
function MenuDrawAll {
  parameter menu.

  local topX is menu["topX"].
  local topY is menu["topY"].
  local width is menu["width"].
  local height is menu["height"].
  local padrow is menu["padrow"].

  print menu["titlebar"] + " " at (topX, topY).
  for i in range(1, height-1) {
    print padrow at (topX, topY + i).
  }
  print menu["bottomBar"] + " " at (topX, topY+height-1).

  MenuDrawContents(menu).
}

// Draws just the inside contents of the menu (not title or borders).
function MenuDrawContents {
  parameter menu.

  local topX is menu["topX"].
  local topY is menu["topY"].
  local width is menu["width"].
  local height is menu["height"].
  local viewtop is menu["viewTop"].
  local contents is menu["contents"].
  
  for i in range(viewTop, min(viewTop+height-2, contents:length)) {
    print " " + contents[i][0]:padright(width-2) at (topX + 1, topY + (1 + i - viewtop)).
  }

  MenuDrawPointer(menu).
}

// Draws just the move of the pointer to a new pick, for use when
// the menu didn't need to scroll.
function MenuDrawPointer {
  parameter menu.

  local topX is menu["topX"].
  local topY is menu["topY"].
  local pick is menu["pick"].
  local width is menu["width"].
  local height is menu["height"].
  local oldPick is menu["oldpick"].
  local viewtop is menu["viewTop"].

  local oldY is topY + 1 + oldPick - viewTop.
  local y is topY + 1 + pick - viewTop.

  // Wipe the old pointer if it's visible on screen:
  if oldY > topY and oldY < topY + height {
    print " " at (topX + 1, oldY).
    print " " at (topX + width - 1, oldY).
  }
  // Draw the new pointer on screen:
  print ">" at (topX + 1, y).
  print "<" at (topX + width - 1, y).

}

