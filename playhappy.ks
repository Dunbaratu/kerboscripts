runoncepath( "lib/song" ).
runoncepath( "songs/happy.ks" ).
playsong(song_happy).
print "testing song...".
wait until not getvoice(0):isplaying.
wait until not getvoice(1):isplaying.
print "done testing song...".