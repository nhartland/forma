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
    lu.assertEquals(self.pattern_1 + self.pattern_2,
                    self.pattern_2)
    lu.assertEquals(self.pattern_2 - self.pattern_2,
                    self.pattern_1)
    lu.assertEquals(self.pattern_2 - self.pattern_1,
                    self.pattern_2)
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

function testPattern:testToString()
    -- Test pattern tostring method
    local pattern_5_string = tostring(self.pattern_5)
    lu.assertIsString(pattern_5_string)
end

function testPattern:testSum()
    -- Test pattern.sum() helper function
    local tp1 = pattern.new({{1,1,1,1,1},
                             {1,0,0,0,1},
                             {1,0,0,0,1},
                             {1,0,0,0,1},
                             {1,1,1,1,1}})
    local tp2 = pattern.new({{0,0,0,0,0},
                             {0,1,1,1,0},
                             {0,1,1,1,0},
                             {0,1,1,1,0},
                             {0,0,0,0,0}})
    local tp12 = primitives.square(5)
    local sum  = pattern.sum(tp1, tp2)
    local sum_v2  = pattern.sum({tp1, tp2})
    lu.assertEquals(tp1+tp2, tp12)
    lu.assertEquals(tp1+tp2, sum)
    lu.assertEquals(tp12, sum)
    lu.assertNotEquals(tp1, sum)
    lu.assertNotEquals(tp2, sum)
    lu.assertEquals(sum, sum_v2)
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

-- Test the standard iterator methods
function testPattern:testIterators()
    local sqpat = primitives.square(20)
    -- These should return alive cells in the same order
    local cells = sqpat:cells()
    local coords = sqpat:cell_coordinates()
    for _=1, sqpat:size(), 1 do
        local ncell  = cells()
        local nx, ny = coords()
        -- Same order in cells and coordinates
        lu.assertEquals(ncell.x, nx)
        lu.assertEquals(ncell.y, ny)
        -- Is a valid cell
        lu.assertTrue(sqpat:has_cell(nx, ny))
    end
    -- Test that the iterators terminate
    lu.assertEquals(cells(), nil)
    lu.assertEquals(coords(), nil)
end

-- Test the shuffled iterator methods
-- It's a bit tricky to test, given the randomness
function testPattern:testShuffledIterators()
    local sqpat = primitives.square(20)
    for icell in sqpat:shuffled_cells() do
        lu.assertTrue(sqpat:has_cell(icell.x, icell.y))
    end
    for x, y in sqpat:shuffled_coordinates() do
        lu.assertTrue(sqpat:has_cell(x, y))
    end
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

function testPattern:testEdge()
    -- Test pattern for edge determination
    local test = pattern.new({{0,0,0},
                              {0,1,0},
                              {0,0,0}})
    -- Moore neighbourhood edge
    local moore_edge = pattern.new({{1,1,1},
                                    {1,0,1},
                                    {1,1,1}})
    -- Von Neumann neighbourhood edge
    local vn_edge    = pattern.new({{0,1,0},
                                    {1,0,1},
                                    {0,1,0}})
    -- Diagonal neighbourhood edge
    local d_edge     = pattern.new({{1,0,1},
                                    {0,0,0},
                                    {1,0,1}})

    -- Moore neighbourhood edge: default case
    lu.assertEquals(test:edge(), moore_edge)
    -- Von Neumann edge test
    lu.assertEquals(test:edge(neighbourhood.von_neumann()), vn_edge)
    -- Diagonal edge test
    lu.assertEquals(test:edge(neighbourhood.diagonal()), d_edge)
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

function testPattern:testNormalise()
    -- Test pattern normalisation
    -- the normalise method should set the origin of any pattern to (0,0)
    local test_pattern_1 = primitives.square(5)
    local test_pattern_2 = test_pattern_1:shift(100,100)
    local test_pattern_3 = test_pattern_2:normalise()
    lu.assertNotEquals(test_pattern_1, test_pattern_2)
    lu.assertNotEquals(test_pattern_2, test_pattern_3)
    lu.assertEquals(test_pattern_1, test_pattern_3)
    -- Test that doesn't depend on :shift
    local test_pattern_4 = pattern.new():insert(5,5)
    local test_pattern_5 = test_pattern_4:normalise()
    lu.assertTrue (test_pattern_4:has_cell(5,5))
    lu.assertFalse(test_pattern_5:has_cell(5,5))
    lu.assertTrue (test_pattern_5:has_cell(0,0))
end

function testPattern:testEnlarge()
    local enlarged_pattern_1 = self.pattern_1:enlarge(2)
    local enlarged_pattern_2 = self.pattern_2:enlarge(2)
    lu.assertEquals(enlarged_pattern_1:size(),0)
    lu.assertEquals(enlarged_pattern_2:size(),100)
