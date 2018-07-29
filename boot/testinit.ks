print "Starting boot/test1.ks".
wait until ship:loaded and ship:unpacked.
compile "0:/boot/test1.ks" to "1:/boot/test1.ksm".
compile "0:/test.ks" to "1:/test.ksm".
set core:bootfilename to "/boot/test1.ksm".
print "About to reboot from boot/test1.ks".
reboot.
