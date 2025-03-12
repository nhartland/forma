--- Tests of basic forma primitives
local lu = require('luaunit')
local cell       = require("forma.cell")
local pattern    = require("forma.pattern")
local primitives = require("forma.primitives")

TestPrimitives = {}

-- Test circle raster ------------------------------------------------
function TestPrimitives:testCircle()
    for i=1,10,1 do
        local circle_raster = primitives.circle(i)
        -- Check that all holes are less than i from centre
        local inside_circle = pattern.interior_holes(circle_raster)
        lu.assertEquals(inside_circle:n_components(), 1) -- Should only be one hole
        for pt in inside_circle[1]:cells() do
            lu.assertTrue(cell.euclidean(pt, cell.new(0,0)) < i )
        end
    end
end
-- Test square raster ------------------------------------------------
function TestPrimitives:testSquare()
    for i=1,10,1 do
        -- Check that there are the correct number of points
        local square_raster = primitives.square(i)
        lu.assertEquals(square_raster:size(), i*i)
    end
    local test_pattern = pattern.new( {{1,1},{1,1}} )
    lu.assertEquals(test_pattern, primitives.square(2))
end
-- Test line raster ------------------------------------------------
function TestPrimitives:testLine()
    -- Draw a bunch of lines, check their properties
    for _=1, 100, 1 do
        local start  = cell.new(math.random(-100, 100), math.random(-100, 100))
        local finish = cell.new(math.random(-100, 100), math.random(-100, 100))
        local line = primitives.line( start, finish )

        -- Must have start and finish cells
        lu.assertTrue(line:has_cell(start.x,  start.y))
        lu.assertTrue(line:has_cell(finish.x, finish.y))
        -- Must consist of one contiguous area
        local floodfill = pattern.floodfill(line, start)
        lu.assertEquals(floodfill, line)
    end
end
-- Test Bezier raster ------------------------------------------------
function TestPrimitives:testBezier()
    -- Draw a bunch of lines, check their properties
    for N=1, 10, 1 do
        local start   = cell.new(math.random(-100, 100), math.random(-100, 100))
        local control = cell.new(math.random(-100, 100), math.random(-100, 100))
        local finish  = cell.new(math.random(-100, 100), math.random(-100, 100))
        local line = primitives.quad_bezier( start, control, finish, N )

        -- Must have start and finish cells
        lu.assertTrue(line:has_cell(start.x,  start.y))
        lu.assertTrue(line:has_cell(finish.x, finish.y))
        -- Must consist of one contiguous area
        local floodfill = pattern.floodfill(line, start)
        lu.assertEquals(floodfill, line)
    end
end
