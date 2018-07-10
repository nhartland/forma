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
-- @usage
-- -- Initialisation and cloning of points
-- local c1 = cell.new(x,y)  -- Constructor
-- local c2 = cell.clone(c1) -- Clone ('procedural' style)
-- local c3 = c1:clone()     -- Clone ('method' stype)
--
-- -- Arithmetic
-- local c4 = (c1 + c2) - c3
--
-- -- Distance measures
-- local d1 = cell.manhattan(c1,c2) -- Manhattan distance ('procedural' stype)
-- local d2 = c1:manhattan(c2)      -- Manhattan distance ('method' style)
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
-- @param x first coordinate
-- @param y second coordinate
-- @return new forma.cell
function cell.new(x,y)
    assert(x == floor(x), "cell.new requires two integer inputs")
    assert(y == floor(y), "cell.new requires two integer inputs")
    local newcell = { x = x, y = y }
    return setmetatable(newcell, cell)
end

--- Perform a copy of a cell.
-- @param icell to be copied
-- @return copy of `icell`
function cell.clone(icell)
    -- Rely on cell.new to catch non-cell inputs
    return cell.new(icell.x, icell.y)
end

--- Add two cell positions
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return c = a + b
function cell.__add(a, b)
    return cell.new(a.x + b.x, a.y + b.y)
end

--- Subtract two cell positions
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return c = a - b
function cell.__sub(a, b)
    return cell.new(a.x - b.x, a.y - b.y)
end

--- Test for equality of two cell vectors.
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return a == b
function cell.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

--- Render a cell as a string.
-- @within Metamethods
-- @param icell the forma.cell being rendered as a string
-- @return string of the form `(icell.x, icell.y)`
function cell.__tostring(icell)
    return '('..icell.x..','..icell.y..')'
end

--- Manhattan distance between cells.
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L1(a,b) = |a.x-b.x| + |a.y-b.y|
function cell.manhattan(a,b)
    return abs(a.x - b.x) + abs(a.y - b.y)
end

--- Chebyshev distance between cells.
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_inf(a,b) = max(|a.x-b.x|, |a.y-b.y|)
function cell.chebyshev(a,b)
    return max(abs(a.x-b.x), abs(a.y-b.y))
end

--- Squared Euclidean distance between cells.
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_2(a,b)^2 = (a-b)^2
function cell.euclidean2(a,b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx*dx+dy*dy
end

--- Euclidean distance between cells.
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_2(a,b) = sqrt((a-b)^2)
function cell.euclidean(a,b)
    return sqrt(cell.euclidean2(a,b))
end

return cell


