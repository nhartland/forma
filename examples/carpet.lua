-- carpet.lua
-- Demonstration of forma cellular automata growth methods
-- Here a nice carpet pattern generator is specified

local rule = require('rule')
local util = require('util')
local pattern = require('pattern')
local automata = require('automata')
local categories = require('categories')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

-- Domain and seed
local sq = pattern.square(10,5)
local rp = sq:rpoint()

local rn = pattern.new()
rn:insert(rp.x, rp.y)

-- Moore neighbourhood rule
local moore = rule.new(neighbourhood.moore(), "B12/S345678")
repeat
	local converged
	rn, converged = automata.grow(rn, sq, {moore})
    rn.onchar, rn.offchar = "X"," "
    local rflct = rn:hreflect()
    rflct = rflct:vreflect():vreflect()
    rflct = rflct:hreflect():hreflect()
    if converged == true then
        print(rflct)
        local point_types = categories.generate(neighbourhood.von_neumann())
        local segments = categories.find_all(rflct, point_types)
        util.pretty_print(rflct, segments, categories.von_neumann_utf8())
    end
until converged == true
