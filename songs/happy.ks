set song_happy to  LEXICON(
  "setup", {
    local vv is getvoice(0).
    set vv:attack to 0.02.
    set vv:decay to 0.01.
    set vv:sustain to 0.8.
    set vv:release to 0.02.
    set vv:wave to "triangle".
    set vv:tempo to 1.5.
    set vv to getvoice(1).
    set vv:attack to 0.05.
    set vv:decay to 0.0.
    set vv:sustain to 1.0.
    set vv:release to 0.2.
    set vv:wave to "sine".
    set vv:tempo to 1.5.
    },
  "voices", LIST(0, 1),
  0, LIST( // rhythm line
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    SLIDENOTE("C2", "A1", 0.2),
    SLIDENOTE("E3", "C3", 0.2),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.1),
    NOTE("C2", 0.1),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("E3", 0.05),
    NOTE("C2", 0.05),
    NOTE("C2", 0.2)
    ),
  1, LIST( // melody line
    NOTE("D4", 0.2),
    NOTE("E4", 0.2),
    NOTE("F4", 0.2),
    NOTE("E4", 0.4),
    NOTE("R", 0.2),
    SLIDENOTE("E5", "F5", 0.1),
    SLIDENOTE("F5", "G5", 0.1),
    SLIDENOTE("F5", "G5", 0.1),
    NOTE("E5", 0.1),
    NOTE("C5", 0.1),
    NOTE("E5", 0.1),
    SLIDENOTE("C5", "G5", 0.2),

    SLIDENOTE("E5", "C5", 0.2),
    SLIDENOTE("C5", "A6", 0.2),
    SLIDENOTE("E5", "C5", 0.2),
    SLIDENOTE("C5", "A6", 0.2),
    SLIDENOTE("E5", "C5", 0.2),
    NOTE("E5", 0.1),
    NOTE("F5", 0.1),
    SLIDENOTE("F5", "C5", 0.3),

    NOTE("D6", 0.1),
    NOTE("E6", 0.1),
    NOTE("D6", 0.1),
    NOTE("E6", 0.1),
    NOTE("D6", 0.1),
    NOTE("C6", 0.1),
    NOTE("D6", 0.5, 0.35)
  )
).