end

function testPattern:testReflect()
    -- Test that a square pattern rotated both vertically and horizontally
    -- is a square pattern of twice the side length
    local test_square_4 = primitives.square(4)
    local test_square_8 = primitives.square(8)
    local test_reflect = test_square_4:vreflect():hreflect()
    lu.assertEquals(test_square_8, test_reflect)
    -- Test for reflections on a more irregular pattern
    local test_irreg = pattern.new({{1,0},
                                    {0,1}}):hreflect()
    local test_irreg_reflect = pattern.new({{1,0,0,1},
                                            {0,1,1,0}})
    lu.assertEquals(test_irreg, test_irreg_reflect)
end

function testPattern:testRotate()
    -- Test that radially symmetric pattern is unchanged after rotation
    local rotate_pattern_2 = self.pattern_2:rotate():normalise()
    lu.assertEquals(rotate_pattern_2, self.pattern_2)
    -- Test non-radially symmetric pattern
    -- This expectation might be a bit counter-intuitive, but remember
    -- that the coordinate system is 'terminal-like' i.e
    --        ------> +x
    --        |
    --        |
    --        |
    --       +y
    local test = pattern.new({{1,0},{1,1}}):rotate():normalise()
    local expectation = pattern.new({{0,1},{1,1}})
    lu.assertEquals(test, expectation)
    -- Test 2pi rotation
    local test2 = test:rotate():rotate():rotate():rotate()
    lu.assertEquals(test, test2)
end

-- Common tests for packtile and packtile_centre
local function test_generic_packing_function(fn)
    -- Should be able to pack 25 single cells into a 5x5 square
    local test_point = primitives.square(1)
    local test_pattern = primitives.square(5)
    for _=1,25 do
        -- Location where the test point can fit into the test pattern
        local pp = fn(test_point, test_pattern)
        lu.assertTrue( test_pattern:has_cell(pp.x, pp.y))
        -- Remove point from test pattern
        test_pattern = test_pattern - test_point:shift(pp.x, pp.y)
    end
    -- Pattern should now be empty
    lu.assertEquals( test_pattern:size(), 0)
    -- Should return nil
    local pp1 = fn(test_point, test_pattern)
    lu.assertEquals(pp1, nil)
    -- Should return nil
    local pp2 = fn(primitives.square(5), primitives.square(1))
    lu.assertEquals(pp2, nil)
end

function testPattern:testPacktile()
    -- Run generic testing function
    test_generic_packing_function(pattern.packtile)
end

function testPattern:testPacktileCentre()
    -- Run generic testing function
    test_generic_packing_function(pattern.packtile_centre)
    -- Test centre-packing
    local test_point = primitives.square(1)
    local test_pattern = pattern.new({{0,1,0,},
                                      {1,1,1,},
                                      {0,1,0,}})
    local pp = test_point:packtile_centre(test_pattern)
    lu.assertEquals(pp.x, 1)
    lu.assertEquals(pp.y, 1)
end

function testPattern:testEditDistance()
    -- Self-distances
    lu.assertEquals(self.pattern_1:edit_distance(self.pattern_1), 0)
    lu.assertEquals(self.pattern_2:edit_distance(self.pattern_2), 0)
    lu.assertEquals(self.pattern_3:edit_distance(self.pattern_3), 0)
    -- Non-overlapping
    local p1 = pattern.new({{1,0},
                            {0,1}})
    local p2 = pattern.new({{0,1},
                            {1,0}})
    lu.assertEquals(p1:edit_distance(p2), 4)
    -- Overlapping
    local edit_distance_23 = self.pattern_2:edit_distance(self.pattern_3)
    lu.assertEquals(edit_distance_23, 5*5 - 1) -- one common point
end

function testPattern:testDilation()
    -- Single-cell pattern
    local single = pattern.new({{1}})  -- 1 at (0,0)
    -- Dilation with a Moore neighborhood (8 directions, plus center).
    -- Make sure your code or your 'nbh' includes (0,0) if you want the original cell to remain.
    local dil = single:dilate(neighbourhood.moore())
    -- A single cell with Moore dilation => center plus 8 neighbors => total 9 cells.
    lu.assertEquals(dil:size(), 9)
    -- Spot check that the center still exists
    lu.assertTrue(dil:has_cell(0, 0))
end

