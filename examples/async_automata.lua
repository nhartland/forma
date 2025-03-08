-- Asynchronous cellular automata
-- Here the use of an asynchronous cellular automata is demonstrated, making
-- use also of symmetrisation methods to generate a final, symmetric pattern.

local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

-- Domain for CA to operate in
local sq = primitives.square(10,5)

-- Make a new pattern consisting of a single random cell from the domain
local start_point = sq:rcell() -- Select a random point
local ca_pattern  = pattern.new():insert(start_point.x, start_point.y)

-- Moore neighbourhood rule for CA
local moore = automata.rule(neighbourhood.moore(), "B12/S012345678")

-- Perform asynchronous CA update until convergence
local converged = false
while converged == false do
    ca_pattern, converged = automata.async_iterate(ca_pattern, sq, {moore})
end

-- Add some symmetry by mirroring the basic pattern a couple of times
local symmetrised_pattern = ca_pattern:hreflect()
symmetrised_pattern = symmetrised_pattern:vreflect():vreflect()
symmetrised_pattern = symmetrised_pattern:hreflect():hreflect()

-- Categorise the pattern according to possible vN neighbours and print to screen
-- This turns the basic pattern into standard 'box-drawing' characters
local vn = neighbourhood.von_neumann()
subpattern.neighbourhood_categories(symmetrised_pattern, vn)
          :print(vn:category_label())
