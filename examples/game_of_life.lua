-- life.lua
-- Demonstration of a 'Game of Life' rule

local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')
math.randomseed( os.time() )

-- Domain and seed
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, math.floor(sq:size()*0.5))

-- vonNeumann neighbourhood for pretty printing
local nbh = neighbourhood.von_neumann()

-- Game of life rule
local life = automata.rule(neighbourhood.moore(), "B3/S23")
local counter, maxcounter = 0, 100
repeat
    counter = counter + 1
    local converged
    rn, converged = automata.iterate(rn, sq, {life})
    local segments = subpattern.neighbourhood_categories(rn, nbh)
    os.execute("clear")
    subpattern.pretty_print(rn, segments, nbh:category_label())
    print(counter .. "/".. maxcounter .. " frames")
until converged == true or counter == maxcounter
