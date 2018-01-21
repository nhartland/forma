-- utility.lua
--- Utilities

local utl = {}

--- C++ style pop-and-swap for unordered lists.
-- @param lst input list.
-- @param t target to be removed from list.
-- @return true if target is found and removed, false if not
function utl.popandswap(lst, t)
	for i=1,#lst,1 do
	    if lst[i] == t then
	        lst[i] = lst[#lst]
	        lst[#lst] = nil
	        return true
	    end
	end
	return false
end

-- Returns true if element e is present in list t, false otherwise
function utl.intable(e, t)
    assert(type(t) == 'table')
    for i=1,#t,1 do
        if e == t[i] then return true end
    end return false
end

-- Fisher-Yates shuffle
-- Returns a shuffled version of the input table
function utl.fisher_yates(table, rng)
  if rng == nil then rng = math.random end
  for i=#table,1,-1 do
    local j = rng(#table)
    table[i], table[j] = table[j], table[i]
  end
end

return utl
