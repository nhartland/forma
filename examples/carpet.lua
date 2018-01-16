-- carpet.lua
-- Demonstration of forma cellular automata growth methods
-- Here a nice carpet pattern generator is specified

local cell = require('cell')
local rule = require('rule')
local pattern = require('pattern')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

local sq = pattern.square(5,5)
local rp = pattern.rpoint(sq)
local rn = pattern.new()
pattern.insert(rn, rp.x, rp.y)
-- Moore neighbourhood rule
local moore = rule.new(neighbourhood.moore(), "B12/S345678")
repeat
	local converged
	rn, converged = cell.grow(rn, sq, {moore})
    rn.onchar, rn.offchar = "X"," "
    local rflct = pattern.hreflect(rn)
    rflct = pattern.vreflect(rflct)
    rflct = pattern.vreflect(rflct)
    rflct = pattern.hreflect(rflct)
    rflct = pattern.hreflect(rflct)
    if converged == true then print(rflct) end
until converged == true 
