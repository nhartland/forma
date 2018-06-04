--- Integer point/vector class defining the position of a cell.
--
-- The `point` class behaves much as a normal 2D vector class, with the
-- restriction that its components must be integer-valued. Normal vector
-- operations are available such as vector addition, subtraction, equivalence
-- and multiplication/division by a constant.
--
-- @module forma.point

local point = {}

-- Point indexing
-- For enabling syntax sugar point:method
point.__index = point

--- Initialise a new forma.point.
-- @param x first coordinate
-- @param y second coordinate
-- @return new forma.point
function point.new(x,y)
    if x == -0 then x = 0 end
    if y == -0 then y = 0 end
	local self = { x = (x~=nil) and x or 0, y = (y~=nil) and y or 0 }
    local valid = self.x == math.floor(self.x) and self.y == math.floor(self.y)
    assert (valid, "point.new requires integer inputs")
	return setmetatable(self, point)
end

--- Perform a copy of a point.
-- @param ipoint to be copied
-- @return copy of `ipoint`
function point.clone(ipoint)
    assert(getmetatable(ipoint) == point, "point.clone requires a point as an argument")
	return point.new(ipoint.x, ipoint.y)
end

--- Add two points, or a constant number to a point.
-- @within Metamethods
-- @param a first point/number
-- @param b second point/number
-- @return c = a + b
function point.__add(a, b)
  if type(a) == "number" and getmetatable(b) == point then
    return point.new(a + b.x, a + b.y)
  elseif type(b) == "number" and getmetatable(a) == point then
    return point.new(a.x + b, a.y + b)
  else
	assert(getmetatable(a) == point and getmetatable(b) == point)
    return point.new(a.x + b.x, a.y + b.y)
  end
end

--- Subtract two points, or a constant number and a point.
-- @within Metamethods
-- @param a first point/number
-- @param b second point/number
-- @return c = a - b
function point.__sub(a, b)
  if type(a) == "number" and getmetatable(b) == point then
    return point.new(a - b.x, a - b.y)
  elseif type(b) == "number" and getmetatable(a) == point then
    return point.new(a.x - b, a.y - b)
  else
	assert(getmetatable(a) == point and getmetatable(b) == point)
    return point.new(a.x - b.x, a.y - b.y)
  end
end

--- Component-wise multiply two points, or a number and a point
-- @within Metamethods
-- @param a first point/number
-- @param b second point/number
-- @return c = a*b
function point.__mul(a, b)
  if type(a) == "number" and getmetatable(b) == point then
    return point.new(b.x * a, b.y * a )
  elseif type(b) == "number" and getmetatable(a) == point then
    return point.new(a.x * b, a.y * b )
  else
	assert(getmetatable(a) == point and getmetatable(b) == point)
    return point.new(a.x * b.x, a.y * b.y )
  end
end

--- Component-wise divide two points, or a number and a point
-- @within Metamethods
-- @param a first point/number
-- @param b second point/number
-- @return c = a/b
function point.__div(a, b)
  if type(a) == "number" and getmetatable(b) == point then
    assert(false, "Cannot divide a number by a point")
  elseif type(b) == "number" and getmetatable(a) == point then
    return point.new(a.x / b, a.y / b )
  else
  assert(getmetatable(a) == point and getmetatable(b) == point)
    return point.new(a.x / b.x, a.y / b.y )
  end
end

--- Test for equality of two points
-- @within Metamethods
-- @param a first point
-- @param b second point
-- @return a == b
function point.__eq(a, b)
	assert(getmetatable(a) == point and getmetatable(b) == point)
	return a.x == b.x and a.y == b.y
end

--- point Render a point to a string
-- @within Metamethods
-- @return string of the form (x,y)
function point.__tostring(self)
	return '('..self.x..','..self.y..')'
end

--- Manhattan distance between points
-- @within Distance measures
-- @param a first point
-- @param b second point
-- @return L1(a,b)
function point.manhattan(a,b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

--- Chebyshev distance between points
-- @within Distance measures
-- @param a first point
-- @param b second point
-- @return L_inf(a,b)
function point.chebyshev(a,b)
    return math.max(math.abs(a.x-b.x), math.abs(a.y-b.y))
end

--- Squared Euclidean distance between points
-- @within Distance measures
-- @param a first point
-- @param b second point
-- @return L_2(a,b)^2
function point.euclidean2(a,b)
    local d = a - b
    return d.x*d.x+d.y*d.y
end

--- Euclidean distance between points
-- @within Distance measures
-- @param a first point
-- @param b second point
-- @return L_2(a,b)
function point.euclidean(a,b)
    return math.sqrt(point.euclidean2(a,b))
end


return point


