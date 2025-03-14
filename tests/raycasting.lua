--- Tests of basic forma primitives
local lu         = require('luaunit')
local pattern    = require("forma.pattern")
local primitives = require("forma.primitives")
local raycasting = require("forma.raycasting")

TestRaycasting   = {}

-- Test single ray ------------------------------------------------
function TestRaycasting:testRay()
    -- Test here is simmilar to line primitives
    -- Draw a bunch of lines, check their properties
    local domain = primitives.square(100)
    for _ = 1, 100, 1 do
        local success = raycasting.cast(domain:rcell(), domain:rcell(), domain)
        -- Must succeed
        lu.assertTrue(success)
    end
end

-- Test 360 raycasting ------------------------------------------------
function TestRaycasting:test360()
    local domain = primitives.square(100)
    for _ = 1, 100, 1 do
        local start  = domain:rcell()
        local traced = raycasting.cast_360(start, domain, 5)
        -- Must have start cells
        lu.assertTrue(traced:has_cell(start.x, start.y))
        -- Most be contained within the domain
        lu.assertTrue(pattern.intersect(domain, traced) == traced)
        -- Must consist of one contiguous area
        local floodfill = pattern.floodfill(traced, start)
        lu.assertTrue(floodfill==traced)
    end
end
