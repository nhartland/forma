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
    self.seeds = subpattern.random(self.square, 10)
end

--  Masked subpattern  ---------------------------------------------------------------
function testSubPatterns:testMask()
    -- Mask out all seed points from the square input pattern,
    -- then check that the masked pattern is identical to
    -- the input pattern minus the seeds.
    local mask = function(icell)
        return self.seeds:has_cell(icell.x, icell.y) == false
    end
    local masked_pattern = subpattern.mask(self.square, mask)
    lu.assertEquals(masked_pattern, self.square - self.seeds)
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

--  Perlin noise ----------------------------------------------------------------
function testSubPatterns:testPerlin()
    -- Test subpattern generation by thresholding perlin noise.
    local test_domain = primitives.square(80, 20)
    local frequency, depth = 0.2, 1
    local thresholds = {0, 0.5, 0.7, 1}
    local noise  = subpattern.perlin(test_domain, frequency, depth, thresholds)
    lu.assertEquals(test_domain, noise[1]) -- Lowest threshold is zero, should be identical to domain
    lu.assertEquals(noise[4]:size(), 0)    -- Lowest threshold is one, should be an empty pattern

    -- Patterns should be progressively smaller as we move up the thresholds
    for ith=2, #thresholds, 1 do
        lu.assertTrue(noise[ith]:size() <= noise[ith-1]:size())
    end
end

--  Random sampling ------------------------------------------------------------------
function testSubPatterns:testRandom()
    lu.assertEquals(getmetatable(self.seeds),  pattern)
    lu.assertEquals(pattern.size(self.seeds), 10)
    lu.assertTrue(self:check_for_overlap({self.square, self.seeds}))
end

--  Poisson-disc sampling ------------------------------------------------------------------
function testSubPatterns:testPoissonDisk()
    local r = 3
    local measure  = cell.chebyshev
    local domain = primitives.square(10)
    local sample = subpattern.poisson_disc(domain, measure, r)
    -- In a poisson disc sample, all sample points should be at least `r` from each other
    local cell_list = sample:cell_list()
    for i = 1, #cell_list, 1 do
        for j = i+1, #cell_list, 1 do
            lu.assertTrue(measure(cell_list[i], cell_list[j]) >= r )
        end
    end
    -- Check that domain is unmodified
    lu.assertEquals(domain:size(), 100)
    -- Check that the sample doesn't fall out of the domain
    lu.assertTrue(self:check_for_overlap({domain, sample}))
end

-- Mitchell's best-candidate sampling -------------------------------------------------
function testSubPatterns:testMitchellSampling()
    -- Approximate Poisson-disc by Mitchell's best-candidate algorithm
    local measure = cell.chebyshev
    local domain  = primitives.square(10)
    local sample  = subpattern.mitchell_sample(domain, measure, 10, 10)
    -- Check that domain is unmodified
    lu.assertEquals(domain:size(), 100)
    -- Check that the sample doesn't fall out of the domain
    lu.assertTrue(self:check_for_overlap({domain, sample}))
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
    local resum = pattern.new()
    for _, partition in ipairs(partitions) do
        resum = resum + partition
        total_points = total_points + partition:size()
        lu.assertTrue(partition:size() <= 10 )
    end
    lu.assertEquals(total_points, self.square:size())
    lu.assertEquals(resum, self.square)
    lu.assertFalse(self:check_for_overlap(partitions))
end

-- Categorisation subpatterns --------------------------------------------------------
function testSubPatterns:testCategories()
    -- Compute a random sample of the square 10x10 pattern with 40 samples
    local sample = subpattern.random(self.square, 40)
    -- Loop through a couple of example neighbourhoods
    local measures = {neighbourhood.moore(), neighbourhood.von_neumann()}
    for _, measure in ipairs(measures) do
        local c_segments = subpattern.neighbourhood_categories(sample, measure)
        -- Ensure each category pattern only contains correctly categorised points
        for cat, seg in ipairs(c_segments) do
            for icell in seg:cells() do
                local test_cat = measure:categorise(sample, icell)
                lu.assertEquals(cat, test_cat)
            end
        end
    end
end

--  Convex hull ---------------------------------------------------------------------
-- Tests the function returning all points on the convex hull
function testSubPatterns:testConvexHullPoints()
    -- Pattern for running convex hull algorithm over
    local test_pattern = pattern.new({{1,0,0,0,1},
                                      {0,0,1,0,0},
                                      {0,1,1,1,0},
                                      {0,0,1,0,0},
                                      {1,0,0,0,1}})
    -- Actual points lying on the convex hull
    local true_pattern = pattern.new({{1,0,0,0,1},
                                      {0,0,0,0,0},
                                      {0,0,0,0,0},
                                      {0,0,0,0,0},
                                      {1,0,0,0,1}})
    local convex_hull  = subpattern.convex_hull_points(test_pattern)
    local overlap = pattern.intersection(convex_hull, true_pattern)
    lu.assertEquals(convex_hull:size(), overlap:size(), true_pattern:size())
end
-- Test the function computing the convex hull
function testSubPatterns:testConvexHull()
    -- Pattern for running convex hull algorithm over
    local test_pattern = pattern.new({{1,0,0,0,1},
                                      {0,0,1,0,0},
                                      {0,1,1,1,0},
                                      {0,0,1,0,0},
                                      {1,0,0,0,1}})
    -- Actual convex hull pattern
    local true_pattern = pattern.new({{1,1,1,1,1},
                                      {1,0,0,0,1},
                                      {1,0,0,0,1},
                                      {1,0,0,0,1},
                                      {1,1,1,1,1}})
    local convex_hull  = subpattern.convex_hull(test_pattern)
    local overlap = pattern.intersection(convex_hull, true_pattern)
    lu.assertEquals(convex_hull:size(), overlap:size(), true_pattern:size())
end
-- Voronoi tesselation ---------------------------------------------------------------
function testSubPatterns:commonVoronoi(voronoi_segments, seeds, measure)

    -- Check for the correct number of segments, and that there are no overlaps
    lu.assertEquals(#voronoi_segments, seeds:size())
    lu.assertFalse(self:check_for_overlap(voronoi_segments))

    -- Check that, for every cell in every segment, the
    -- closest seed for that segment intersects with the segment
    -- (should define a voronoi tesselation)
    for _,segment in ipairs(voronoi_segments) do
        -- Loop over all cells in this segment
        for segment_cell in segment:cells() do
            -- Find the closest seed to this cell
            local closest_seed, seed_distance = nil, math.huge
            for seed_cell in seeds:cells() do
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
    local measure = cell.manhattan
    local voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_segments, self.seeds, measure)
end
function testSubPatterns:testVoronoi_Euclidean()
    local measure = cell.euclidean
    local voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_segments, self.seeds, measure)
end
function testSubPatterns:testVoronoi_Chebyshev()
    local measure = cell.chebyshev
    local voronoi_segments = subpattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_segments, self.seeds, measure)
end
function testSubPatterns:testLloydsAlgorithm()
    local measure = cell.chebyshev
    local segments, centres, converged = subpattern.voronoi_relax(self.seeds, self.square, measure)
    self:commonVoronoi(segments, centres, measure)
end
-- Helper functions ------------------------------------------------------------------
function testSubPatterns:check_for_overlap(segments)
    -- Check that segments overlap
    -- Returns true if there is an overlap, false otherwise
    for i=1, #segments-1, 1 do
        for j=i+1, #segments, 1 do
            local int = pattern.intersection(segments[i], segments[j])
            if int:size() ~= 0 then return true end
        end
    end
    return false
end
