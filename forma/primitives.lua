--- Primitive (line, rectangle and circle) patterns.
--- This module provides convenience functions for the generation of basic
--- `pattern` shapes. So far including lines, squares/rectangles and circle
--- rasters.
---
--- ```lua
--- -- Draw some squares
--- local square_pattern = primitives.square(5)      -- 5x5
--- local rectangle_pattern = primitives.square(3,5) -- 3x5
---
--- -- Draw a line
--- local line = primitives.line(cell.new(0,0), cell.new(10,10))
---
--- -- Draw a circle about (0,0) with radius 5
--- local circle = primitives.circle(5)
--- ```
---@class forma.primitives
local primitives = {}

local cell          = require('forma.cell')
local pattern       = require('forma.pattern')
local symmetry      = require('forma.symmetry')
local multipattern  = require('forma.multipattern')
local neighbourhood = require('forma.neighbourhood')

--- Generate a square pattern.
---
--- ```lua
--- local sq = primitives.square(5)
--- local rect = primitives.square(3, 5)
--- ```
---@param x number size in x
---@param y? number size in y (default `y = x`)
---@return forma.pattern pattern square pattern of size `{x, y}`
function primitives.square(x, y)
    y = y ~= nil and y or x
    assert(type(x) == "number",
        'primitives.square requires a number as the first argument')
    assert(type(y) == "number",
        'primitives.square requires either a number or nil as a second argument')

    local sqPattern = pattern.new()
    for i = 0, x - 1, 1 do
        for j = 0, y - 1, 1 do
            sqPattern:insert(i, j)
        end
    end

    return sqPattern
end

--- Generate a line pattern.
--- According to Bresenham's line algorithm.
---
--- ```lua
--- local line = primitives.line(cell.new(0, 0), cell.new(10, 10))
--- ```
---@param start forma.cell a cell denoting the start of the line
---@param finish forma.cell a cell denoting the end of the line
---@return forma.pattern pattern a pattern consisting of a line between `start` and `finish`
function primitives.line(start, finish)
    assert(getmetatable(start) == cell, "primitives.line requires a cell as the first argument")
    assert(getmetatable(finish) == cell, "primitives.line requires a cell as the second argument")
    local deltax = finish.x - start.x
    local sx = (deltax > 0 and 1) or (deltax < 0 and -1) or 0
    deltax = math.abs(deltax) * 2

    local deltay = finish.y - start.y
    local sy = (deltay > 0 and 1) or (deltay < 0 and -1) or 0
    deltay = math.abs(deltay) * 2

    local x, y = start.x, start.y
    local line = pattern.new():insert(x, y)

    if deltax >= deltay then
        local err = deltay - deltax / 2
        while x ~= finish.x do
            if err > 0 or (err == 0 and sx > 0) then
                err = err - deltax
                y = y + sy
            end
            err = err + deltay
            x = x + sx
            line:insert(x, y)
        end
    else
        local err = deltax - deltay / 2
        while y ~= finish.y do
            if err > 0 or (err == 0 and sy > 0) then
                err = err - deltay
                x = x + sx
            end
            err = err + deltax
            y = y + sy
            line:insert(x, y)
        end
    end
    return line
end

