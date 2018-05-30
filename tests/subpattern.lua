--- Tests of subpattern construction
local lu = require('tests/luaunit')

local point = require("point")
local pattern = require("pattern")
local subpattern = require("subpattern")

testSubPatterns = {}

function testSubPatterns:setUp()
    self.square = pattern.square(10)
    self.seeds = subpattern.random(self.square, 0.1) -- For voronoi tesselation
end

--- Test the random sampling of patterns
function testSubPatterns:testRandom()
    lu.assertEquals(pattern.size(self.seeds), 10)
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

-- Common Voronoi tesselation testing
function testSubPatterns:commonVoronoi(measure)
    voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)

    -- Check for the correct number of segments
    lu.assertEquals(#voronoi_segments, self.seeds:size())

    -- Check that no segments overlap
    -- TODO: This part of the test is very slow, need to improve pattern.intersection
    for i=1, #voronoi_segments-1, 1 do
        for j=i+1, #voronoi_segments, 1 do
            -- Compute intersection
            local int = pattern.intersection(voronoi_segments[i], voronoi_segments[j])
            lu.assertEquals(int:size(),  0)
        end
    end

    -- Check that, for every point in every segment, the
    -- closest seed for that segment intersects with the segment
    -- (should define a voronoi tesselation)
    for _,segment in ipairs(voronoi_segments) do
        -- Loop over all cells in this segment
        for icell, segment_cell in ipairs(segment:pointlist()) do
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

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
