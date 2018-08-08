---  Cell neighbourhood definitions.
-- The **neighbourhood** of a `cell` in a `pattern` defines which other cells
-- are considered its neighbours. This is an important definition for many
-- functions in forma. For example, when finding all cells that border a
-- pattern in `subpattern.edge` a definition of *border* in terms of a
-- neighbourhood is required. Cellular `automata` rules are also defined in
-- terms of neighbourhoods.
--
-- This module provides a class to represent a neighbourhood, along with
-- examples of typical neighbourhoods such as the `Moore` or `von Neumann`
-- neighbourhoods.
--
-- @usage
--  -- Load some neighbourhoods to use with other functions
--  local moore = neighbourhood.moore()
--  local vn    = neighbourhood.von_neumann()
--
--  -- Define a new neighbourhood from a table of forma.cells
--  local new_neighbourhood = neighbourhood.new({cell_list})
--
-- @module forma.neighbourhood
local neighbourhood = {}
local cell = require('forma.cell')

-- Neighbourhood indexing
-- For enabling syntax sugar neighbourhood:method
neighbourhood.__index = neighbourhood

-- Helpers --------------------------------------------------------------
--- Generate a list of possible neighbourhood configurations.
-- @param neighbour_cells the neighbourhood to generate categories for
-- @return a table categorising possible neighbourhood configurations
-- Maybe have this run on demand, rather than always building this for all
-- neighbourhoods?
local function generate_categories(neighbour_cells)
    assert(#neighbour_cells > 0, "categories.generate requires a non-empty neighbourhood")
    local categories = {cell.new(0,0)}

    for i=1, #neighbour_cells, 1 do
        local target_cell = neighbour_cells[i]
        for j=1, #categories, 1 do
            local new_category = {}
            new_category[1] = cell.clone(target_cell)
            local category_size = #categories[j]
            for k=1, category_size, 1 do
                new_category[#new_category+1] = categories[j][k]
            end
            categories[#categories+1] = new_category
        end
    end
    -- Sort by number of elements and return
    table.sort(categories, function(a,b) return #a > #b end)
    return categories
end

--- Neighbourhoods
-- @section neighbourhoods

--- The Moore neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/Moore_neighborhood).
--
-- Contains all cells with Chebyshev distance 1
-- from origin. Used in Conway's Game of Life.
function neighbourhood.moore()
    local nbh = {}
    table.insert(nbh, cell.new(1,0))
    table.insert(nbh, cell.new(0,1))
    table.insert(nbh, cell.new(-1,0))
    table.insert(nbh, cell.new(0,-1))
    table.insert(nbh, cell.new(1,1))
    table.insert(nbh, cell.new(1,-1))
    table.insert(nbh, cell.new(-1,-1))
    table.insert(nbh, cell.new(-1,1))
    nbh = neighbourhood.new(nbh)
    nbh.category_label = nil
    return nbh
end

--- The von Neumann neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/von_Neumann_neighborhood).
--
-- Contains all cells with Manhattan distance 1 from origin.
function neighbourhood.von_neumann()
    local nbh = {}
    table.insert(nbh, cell.new(1,0))
    table.insert(nbh, cell.new(0,1))
    table.insert(nbh, cell.new(-1,0))
    table.insert(nbh, cell.new(0,-1))
    nbh = neighbourhood.new(nbh)
    -- utf8 characters for the 16 possible von neumann categories
    nbh._category_label = {'┼','├','┴','┤','┬','─','┘','└','│','┌','┐','╷','╴','╶','╵','.'}
    return nbh
end

--- The diagonal neighbourhood.
--
-- Contains all cells diagonally bordering the origin. i.e the Moore
-- neighbourhood with the von Neumann subtracted.
function neighbourhood.diagonal()
    local nbh = {}
    table.insert(nbh, cell.new(1,1))
    table.insert(nbh, cell.new(1,-1))
    table.insert(nbh, cell.new(-1,-1))
    table.insert(nbh, cell.new(-1,1))
    nbh = neighbourhood.new(nbh)
    nbh._category_label = nil -- TODO
    return nbh
end

--- The twice diagonal neighbourhood.
--
-- Contains all cells two cells away from the origin
-- along the diagonal axes.
function neighbourhood.diagonal_2()
    local nbh = {}
    table.insert(nbh, cell.new(2,2))
    table.insert(nbh, cell.new(2,-2))
    table.insert(nbh, cell.new(-2,-2))
    table.insert(nbh, cell.new(-2,2))
    nbh = neighbourhood.new(nbh)
    nbh._category_label = nil -- TODO
    return nbh
end

--- Functions
-- @section functions

--- Generate a new neighbourhood from a set of cells.
-- @param neighbour_cells a list of neighbouring cell vectors
-- @return a forma.neighbourhood comprised of `neighbour_cells`
function neighbourhood.new(neighbour_cells)
    assert(#neighbour_cells > 0, "neighbourhood.new requires a non-empty list of neighbouring cells")
    local nbh = {}
    for _,v in ipairs(neighbour_cells) do
        table.insert(nbh, cell.clone(v))
    end
    nbh.categories = nil -- Generated on demand
    nbh = setmetatable(nbh, neighbourhood)
    return nbh
end

--- Identify which category a cell in a pattern fits into.
-- Categorises cells in a pattern according to their neighbourhood
-- configuration. For each cell in a forma.pattern, there are a finite number
-- of possible configurations of neighbouring cells. Specifically, each cell
-- has 2^n possible neighbourhood configurations where n is the number of cells
-- in the neighbourhood. This method categorises cells according to which type
-- of neighbourhood they are in.
-- @param nbh the forma.neighbourhood to categorise the cell in
-- @param ip the input pattern
-- @param icell the cell in `ip` of interest
-- @return the index of 'icats' that 'cell' belongs to
-- This assumes that the categories table is sorted - should fix this
function neighbourhood.categorise(nbh, ip, icell)
    local ncategories = nbh:get_ncategories() -- Generates the categorisation if needed
    for i=1, ncategories, 1 do
        local category = nbh.categories[i]
        local match_cells = true
        for j=1, #category, 1 do
            local np = icell + category[j]
            if ip:has_cell(np.x, np.y) == false then
                match_cells = false
            end
        end
        if match_cells then return i end
    end
    assert(false, "neighbourhood.categorise cannot find a valid category")
end

--- Returns the category labelling (if it exists) for a neighbourhood.
-- @param nbh the neighbourhood to fetch the category labelling for.
-- @return a table of labels, one for each neighbourhood category.
function neighbourhood.category_label(nbh)
    return nbh._category_label
end

--- Returns the number of categories for a neighbourhood
-- @param `nbh` the `neighbourhood` in question
-- @return the number of categories for neighbourhood `nbh`
function neighbourhood.get_ncategories(nbh)
    -- Generate categories if needed
    if nbh.categories == nil then
        nbh.categories = generate_categories(nbh)
    end
    return #nbh.categories
end

return neighbourhood