--- Draw a quadratic bezier curve.
--- Uses an algorithm from rosettacode.org.
--- This function returns both a pattern consisting of the drawn bezier curve,
--- and a list of points along the curve. This may be important in case the
--- curve back-tracks over existing cells, which cannot be represented in a
--- forma `pattern`. The full pattern consists of `N` of these points, joined
--- by bresenham line segments.
---
--- ```lua
--- local curve, points = primitives.quad_bezier(
---     cell.new(0, 0), cell.new(5, 10), cell.new(10, 0))
--- ```
---@param start forma.cell a cell denoting the start of the curve
---@param control forma.cell a cell denoting the control point of the curve
---@param finish forma.cell a cell denoting the end of the curve
---@param N? integer number of line-segments to construct the curve with (default: 20)
---@return forma.pattern pattern a pattern consisting of the bezier curve
---@return forma.cell[] points an ordered list of cells consisting of points along the curve
function primitives.quad_bezier(start, control, finish, N)
    if N == nil then N = 20 end
    assert(getmetatable(start) == cell, "primitives.quad_bezier requires a cell as the first argument")
    assert(getmetatable(control) == cell, "primitives.quad_bezier requires a cell as the second argument")
    assert(getmetatable(finish) == cell, "primitives.quad_bezier requires a cell as the third argument")
    assert(type(N) == 'number' and N > 0,
        "primitives.quad_bezier requires an integer with value at least 1 as fourth argument")
    local x1, y1 = start.x, start.y
    local x2, y2 = control.x, control.y
    local x3, y3 = finish.x, finish.y
    local line_points = { cell.new(x1, y1) }
    for i = 1, N, 1 do
        local t = i / N;
        local a = math.pow((1.0 - t), 2.0)
        local b = 2.0 * t * (1.0 - t);
        local c = math.pow(t, 2.0);
        local x = math.floor(a * x1 + b * x2 + c * x3 + 0.5)
        local y = math.floor(a * y1 + b * y2 + c * y3 + 0.5)
        local new_point = cell.new(x, y)
        local last_point = line_points[#line_points]
        -- Remove duplicate points
        if new_point ~= last_point then
            table.insert(line_points, new_point)
        end
    end
    -- Build the curve from the points
    local bezier = pattern.new()
    for i = 1, #line_points - 1, 1 do
        local line = primitives.line(line_points[i], line_points[i + 1])
        for x, y in line:cell_coordinates() do
            bezier:insert(x, y, false)
        end
    end
    return bezier, line_points
end

--- Generate a circle pattern.
--- Bresenham algorithm.
---
--- ```lua
--- local circle = primitives.circle(5)
--- ```
---@param r number the radius of the circle to be drawn
---@return forma.pattern pattern circular pattern of radius `r` and origin `(0,0)`
function primitives.circle(r)
    assert(type(r) == 'number', 'primitives.circle requires a number for the radius')
    assert(r > 0, 'primitives.circle requires a positive number for the radius')

    local x, y = -r, 0
    local acc = 2 - 2 * r

    local cp = pattern.new()
    repeat
        cp:insert(-x, y)
        cp:insert(-y, -x)
        cp:insert(x, -y)
        cp:insert(y, x)

        r = acc
        if (r <= y) then
            y = y + 1
            acc = acc + y * 2 + 1
        end
        if (r > x or acc > y) then
            x = x + 1
            acc = acc + x * 2 + 1;
        end
    until (x == 0)

    return cp
end

--- Generate a set of lattice animals.
---
--- Depending on the neighbourhood these could be:
---  von Neumann (default): polyominos
---  Moore: polyplets
---
--- ```lua
--- local free_polyominos = primitives.animals(5, nbh.von_neumann(), symmetry.groups.D4)
--- local fixed_polyominos = primitives.animals(5, nbh.von_neumann(), symmetry.groups.C1)
--- local one_sided_polyominos = primitives.animals(5, nbh.von_neumann(), symmetry.groups.C4)
--- ```
---@param n integer the order of the lattice animal to be generated
---@param nbh? forma.neighbourhood the neighbourhood to be considered
---@param G? forma.symmetry.group a symmetry group to deduplicate the animals by
---@return forma.multipattern pattern a multipattern of animals
function primitives.animals(n, nbh, G)
    -- By default do not deduplicate animals, use the trivial group
    G = G or symmetry.groups.C1
    -- By default use the von Neumann neighbourhood -> generates polyominos
    nbh = nbh or neighbourhood.von_neumann()
    assert(type(n) == 'number' and n > 0, "primitives.animals requires a positive integer as the first argument")
    assert(math.floor(n) == n, "primitives.animals requires an integer as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "primitives.animals requires a neighbourhood as the second argument")
    assert(getmetatable(G) == symmetry.group, "primitives.animals requires a group as the third argument")
    local animals = multipattern.new({ primitives.square(1) })
    for _ = 2, n, 1 do
        local new_animals = multipattern.new()
        for _, animal in ipairs(animals.components) do
            local edges = animal:exterior_hull(nbh)
            for x, y in edges:cell_coordinates() do
                new_animals:insert(
                    animal:clone()
                    :insert(x, y)
                    :canonical_form(G)
                )
            end
        end
        animals = new_animals:distinct()
    end
    return animals
end

return primitives
