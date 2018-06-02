--- Pattern primitives
-- This module provides functions for the generation of basic
-- pattern shapes such as square/rectangular or raster circle patterns.
-- @module forma.primitives
local primitives = {}

local thispath = select('1', ...):match(".+%.") or ""
local pattern = require(thispath .. 'pattern')

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
        cp:insert_over(-x, -y)
        cp:insert_over(-y, -x)
        cp:insert_over( y, -x)
        cp:insert_over( x, -y)
        cp:insert_over(-x,  y)
        cp:insert_over(-y,  x)
        cp:insert_over( y,  x)
        cp:insert_over( x,  y)

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