--- Tests of subpattern construction
local lu            = require('luaunit')

local cell          = require("forma.cell")
local pattern       = require("forma.pattern")
local primitives    = require("forma.primitives")
local neighbourhood = require("forma.neighbourhood")

TestSubPatterns     = {}

function TestSubPatterns:setUp()
    -- Test patterns for Voronoi tesselation and random sampling tests
    self.square = primitives.square(10)
    self.seeds = pattern.sample(self.square, 10)
end

--  Filter subpattern  ---------------------------------------------------------------
function TestSubPatterns:testFilter()
    -- Filter out all seed points from the square input pattern,
    -- then check that the filtered pattern is identical to
    -- the input pattern minus the seeds.
    local fn = function(icell)
        return self.seeds:has_cell(icell.x, icell.y) == false
    end
    local filtered_pattern = pattern.filter(self.square, fn)
    lu.assertEquals(filtered_pattern, self.square - self.seeds)
end

--  FloodFill -------------------------------------------------------------------------
function TestSubPatterns:testFloodFill()
    -- Basic test of flood-fill algorithm. Tested on a fully-(moore) connected
    -- pattern it should return the same pattern as input. The translate is just a
    -- consistency check.
    local test_pattern = pattern.new({ { 1, 0, 0, 1, },
        { 0, 1, 1, 0, },
        { 0, 1, 1, 0, },
        { 1, 0, 0, 1, } }):translate(100, -100)
    local floodfill = pattern.floodfill(test_pattern,
        test_pattern:rcell(),
        neighbourhood.moore())
    lu.assertEquals(floodfill, test_pattern)
end

--  Connected Components --------------------------------------------------------------
function TestSubPatterns:testConnectedComponents()
    -- Measure the number of connected components in a pattern by flood-filling.
    -- This test pattern should return one segment for the Moore neighbourhood,
    -- and five for the von Neumann neighbourhood. The translate is just a
    -- consistency check.
    local test_pattern     = pattern.new({ { 1, 0, 0, 1, },
        { 0, 1, 1, 0, },
        { 0, 1, 1, 0, },
        { 1, 0, 0, 1, } }):translate(100, -100)
    local moore_components = pattern.connected_components(test_pattern, neighbourhood.moore())
    local vn_components    = pattern.connected_components(test_pattern, neighbourhood.von_neumann())
    lu.assertEquals(moore_components:n_components(), 1)
    lu.assertEquals(vn_components:n_components(), 5)
end

--  Interior holes ----------------------------------------------------------------
function TestSubPatterns:testInteriorHoles()
    -- Test pattern should return one hole for Moore neighbourhood,
    -- and two for von Neumann neighbourhood. The translate is just a
    -- consistency check.
    local test_pattern      = pattern.new({ { 1, 1, 1, 1, 1, 1, 1 },
        { 1, 0, 0, 0, 0, 0, 1 },
        { 1, 0, 0, 1, 0, 0, 1 },
        { 1, 0, 1, 0, 1, 0, 1 },
        { 1, 0, 0, 1, 0, 0, 1 },
        { 1, 0, 0, 0, 0, 0, 1 },
        { 1, 1, 1, 1, 1, 1, 1 } }):translate(100, -100)
    local moore_subpatterns = pattern.interior_holes(test_pattern, neighbourhood.moore())
    local vn_subpatterns    = pattern.interior_holes(test_pattern, neighbourhood.von_neumann())
    lu.assertEquals(moore_subpatterns:n_components(), 1)
    lu.assertEquals(vn_subpatterns:n_components(), 2)
    lu.assertFalse(self:check_for_overlap(vn_subpatterns.components))
    -- Check that neighbourhood defaults to vN, and edge diagonal case
    local test_circle = primitives.circle(1)
    lu.assertEquals(pattern.interior_holes(test_circle):n_components(), 1)
end

--  Perlin noise ----------------------------------------------------------------
function TestSubPatterns:testPerlin()
    -- Test subpattern generation by thresholding perlin noise.
    local test_domain      = primitives.square(80, 20)
    local frequency, depth = 0.2, 1
    local thresholds       = { 0, 0.5, 0.7, 1 }
    local noise            = pattern.perlin(test_domain, frequency, depth, thresholds)
    lu.assertEquals(test_domain, noise[1]) -- Lowest threshold is zero, should be identical to domain
    lu.assertEquals(noise[4]:size(), 0)    -- Lowest threshold is one, should be an empty pattern

    -- Patterns should be progressively smaller as we move up the thresholds
    for ith = 2, #thresholds, 1 do
        lu.assertTrue(noise[ith]:size() <= noise[ith - 1]:size())
    end
