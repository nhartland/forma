-- caves.lua
-- Demonstration of classic cellular-automata cave generation (4-5 rule)

local cell = require('cell')
local rule = require('rule')
local pattern = require('pattern')
local neighbourhood = require('neighbourhood')
math.randomseed( os.time() )

local sq = pattern.square(80,20)
local rn = pattern.random(sq, 0.5)
sq.onchar, sq.offchar = "∎", " "

-- Moore neighbourhood rule
local moore = rule.new(neighbourhood.moore(), "B5678/S45678")
local ite = 0
repeat
	local converged
	rn, converged = cell.iterate(rn, sq, {moore})
	print(sq - rn) ite = ite+1
until converged == true

print("Converged in " .. tostring(ite) .. " iterations")

