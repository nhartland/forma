-- corridors.lua
-- Demonstration of forma growth automata functions
-- Generates a plausible corridor system in an 80x20 box

-- 'Growth automata' follow the same 'birth' rules as normal CA,
-- but the survival rule is ignored (all cells survive). Every iteration
-- of the growth automata adds only one cell.

local util = require('util')
local pattern = require('pattern')
local primitives = require('primitives')
local automata = require('automata')
local categories = require('categories')
local neighbourhood = require('neighbourhood')
math.randomseed(os.time())

local sq = primitives.square(80,20)
local seed = sq:rpoint()

local tp = pattern.new()
tp:insert(seed.x, seed.y)

-- Complicated ruleset (leaving diag2 out provides a denser pattern)
local moore = automata.rule(neighbourhood.moore(),      "B12/S012345678")
local diag  = automata.rule(neighbourhood.diagonal(),   "B0123/S01234")
local diag2 = automata.rule(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = automata.rule(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {diag2, diag, vn, moore}

local ite = 0
local point_types = categories.generate(neighbourhood.von_neumann())
repeat
	local converged
	tp, converged = automata.grow(tp, sq, ruleset)
    ite = ite + 1
    local segments = categories.find_all(tp, point_types)
    os.execute("clear")
    util.pretty_print(tp, segments, categories.von_neumann_utf8())
until converged == true


print("Converged in " .. tostring(ite) .. " iterations")

