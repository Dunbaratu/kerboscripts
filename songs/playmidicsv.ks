@LAZYGLOBAL OFF.
//
parameter
  playMidiCsv_filePath is path("0:/midi/fur_Elise.csv"), // can be overridden by RUN parameter.
  waveParameter is "sine",
  speedParameter is 1.
{

local NotePrefix is "Note_".
local NoteStartString is "Note_on_c".
local NoteEndString is "Note_off_c".
local NoteEndVelocity is 0.
local clockPerQuarter is 384. // 480 is more standard, can be read from midi header
global voiceTempo is 1.

local channelData is lex(). // this holds the data for each channel

local currentNoteStart is "r".

global noteList is list().
for i in range(-1, 10) // uses -1 because there are 12 notes below the zero octive in midi
{
    noteList:add("c" + i).
    noteList:add("c#" + i).
    noteList:add("d" + i).
    noteList:add("d#" + i).
    noteList:add("e" + i).
    noteList:add("f" + i).
    noteList:add("f#" + i).
    noteList:add("g" + i).
    noteList:add("g#" + i).
    noteList:add("a" + i).
    noteList:add("a#" + i).
    noteList:add("b" + i).
}

function parseInt {
    parameter str.
    return floor(str:toscalar(0)).
}

function ptp { // print time plus [str]
    parameter str.
    local line to "T+" + round(missiontime):tostring:padright(5):replace(" ", "-") + "- " + str.
    print line.
}

function alert { // prints the string to hud (green) and ptp
    parameter str.
    hudtext(str, 30, 3, 18, white, false).
    ptp(str).
}

function error { // prints the string to hud (red) and ptp
    parameter str.
    hudtext(str, 300, 2, 18, red, false).
    ptp(str).
}

function startNote {
    parameter split.

    local channel is parseInt(split[3]:trim).

    // Before anything else: if this is the second of two
    // back-to-back notes without a rest between them, then
    // end the prev note where this one begins before
    // we clobber the data in channelData with the new note:
    if channelData:haskey(channel) and channelData[channel]["pendingNote"] {
      endNote(split).
    }

    local noteIndex is parseInt(split[4]:trim).
    local startBeat is parseInt(split[1]:trim).
    if not channelData:haskey(channel) {
        local datum is lex().
        set datum["idx"] to -1.
        set datum["startBeat"] to -1.
        set datum["endBeat"] to -1.
        set datum["pendingNote"] to -1.
        channelData:add(channel, datum).
    }
    // a note has started for this channel:
    set channelData[channel]["pendingNote"] to true.
    if not channelSongs:haskey(channel) {
        channelSongs:add(channel, list()).
    }
    if channelData[channel]["idx"] = -1 {
        // alert("Start note: " + noteIndex).
        set channelData[channel]["idx"] to noteIndex.
        set channelData[channel]["startBeat"] to startBeat.
        local endBeat is channelData[channel]["endBeat"].
        if endBeat < 0 and endBeat <> startBeat {
            // Insert a dummy rest before this first note to pad out
            // the time up to now (in case it's not the only channel and isn't
            // supposed to start yet at the beginning of the song.)
            // error("Inserting rest").
            local restDuration is startBeat.
            local nt is note("r", round(restDuration / (4*clockPerQuarter), 5)).
            channelSongs[channel]:add(nt).
        }
    }
    // a note has started for this channel:
    set channelData[channel]["pendingNote"] to true.
}

global channelSongs is lex().

function endNote {
    parameter split.
    // print split.
    local channel is parseInt(split[3]:trim).
    local noteIndex is parseInt(split[4]:trim).
    local endBeat is parseInt(split[1]:trim).
    local currentNote is channelData[channel]["idx"].

    if not channelSongs:haskey(channel) {
        channelSongs:add(channel, list()).
    }
    local startBeat is channelData[channel]["startBeat"].
    set channelData[channel]["endBeat"] to endBeat.

    local beatDuration is endBeat - startBeat.
    local duration is round(beatDuration / (4*clockPerQuarter), 5).

    // TODO: The last value in the CSV line is "velocity", which
    // basically means volume ('velocity' as in how hard you hit
    // the piano keyboard).  We should read that and use it in the
    // note() constructor.
    local nt is note(noteList[currentNote], duration).
    // a couple of other methods I tried first:
    // local nt is note(noteList[currentNote], duration, duration * .9, 10).
    // local nt is note(noteList[currentNote], duration * .9, duration).
    channelSongs[channel]:add(nt).
    set channelData[channel]["idx"] to -1.
    set channelData[channel]["startBeat"] to -1.
    // The prev note has ended for this channel:
    set channelData[channel]["pendingNote"] to false.
}


local vfile is open(playMidiCsv_filePath).
local content is vfile:readall().

for line in content {
    print "eraseme: " + line.
    local split is line:split(",").
    if split:length > 5 and split[2]:contains(NotePrefix) {
    // if split:length > 5 and (split[0]:trim = "2") {
        if split[2]:trim = NoteStartString and split[5]:trim <> "0" {
            startNote(split).
        }
        else if split[2]:trim = NoteEndString or split[5]:trim = "0" {
            endNote(split).
        }
    }
    else if split[2]:trim = "Tempo" {
        local microSecondsPerQNote is parseInt(split[3]:trim).
        global secondsPerWholeNote is microSecondsPerQNote * 4 / 1000000.
    }
    else if split[2]:trim = "Header" {
        set clockPerQuarter to parseInt(split[5]:trim).
    }
}
wait 0.
for key in channelSongs:keys {
    local voice is getvoice(key).
    set voice:wave to waveParameter.
    set voice:tempo to secondsPerWholeNote / speedParameter.
    set voice:release to 0.125.
    set voice:attack to 0.04.
    set voice:decay to 0.125.
    set voice:sustain to 0.4.
    alert("VoiceTempo: " + voiceTempo).
    alert("Begin Playing").
    voice:play(channelSongs[key]).
    log "---------------- VOICE " + key + " --------------" to "testnotes.txt". // eraseme
    log " " + channelSongs[key] to "testnotes.txt". // eraseme
    // uncomment the following lines to play voices indepedantly
    // wait until not voice:isplaying.
    // alert("Finish Playing").
}
wait until not getvoice(0):isplaying.
alert("Finish Playing").

}
