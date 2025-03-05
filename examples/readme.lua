-- Readme example
-- This generates the example used in the readme. Runs a 4-5 rule CA for 'cave
-- generation and then computes the contiguous sub-patterns and prints them.

-- Load forma modules, lazy init is also available, i.e
-- require('forma')
local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')

-- Generate a square box to run the CA inside
local domain = primitives.square(80,20)

-- CA initial condition: 800-point random sample of the domain
local ca = subpattern.random(domain, 800)

-- Moore (8-cell) neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")

-- Run the CA until converged or 1000 iterations
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, domain, {moore})
    ite = ite+1
end

-- Access a subpattern's cell coordinates for external use
for icell in ca:cells() do
    -- local foo = bar(icell)
    -- or
    -- local foo = bar(icell.x, icell.y)
end

-- Find all 4-contiguous connected components of the CA pattern
-- Uses the von-neumann neighbourhood to determine 'connectedness'
-- but any custom neighbourhood can be used)
local connected_components = subpattern.connected_components(ca, neighbourhood.von_neumann())

-- Print a representation to io.output
subpattern.print_patterns(domain, connected_components)

