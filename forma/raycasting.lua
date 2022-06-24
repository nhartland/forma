--- Ray tracing algorithms
-- Algorithms for identifying visible segments of a pattern from a single cell
-- This can be used for 'field of view' applications
-- Sources:
-- http:--www.adammil.net/blog/v125_Roguelike_Vision_Algorithms.html
-- http://www.roguebasin.com/index.php?title=LOS_using_strict_definition

local ray = {}

local cell          = require('forma.cell')
local pattern       = require('forma.pattern')

--- Casts a ray from a start to an end cell.
-- Returns {true/false} if the cast is successful/blocked, along with a pattern
-- of the ray trajectory. Simmilar to primitives.line, but taking a traversible
-- domain into account.
-- Adapted from: http://www.roguebasin.com/index.php?title=LOS_using_strict_definition
-- @param v0 starting cell of ray
-- @param v1 end cell of ray
-- @param the domain in which we are casting
-- @return (true/false (if the ray was unblocked/blocked), the ray pattern)
function ray.cast(v0, v1, domain)

    -- Start cell was already blocked
    if domain:has_cell(v0.x, v0.y) == false then
        return false, pattern.new()
    end

    -- Initial pattern
    local lit_pattern = pattern.new():insert(v0.x, v0.y)

    local dv = v1 - v0
    local sx = (v0.x < v1.x) and 1 or -1
    local sy = (v0.y < v1.y) and 1 or -1

    local nx = v0:clone()
    local denom = cell.euclidean(v1, v0)
    while (nx.x ~= v1.x or nx.y ~= v1.y) do
        if (domain:has_cell(nx.x, nx.y) == false) then return false, lit_pattern end
        if(math.abs(dv.y * (nx.x - v0.x + sx) - dv.x * (nx.y - v0.y)) / denom < 0.5) then
            nx.x = nx.x + sx
        elseif(math.abs(dv.y * (nx.x - v0.x) - dv.x * (nx.y - v0.y + sy)) / denom < 0.5) then
            nx.y = nx.y + sy
        else
            nx.x = nx.x + sx
            nx.y = nx.y + sy
        end
    end
    if domain:has_cell(nx.x, nx.y) then
        lit_pattern:insert(nx.x, nx.y)
    end
    return true, lit_pattern
end

--- Casts rays from a start cell across an octant.
-- @param v0 starting cell of ray
-- @param the domain in which we are casting
-- @param the octant identifier (integer between 1 and 8)
-- @param radius the maximum length of the ray
-- @return the pattern illuminated by the ray casting
function ray.cast_octant(v0, domain, oct, ray_length)
    local function transformOctant(r, c)
        if oct == 1 then return r, -c end
        if oct == 2 then return r,  c end
        if oct == 3 then return c,  r end
        if oct == 4 then return -c,  r end
        if oct == 5 then return -r,  c end
        if oct == 6 then return -r, -c end
        if oct == 7 then return -c, -r end
        if oct == 8 then return c, -r end
    end
    local lit_pattern = pattern.new()
    for row=1,ray_length,1 do
        for col=0,row,1 do
            local tcol,trow = transformOctant(row,col)
            local v1 = v0:clone() + cell.new(tcol, -trow)
            if cell.euclidean2(v0, v1) < ray_length*ray_length then
                _, np = ray.cast(v0,v1,domain)
                lit_pattern = lit_pattern + np
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
    local lit_pattern = pattern.new()
    for ioct=1,8,1 do
        local np = ray.cast_octant(v, domain, ioct, ray_length)
        lit_pattern = lit_pattern + np
    end
    return lit_pattern
end

return ray
