-- caves.lua
-- Demonstration of classic cellular-automata cave generation

local cell = require('cell')
local rule = require('rule')
local pattern = require('pattern')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

local sq = pattern.square(80,25)
local rn = pattern.random(sq, 0.41)

-- Moore neighbourhood rule
local moore = rule.new(neighbourhood.moore(), "B5678/S345678")
local ite = 0
repeat
	local converged
	rn, converged = cell.iterate(rn, sq, {moore})
    rn.onchar, rn.offchar = "X"," "
	print(rn) ite = ite+1
until converged == true

print("Converged in " .. tostring(ite) .. " iterations")

