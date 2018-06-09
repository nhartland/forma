-- corridors.lua
-- Demonstration of forma asynchronous cellular automata
-- Generates a plausible corridor system in an 80x20 box

-- 'asynchronous CA' follow the same rules as normal CA, but the rule is
-- applied at random to only once cell at a time, unlike normal synchronous
-- rules where the whole pattern is updated.

local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

math.randomseed(os.time())

local sq = primitives.square(80,20)
local seed = sq:rcell()

local tp = pattern.new()
tp:insert(seed.x, seed.y)

-- Complicated ruleset (leaving diag2 out provides a denser pattern)
local moore = automata.rule(neighbourhood.moore(),      "B12/S012345678")
local diag  = automata.rule(neighbourhood.diagonal(),   "B0123/S01234")
local diag2 = automata.rule(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = automata.rule(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {diag2, diag, vn, moore}

local ite = 0
repeat
    local converged
    tp, converged = automata.async_iterate(tp, sq, ruleset)
    ite = ite + 1
until converged == true

local nbh = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(tp, nbh)
subpattern.pretty_print(tp, segments, nbh:category_label())
