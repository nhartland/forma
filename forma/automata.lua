--- Pattern manipulation with Cellular Automata.
--
-- Cellular Automata are defined here by two parameters. Firstly a
-- `neighbourhood` that the rule acts on. Secondly a `rule` specifying the
-- conditions under which cells are *Born* (B) or *Survive* (S). These rules
-- are initialised with a string rule in the "Golly" format. i.e a rule which
-- activates cells with one neighbour and deactivates cells with two would have
-- the rule string "B1/S2". The neighbourhood is specified by an instance of
-- the `neighbourhood` submodule as usual.
--
-- Once a rule is specified, there are two provided implementations of a CA.
-- Firstly the standard *synchronous* CA is implemented in `automata.iterate`
-- whereby all cells are updated simultaneously. Secondly an *asynchronous*
-- update is provided in `automata.async_iterate` in which each iteration
-- updates only one cell at random.
--
-- For both methods, multiple rules can be applied simultaneously through the
-- ruleset by supplying a table containting more than one `rule`. Rule
-- conflicts are resolved in favour of cell deactivation, i.e if there are two
-- nested rulesets, with a cell passing one and failing the other either
-- survival or birth rules, the cell will be deactivated in the next iteration.
--
-- All CA updates here are only possible on a *finite* domain of cells. That
-- domain must be specified as a `pattern` in the iteration call.
--
-- Both the synchronous and asynchronous iterations return the result of one CA
-- iteration and a bool specifying whether or not the iteration has converged
-- to a stable pattern.
--
--### Relevant examples
--
-- - @{cellular_automata.lua}
-- - @{async_automata.lua}
--
-- @module forma.automata
local automata= {}

local pattern = require('forma.pattern')