function testPattern:testErosion()
    -- 3x3 block. By default, pattern.new interprets
    -- the top row of the table as y=0, then next as y=1, etc.
    -- So the pattern has these active coords (x,y):
    -- (0,0),(1,0),(2,0),
    -- (0,1),(1,1),(2,1),
    -- (0,2),(1,2),(2,2)
    local block3 = pattern.new({
        {1,1,1},
        {1,1,1},
        {1,1,1},
    })
    -- Erode with the Moore neighborhood (including center).
    local eroded = block3:erode(neighbourhood.moore())
    -- A 3x3 block eroded (Moore, center included) leaves only the middle cell => total size=1.
    lu.assertEquals(eroded:size(), 1)
    -- Check that the middle cell is present at (1,1)
    lu.assertTrue(eroded:has_cell(1,1))
end

function testPattern:testXor()
    -- We'll test the function-based XOR (pattern.xor(a, b)).
    -- For example, define two single-cell patterns side-by-side:
    local a = pattern.new({{1,0}}) -- active cell at (0,0)
    local b = pattern.new({{0,1}}) -- active cell at (1,0)
    local x = pattern.xor(a, b)
    -- XOR of a,b should have 2 cells: (0,0) and (1,0)
    lu.assertEquals(x:size(), 2)
    lu.assertTrue(x:has_cell(0,0))
    lu.assertTrue(x:has_cell(1,0))
    -- Self XOR should be empty
    lu.assertEquals(pattern.xor(a, a):size(), 0)
end

function testPattern:testIntersectionOperator()
    -- We'll assume you bound `__mul` to pattern.intersection, so a*b does set intersection.
    local a = pattern.new({
        {1,1},  -- cells at (0,0) and (1,0)
        {1,1},  -- cells at (0,1) and (1,1)
    })
    local b = pattern.new({
        {0,1},  -- cell at (1,0)
        {1,1},  -- cells at (0,1) and (1,1)
    })
    -- Intersection => (1,0), (0,1), (1,1)
    local i = a * b  -- uses __mul
    lu.assertEquals(i:size(), 3)
    lu.assertTrue(i:has_cell(1,0))
    lu.assertTrue(i:has_cell(0,1))
    lu.assertTrue(i:has_cell(1,1))
    lu.assertFalse(i:has_cell(0,0))
end

function testPattern:testXorOperator()
    -- We'll assume you bound `__pow` to pattern XOR, so a^b does symmetric difference.
    local a = pattern.new({
        {1,1},  -- (0,0), (1,0)
        {1,1},  -- (0,1), (1,1)
    })
    local b = pattern.new({
        {0,1},  -- (1,0)
        {1,1},  -- (0,1), (1,1)
    })
    -- Intersection is 3 cells. Union is 4 cells. XOR => union - intersection => 1 cell: (0,0).
    local x = a ^ b  -- uses __pow
    lu.assertEquals(x:size(), 1)
    lu.assertTrue(x:has_cell(0,0))
end

function testPattern:testOpening()
    -- This pattern is a 3x3 block plus a single "finger" cell on the top row.
    -- The table rows go from top to bottom in your code, so:
    --   row 0 => y=0
    --   row 1 => y=1
    --   row 2 => y=2
    --   row 3 => y=3
    --
    -- Active coordinates:
    --   (0,0),(1,0),(2,0),
    --   (0,1),(1,1),(2,1),
    --   (0,2),(1,2),(2,2),
    --   (0,3) <-- single extra cell above the block
    local p = pattern.new({
        {1,1,1},
        {1,1,1},
        {1,1,1},
        {1,0,0},  -- single protrusion at (0,3)
    })

    -- After an erosion->dilation with a Moore neighborhood (including (0,0) as center),
    -- the 3x3 block remains, but the lone protrusion cell at (0,3) is removed.
    -- The final shape is just the 3x3 block at y=0..2, x=0..2:
    --
    --   (0,0),(1,0),(2,0),
    --   (0,1),(1,1),(2,1),
    --   (0,2),(1,2),(2,2)
    local p_open = pattern.new({
        {1,1,1},
        {1,1,1},
        {1,1,1},
    })

    local opened = p:opening(neighbourhood.moore())
    lu.assertEquals(opened, p_open)
end

function testPattern:testClosing()
    -- A 3x3 block with a single hole in the middle (1,1):
    --    (0,0),(1,0),(2,0),
    --    (0,1),      (2,1),
    --    (0,2),(1,2),(2,2)
    local c = pattern.new({
        {1,1,1},
        {1,0,1},
        {1,1,1},
    })

    -- With closing (dilation->erosion) and a Moore neighborhood,
    -- that hole at (1,1) gets filled during dilation, leaving a solid 3x3 block,
    -- and after erosion we remain with the same 3x3 block fully filled:
    local c_closed = pattern.new({
        {1,1,1},
        {1,1,1},
        {1,1,1},
    })

    local closed = c:closing(neighbourhood.moore())
    lu.assertEquals(closed, c_closed)
end

