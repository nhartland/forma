---@meta

--- Cell neighbourhood definitions.
---@class forma.neighbourhood
local neighbourhood = {}

--- Generate a new neighbourhood from a set of cells.
---@param neighbour_cells forma.cell[]
---@return forma.neighbourhood
function neighbourhood.new(neighbour_cells) end

--- The Moore neighbourhood (8-connected).
---@return forma.neighbourhood
function neighbourhood.moore() end

--- The von Neumann neighbourhood (4-connected).
---@return forma.neighbourhood
function neighbourhood.von_neumann() end

--- The diagonal neighbourhood.
---@return forma.neighbourhood
function neighbourhood.diagonal() end

--- The twice diagonal neighbourhood.
---@return forma.neighbourhood
function neighbourhood.diagonal_2() end

--- The knight neighbourhood.
---@return forma.neighbourhood
function neighbourhood.knight() end

--- Categorise a cell's neighbourhood configuration.
---@param nbh forma.neighbourhood
---@param ip forma.pattern
---@param icell forma.cell
---@return integer
function neighbourhood.categorise(nbh, ip, icell) end

--- Returns the category labelling for a neighbourhood.
---@param nbh forma.neighbourhood
---@return string[]?
function neighbourhood.category_label(nbh) end

--- Returns the number of categories for a neighbourhood.
---@param nbh forma.neighbourhood
---@return integer
function neighbourhood.get_ncategories(nbh) end

return neighbourhood
