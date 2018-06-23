-- town.lua
-- Generates a plausible small town layout. Following a similar setup to the
-- corridor example but with more post-processing.

local pattern       = require('forma.pattern')
local automata      = require('forma.automata')
local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')
math.randomseed(os.time())

local sq = primitives.square(20,10)
local seed = pattern.rcell(sq)
local tp = pattern.new():insert(seed.x, seed.y)

-- Complicated ruleset
local moore = automata.rule(neighbourhood.moore(),      "B12/S012345678")
local diag  = automata.rule(neighbourhood.diagonal(),   "B0123/S01234")
local diag2 = automata.rule(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = automata.rule(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {diag2, diag, vn, moore}

repeat
    local converged
    tp, converged = automata.async_iterate(tp, sq, ruleset)
until converged == true

tp = pattern.edge(tp) -- Comment this out and you get a subsystem
tp = pattern.enlarge(tp,4)
tp = pattern.surface(tp)

-- Pretty print according to neighbourhood
local nbh = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(tp, nbh)
subpattern.pretty_print(tp, segments, nbh:category_label())

