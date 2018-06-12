--- Tests of subpattern construction
local lu = require('luaunit')

local cell          = require("forma.cell")
local pattern       = require("forma.pattern")
local primitives    = require("forma.primitives")
local subpattern    = require("forma.subpattern")
local neighbourhood = require("forma.neighbourhood")

testSubPatterns = {}

function testSubPatterns:setUp()
    -- Test patterns for Voronoi tesselation and random sampling tests
    self.square = primitives.square(10)
    self.seeds = subpattern.random(self.square, 0.1)
end

--  FloodFill -------------------------------------------------------------------------
function testSubPatterns:testFloodFill()
    -- Basic test of flood-fill algorithm. Tested on a fully-(moore) connected
    -- pattern it should return the same pattern as input. The shift is just a
    -- consistency check.
    local test_pattern = pattern.new({{1,0,0,1,},
                                      {0,1,1,0,},
                                      {0,1,1,0,},
                                      {1,0,0,1,}}):shift(100,-100)
    local floodfill = subpattern.floodfill(test_pattern,
                                           test_pattern:rcell(),
                                           neighbourhood.moore())
    lu.assertEquals(floodfill, test_pattern)
end

--  FloodFill segments ----------------------------------------------------------------
function testSubPatterns:testFFSegments()
    -- Measure the number of connected segments in a pattern by flood-filling.
    -- This test pattern should return one segment for the Moore neighbourhood,
    -- and five for the von Neumann neighbourhood. The shift is just a
    -- consistency check.
    local test_pattern = pattern.new({{1,0,0,1,},
                                      {0,1,1,0,},
                                      {0,1,1,0,},
                                      {1,0,0,1,}}):shift(100,-100)
    local moore_segments = subpattern.segments(test_pattern, neighbourhood.moore())
    local vn_segments    = subpattern.segments(test_pattern, neighbourhood.von_neumann())
    lu.assertEquals(#moore_segments, 1)
    lu.assertEquals(#vn_segments, 5)
end

--  Enclosed segments ----------------------------------------------------------------
function testSubPatterns:testEnclosed()
    -- Test pattern should return one enclosed area for Moore neighbourhood,
    -- and two areas for von Neumann neighbourhood. The shift is just a
    -- consistency check.
    local test_pattern = pattern.new({{1,1,1,1,1,1,1},
                                      {1,0,0,0,0,0,1},
                                      {1,0,0,1,0,0,1},
                                      {1,0,1,0,1,0,1},
                                      {1,0,0,1,0,0,1},
                                      {1,0,0,0,0,0,1},
                                      {1,1,1,1,1,1,1}}):shift(100,-100)
    local moore_segments = subpattern.enclosed(test_pattern, neighbourhood.moore())
    local vn_segments    = subpattern.enclosed(test_pattern, neighbourhood.von_neumann())
    lu.assertEquals(#moore_segments, 1)
    lu.assertEquals(#vn_segments, 2)
    lu.assertFalse(self:check_for_overlap(vn_segments))
    -- Check that neighbourhood defaults to vN, and edge diagonal case
    local test_circle = primitives.circle(1)
    lu.assertEquals(#subpattern.enclosed(test_circle),1)
end

--  Random sampling ------------------------------------------------------------------
function testSubPatterns:testRandom()
    lu.assertEquals(getmetatable(self.seeds),  pattern)
    lu.assertEquals(pattern.size(self.seeds), 10)
    lu.assertTrue(self:check_for_overlap({self.square, self.seeds}))
end

--  Maximum Rectangle  ---------------------------------------------------------------
function testSubPatterns:testMaxRectangle()
    -- Basic test of the 'maximum rectangular area' subpattern finder.
    -- When run on a square pattern, it should return the input pattern.
    local rect = subpattern.maxrectangle(self.square)
    lu.assertEquals(rect, self.square)
    -- Adding a single extra point far from the square pattern should not change anything
    local extra_point = self.square + pattern.new():insert(1000,1000)
    local rect2 = subpattern.maxrectangle(extra_point)
    lu.assertEquals(rect2, self.square)
end

--  Binary space partitioning  -------------------------------------------------------
function testSubPatterns:testBinarySpacePartition()
    -- Testing on a square test pattern. The returned segments should all
    -- have fewer than 10 active cells.
    local partitions  = subpattern.bsp(self.square, 10)
    local total_points = 0
    for _, partition in ipairs(partitions) do
        total_points = total_points + partition:size()
        lu.assertTrue(partition:size() <= 10 )
    end
    lu.assertEquals(total_points, self.square:size())
    lu.assertEquals(pattern.sum(unpack(partitions)), self.square)
    lu.assertFalse(self:check_for_overlap(partitions))
end

-- Voronoi tesselation ---------------------------------------------------------------
function testSubPatterns:commonVoronoi(measure)
    local voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)

    -- Check for the correct number of segments, and that there are no overlaps
    lu.assertEquals(#voronoi_segments, self.seeds:size())
    lu.assertFalse(self:check_for_overlap(voronoi_segments))

    -- Check that, for every cell in every segment, the
    -- closest seed for that segment intersects with the segment
    -- (should define a voronoi tesselation)
    for _,segment in ipairs(voronoi_segments) do
        -- Loop over all cells in this segment
        for _, segment_cell in ipairs(segment:cell_list()) do
            -- Find the closest seed to this cell
            local closest_seed, seed_distance = nil, math.huge
            for _, seed_cell in ipairs(self.seeds:cell_list()) do
                local distance = measure(segment_cell, seed_cell)
                if distance < seed_distance then
                    seed_distance = distance
                    closest_seed = seed_cell
                end
            end

            -- Ensure that the closest seed is in the cell
            lu.assertTrue(segment:has_cell(closest_seed.x, closest_seed.y))
        end
    end
end

-- Test Voronoi tesselation with various distance measures
function testSubPatterns:testVoronoi_Manhattan()
    self:commonVoronoi(cell.manhattan)
end
function testSubPatterns:testVoronoi_Euclidean()
    self:commonVoronoi(cell.euclidean)
end
function testSubPatterns:testVoronoi_Chebyshev()
    self:commonVoronoi(cell.chebyshev)
end

-- Helper functions ------------------------------------------------------------------
function testSubPatterns:check_for_overlap(segments)
    -- Check that no segments overlap
    -- Returns true if there is an overlap, false otherwise
    for i=1, #segments-1, 1 do
        for j=i+1, #segments, 1 do
            local int = pattern.intersection(segments[i], segments[j])
            if int:size() ~= 0 then return true end
        end
    end
    return false
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
