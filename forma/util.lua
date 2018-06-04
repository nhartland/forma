--- Utility functions - primarily for internal use.
-- @module forma.util

local util = {}

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
-- Prints a list of pattern segments to `io.output`. If provided, a table
-- of segment labels can be used, with one entry per segment.
-- @param domain the basic patterns from which the segments are drawn.
-- @param segments the table of segments to be drawn.
-- @param chars the characters to be printed for each segment (optional).
function util.pretty_print(domain, segments, chars)
    -- If no dictionary is supplied generate a new one (starting from '0')
    if chars == nil then
        chars = {}
        for i=1, #segments, 1 do table.insert(chars, string.char(i+47)) end
    end
    -- Print out the segments to a map
    for i=domain.min.y, domain.max.y,1 do
        local string = ''
        for j=domain.min.x, domain.max.x,1 do
            local token = ' '
            for k,v in ipairs(segments) do
            if v:has_cell(j, i) then token = chars[k] end end
            string = string .. token
        end
        io.write(string .. '\n')
    end
end

return util
