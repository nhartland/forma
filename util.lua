--- Utilities
-- @module forma.util

local util = {}
local pattern = require('pattern')

--- C++ style pop-and-swap for unordered lists.
-- @param lst input list.
-- @param t target to be removed from list.
-- @return true if target is found and removed, false if not
function util.popandswap(lst, t)
	for i=1,#lst,1 do
	    if lst[i] == t then
	        lst[i] = lst[#lst]
	        lst[#lst] = nil
	        return true
	    end
	end
	return false
end

--- Method for checking if an element is in a list.
-- @param e element to check for in list.
-- @param t input list.
-- @return true if e is present in t, false if not
function util.intable(e, t)
    assert(type(t) == 'table')
    for i=1,#t,1 do
        if e == t[i] then return true end
    end return false
end

--- Fisher-Yates shuffle.
-- Performs an in-place shuffle of the input table
-- @param table the table to be shuffled.
-- @param rng a random number generator (syntax as per math.random).
function util.fisher_yates(table, rng)
  if rng == nil then rng = math.random end
  for i=#table,1,-1 do
    local j = rng(#table)
    table[i], table[j] = table[j], table[i]
  end
end

--- Pretty print a list of forma.patterns.
-- Prints a list of pattern segments to the terminal, with a given list of
-- chars per segment.
-- @param domain the basic patterns from which the segments are drawn.
-- @param segments the table of segments to be drawn.
-- @param chars the characters to be printed for each segment.
function util.pretty_print(domain, segments, chars)
    print('$')
    -- Print out the segments to a map
    for i=domain.min.y, domain.max.y,1 do
        local string = '.'
        for j=domain.min.x, domain.max.x,1 do
            local token = ' '
            for k,v in ipairs(segments) do
            if pattern.point(v, j, i) ~= nil then token = chars[k] end end
            string = string .. token
        end 
        print(string)
    end
end

return util
