-- Cellular automata
-- Demonstration of classic cellular-automata cave generation (4-5 rule).
local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')

-- Domain for CA
local sq = primitives.square(80,20)

-- CA initial condition: sample at random from the domain
local ca = subpattern.random(sq, 800)

-- Moore neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, sq, {moore})
    ite = ite+1
end

-- Print to stdout
subpattern.print_patterns(sq, {ca}, {'#'})