end

--  Random sampling ------------------------------------------------------------------
function TestSubPatterns:testRandom()
    lu.assertEquals(getmetatable(self.seeds), pattern)
    lu.assertEquals(pattern.size(self.seeds), 10)
    lu.assertTrue(self:check_for_overlap({ self.square, self.seeds }))
end

--  Poisson-disc sampling ------------------------------------------------------------------
function TestSubPatterns:testPoissonDisk()
    local r         = 3
    local measure   = cell.chebyshev
    local domain    = primitives.square(10)
    local sample    = pattern.sample_poisson(domain, measure, r)
    -- In a poisson disc sample, all sample points should be at least `r` from each other
    local cell_list = sample:cell_list()
    for i = 1, #cell_list, 1 do
        for j = i + 1, #cell_list, 1 do
            lu.assertTrue(measure(cell_list[i], cell_list[j]) >= r)
        end
    end
    -- Check that domain is unmodified
    lu.assertEquals(domain:size(), 100)
    -- Check that the sample doesn't fall out of the domain
    lu.assertTrue(self:check_for_overlap({ domain, sample }))
end

-- Mitchell's best-candidate sampling -------------------------------------------------
function TestSubPatterns:testMitchellSampling()
    -- Approximate Poisson-disc by Mitchell's best-candidate algorithm
    local measure = cell.chebyshev
    local domain  = primitives.square(10)
    local sample  = pattern.sample_mitchell(domain, measure, 10, 10)
    -- Check that domain is unmodified
    lu.assertEquals(domain:size(), 100)
    -- Check that the sample doesn't fall out of the domain
    lu.assertTrue(self:check_for_overlap({ domain, sample }))
end

--  Maximum Rectangle  ---------------------------------------------------------------
function TestSubPatterns:testMaxRectangle()
    -- Basic test of the 'maximum rectangular area' subpattern finder.
    -- When run on a square pattern, it should return the input pattern.
    local rect = pattern.max_rectangle(self.square)
    lu.assertEquals(rect, self.square)
    -- Adding a single extra point far from the square pattern should not change anything
    local extra_point = self.square + pattern.new():insert(1000, 1000)
    local rect2 = pattern.max_rectangle(extra_point)
    lu.assertEquals(rect2, self.square)
end

--  Binary space partitioning  -------------------------------------------------------
function TestSubPatterns:testBinarySpacePartition()
    -- Testing on a square test pattern. The returned subpatterns should all
    -- have fewer than 10 active cells.
    local partitions   = pattern.bsp(self.square, 10).components
    local total_points = 0
    local resum        = pattern.new()
    for _, partition in ipairs(partitions) do
        resum = resum + partition
        total_points = total_points + partition:size()
        lu.assertTrue(partition:size() <= 10)
    end
    lu.assertEquals(total_points, self.square:size())
    lu.assertEquals(resum, self.square)
    lu.assertFalse(self:check_for_overlap(partitions))
end

-- Categorisation subpatterns --------------------------------------------------------
function TestSubPatterns:testCategories()
    -- Compute a random sample of the square 10x10 pattern with 40 samples
    local sample = pattern.sample(self.square, 40)
    -- Loop through a couple of example neighbourhoods
    local measures = { neighbourhood.moore(), neighbourhood.von_neumann() }
    for _, measure in ipairs(measures) do
        local c_subpatterns = pattern.neighbourhood_categories(sample, measure).components
        -- Ensure each category pattern only contains correctly categorised points
        for cat, seg in ipairs(c_subpatterns) do
            for icell in seg:cells() do
                local test_cat = measure:categorise(sample, icell)
                lu.assertEquals(cat, test_cat)
            end
        end
    end
end

