--- Integer point/vector class defining the position of a cell.
--
-- The **cell** class behaves much as a normal 2D vector class, with the
-- restriction that its components must be integer-valued. A subset of normal
-- vector operations are available, namely a vector addition and subtraction,
-- along with a vector equality check.
--
-- Along with the `cell` class definition, a number of distance measures
-- between cell positions are provided. Specifically, the Manhattan, Chebyshev
-- and Euclidean distances.
--
-- @module forma.cell
local cell = {}

local abs   = math.abs
local max   = math.max
local sqrt  = math.sqrt
local floor = math.floor

-- Cell indexing
-- For enabling syntax sugar cell:method
cell.__index = cell

--- Initialise a new forma.cell.
-- @usage
-- local x, y = 1, 5
-- local new_cell = cell.new(x,y)
-- @param x first coordinate
-- @param y second coordinate
-- @return new forma.cell
function cell.new(x,y)
    assert(x == floor(x), "cell.new requires two integer inputs")
    assert(y == floor(y), "cell.new requires two integer inputs")
    local newcell = { x = x, y = y }
    return (setmetatable(newcell, cell))
end

--- Perform a copy of a cell.
-- @usage
-- local old_cell = cell.new(1,1)
-- local new_cell = old_cell:clone()
-- @param icell to be copied
-- @return copy of `icell`
function cell.clone(icell)
    -- Rely on cell.new to catch non-cell inputs
    return (cell.new(icell.x, icell.y))
end

--- Add two cell positions
-- @usage
-- local c1, c2 = cell.new(1,1), cell.new(0,0)
-- local c3 = c2 + c1
-- assert(c3 == c1)
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return c = a + b
function cell.__add(a, b)
    return (cell.new(a.x + b.x, a.y + b.y))
end

--- Subtract two cell positions
-- @usage
-- local c1, c2 = cell.new(1,1), cell.new(2,2)
-- local c3 = c2 - c1
-- assert(c3 == c1)
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return c = a - b
function cell.__sub(a, b)
    return (cell.new(a.x - b.x, a.y - b.y))
end

--- Test for equality of two cell vectors.
-- assert(cell.new(0,1) == cell.new(0,1)
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return a == b
function cell.__eq(a, b)
    return (a.x == b.x and a.y == b.y)
end

--- Render a cell as a string.
-- @usage
-- print(cell.new(1,1))
-- @within Metamethods
-- @param icell the forma.cell being rendered as a string
-- @return string of the form `(icell.x, icell.y)`
function cell.__tostring(icell)
    return '('..icell.x..','..icell.y..')'
end

--- Manhattan distance between cells.
-- @usage
-- local distance = cell.manhattan(cell.new(1,2), cell.new(3,4))
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L1(a,b) = |a.x-b.x| + |a.y-b.y|
function cell.manhattan(a,b)
    return (abs(a.x - b.x) + abs(a.y - b.y))
end

--- Chebyshev distance between cells.
-- @usage
-- local distance = cell.chebyshev(cell.new(1,2), cell.new(3,4))
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_inf(a,b) = max(|a.x-b.x|, |a.y-b.y|)
function cell.chebyshev(a,b)
    return (max(abs(a.x-b.x), abs(a.y-b.y)))
end

--- Euclidean distance between cells.
-- @usage
-- local distance = cell.euclidean(cell.new(1,2), cell.new(3,4))
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_2(a,b) = sqrt((a-b)^2)
function cell.euclidean(a,b)
    return sqrt(cell.euclidean2(a,b))
end

--- Squared Euclidean distance between cells.
-- A little faster than `cell.euclidean` as it avoids the sqrt.
-- @usage
-- local distance = cell.euclidean2(cell.new(1,2), cell.new(3,4))
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_2(a,b)^2 = (a-b)^2
function cell.euclidean2(a,b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return (dx*dx+dy*dy)
end

return cell


