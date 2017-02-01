print "Copying land_it files and nothing else.".
switch to 1.
createdir("/lib/").
createdir("/songs/").
copypath("0:/land_it.ks","").
copypath("0:/lib/land.ks","/lib/").
copypath("0:/lib/isp.ks","/lib/").
copypath("0:/lib/song.ks","/lib/").
copypath("0:/songs/happy.ks","/songs/").
copypath("0:/songs/sad.ks","/songs/").
cd("/lib"). list.
cd("/songs"). list.
cd("/"). list.
