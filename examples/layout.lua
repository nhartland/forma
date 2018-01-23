-- manor.lua
-- Use of a few different functions to generate some sort of outline 

local cell = require('cell')
local rule = require('rule')
local pattern = require('pattern')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

-- Generate a square domain, and a single point seed
local sq = pattern.square(10,10)
local rp = pattern.rpoint(sq)
local rn = pattern.new()
pattern.insert(rn, rp.x, rp.y)

-- Basic Moore neighbourhood rule
local moore = rule.new(neighbourhood.moore(), "B123/S345678")
repeat
	local converged
	rn, converged = cell.grow(rn, sq, {moore})
until converged == true or pattern.size(rn) == 10

-- Add some symmetry and smear pattern
rn = pattern.hreflect(rn)
local sm = pattern.smear(rn, 3)

-- Print to stdout
rn.onchar, rn.offchar = "X"," "
sm.onchar, sm.offchar = "X"," "
print(rn)
print(sm)


