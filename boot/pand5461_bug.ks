@lazyglobal off.
wait until ship:loaded and ship:unpacked.
print "Proof I am running.".
if homeconnection:isconnected and homeconnection:delay <= 2 {
  compile "0:/pand5461_test.ks" to "1:/pand5461_test.ksm".
}

runpath("pand5461_test.ksm").
lock steering to up.
