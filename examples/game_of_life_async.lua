-- life.lua
-- Demonstration of a 'Game of Life' rule

local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')
math.randomseed( os.time() )

local print_every_iteration = false

-- Domain and seed
local sq = primitives.square(40,20)
local rn = subpattern.random(sq, 0.5)

-- vonNeumann neighbourhood for pretty printing
local nbh = neighbourhood.von_neumann()

-- Game of life rule
-- The async rule converges quite well with an alterative : "B3/S123"
local life = automata.rule(neighbourhood.moore(), "B3/S23")
local counter, maxcounter = 0, 500
repeat
    counter = counter + 1
    local converged
    rn, converged = automata.async_iterate(rn, sq, {life})

    if print_every_iteration then
        local reflect = rn:hreflect()
        local segments = subpattern.neighbourhood_categories(reflect, nbh)
        os.execute("clear")
        subpattern.pretty_print(reflect, segments, nbh:category_label())
    end
until converged == true or counter == maxcounter

local reflect = rn:hreflect()
local segments = subpattern.neighbourhood_categories(reflect, nbh)
subpattern.pretty_print(reflect, segments, nbh:category_label())