--  Convex hull ---------------------------------------------------------------------
-- Test the function computing the convex hull
function TestSubPatterns:testConvexHull()
    -- Pattern for running convex hull algorithm over
    local test_pattern = pattern.new({ { 1, 0, 0, 0, 1 },
        { 0, 0, 1, 0, 0 },
        { 0, 1, 1, 1, 0 },
        { 0, 0, 1, 0, 0 },
        { 1, 0, 0, 0, 1 } })
    -- Actual convex hull pattern
    local true_pattern = pattern.new({ { 1, 1, 1, 1, 1 },
        { 1, 0, 0, 0, 1 },
        { 1, 0, 0, 0, 1 },
        { 1, 0, 0, 0, 1 },
        { 1, 1, 1, 1, 1 } })
    local convex_hull  = pattern.convex_hull(test_pattern)
    local overlap      = pattern.intersect(convex_hull, true_pattern)
    lu.assertEquals(convex_hull:size(), overlap:size(), true_pattern:size())
end

-- Thinning --------------------------------------------------------------------------
function TestSubPatterns:testThinning()
    -- Test 1: Thinning a 3x3 block
    -- Expectation: only the center (1,1) remains.
    local block = pattern.new({
        { 1, 1, 1 },
        { 1, 1, 1 },
        { 1, 1, 1 },
    })
    local block_thinned = pattern.thin(block, neighbourhood.moore())
    lu.assertEquals(block_thinned:size(), 3, "3x3 block should collapse to a single cell")
    lu.assertTrue(block_thinned:has_cell(2, 2), "Center cell (2,2) should remain")

    -- Test 2: Thinning a single 5-wide row
    -- A one-dimensional line is already minimal, so it should remain unchanged.
    local row = pattern.new({
        { 1, 1, 1, 1, 1 }, -- row of 5 active cells at y=0
    })
    local row_thinned = pattern.thin(row, neighbourhood.moore())
    lu.assertEquals(row_thinned:size(), 5, "Row of length 5 should remain length 5")
    lu.assertEquals(row_thinned, row, "Row should be unchanged by thinning")
end

-- Voronoi tesselation ---------------------------------------------------------------
function TestSubPatterns:commonVoronoi(voronoi_multipattern, seeds, measure)
    -- Check for the correct number of subpatterns, and that there are no overlaps
    lu.assertEquals(voronoi_multipattern:n_components(), seeds:size())
    lu.assertFalse(self:check_for_overlap(voronoi_multipattern.components))

    -- Check that, for every cell in every subpattern, the closest seed for
    -- that subpattern intersects with it (should define a voronoi
    -- tesselation).
    for _, sp in ipairs(voronoi_multipattern.components) do
        -- Loop over all cells in this segment
        for sp_cell in sp:cells() do
            -- Find the closest seed to this cell
            local closest_seed, seed_distance = nil, math.huge
            for seed_cell in seeds:cells() do
                local distance = measure(sp_cell, seed_cell)
                if distance < seed_distance then
                    seed_distance = distance
                    closest_seed = seed_cell
                end
            end

            -- Ensure that the closest seed is in the cell
            lu.assertTrue(sp:has_cell(closest_seed.x, closest_seed.y))
        end
    end
end

-- Test Voronoi tesselation with various distance measures
function TestSubPatterns:testVoronoi_Manhattan()
    local measure = cell.manhattan
    local voronoi_multipattern = pattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_multipattern, self.seeds, measure)
end

function TestSubPatterns:testVoronoi_Euclidean()
    local measure = cell.euclidean
    local voronoi_multipattern = pattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_multipattern, self.seeds, measure)
end

function TestSubPatterns:testVoronoi_Chebyshev()
    local measure = cell.chebyshev
    local voronoi_multipattern = pattern.voronoi(self.seeds, self.square, measure)
    self:commonVoronoi(voronoi_multipattern, self.seeds, measure)
end

function TestSubPatterns:testLloydsAlgorithm()
    local measure = cell.chebyshev
    local multipattern, centres, _ = pattern.voronoi_relax(self.seeds, self.square, measure)
    self:commonVoronoi(multipattern, centres, measure)
end

-- Helper functions ------------------------------------------------------------------
function TestSubPatterns:check_for_overlap(subpatterns)
    -- Check that subpatterns overlap
    -- Returns true if there is an overlap, false otherwise
    for i = 1, #subpatterns - 1, 1 do
        for j = i + 1, #subpatterns, 1 do
            local int = pattern.intersect(subpatterns[i], subpatterns[j])
            if int:size() ~= 0 then return true end
        end
    end
    return false
end
