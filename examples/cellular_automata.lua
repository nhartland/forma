-- cellular_automata.lua
-- Demonstration of classic cellular-automata cave generation (4-5 rule)

local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')

math.randomseed( os.time() )

-- Domain for CA
local sq = primitives.square(80,20)

-- CA initial condition: sample at random from the domain
local ca = subpattern.random(sq, math.floor(sq:size()*0.5))

-- Moore neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, sq, {moore})
    ite = ite+1
end

ca.onchar, ca.offchar = "#", " "
print(ca)
