---@meta

--- Integer point/vector class defining the position of a cell.
---@class forma.cell
---@field x integer
---@field y integer
---@operator add(forma.cell): forma.cell
---@operator sub(forma.cell): forma.cell
local cell = {}

--- Initialise a new forma.cell.
---@param x integer
---@param y integer
---@return forma.cell
function cell.new(x, y) end

--- Perform a copy of a cell.
---@param icell forma.cell
---@return forma.cell
function cell.clone(icell) end

--- Add two cell positions.
---@param a forma.cell
---@param b forma.cell
---@return forma.cell
function cell.__add(a, b) end

--- Subtract two cell positions.
---@param a forma.cell
---@param b forma.cell
---@return forma.cell
function cell.__sub(a, b) end

--- Test for equality of two cell vectors.
---@param a forma.cell
---@param b forma.cell
---@return boolean
function cell.__eq(a, b) end

--- Render a cell as a string.
---@param icell forma.cell
---@return string
function cell.__tostring(icell) end

--- Manhattan distance between cells.
---@param a forma.cell
---@param b forma.cell
---@return number
function cell.manhattan(a, b) end

--- Chebyshev distance between cells.
---@param a forma.cell
---@param b forma.cell
---@return number
function cell.chebyshev(a, b) end

--- Euclidean distance between cells.
---@param a forma.cell
---@param b forma.cell
---@return number
function cell.euclidean(a, b) end

--- Squared Euclidean distance between cells.
---@param a forma.cell
---@param b forma.cell
---@return number
function cell.euclidean2(a, b) end

return cell
