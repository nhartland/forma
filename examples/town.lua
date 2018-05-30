-- town.lua
-- Generates a plausible small town layout. Following a simmilar setup to the
-- corridor example but with more post-processing.

local rule = require('rule')
local util = require('util')
local pattern = require('pattern')
local automata = require('automata')
local categories = require('categories')
local neighbourhood = require('neighbourhood')
math.randomseed(os.time())

local sq = pattern.square(20,10)
local tp = pattern.new()
local seed = pattern.rpoint(sq)
pattern.insert(tp, seed.x, seed.y)

-- Complicated ruleset
local moore = rule.new(neighbourhood.moore(),      "B12/S012345678")
local diag  = rule.new(neighbourhood.diagonal(),   "B0123/S01234")
local diag2 = rule.new(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = rule.new(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {diag2, diag, vn, moore}

repeat
	local converged
	tp, converged = automata.grow(tp, sq, ruleset)
until converged == true

tp = pattern.edge(tp) -- Comment this out and you get the 'sewerage system'
tp = pattern.enlarge(tp,4)
tp = pattern.surface(tp)
local point_types = categories.generate(neighbourhood.von_neumann())
local segments = categories.find_all(tp, point_types)
util.pretty_print(tp, segments, categories.von_neumann_utf8())

