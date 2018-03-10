--- Geometric pattern generation by rasterisation
-- This module implements pattern generation by the Bresenham line drawing and
-- circle algorithms.
-- @module forma.raster

local pattern = require('pattern')

local raster = {}


-- Verify that a point is not duplicated
-- Maybe should be in forma.pattern?
local function add_point(ip, x, y)
    if pattern.point(ip, x, y) == nil then
        pattern.insert(ip, x, y)
    end
end

--- Generate a circular pattern of a certain radius
-- http://willperone.net/Code/codecircle.php suggests a faster method
-- might be worth a look
-- @param r the radius of the circle to be drawn
-- @return a rasterised circle pattern with the requested radius
function raster.circle(r)
    local cp = pattern.new()
    local x, y = 0, r
    local p = 3 - 2*r
    if r == 0 then return cp end
    while (y >= x) do
        add_point(cp, -x, -y)
        add_point(cp, -y, -x)
        add_point(cp,  y, -x)
        add_point(cp,  x, -y)
        add_point(cp, -x,  y)
        add_point(cp, -y,  x)
        add_point(cp,  y,  x)
        add_point(cp,  x,  y)

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

return raster
