--- Pattern generation by Cellular Automata
-- @module forma.automata
local automata= {}

local thispath = select('1', ...):match(".+%.") or ""
local pattern = require(thispath .. 'pattern')
local util = require(thispath .. 'util')

--- Cellular automata rule parsing.
-- Takes a string signature i.e "X1234" and converts it into a boolean lookup-table
-- @param nbh the requested neighbourhood of the rule
-- @param rulesub the string signature in question
-- @return a boolean look-up table for the rule
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

--- Defines a cellular automata ruleset.
-- Takes a string signature in the 'Golly' format (BXX/SXX).
-- @param neighbourhood specifying the neighbourhood the rule is to be applied in
-- @param rulesig string specifying the ruleset (i.e B23/S1)
-- @return a verified rule for CA
function automata.rule(neighbourhood, rulesig)
    assert(type(neighbourhood) == 'table', "forma.automata.rule: first argument must be a neighbourhood table")
    assert(type(rulesig) == 'string', "forma.automata.rule: parse_rules trying to parse a " .. type(rulesig))
	local Bpos, Spos = string.find(rulesig, 'B'), string.find(rulesig, 'S')
	assert(Bpos == 1 and Spos ~= nil, "forma.automata.rule: parse_rules cannot understand rule " .. rulesig)
    local Brule, Srule = string.sub(rulesig, 1, Spos-2), string.sub(rulesig, Spos, #rulesig)
	local newrule = {neighbourhood = neighbourhood}
    newrule.B = parse_rule(neighbourhood, Brule)
    newrule.S = parse_rule(neighbourhood, Srule)
	return newrule
end

--- Pattern neighbour count.
-- Counts how many adjacent points there are to vec
-- @param pa provided pattern for neighbour count
-- @param pt point in pattern for neighbour count
-- @param nbh neighbourhood for testing
-- @return square forma.pattern of size {x,y}
local function nCount(pa, pt, nbh)
	local n = 0
	for i=1,#nbh,1 do
		local tpt = pt + nbh[i]
		if pa:has_cell(tpt.x, tpt.y) then n = n + 1 end
	end
	return n
end

--- Ruleset pass/fail analysis
-- This function assesses whether or not a cell should be alive
local function check_cell(ruleset, ipattern, ipoint)
    local alive_cell = true -- Start by assuming the cell will be alive
     for i=1, #ruleset, 1 do
        local irule = ruleset[i]
        assert(irule ~= nil, "forma.automata check_cell: nil element found in ruleset")
	    local count = nCount(ipattern, ipoint, irule.neighbourhood)
	    local alive = ipattern:has_cell(ipoint.x, ipoint.y)
	    if     alive == false and irule.B[count] ~= true then  -- Birth
             alive_cell = false break
	    elseif alive == true  and irule.S[count] ~= true then  -- Survival
             alive_cell = false break
	    end
     end
    return alive_cell
end

--- Cellular automata iteration.
-- Performs one CA tick on pattern prevp in the specified domain
-- @param prevp the previous iteration of the pattern
-- @param domain the points in which the CA operates
-- @param ruleset a list of forma.rules for performing the CA on
-- @return the next iteration, and a bool specifying if convergence has been reached.
function automata.iterate(prevp, domain, ruleset)
	assert(getmetatable(prevp) == pattern,
           "forma.automata: iterate requires a pattern as a first argument")
	assert(getmetatable(domain) == pattern,
           "forma.automata: iterate requires a pattern as a second argument")
	local nextp = pattern.new()
    for i=1, #domain.pointset, 1 do
        local v = domain.pointset[i]
        local alive_cell = check_cell(ruleset, prevp, v)
		if alive_cell == true then nextp:insert(v.x, v.y) end
	end
	local converged = (nextp:size() == prevp:size()) and (nextp-prevp):size() == 0
	return nextp, converged
end

--- Cellular automata growth.
-- Performs one CA tick on pattern prevp in the specified domain
-- but only adding one cell at a time at the edge of an existing pattern
-- @param prevp the previous iteration of the pattern
-- @param domain the points in which the CA operates
-- @param ruleset a list of forma.rules for performing the CA on
-- @param rng a (optional) random number generator (syntax as per math.random).
-- @return the next iteration, and a bool specifying if convergence has been reached.
function automata.grow(prevp, domain, ruleset, rng)
	assert(getmetatable(prevp)  == pattern,
           "forma.automata: grow requires a pattern as a first argument")
	assert(getmetatable(domain) == pattern,
           "forma.automata: grow requires a pattern as a second argument")
    -- Compute all cells that could change under this ruleset
    local mutable_cells = pattern.new()
    for _, rule in ipairs(ruleset) do
	    mutable_cells = mutable_cells + prevp:edge(rule.neighbourhood)
    end
    local testdomain = pattern.intersection(mutable_cells, domain)
    local testpoints = testdomain:pointlist()
    util.fisher_yates(testpoints, rng)
    for i=1, #testpoints, 1 do
       if check_cell(ruleset, prevp, testpoints[i]) == true then
           local nextp = pattern.clone(prevp)
           nextp:insert(testpoints[i].x, testpoints[i].y)
	       return nextp, false
       end
    end
    return prevp, true
end

return automata
