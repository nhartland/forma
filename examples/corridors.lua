-- Combining cellular automata rules
-- Here the way multiple CA rules can be combined into a single ruleset is
-- demonstrated. A asynchronous cellular automata with a complicated ruleset
-- generates an interesting 'corridor' like pattern.

local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

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

repeat
    local converged
    tp, converged = automata.async_iterate(tp, sq, ruleset)
until converged

local nbh = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(tp, nbh)
subpattern.print_patterns(tp, segments, nbh:category_label())
