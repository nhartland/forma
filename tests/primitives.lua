--- Tests of basic forma primitives
local lu            = require('luaunit')
local cell          = require("forma.cell")
local pattern       = require("forma.pattern")
local primitives    = require("forma.primitives")
local symmetry      = require("forma.symmetry")
local neighbourhood = require("forma.neighbourhood")

TestPrimitives = {}

-- Test circle raster ------------------------------------------------
function TestPrimitives:testCircle()
    for i = 1, 10, 1 do
        local circle_raster = primitives.circle(i)
        -- Check that all holes are less than i from centre
        local inside_circle = pattern.interior_holes(circle_raster)
        lu.assertEquals(#inside_circle, 1) -- Should only be one hole
        for pt in inside_circle[1]:cells() do
            lu.assertTrue(cell.euclidean(pt, cell.new(0, 0)) < i)
        end
    end
end

-- Test square raster ------------------------------------------------
function TestPrimitives:testSquare()
    for i = 1, 10, 1 do
        -- Check that there are the correct number of points
        local square_raster = primitives.square(i)
        lu.assertEquals(square_raster:size(), i * i)
    end
    local test_pattern = pattern.new({ { 1, 1 }, { 1, 1 } })
    lu.assertTrue(test_pattern == primitives.square(2))
end

-- Test line raster ------------------------------------------------
function TestPrimitives:testLine()
    -- Draw a bunch of lines, check their properties
    for _ = 1, 100, 1 do
        local start  = cell.new(math.random(-100, 100), math.random(-100, 100))
        local finish = cell.new(math.random(-100, 100), math.random(-100, 100))
        local line   = primitives.line(start, finish)

        -- Must have start and finish cells
        lu.assertTrue(line:has_cell(start.x, start.y))
        lu.assertTrue(line:has_cell(finish.x, finish.y))
        -- Must consist of one contiguous area
        local floodfill = pattern.floodfill(line, start)
        lu.assertTrue(floodfill == line)
    end

    -- Test horizontal line
    local h_start = cell.new(0, 0)
    local h_finish = cell.new(10, 0)
    local h_line = primitives.line(h_start, h_finish)
    lu.assertEquals(h_line:size(), 11)
    lu.assertTrue(h_line:has_cell(5, 0))

    -- Test vertical line
    local v_start = cell.new(0, 0)
    local v_finish = cell.new(0, 10)
    local v_line = primitives.line(v_start, v_finish)
    lu.assertEquals(v_line:size(), 11)
    lu.assertTrue(v_line:has_cell(0, 5))
end

-- Test Bezier raster ------------------------------------------------
function TestPrimitives:testBezier()
    -- Draw a bunch of lines, check their properties
    for N = 1, 10, 1 do
        local start   = cell.new(math.random(-100, 100), math.random(-100, 100))
        local control = cell.new(math.random(-100, 100), math.random(-100, 100))
        local finish  = cell.new(math.random(-100, 100), math.random(-100, 100))
        local line    = primitives.quad_bezier(start, control, finish, N)

        -- Must have start and finish cells
        lu.assertTrue(line:has_cell(start.x, start.y))
        lu.assertTrue(line:has_cell(finish.x, finish.y))
        -- Must consist of one contiguous area
        local floodfill = pattern.floodfill(line, start)
        lu.assertTrue(floodfill == line)
    end
end

-- Test animals -----------------------------------------------------
function TestPrimitives:testPolyominos()
    -- Expected number of polyominos of each size
    local fixed_cardinality = { 1, 2, 6, 19, 63, 216 }
    local free_cardinality  = { 1, 1, 2, 5, 12, 35 }
    for n = 1, 6, 1 do
        lu.assertEquals(
            primitives.animals(n):n_components(),
            fixed_cardinality[n]
        )
        lu.assertEquals(
            primitives.animals(n, nil, symmetry.groups.D4):n_components(),
            free_cardinality[n]
        )
    end
end

function TestPrimitives:testPolyplets()
    -- Expected number of polyplets of each size
    local fixed_cardinality = { 1, 4, 20, 110, 638, 3832 }
    local free_cardinality  = { 1, 2, 5, 22, 94, 524 }
    for n = 1, 6, 1 do
        lu.assertEquals(
            primitives.animals(n, neighbourhood.moore()):n_components(),
            fixed_cardinality[n]
        )
        lu.assertEquals(
            primitives.animals(n, neighbourhood.moore(), symmetry.groups.D4):n_components(),
            free_cardinality[n]
        )
    end
end
