--- Tests of basic forma primitives
local lu = require('luaunit')
local pattern    = require("forma.pattern")
local primitives = require("forma.primitives")
local subpattern = require("forma.subpattern")
local raycasting = require("forma.raycasting")

testRaycasting = {}

-- Test single ray ------------------------------------------------
function testRaycasting:testRay()
    -- Test here is simmilar to line primitives
    -- Draw a bunch of lines, check their properties
    local domain = primitives.square(100)
    for _=1, 100, 1 do
        local start  = domain:rcell()
        local finish = domain:rcell()
        local ray = raycasting.cast( start, finish, domain )

        -- Must have start and finish cells
        lu.assertTrue(ray:has_cell(start.x,  start.y))
        lu.assertTrue(ray:has_cell(finish.x, finish.y))
        -- Must consist of one contiguous area
        local floodfill = subpattern.floodfill(ray, start)
        lu.assertEquals(floodfill, ray)
    end
end

-- Test 360 raycasting ------------------------------------------------
function testRaycasting:test360()
    local domain = primitives.square(100)
    for _=1, 100, 1 do
        local start  = domain:rcell()
        local traced = raycasting.cast_360( start, domain, 5 )
        -- Must have start cells
        lu.assertTrue(traced:has_cell(start.x,  start.y))
        -- Most be contained within the domain
        lu.assertEquals(pattern.intersection(domain, traced), traced)
        -- Must consist of one contiguous area
        local floodfill = subpattern.floodfill(traced, start)
        lu.assertEquals(floodfill, traced)
    end
end
