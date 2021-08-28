set song_happy to  LEXICON(
  "setup", {
    local vv is getvoice(0).
    set vv:attack to 0.02.
    set vv:decay to 0.01.
    set vv:sustain to 1.
    set vv:release to 0.5.
    set vv:wave to "sawtooth".
    set vv:volume to 0.3.
    set vv:tempo to 1.5.
    set vv to getvoice(1).
    set vv:attack to 0.05.
    set vv:decay to 0.0.
    set vv:sustain to 1.0.
    set vv:release to 0.2.
    set vv:wave to "pulse".
    set vv:tempo to 1.5.
    },
  "voices", LIST(0, 1),
  0, LIST( // rhythm line
    slidenote("E1", "C3", 1),
    slidenote("E1", "C3", 1),
    slidenote("E1", "C3", 1),
    slidenote("E1", "C3", 1)
    ),
  1, LIST( // melody line
    note("C3", 0.125),
    note("D3", 0.125),
    note("R",  0.125),
    note("F3", 0.125),
    note("G3", 0.125),
    note("F3", 0.125),
    note("G3", 0.25),
    note("F#3", 0.25),
    note("D3", 0.25),
    note("E3", 0.25),
    note("C3", 0.25),
    note("C3", 0.125),
    note("D3", 0.125),
    note("R", 0.25),
    note("F3", 0.125),
    note("G3", 0.125),
    note("D3", 0.125),
    note("G3", 0.125),
    note("C4", 0.125),
    note("D4", 0.125),
    note("F4", 0.5)
  )
).
