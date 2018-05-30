--- Pattern generation by Cellular Automata
-- @module forma.automata
local automata= {}

local thispath = select('1', ...):match(".+%.") or ""
local pattern = require(thispath .. 'pattern')
local rule = require(thispath .. 'rule')
local util = require(thispath .. 'util')

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
        local alive_cell = rule.check(ruleset, prevp, v)
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
           "forma.automata: iterate requires a pattern as a first argument")
	assert(getmetatable(domain) == pattern,
           "forma.automata: iterate requires a pattern as a second argument")
    local testdomain = pattern.intersection(prevp:edge(), domain)
    local testpoints = testdomain:pointlist()
    util.fisher_yates(testpoints, rng)
    for i=1, #testpoints, 1 do
       if rule.check(ruleset, prevp, testpoints[i]) == true then
           local nextp = pattern.clone(prevp)
           nextp:insert(testpoints[i].x, testpoints[i].y)
	       return nextp, false
       end
    end
    return prevp, true
end

return automata
