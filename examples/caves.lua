-- caves.lua
-- Demonstration of classic cellular-automata cave generation (4-5 rule)

local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')
math.randomseed( os.time() )

local sq = primitives.square(80,20)
local rn = subpattern.random(sq, math.floor(sq:size()*0.5))
sq.onchar, sq.offchar = "#", " "

-- Moore neighbourhood rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")
local ite = 0
repeat
    local converged
    rn, converged = automata.iterate(rn, sq, {moore})
    ite = ite+1
until converged == true

print(sq-rn)
