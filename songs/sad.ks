set song_sad to  LEXICON(
  "setup", {
    local vv is getvoice(0).
    set vv:attack to 0.02.
    set vv:decay to 0.01.
    set vv:sustain to 0.8.
    set vv:release to 0.02.
    set vv:wave to "sawtooth".
    set vv:tempo to 0.5.
    },
  "voices", LIST(0),
  0, LIST( // rhythm line
    NOTE("R", 0.5),
    NOTE("D3", 0.5, 0.45),
    NOTE("Bb2", 0.7, 0.65),
    NOTE("Bb2", 0.7, 0.65),
    NOTE("F2", 0.5, 0.4),
    SLIDENOTE("C3", "Bb0", 2.0, 1.5)
  )
).



