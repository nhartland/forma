--- Tests of basic forma primitives
local lu = require('luaunit')
local cell       = require("forma.cell")
local primitives = require("forma.primitives")
local subpattern = require("forma.subpattern")

testPrimitives = {}

function testPrimitives:setUp()
end

-- Test circle raster ------------------------------------------------
function testPrimitives:testCircle()
    for i=1,10,1 do
        local circle_raster = primitives.circle(i)
        -- Check that all enclosed points are less than i from centre
        local inside_circle = subpattern.enclosed(circle_raster)
        lu.assertEquals(#inside_circle, 1) -- Should only be one enclosed segment
        local inside_points = inside_circle[1]:cell_list()
        for _,pt in ipairs(inside_points) do
            lu.assertTrue(cell.euclidean(pt, cell.new(0,0)) < i )
        end

    end
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
