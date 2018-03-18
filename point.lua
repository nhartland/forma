--- Basic point handling
-- @module forma.point
local point = {}

--- Initialise a forma.point
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

--- Add two points, or a number and a point
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

--- Subtract two points, or a number and a point
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

--- Point equality test
-- @param a first point
-- @param b second point
-- @return a == b
function point.__eq(a, b)
	assert(getmetatable(a) == point and getmetatable(b) == point)
	return a.x == b.x and a.y == b.y
end

--- point tostring
-- @return string of the form (x,y)
function point.__tostring(self)
	return '('..self.x..','..self.y..')'
end

--- Returns a copy of a point
-- @return copy of self
function point:clone()
	return point.new(self.x, self.y)
end

-- Minkowski distance between points
-- @param a first point
-- @param b second point
-- @return L1(a,b)
function point.minkowski(a,b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

-- Chebyshev distance between points
-- @param a first point
-- @param b second point
-- @return L_inf(a,b)
function point.chebyshev(a,b)
    return math.max(math.abs(a.x-b.x), math.abs(a.y-b.y))
end

-- Squared Euclidean distance between points
-- @param a first point
-- @param b second point
-- @return L_2(a,b)^2
function point.euclidean2(a,b)
    local d = a - b
    return d.x*d.x+d.y*d.y
end

-- Euclidean distance between points
-- @param a first point
-- @param b second point
-- @return L_2(a,b)
function point.euclidean(a,b)
    return math.sqrt(point.euclidean2(a,b))
end

-- Neighbouring points of a source
-- @param dirs a table of directions (e.g forma.neighbourhood)
-- @return a function which takes a point and returns it's neighbours
function point.neighbours(dirs)
	assert(type(dirs) == "table")
	for i=1,#dirs,1 do assert(getmetatable(dirs[i]) == point) end
	return function(a)
		assert(getmetatable(a) == point)
		local t = {}
		for i=1,#dirs,1 do
			assert(getmetatable(a) == point)
			table.insert(t, a+dirs[i])
		end
		return t
	end
end

return point


