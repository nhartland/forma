--- Tests of basic forma pattern functions
local lu = require('luaunit')
local pattern       = require("forma.pattern")
local primitives    = require("forma.primitives")
local neighbourhood = require("forma.neighbourhood")

testPattern = {}

function testPattern:setUp()
    self.pattern_1 = pattern.new()
    self.pattern_2 = primitives.square(5)
    self.pattern_3 = primitives.square(1)
    self.pattern_4 = pattern.new({{1}})
    self.pattern_5 = pattern.new({{1,1,1,1,1},
                                  {1,1,1,1,1},
                                  {1,1,1,1,1},
                                  {1,1,1,1,1},
                                  {1,1,1,1,1}})
end

-- Test the spatial hashing limits
function testPattern:testSpatialHash()
    local max = pattern.get_max_coordinate()
    lu.assertTrue( max > 0 )
    local limits = { -max, max, 0 }
    for _, x in ipairs(limits) do
        for _, y in ipairs(limits) do
            lu.assertTrue(pattern.test_coordinate_map(x,y))
        end
    end
    -- Test that hash fails outside of specified limits
    lu.assertFalse(pattern.test_coordinate_map(2*max, 2*max))
end

-- Test eq, add, sub operators
function testPattern:testOperators()
    lu.assertEquals(self.pattern_1, self.pattern_1)
    lu.assertEquals(self.pattern_1 +self.pattern_2,
                    self.pattern_2)
    lu.assertEquals(self.pattern_2 -self.pattern_2,
                    self.pattern_1)
end

function testPattern:testConstructor()
    lu.assertEquals(pattern.size(self.pattern_1),0)
    lu.assertEquals(pattern.size(self.pattern_2),25)
    lu.assertEquals(pattern.size(self.pattern_2),25)
    -- Test that both methods of generating patterns work
    lu.assertEquals(self.pattern_4, self.pattern_3)
    lu.assertEquals(self.pattern_5, self.pattern_2)
end

function testPattern:testClone()
    -- Test pattern cloning
    local pattern_5_clone = self.pattern_5:clone()
    lu.assertEquals(pattern_5_clone, self.pattern_5)
    lu.assertNotEquals(pattern_5_clone, self.pattern_4)
end

-- Test insert methods
function testPattern:testInsert()
    -- Test both insert methods
    local insert_test = pattern.new()
    pattern.insert(insert_test, 1, -1)
    insert_test:insert(-1, 1)

    lu.assertEquals(pattern.size(insert_test),2)
    lu.assertEquals(insert_test.max.x,1)
    lu.assertEquals(insert_test.max.y,1)
    lu.assertEquals(insert_test.min.x,-1)
    lu.assertEquals(insert_test.min.y,-1)
end

function testPattern:testCentroid()
    -- Test five patterns which should have the same
    -- centroid, and one which should not
    local centroid1 = pattern.new({{1,1,1},
                                   {1,0,1},
                                   {1,1,1}}):centroid()
    local centroid2 = pattern.new({{1,0,1},
                                   {0,0,0},
                                   {1,0,1}}):centroid()
    local centroid3 = pattern.new({{0,1,0},
                                   {0,0,0},
                                   {0,1,0}}):centroid()
    local centroid4 = pattern.new({{0,0,0},
                                   {1,0,1},
                                   {0,0,0}}):centroid()
    local centroid5 = pattern.new({{0,0,0},
                                   {0,1,0},
                                   {0,0,0}}):centroid()
    -- This should not be the same as the others
    local centroid6 = pattern.new({{1,1,1},
                                   {0,0,0},
                                   {0,0,0}}):centroid()
    lu.assertEquals(centroid1, centroid2)
    lu.assertEquals(centroid2, centroid3)
    lu.assertEquals(centroid3, centroid4)
    lu.assertEquals(centroid4, centroid5)
    lu.assertNotEquals(centroid5, centroid6)
end

function testPattern:testMedoid()
    -- Test five patterns which should have the same
    -- medoid, and one which should not
    local medoid1 = pattern.new({{1,1,1},
                                 {1,1,1},
                                 {1,1,1}}):medoid()
    local medoid2 = pattern.new({{1,0,1},
                                 {0,1,0},
                                 {1,0,1}}):medoid()
    local medoid3 = pattern.new({{0,1,0},
                                 {0,1,0},
                                 {0,1,0}}):medoid()
    local medoid4 = pattern.new({{0,0,0},
                                 {1,1,1},
                                 {0,0,0}}):medoid()
    local medoid5 = pattern.new({{0,0,0},
                                 {0,1,0},
                                 {0,0,0}}):medoid()
    -- This should not be the same as the others
    local medoid6 = pattern.new({{0,1,0},
                                 {1,0,1},
                                 {0,1,0}}):medoid()
    lu.assertEquals(medoid1, medoid2)
    lu.assertEquals(medoid2, medoid3)
    lu.assertEquals(medoid3, medoid4)
    lu.assertEquals(medoid4, medoid5)
    lu.assertNotEquals(medoid5, medoid6)
end

function testPattern:testSurface()
    -- Surface of a single point should just return that point back
    local surface_pattern_3 = self.pattern_3:surface()
    lu.assertEquals(surface_pattern_3, self.pattern_3)

    -- Test pattern for surface determination
    local test = pattern.new({{1,1,1,1,1},
                              {1,0,1,0,1},
                              {1,1,1,1,1},
                              {1,0,1,0,1},
                              {1,1,1,1,1}})

    -- Moore neighbourhood surface - should be the same pattern
    local moore_surface = test:surface()
    lu.assertEquals(moore_surface, test)

    -- von Neumann neighbourhood surface - centre tile should be zero
    local vn_surface = test:surface(neighbourhood.von_neumann())
    local vn_check = pattern.new({{1,1,1,1,1},
                                  {1,0,1,0,1},
                                  {1,1,0,1,1},
                                  {1,0,1,0,1},
                                  {1,1,1,1,1}})
    lu.assertEquals(vn_surface, vn_check)
end

function testPattern:testEnlarge()
    local enlarged_pattern_1 = self.pattern_1:enlarge(2)
    local enlarged_pattern_2 = self.pattern_2:enlarge(2)
    lu.assertEquals(enlarged_pattern_1:size(),0)
    lu.assertEquals(enlarged_pattern_2:size(),100)
end
