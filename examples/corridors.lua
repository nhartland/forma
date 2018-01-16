-- corridors.lua
-- Demonstration of forma growth automata functions
-- Generates a plausible corridor system in a 50x20 box

-- 'Growth automata' follow the same 'birth' rules as normal CA,
-- but the survival rule is ignored (all cells survive). Every iteration
-- of the growth automata adds only one cell.

local cell = require('cell')
local rule = require('rule')
local neighbourhood = require('neighbourhood')
local pattern = require('pattern')
math.randomseed(os.time())

local sq = pattern.square(50,20)
local tp = pattern.new()
local seed = pattern.rpoint(sq)
pattern.insert(tp, seed.x, seed.y)

-- Complicated ruleset
local moore = rule.new(neighbourhood.moore(),      "B12/S012345678")
local diag  = rule.new(neighbourhood.diagonal(),   "B0123/S01234")
local diag2 = rule.new(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = rule.new(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {diag2, diag, vn, moore}

local ite = 0
repeat
	local converged
	tp, converged = cell.grow(tp, sq, ruleset)
    tp.offchar, tp.onchar = " ", "X"
	print(tp) ite = ite+1
until converged == true

print("Converged in " .. tostring(ite) .. " iterations")

