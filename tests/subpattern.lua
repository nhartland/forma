--- Tests of subpattern construction
local lu = require('luaunit')

local point         = require("forma.point")
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
                                           test_pattern:rpoint(),
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
end

--  Random sampling ------------------------------------------------------------------
function testSubPatterns:testRandom()
    lu.assertEquals(pattern.size(self.seeds), 10)
end

-- Voronoi tesselation ---------------------------------------------------------------
function testSubPatterns:commonVoronoi(measure)
    local voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)

    -- Check for the correct number of segments
    lu.assertEquals(#voronoi_segments, self.seeds:size())

    -- Check that no segments overlap
    for i=1, #voronoi_segments-1, 1 do
        for j=i+1, #voronoi_segments, 1 do
            local int = pattern.intersection(voronoi_segments[i], voronoi_segments[j])
            lu.assertEquals(int:size(),  0)
        end
    end

    -- Check that, for every point in every segment, the
    -- closest seed for that segment intersects with the segment
    -- (should define a voronoi tesselation)
    for _,segment in ipairs(voronoi_segments) do
        -- Loop over all cells in this segment
        for _, segment_cell in ipairs(segment:pointlist()) do
            -- Find the closest seed to this cell
            local closest_seed, seed_distance = nil, math.huge
            for _, seed_cell in ipairs(self.seeds:pointlist()) do
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
    self:commonVoronoi(point.manhattan)
end
function testSubPatterns:testVoronoi_Euclidean()
    self:commonVoronoi(point.euclidean)
end
function testSubPatterns:testVoronoi_Chebyshev()
    self:commonVoronoi(point.chebyshev)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
