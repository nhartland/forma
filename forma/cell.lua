--- Integer point/vector class defining the position of a cell.
---
--- The **cell** class behaves much as a normal 2D vector class, with the
--- restriction that its components must be integer-valued. A subset of normal
--- vector operations are available, namely a vector addition and subtraction,
--- along with a vector equality check.
---
--- Along with the `cell` class definition, a number of distance measures
--- between cell positions are provided. Specifically, the Manhattan, Chebyshev
--- and Euclidean distances.
---@class forma.cell
---@field x integer x-coordinate
---@field y integer y-coordinate
local cell = {}

local abs   = math.abs
local max   = math.max
local sqrt  = math.sqrt
local floor = math.floor

-- Cell indexing
-- For enabling syntax sugar cell:method
cell.__index = cell

--- Initialise a new forma.cell.
---
--- ```lua
--- local x, y = 1, 5
--- local new_cell = cell.new(x, y)
--- ```
---@param x integer first coordinate
---@param y integer second coordinate
---@return forma.cell cell new forma.cell
function cell.new(x, y)
    assert(x == floor(x), "cell.new requires two integer inputs")
    assert(y == floor(y), "cell.new requires two integer inputs")
    local newcell = { x = x, y = y }
    return (setmetatable(newcell, cell))
end

--- Perform a copy of a cell.
---
--- ```lua
--- local old_cell = cell.new(1, 1)
--- local new_cell = old_cell:clone()
--- ```
---@param icell forma.cell cell to be copied
---@return forma.cell cell copy of `icell`
function cell.clone(icell)
    -- Rely on cell.new to catch non-cell inputs
    return (cell.new(icell.x, icell.y))
end

--- Add two cell positions.
---
--- ```lua
--- local c1, c2 = cell.new(1, 1), cell.new(0, 0)
--- local c3 = c2 + c1
--- assert(c3 == c1)
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return forma.cell c c = a + b
function cell.__add(a, b)
    return (cell.new(a.x + b.x, a.y + b.y))
end

--- Subtract two cell positions.
---
--- ```lua
--- local c1, c2 = cell.new(1, 1), cell.new(2, 2)
--- local c3 = c2 - c1
--- assert(c3 == c1)
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return forma.cell c c = a - b
function cell.__sub(a, b)
    return (cell.new(a.x - b.x, a.y - b.y))
end

--- Test for equality of two cell vectors.
---
--- ```lua
--- assert(cell.new(0, 1) == cell.new(0, 1))
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return boolean equal a == b
function cell.__eq(a, b)
    return (a.x == b.x and a.y == b.y)
end

--- Render a cell as a string.
---
--- ```lua
--- print(cell.new(1, 1))
--- ```
---@param icell forma.cell the cell being rendered as a string
---@return string str string of the form `(icell.x, icell.y)`
function cell.__tostring(icell)
    return '(' .. icell.x .. ',' .. icell.y .. ')'
end

--- Manhattan distance between cells.
---
--- ```lua
--- local distance = cell.manhattan(cell.new(1, 2), cell.new(3, 4))
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return integer distance L1(a,b) = |a.x-b.x| + |a.y-b.y|
function cell.manhattan(a, b)
    return (abs(a.x - b.x) + abs(a.y - b.y))
end

--- Chebyshev distance between cells.
---
--- ```lua
--- local distance = cell.chebyshev(cell.new(1, 2), cell.new(3, 4))
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return integer distance L_inf(a,b) = max(|a.x-b.x|, |a.y-b.y|)
function cell.chebyshev(a, b)
    return (max(abs(a.x - b.x), abs(a.y - b.y)))
end

--- Euclidean distance between cells.
---
--- ```lua
--- local distance = cell.euclidean(cell.new(1, 2), cell.new(3, 4))
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return number distance L_2(a,b) = sqrt((a-b)^2)
function cell.euclidean(a, b)
    return sqrt(cell.euclidean2(a, b))
end

--- Squared Euclidean distance between cells.
--- A little faster than `cell.euclidean` as it avoids the sqrt.
---
--- ```lua
--- local distance = cell.euclidean2(cell.new(1, 2), cell.new(3, 4))
--- ```
---@param a forma.cell first cell
---@param b forma.cell second cell
---@return number distance L_2(a,b)^2 = (a-b)^2
function cell.euclidean2(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return (dx * dx + dy * dy)
end

return cell
