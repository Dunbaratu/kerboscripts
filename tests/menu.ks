run once "/lib/menu".
clearscreen.

// A menu is a Lexicon returned by the make_menu() user function:
set submenu2 to make_menu(
    0,  // topX
    0,  // topY
    20, // max allowed screen width (truncates things if they're wider).
    5,  // max allowed screen height (scrolls content within the box if there's more).
    "Letters", // title of menu.

    // Contents of menu is a 2-D list of (string1, delegate1), (string2, delegate2), etc.
    // When you pick the item it executes the delegate.
    LIST(
      LIST( "A", { print "Delegate that prints 'A'" at (0,0). } ),
      LIST( "B", { print "Delegate that prints 'B'" at (0,0). } ),
      LIST( "C", { print "Delegate that prints 'C'" at (0,0). } )
    )
  ).
// Here's another menu example, this time using named delegates instead of anon:
set submenu1 to make_menu( 0, 0, 20, 8, "SubMenu1",
    LIST(
      // Note, instead of assigning a delegate, you may choose to
      // assign another instance of a menu made by make_menu.
      // This is how you invoke a sub-menu when you pick the item.
      LIST( "Pick a letter", submenu2),

      // Note, when assigning a sub-menu you could choose to just
      // assign it in-line if you like by calling make_menu right there:
      LIST( "Pick a number", make_menu( 0, 0, 20, 5, "Numbers",
        LIST(
          LIST( "1", {print "one  " at (0,1).}),
          LIST( "2", {print "two  " at (0,1).}), 
          LIST( "3", {print "three" at (0,1).})
          )
        )
      ),
      LIST( "subItem1", MyFunc@:bind("subitem 1") ),
      LIST( "subItem2", MyFunc@:bind("subitem 2") ),
      LIST( "subItem3", MyFunc@:bind("subitem 3") ),
      LIST( "subItem4", MyFunc@:bind("subitem 4") )
    )
  ).
// Here is my outermost menu that includes the above two menus:
set testMenu1 to make_menu( 3, 4, 30, 8, "Menu 1",
  LIST(
    LIST( "menu1 item1",     MyFunc@:bind("item 1") ),
    LIST( "menu1 item two",  MyFunc@:bind("item 2") ),
    LIST( "menu1 item3",     MyFunc@:bind("item 3") ),
    LIST( "menu1 item4",     MyFunc@:bind("item 4") ),
    LIST( "SubMenu1",        subMenu1 ),
    LIST( "menu1 item VI",   MyFunc@:bind("item 6") ),
    LIST( "menu1 item VII",  MyFunc@:bind("item 7") ),
    LIST( "menu1 item VIII", MyFunc@:bind("item 8") ),
    LIST( "menu1 item IX",   MyFunc@:bind("item 9") ),
    LIST( "menu1 item 10",   MyFunc@:bind("item 10") ),
    LIST( "menu1 item 11",   MyFunc@:bind("item 11") ),
    LIST( "menu1 item 12",   MyFunc@:bind("item 12") ),
    LIST( "menu1 item 13",   MyFunc@:bind("item 13") ),
    LIST( "menu1 item 14",   MyFunc@:bind("item 14") ),
    LIST( "menu1 item 15",   MyFunc@:bind("item 15") ) 
    )
  ).

testMenu1["start"]().

// Just a way to test and prove the delegates are getting called:
function MyFunc {
  parameter text.
  
  hudtext(text, 1, 1, 20, blue, false).
}
