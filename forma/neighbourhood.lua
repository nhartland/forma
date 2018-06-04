---  Cell neighbourhood definitions
-- @module forma.neighbourhood
local neighbourhood = {}
local point = require('forma.point')

-- Neighbourhood indexing
-- For enabling syntax sugar neighbourhood:method
neighbourhood.__index = neighbourhood

--- Generate a list of possible neighbourhood configurations.
-- Categorises points in a pattern according to their neighbourhood
-- configuration. For each point in a forma.pattern, there are a finite number
-- of possible configurations of neighbouring points. Specifically, each point
-- has 2^n possible neighbourhood configurations where n is the number of
-- points in the neighbourhood. This module categorised points according to
-- which type of neighbourhood they are in.
-- @param neighbour_cells the neighbourhood to generate categories for
-- @return a table categorising possible neighbourhood configurations
-- Maybe have this run on demand, rather than always building this for all
-- neighbourhoods?
local function generate_categories(neighbour_cells)
    assert(#neighbour_cells > 0, "categories.generate requires a non-empty neighbourhood")
    local categories = {point.new(0,0)}

    for i=1, #neighbour_cells, 1 do
        local target_point = neighbour_cells[i]
        for j=1, #categories, 1 do
            local new_category = {point.clone(target_point)}
            for k=1, #categories[j], 1 do
                table.insert(new_category, categories[j][k])
            end
            table.insert(categories, new_category)
        end
    end
    -- Sort by number of elements and return
    table.sort(categories, function(a,b) return #a > #b end)
    return categories
end

--- Generate a new neighbourhood from a set of cells
-- @param neighbour_cells a list of neighbouring cell vectors
-- @return a forma.neighbourhood comprised of `neighbour_cells`
function neighbourhood.new(neighbour_cells)
    assert(#neighbour_cells > 0, "neighbourhood.new requires a non-empty list of neighbouring cells")
    local nbh = {}
    for _,v in ipairs(neighbour_cells) do
        table.insert(nbh, point.clone(v))
    end
    nbh.categories = generate_categories(nbh)
    nbh = setmetatable(nbh, neighbourhood)
    return nbh
end

--- Identify which category a point in a pattern fits into.
-- @param nbh the forma.neighbourhood to categorise the point in
-- @param ip the input pattern
-- @param ipoint the point in `ip` of interest
-- @return the index of 'icats' that 'point' belongs to
-- This assumes that the categories table is sorted - should fix this
function neighbourhood.categorise(nbh, ip, ipoint)
    for i=1, #nbh.categories, 1 do
        local category = nbh.categories[i]
        local match_cells = true
        for j=1, #category, 1 do
            local np = ipoint + category[j]
            if ip:has_cell(np.x, np.y) == false then
                match_cells = false
            end
        end
        if match_cells then return i end
    end
    assert(false, "neighbourhood.categorise cannot find a valid category")
end

--- The Moore neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/Moore_neighborhood).
--
-- Contains all points with Chebyshev distance 1
-- from origin. Used in Conway's Game of Life.
function neighbourhood.moore()
    local nbh = {}
    table.insert(nbh, point.new(1,0))
    table.insert(nbh, point.new(0,1))
    table.insert(nbh, point.new(-1,0))
    table.insert(nbh, point.new(0,-1))
    table.insert(nbh, point.new(1,1))
    table.insert(nbh, point.new(1,-1))
    table.insert(nbh, point.new(-1,-1))
    table.insert(nbh, point.new(-1,1))
    nbh = neighbourhood.new(nbh)
    nbh.category_label = nil
    return nbh
end

--- The von Neumann neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/von_Neumann_neighborhood).
--
-- Contains all points with Manhattan distance 1 from origin.
function neighbourhood.von_neumann()
    local nbh = {}
    table.insert(nbh, point.new(1,0))
    table.insert(nbh, point.new(0,1))
    table.insert(nbh, point.new(-1,0))
    table.insert(nbh, point.new(0,-1))
    nbh = neighbourhood.new(nbh)
    --- utf8 characters for the 16 possible von neumann categories
    nbh._category_label = {'┼','├','┴','┤','┬','─','┘','└','│','┌','┐','╷','╴','╶','╵','.'}
    return nbh
end

--- The diagonal neighbourhood.
--
-- Contains all points diagonally bordering the origin. i.e the Moore
-- neighbourhood with the von Neumann subtracted.
function neighbourhood.diagonal()
    local nbh = {}
    table.insert(nbh, point.new(1,1))
    table.insert(nbh, point.new(1,-1))
    table.insert(nbh, point.new(-1,-1))
    table.insert(nbh, point.new(-1,1))
    nbh = neighbourhood.new(nbh)
    nbh._category_label = nil -- TODO
    return nbh
end

--- The twice diagonal neighbourhood.
--
-- Contains all points two cells away from the origin
-- along the diagonal axes.
function neighbourhood.diagonal_2()
    local nbh = {}
    table.insert(nbh, point.new(2,2))
    table.insert(nbh, point.new(2,-2))
    table.insert(nbh, point.new(-2,-2))
    table.insert(nbh, point.new(-2,2))
    nbh = neighbourhood.new(nbh)
    nbh._category_label = nil -- TODO
    return nbh
end

--- Returns the category labelling (if it exists) for a neighbourhood.
-- @param nbh the neighbourhood to fetch the category labelling for.
-- @return a table of labels, one for each neighbourhood category.
function neighbourhood.category_label(nbh)
    return nbh._category_label
end

-- Neighbouring points of a source.
-- Returns a closure for use in pathing e.g a-star.
-- @param dirs a list of vectors (e.g forma.neighbourhood)
-- @return a function which takes a point and returns it's neighbours
--function neighbourhood.closure(dirs)
--	assert(type(dirs) == "table")
--	for i=1,#dirs,1 do assert(getmetatable(dirs[i]) == point) end
--	return function(a)
--		assert(getmetatable(a) == point)
--		local t = {}
--		for i=1,#dirs,1 do
--			assert(getmetatable(a) == point)
--			table.insert(t, a+dirs[i])
--		end
--		return t
--	end
--end

return neighbourhood


