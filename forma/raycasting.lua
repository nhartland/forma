--- Ray tracing algorithms
-- Algorithms for identifying visible segments of a pattern from a single cell
-- This can be used for 'field of view' applications
-- Sources:
-- http:--www.adammil.net/blog/v125_Roguelike_Vision_Algorithms.html
-- http://www.roguebasin.com/index.php?title=LOS_using_strict_definition

local ray     = {}

local cell    = require('forma.cell')
local pattern = require('forma.pattern')

--- Casts a ray from a start to an end cell.
-- Returns {true/false} if the cast is successful/blocked.
-- Adapted from: http://www.roguebasin.com/index.php?title=LOS_using_strict_definition
-- @param v0 starting cell of ray
-- @param v1 end cell of ray
-- @param the domain in which we are casting
-- @return true or false depending on whether the ray was successfully cast
function ray.cast(v0, v1, domain)
    assert(getmetatable(v0) == cell, "ray.cast requires a cell as the first argument")
    assert(getmetatable(v1) == cell, "ray.cast requires a cell as the second argument")
    assert(getmetatable(domain) == pattern, "ray.cast requires a pattern as the third argument")
    -- Start or end cell was already blocked
    if domain:has_cell(v0.x, v0.y) == false or domain:has_cell(v1.x, v1.y) == false then
        return false
    end
    -- Initialise line walk
    local dv = v1 - v0
    local sx = (v0.x < v1.x) and 1 or -1
    local sy = (v0.y < v1.y) and 1 or -1
    -- Rasterise step by step
    local nx = v0:clone()
    local denom = cell.euclidean(v1, v0)
    while (nx.x ~= v1.x or nx.y ~= v1.y) do
        -- Ray is blocked
        if domain:has_cell(nx.x, nx.y) == false then
            return false
            -- Ray is not blocked, calculate next step
        elseif (math.abs(dv.y * (nx.x - v0.x + sx) - dv.x * (nx.y - v0.y)) / denom < 0.5) then
            nx.x = nx.x + sx
        elseif (math.abs(dv.y * (nx.x - v0.x) - dv.x * (nx.y - v0.y + sy)) / denom < 0.5) then
            nx.y = nx.y + sy
        else
            nx.x = nx.x + sx
            nx.y = nx.y + sy
        end
    end
    -- Successfully traced a ray
    return true
end

--- Casts rays from a start cell across an octant.
-- @param v0 starting cell of ray
-- @param the domain in which we are casting
-- @param the octant identifier (integer between 1 and 8)
-- @param radius the maximum length of the ray
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
    local lit_pattern = pattern.new()
    for row = 1, ray_length, 1 do
        for col = 0, row, 1 do
            local tcol, trow = transformOctant(row, col)
            local v1 = v0:clone() + cell.new(tcol, -trow)
            if cell.euclidean2(v0, v1) < ray_length * ray_length then
                local ray_status = ray.cast(v0, v1, domain)
                -- Successful ray casting, add to the illuminated pattern
                if ray_status == true then
                    lit_pattern:insert(v1.x, v1.y)
                end
            end
        end
    end
    return lit_pattern
end

--- Casts rays from a starting cell in all directions
-- @param v0 starting cell of ray
-- @param the domain in which we are casting
-- @param the maximum length of the ray
-- @return the pattern illuminated by the ray casting
function ray.cast_360(v, domain, ray_length)
    assert(getmetatable(v) == cell, "ray.cast_360 requires a cell as the first argument")
    assert(getmetatable(domain) == pattern, "ray.cast_360 requires a pattern as the second argument")
    assert(type(ray_length) == 'number', "ray.cast_360 requires a number as the third argument")
    local lit_pattern = pattern.new():insert(v.x, v.y)
    for ioct = 1, 8, 1 do
        local np = ray.cast_octant(v, domain, ioct, ray_length)
        lit_pattern = lit_pattern + np
    end
    return lit_pattern
end

return ray
