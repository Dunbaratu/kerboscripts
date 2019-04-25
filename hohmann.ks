parameter tgt.

run once "/lib/orbit".

print "Calculating Hohmann transfer Node.".
local Hohmann_node is make_Hohmann_node(tgt).
print "Adding Hohmann transfer Node to flight plan.".
ADD Hohmann_node.
print "Done.".
