function playsong {
  parameter song.

  song["setup"]:call().
  for vNum in song["voices"] {
    getvoice(vNum):play(song[vNum]).
  }
}