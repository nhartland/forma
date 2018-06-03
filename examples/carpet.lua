-- @script carpet.lua.
-- Using Async Cellular Automata with symmetrising methods.
-- Demonstration of pattern generation by asynchronous cellular automata
-- Here a small basic pattern is generated, which is then enlarged by
-- reflection into a nicely symmetric larger pattern.

local util = require('util')
local pattern = require('pattern')
local primitives = require('primitives')
local automata = require('automata')
local categories = require('categories')
local neighbourhood = require('neighbourhood')

math.randomseed( os.time() )

-- Initial CA domain
local sq = primitives.square(10,5)

-- Make a new pattern consisting of a random (seed) point from the domain
local rn = pattern.new()
local rp = sq:rpoint()
rn:insert(rp.x, rp.y)

-- Moore neighbourhood rule
local moore = automata.rule(neighbourhood.moore(), "B12/S12345678")

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
        local point_types = categories.generate(neighbourhood.von_neumann())
        local segments = categories.find_all(rflct, point_types)
        util.pretty_print(rflct, segments, categories.von_neumann_utf8())
    end
until converged == true
