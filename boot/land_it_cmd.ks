wait 2. // need to let Remote tech find itself.
print "copying files".
if not exists("1:/lib/") createdir("1:/lib").
if not exists("1:/songs/") createdir("1:/songs").
copypath("0:/lib/isp.ks","1:/lib/").
copypath("0:/lib/song.ks","1:/lib/").
copypath("0:/lib/land.ks","1:/lib/").
copypath("0:/lib/sanity.ks","1:/lib/").
copypath("0:/lib/ro.ks","1:/lib/").
copypath("0:/songs/sad.ks","1:/songs/").
copypath("0:/songs/happy.ks","1:/songs/").
copypath("0:/land_it_vary.ks","1:/").

