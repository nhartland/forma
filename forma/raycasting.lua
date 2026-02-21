--- Ray tracing algorithms
-- Algorithms for identifying visible segments of a pattern from a single cell.
-- This can be used for 'field of view' applications.
--
-- Sources:
--
-- `http://www.adammil.net/blog/v125_Roguelike_Vision_Algorithms.html`
-- `http://www.roguebasin.com/index.php?title=LOS_using_strict_definition`
--
-- @module forma.raycasting

local ray = {}

local cell    = require('forma.cell')
local pattern = require('forma.pattern')

-- Internal ray cast
local function cast_xy(x0, y0, x1, y1, domain)
    -- Start or end cell was already blocked
    if not domain:has_cell(x0, y0) or not domain:has_cell(x1, y1) then
        return false
    end
    -- Initialise line walk
    local dx, dy = x1 - x0, y1 - y0
    local sx = (x0 < x1) and 1 or -1
    local sy = (y0 < y1) and 1 or -1
    -- Rasterise step by step
    local nx, ny = x0, y0
    local denom = math.sqrt(dx * dx + dy * dy)
    while nx ~= x1 or ny ~= y1 do
        -- Ray is blocked
        if not domain:has_cell(nx, ny) then
            return false
            -- Ray is not blocked, calculate next step
        elseif math.abs(dy * (nx - x0 + sx) - dx * (ny - y0)) / denom < 0.5 then
            nx = nx + sx
        elseif math.abs(dy * (nx - x0) - dx * (ny - y0 + sy)) / denom < 0.5 then
            ny = ny + sy
        else
            nx = nx + sx
            ny = ny + sy
        end
    end
    -- Successfully traced a ray
    return true
end

--- Casts a ray from a start to an end cell.
-- Returns {true/false} if the cast is successful/blocked.
-- Adapted from:
--
-- `http://www.roguebasin.com/index.php?title=LOS_using_strict_definition`
-- @param v0 starting cell of ray
-- @param v1 end cell of ray
-- @param domain the domain in which we are casting
-- @return true or false depending on whether the ray was successfully cast
function ray.cast(v0, v1, domain)
    assert(getmetatable(v0) == cell, "ray.cast requires a cell as the first argument")
    assert(getmetatable(v1) == cell, "ray.cast requires a cell as the second argument")
    assert(getmetatable(domain) == pattern, "ray.cast requires a pattern as the third argument")
    return cast_xy(v0.x, v0.y, v1.x, v1.y, domain)
end

--- Casts rays from a start cell across an octant.
-- @param v0 starting cell of ray
-- @param domain the domain in which we are casting
-- @param oct the octant identifier (integer between 1 and 8)
-- @param ray_length the maximum length of the ray
-- @return the pattern illuminated by the ray casting
function ray.cast_octant(v0, domain, oct, ray_length)
    assert(getmetatable(v0) == cell, "ray.cast_octant requires a cell as the first argument")
    assert(getmetatable(domain) == pattern, "ray.cast_octant requires a pattern as the second argument")
    assert(type(oct) == 'number', "ray.cast_octant requires a number as the third argument")
    assert(type(ray_length) == 'number', "ray.cast_octant requires a number as the fourth argument")
    local function transformOctant(r, c)
        if oct == 1 then return r, -c end
        if oct == 2 then return r, c end
        if oct == 3 then return c, r end
        if oct == 4 then return -c, r end
        if oct == 5 then return -r, c end
        if oct == 6 then return -r, -c end
        if oct == 7 then return -c, -r end
        if oct == 8 then return c, -r end
    end
    local x0, y0 = v0.x, v0.y
    local ray_length_sq = ray_length * ray_length
    local lit_pattern = pattern.new()
    for row = 1, ray_length do
        for col = 0, row do
            local tcol, trow = transformOctant(row, col)
            local x1, y1 = x0 + tcol, y0 - trow
            local dx, dy = x1 - x0, y1 - y0
            if dx * dx + dy * dy < ray_length_sq then
                if cast_xy(x0, y0, x1, y1, domain) then
                    lit_pattern:insert(x1, y1)
                end
            end
        end
    end
    return lit_pattern
end

--- Casts rays from a starting cell in all directions
-- @param v0 starting cell of ray
-- @param domain the domain in which we are casting
-- @param ray_length the maximum length of the ray
-- @return the pattern illuminated by the ray casting
function ray.cast_360(v0, domain, ray_length)
    assert(getmetatable(v0) == cell, "ray.cast_360 requires a cell as the first argument")
    assert(getmetatable(domain) == pattern, "ray.cast_360 requires a pattern as the second argument")
    assert(type(ray_length) == 'number', "ray.cast_360 requires a number as the third argument")
    local lit_pattern = pattern.new():insert(v0.x, v0.y)
    for ioct = 1, 8, 1 do
        local np = ray.cast_octant(v0, domain, ioct, ray_length)
        for x, y in np:cell_coordinates() do
            if not lit_pattern:has_cell(x, y) then
                lit_pattern:insert(x, y)
            end
        end
    end
    return lit_pattern
end

return ray
