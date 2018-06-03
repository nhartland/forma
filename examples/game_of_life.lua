-- life.lua
-- Demonstration of a 'Game of Life' rule

local util = require('util')
local subpattern = require('subpattern')
local primitives = require('primitives')
local automata = require('automata')
local categories = require('categories')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

-- Domain and seed
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 0.5)

-- Game of life rule
local life = automata.rule(neighbourhood.moore(), "B3/S23")
local counter, maxcounter = 0, 100
repeat
    counter = counter + 1
	local converged
	rn, converged = automata.iterate(rn, sq, {life})
    local point_types = categories.generate(neighbourhood.von_neumann())
    local segments = categories.find_all(rn, point_types)
    os.execute("clear")
    util.pretty_print(rn, segments, categories.von_neumann_utf8())
    print(counter .. "/".. maxcounter .. " frames")
until converged == true or counter == maxcounter
