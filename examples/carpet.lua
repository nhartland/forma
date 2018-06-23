-- carpet.lua.
-- Using Async Cellular Automata with symmetrising methods.
-- Demonstration of pattern generation by asynchronous cellular automata
-- Here a small basic pattern is generated, which is then enlarged by
-- reflection into a nicely symmetric larger pattern.

local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

math.randomseed( os.time() )

-- Initial CA domain
local sq = primitives.square(10,5)

-- Make a new pattern consisting of a random (seed) cell from the domain
local rn = pattern.new()
local rp = sq:rcell()
rn:insert(rp.x, rp.y)

-- Moore neighbourhood rule
local moore = automata.rule(neighbourhood.moore(), "B12/S012345678")

repeat
    -- Perform asynchronous CA update
    local converged
    rn, converged = automata.async_iterate(rn, sq, {moore})

    if converged == true then
        -- Mirror the basic pattern a couple of times
        local rflct = rn:hreflect()
        rflct = rflct:vreflect():vreflect()
        rflct = rflct:hreflect():hreflect()
        -- Categorise the pattern according to possible vN neighbours and print to screen
        local vn = neighbourhood.von_neumann()
        local segments = subpattern.neighbourhood_categories(rflct, vn)
        subpattern.pretty_print(rflct, segments, vn:category_label())
    end
until converged == true
