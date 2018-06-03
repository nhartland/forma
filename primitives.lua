--- Pattern primitives
-- This module provides functions for the generation of basic
-- pattern shapes such as square/rectangular or raster circle patterns.
-- @module forma.primitives
local primitives = {}

local thispath = select('1', ...):match(".+%.") or ""
local pattern = require(thispath .. 'pattern')

--- Point insertion into a pattern without failing if point already exists.
-- This function differs only from pattern.insert by first checking if the point
-- already exists in the pointset. Therefore bypassing the assert.
-- @param ip pattern for point insertion
-- @param x first coordinate of new point
-- @param y second coordinate of new point
-- @return true if the insert was sucessful, false if not
local function pattern_insert_over( ip, x, y )
    if ip:has_cell(x, y) == false then
       pattern.insert(ip, x, y)
       return true
    end
    return false
end

--- Basic square pattern
-- @param x size in x
-- @param y size in y (default y = x)
-- @return square forma.pattern of size {x,y}
function primitives.square(x,y)
	y = y ~= nil and y or x
	assert(type(x) == "number",
           'primitives.square requires a number as the first argument')
	assert(type(x) == "number",
           'primitives.square requires either a number or nil as a second argument')

	local sqPattern = pattern.new()
	for i=0, x-1, 1 do
		for j=0, y-1, 1 do
			sqPattern:insert(i,j)
		end
	end

	return sqPattern
end

-- Bresenham line algorithm
-- @param start a forma.point denoting the start of the line
-- @param finish a forma.point denoting the end of the line
-- @return a forma.pattern consisting of a line between (start, finish)
function primitives.line(start, finish)
	local deltax = finish.x - start.x
	local sx = deltax / math.abs(deltax)
	deltax = bit.lshift( math.abs(deltax), 1)

	local deltay = finish.y - start.y
	local sy = deltay / math.abs(deltay)
	deltay = bit.lshift( math.abs(deltay), 1)

	local x,y = start.x, start.y
    local line = pattern.new():insert(x,y)

	if deltax >= deltay then
		local error = deltay - bit.rshift(deltax, 1)
		while x ~= finish.x do
			if error > 0 or (error == 0 and sx > 0 ) then
				error = error - deltax
				y = y + sy
			end
			error = error + deltay
			x = x + sx
            line:insert(x,y)
		end
	else
		local error = deltax - bit.rshift(deltay ,1)
		while y ~= finish.y do
			if error > 0 or (error == 0 and sy > 0) then
				error = error - deltay
				x = x + sx
			end
			error = error + deltax
			y = y + sy
            line:insert(x,y)
		end
	end
    return line
end

--- Basic circular pattern
-- http://willperone.net/Code/codecircle.php suggests a faster method
-- might be worth a look
-- @param r the radius of the circle to be drawn
-- @return circular forma.pattern of radius r
function primitives.circle(r)
	assert(type(r) == 'number', 'primitives.circle requires a number for the radius')
	assert(r >= 0, 'primitives.circle requires a positive number for the radius')

    local cp = pattern.new()
    local x, y = 0, r
    local p = 3 - 2*r
    if r == 0 then return cp end

    -- insert_over needed here because this algorithm duplicates some points
    while (y >= x) do
        pattern_insert_over(cp,-x, -y)
        pattern_insert_over(cp,-y, -x)
        pattern_insert_over(cp, y, -x)
        pattern_insert_over(cp, x, -y)
        pattern_insert_over(cp,-x,  y)
        pattern_insert_over(cp,-y,  x)
        pattern_insert_over(cp, y,  x)
        pattern_insert_over(cp, x,  y)

        x = x + 1
        if p < 0 then
            p = p + 4*x + 6
        else
            y = y - 1
            p = p + 4*(x - y) + 10
        end
    end
    return cp
end

return primitives
