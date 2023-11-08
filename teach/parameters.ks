// a program that demonstrates how parameters work.

parameter alt1, alt2.

local GravParam is ship:body:mu.

print "I already know:".
print "GravParam = " +  GravParam.
print "You gave me:".
print "altitude 1 = " + alt1.
print "altitude 2 = " + alt2.

local rad1 is ship:body:radius + alt1.
local rad2 is ship:body:radius + alt2.

print "Formula result is:".

local result is sqrt(GravParam/rad1)*(sqrt(2*rad2/(rad1+rad2))-1).

print result.