-- Cellular automata rule parsing.
-- Takes a string signature i.e "X1234" and converts it into a boolean lookup-table
-- @param nbh the requested neighbourhood of the rule
-- @param rulesub the string signature in question
-- @return A boolean look-up table for the rule
local function parse_rule(nbh, rulesub)
    local ruletable = {}
    for i=2,#rulesub,1 do
        local nv = tonumber(string.sub(rulesub,i,i))
        assert(nv ~= nil, "forma.automata attempting to parse nil rulesub: " .. rulesub .." " ..string.sub(rulesub,i,i))
        assert(nv >= 0, nv <= #nbh,  "Requested rule " .. rulesub .. " cannot be accomodated into neighbourhood")
        assert(ruletable[nv] == nil, "Requested rule " .. rulesub .. " includes duplicate values")
        ruletable[nv] = true
    end
    return ruletable
end

--- Ruleset Generation
-- @section

--- Define a cellular automata rule.
-- CA rules in forma are defined by a `neighbourhood` in the usual CA sense and
-- a string signature in the 'Golly' format (BXX/SXX). This function
-- initialises a rule, and performs a few consistency checks.
-- @usage
--  -- Initialise a rule corresponding to Conway's Game of Life
--  local gol_rule = automata.rule(neighbourhood.moore(), "B3/S23")
-- @param neighbourhood specifying the `neighbourhood` the rule is to be applied in.
-- @param rule_string string specifying the ruleset (i.e B23/S1).
-- @return A verified rule for use with the CA methods.
function automata.rule(neighbourhood, rule_string)
    assert(type(neighbourhood) == 'table', "forma.automata.rule: first argument must be a neighbourhood table")
    assert(type(rule_string) == 'string', "forma.automata.rule: parse_rules trying to parse a " .. type(rule_string))
    local Bpos, Spos = string.find(rule_string, 'B'), string.find(rule_string, 'S')
    assert(Bpos == 1 and Spos ~= nil, "forma.automata.rule: parse_rules cannot understand rule " .. rule_string)
    local Brule, Srule = string.sub(rule_string, 1, Spos-2), string.sub(rule_string, Spos, #rule_string)
    local newrule = {neighbourhood = neighbourhood}
    newrule.B = parse_rule(neighbourhood, Brule)
    newrule.S = parse_rule(neighbourhood, Srule)
    return newrule
end

-- Pattern neighbour count.
-- Counts how many adjacent cells there are to a cell at (ix, iy)
-- @param pa provided pattern for neighbour count
-- @param nbh neighbourhood for testing
-- @param ix x-coordinate of point check
-- @param iy y-coordinate of point check
-- @return Number of active cells in the neighbourhood of cell (ix, iy)
local function nCount(pa, nbh, ix, iy)
    local n = 0
    for i=1,#nbh,1 do
        local x, y = ix+nbh[i].x, iy+nbh[i].y
        if pa:has_cell(x, y) then n = n + 1 end
    end
    return n
end

-- Ruleset pass/fail analysis
-- This function assesses whether or not a cell should be alive
local function check_cell(ruleset, ipattern, ix, iy)
    local alive = ipattern:has_cell(ix, iy)
    if alive == false then -- Check Birth
        for i=1, #ruleset, 1 do
            local irule = ruleset[i]
            local count = nCount(ipattern, irule.neighbourhood, ix, iy)
            if irule.B[count] == nil then return false end
        end
    else -- Check Survival
        for i=1, #ruleset, 1 do
            local irule = ruleset[i]
            local count = nCount(ipattern, irule.neighbourhood, ix, iy)
            if irule.S[count] == nil then return false end
        end
    end
    return true
end

-- Check that the ruleset has no nil entries
local function check_ruleset(ruleset)
    for i=1, #ruleset, 1 do
        assert(ruleset[i], "forma.automata check_ruleset: nil element found in ruleset")
        assert(ruleset[i].B, "forma.automata check_ruleset: invalid rule found in ruleset")
        assert(ruleset[i].S, "forma.automata check_ruleset: invalid rule found in ruleset")
    end
end

--- CA Iteration
-- @section

--- Synchronous cellular automata iteration.
-- Performs one standard synchronous CA update on pattern prevp in the specified domain.
-- @usage
--  -- Domain and initial state (500 seed points) for the CA
--  local domain = primitives.square(100)
--  local ca_pat = subpattern.random(sq, 500)
--  -- Repeat iteration until convergence is reached
--  local converged = false
--  repeat
--  	ca_pat, converged = automata.iterate(ca_pat, domain, {gol_rule})
--  until converged == true
-- @param prevp the previous iteration of the pattern
-- @param domain the cells in which the CA operates
-- @param ruleset a table of forma.rules defining the CA
-- @return The result of the CA iteration [pattern].
-- @return Convergence flag [bool: true if converged, false otherwise].
function automata.iterate(prevp, domain, ruleset)
    assert(getmetatable(prevp) == pattern,
    "forma.automata: iterate requires a pattern as a first argument")
    assert(getmetatable(domain) == pattern,
    "forma.automata: iterate requires a pattern as a second argument")
    check_ruleset(ruleset)
    local nextp = pattern.new()
    for x, y in domain:cell_coordinates() do
        local alive_cell = check_cell(ruleset, prevp, x, y)
        if alive_cell == true then nextp:insert(x, y) end
    end
    local converged = (nextp:size() == prevp:size()) and (nextp-prevp):size() == 0
    return nextp, converged
end

--- Asynchronous cellular automata iteration.
-- Performs a CA update on one cell (chosen randomly) in the specified domain.
-- This corresponds to a 'random independent scheme' update.
-- @usage
--  -- Domain and initial state (500 seed points) for the CA
--  local domain = primitives.square(100)
--  local ca_pat = subpattern.random(sq, 500)
--  local rng    = math.random
--  -- Repeat iteration until convergence is reached
--  local converged = false
--  repeat
--  	ca_pat, converged = automata.async_iterate(ca_pat, domain, {gol_rule}, rng)
--  until converged == true
-- @param prevp the previous iteration of the pattern
-- @param domain the cells in which the CA operates
-- @param ruleset a table of forma.rules defining the CA
-- @param rng a (optional) random number generator (syntax as per math.random).
-- @return The result of the CA iteration [pattern].
-- @return Convergence flag [bool: true if converged, false otherwise].
function automata.async_iterate(prevp, domain, ruleset, rng)
    if rng == nil then rng = math.random end
    assert(getmetatable(prevp)  == pattern,
    "forma.automata: async_iterate requires a pattern as a first argument")
    assert(getmetatable(domain) == pattern,
    "forma.automata: async_iterate requires a pattern as a second argument")
    check_ruleset(ruleset)
    for tp in domain:shuffled_cells(rng) do
        local check = check_cell(ruleset, prevp, tp.x, tp.y)
        if prevp:has_cell(tp.x, tp.y) and check == false then
            -- Copy old pattern, subtracting off newly deactivated cell
            local nextp = prevp - pattern.new():insert(tp.x, tp.y)
            return nextp, false
        elseif prevp:has_cell(tp.x, tp.y) == false and check == true then
            -- Activate new cell
            local nextp = prevp + pattern.new():insert(tp.x, tp.y)
            return nextp, false
        end
    end
    return prevp, true
end

return automata
