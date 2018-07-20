-- Combining cellular automata rules
-- Here the way multiple CA rules can be combined into a single ruleset is
-- demonstrated. A asynchronous cellular automata with a complicated ruleset
-- generates an interesting 'corridor' like pattern.

local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

-- Generate a domain, and an initial state ca with one random seed cell
local domain = primitives.square(80,20)
local ca = subpattern.random(domain, 1)

-- Complicated ruleset, try leaving out or adding more rules
local moore = automata.rule(neighbourhood.moore(),      "B12/S012345678")
local diag  = automata.rule(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = automata.rule(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {vn, moore, diag}

repeat
    local converged
    ca, converged = automata.async_iterate(ca, domain, ruleset)
until converged

local nbh = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(ca, nbh)
subpattern.print_patterns(domain, segments, nbh:category_label())
