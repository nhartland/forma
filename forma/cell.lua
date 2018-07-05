--- Integer point/vector class defining the position of a cell.
--
-- The **cell** class behaves much as a normal 2D vector class, with the
-- restriction that its components must be integer-valued. Several normal
-- vector operations are available such as a vector equality check, vector
-- addition, subtraction, and multiplication by an integer.
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
-- local c4 = (c1 + c2) - c3*5
--
-- -- Distance measures
-- local d1 = cell.manhattan(c1,c2) -- Manhattan distance ('procedural' stype)
-- local d2 = c1:manhattan(c2)      -- Manhattan distance ('method' style)
--
-- @module forma.cell
local cell = {}

-- Cell indexing
-- For enabling syntax sugar cell:method
cell.__index = cell

--- Initialise a new forma.cell.
-- @param x first coordinate
-- @param y second coordinate
-- @return new forma.cell
function cell.new(x,y)
    assert(x and y, "cell.new requires two integer arguments")
    assert(x == math.floor(x) and y == math.floor(y), "cell.new requires two integer inputs")
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

--- Add two cells, or add a number to a cell.
-- @within Metamethods
-- @param a first cell or number
-- @param b second cell or number
-- @return c = a + b
function cell.__add(a, b)
    if type(a) == "number" and getmetatable(b) == cell then
        return cell.new(a + b.x, a + b.y)
    elseif type(b) == "number" and getmetatable(a) == cell then
        return cell.new(a.x + b, a.y + b)
    else
        assert(getmetatable(a) == cell and getmetatable(b) == cell)
        return cell.new(a.x + b.x, a.y + b.y)
    end
end

--- Subtract two cells, or a number and a cell.
-- @within Metamethods
-- @param a first cell or number
-- @param b second cell or number
-- @return c = a - b
function cell.__sub(a, b)
    if type(a) == "number" and getmetatable(b) == cell then
        return cell.new(a - b.x, a - b.y)
    elseif type(b) == "number" and getmetatable(a) == cell then
        return cell.new(a.x - b, a.y - b)
    else
        assert(getmetatable(a) == cell and getmetatable(b) == cell)
        return cell.new(a.x - b.x, a.y - b.y)
    end
end

--- Multiply a cell by an number.
-- @within Metamethods
-- @param a first cell or number
-- @param b second cell or number
-- @return c = a*b
function cell.__mul(a, b)
    if type(a) == "number" and getmetatable(b) == cell then
        return cell.new(b.x * a, b.y * a )
    elseif type(b) == "number" and getmetatable(a) == cell then
        return cell.new(a.x * b, a.y * b )
    end
    assert("forma.cell.__mul: unrecognised argument. Expected arguments are a forma.cell and a number.")
end

--- Divide a cell position by a number.
-- @within Metamethods
-- @param a a forma.cell
-- @param b a number
-- @return c = a/b
function cell.__div(a, b)
    if type(a) == "number" and getmetatable(b) == cell then
        assert(false, "Cannot divide a number by a cell")
    elseif type(b) == "number" and getmetatable(a) == cell then
        return cell.new(a.x / b, a.y / b )
    end
    assert("forma.cell.__div: unrecognised argument. Expected arguments are a forma.cell and a number.")
end

--- Test for equality of two cells.
-- @within Metamethods
-- @param a first cell
-- @param b second cell
-- @return a == b
function cell.__eq(a, b)
    assert(getmetatable(a) == cell and getmetatable(b) == cell)
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
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

--- Chebyshev distance between cells.
-- @within Distance measures
-- @param a first cell
-- @param b second cell
-- @return L_inf(a,b) = max(|a.x-b.x|, |a.y-b.y|)
function cell.chebyshev(a,b)
    return math.max(math.abs(a.x-b.x), math.abs(a.y-b.y))
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
    return math.sqrt(cell.euclidean2(a,b))
end

return cell


