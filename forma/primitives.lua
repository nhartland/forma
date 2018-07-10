--- Primitive (line, rectangle and circle) patterns.
-- This module provides convenience functions for the generation of basic
-- `pattern` shapes. So far including lines, squares/rectangles and circle
-- rasters.
--
-- @usage
-- -- Draw some squares
-- local square_pattern = primitives.square(5)      -- 5x5
-- local rectangle_pattern = primitives.square(3,5) -- 3x5
--
-- -- Draw a line
-- local line = primitives.line(cell.new(0,0), cell.new(10,10))
--
-- -- Draw a circle about (0,0) with radius 5
-- local circle = primitives.circle(5)
--
-- @module forma.primitives
local primitives = {}

local pattern = require('forma.pattern')

----------------------------------------------------------------------------
--- Geometry primitives
-- @section primitives

--- Generate a square pattern.
-- @param x size in x
-- @param y size in y (default `y = x`)
-- @return square forma.pattern of size `{x,y}`
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

--- Generate a line pattern.
-- According to Bresenham's line algorithm.
-- @param start  a forma.cell denoting the start of the line
-- @param finish a forma.cell denoting the end of the line
-- @return a pattern consisting of a line between `start` and `finish`
function primitives.line(start, finish)
    local deltax = finish.x - start.x
    local sx = deltax / math.abs(deltax)
    deltax = math.abs(deltax)*2.

    local deltay = finish.y - start.y
    local sy = deltay / math.abs(deltay)
    deltay = math.abs(deltay)*2.

    local x,y = start.x, start.y
    local line = pattern.new():insert(x,y)

    if deltax >= deltay then
        local err = deltay - deltax/2.
        while x ~= finish.x do
            if err > 0 or (err == 0 and sx > 0 ) then
                err = err - deltax
                y = y + sy
            end
            err = err + deltay
            x = x + sx
            line:insert(x,y)
        end
    else
        local err = deltax - deltay/2.
        while y ~= finish.y do
            if err > 0 or (err == 0 and sy > 0) then
                err = err - deltay
                x = x + sx
            end
            err = err + deltax
            y = y + sy
            line:insert(x,y)
        end
    end
    return line
end

--- Generate a circle pattern.
-- Bresenham algorithm.
-- @param r the radius of the circle to be drawn
-- @return circular forma.pattern of radius `r` and origin `(0,0)`
function primitives.circle(r)
    assert(type(r) == 'number', 'primitives.circle requires a number for the radius')
    assert(r >= 0, 'primitives.circle requires a positive number for the radius')

    local x, y = -r,0
    local acc = 2-2*r

    local cp = pattern.new()
    repeat
        cp:insert(-x,  y)
        cp:insert(-y, -x)
        cp:insert( x, -y)
        cp:insert( y,  x)

        r = acc
        if (r <= y) then
            y = y + 1
            acc = acc + y*2 + 1
        end
        if (r > x or acc > y) then
            x = x + 1
            acc = acc + x*2+1;
        end
    until (x == 0)

    return cp
end

return primitives
