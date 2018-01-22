--- Definition of neighbourhood tiling categorisations
-- @module forma.categories
-- Categorises points in a pattern according to their neighbourhood
-- configuration.  For each point in a forma.pattern, there are a finite number
-- of possible configurations of neighbouring points. Specifically, each point
-- has 2^n possible neighbourhood configurations where n is the number of
-- points in the neighbourhood. This module categorised points according to
-- which type of neighbourhood they are in.

-- This is used primarily with the Von-Neumann neighbourhood to convert
-- edges of e.g walls from X  to └
--                         XX
local categories = {}

local thispath = select('1', ...):match(".+%.") or ""
local pattern = require(thispath .. 'pattern')

--- A helper method return utf8 characters for the 16 possible von neumann categories
function categories.von_neumann_utf8()
   return {'┼','├','┴','┤','┬','─','┘','└','│','┌','┐','╷','╴','╶','╵','.'}
end

--- Generate a list of neighbourhood categories.
-- @param neighbourhood the neighbourhood to generate categories for
-- @return a table of possible neighbourhood configurations
function categories.generate(neighbourhood)
    assert(#neighbourhood > 0, "categories.generate requires a non-empty neighbourhood")
    local start_pattern = pattern.new()
    pattern.insert(start_pattern, 0,0)
    local categorisation = {start_pattern}

    for i=1, #neighbourhood, 1 do
        local target_point = neighbourhood[i]
        local existing_categories = #categorisation
        for j=1, existing_categories, 1 do
            local new_pattern = pattern.clone(categorisation[j])
            pattern.insert(new_pattern, target_point.x, target_point.y)
            table.insert(categorisation, new_pattern)
        end
    end
    -- Sort by number of elements and return
    table.sort(categorisation, function(a,b) return a.size > b.size end)
    return categorisation
end

--- Identify which category a point in a pattern fits into.
-- @param ip the input domain pattern
-- @param point the point of interest
-- @param icats the table of possible categories
-- @return the index of 'icats' that 'point' belongs to
function categories.which(ip, point, icats)
    for i=1, #icats, 1 do
        local category = icats[i]
        local shifted = pattern.shift(category, point.x, point.y)
        local inter   = pattern.intersection(ip, shifted)
        if inter.size == category.size then return i end
    end
    assert(false, "categories.which cannot find a valid category")
end


--- Categorise all points in a pattern according to a list of possibilities.
-- @param ip the pattern in which points are to be categorised
-- @param icats the table of possible categories
-- @return a table of #icats patterns, where each point in ip is categorised
function categories.find_all(ip, icats)
    local category_patterns = {}
    for i=1, #icats, 1 do
        category_patterns[i] = pattern.new()
    end

    for i=1, #ip.pointset, 1 do
        local cat = categories.which(ip, ip.pointset[i], icats)
        pattern.insert(category_patterns[cat], ip.pointset[i].x, ip.pointset[i].y)
    end
    return category_patterns
end

return categories

