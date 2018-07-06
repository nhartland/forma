--- Tests of basic forma category functions
local lu = require('luaunit')
local primitives    = require("forma.primitives")
local neighbourhood = require("forma.neighbourhood")

testNeighbourhood = {}

function testNeighbourhood:setUp()
    self.pattern_1 = primitives.square(1)
    self.pattern_2 = primitives.square(3)
end

-- There should be 2^n categories for a neighbourhood with n elements
function testNeighbourhood:testVonNeumann()
     local von_neumann    = neighbourhood.von_neumann()
     lu.assertEquals(4, #von_neumann )
     lu.assertEquals(16, #von_neumann.categories )
     -- Test categorisation
     local ct1 = von_neumann:categorise(self.pattern_1, self.pattern_1:medoid())
     local ct2 = von_neumann:categorise(self.pattern_2, self.pattern_2:medoid())
     lu.assertEquals(16,ct1) -- Lowest category (single cell)
     lu.assertEquals(1, ct2) -- Highest category (full neighbourhood)
end

function testNeighbourhood:testMoore()
     local moore            = neighbourhood.moore()
     lu.assertEquals(8, #moore)
     lu.assertEquals(256, #moore.categories)
     -- Test categorisation
     local ct1 = moore:categorise(self.pattern_1, self.pattern_1:medoid())
     local ct2 = moore:categorise(self.pattern_2, self.pattern_2:medoid())
     lu.assertEquals(256,ct1) -- Lowest category (single cell)
     lu.assertEquals(1, ct2)  -- Highest category (full neighbourhood)
end
