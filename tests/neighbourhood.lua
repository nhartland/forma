--- Tests of basic forma category functions
local lu = require('luaunit')
local primitives    = require("forma.primitives")
local neighbourhood = require("forma.neighbourhood")

testNeighbourhood = {}

function testNeighbourhood:setUp()
    self.pattern_1 = primitives.square(1)
    self.pattern_2 = primitives.square(3)
    self.pattern_3 = primitives.square(5)
end

-- Tests a generic neighbourhood with `nelm` elements, for which `pmax` is a
-- pattern with a medoid cell with a completely filled neighbourhood.
function testNeighbourhood:commonTest(nbh, nelm, pmax)
     -- There should be 2^n categories for a neighbourhood with n elements.
     local ncat = math.pow(2, nelm)
     lu.assertEquals(nelm, #nbh )
     lu.assertEquals(ncat, nbh:get_ncategories() )
     -- Test categorisation
     local ctmin = nbh:categorise(self.pattern_1, self.pattern_1:medoid())
     local ctmax = nbh:categorise(pmax, pmax:medoid())
     lu.assertEquals(ncat, ctmin) -- Lowest category (single cell)
     lu.assertEquals(   1, ctmax) -- Highest category (full neighbourhood)
end

function testNeighbourhood:testVonNeumann()
     local von_neumann = neighbourhood.von_neumann()
     self:commonTest(von_neumann, 4, self.pattern_2)
end

function testNeighbourhood:testMoore()
     local moore = neighbourhood.moore()
     self:commonTest(moore, 8, self.pattern_2)
end

function testNeighbourhood:testDiagonal()
     local diagonal = neighbourhood.diagonal()
     self:commonTest(diagonal, 4, self.pattern_2)
end

function testNeighbourhood:testDiagonal2()
     local diagonal_2 = neighbourhood.diagonal_2()
     self:commonTest(diagonal_2, 4, self.pattern_3)
end

function testNeighbourhood:testKnight()
    -- Knight neighborhood should have 8 offsets, hence 2^8 = 256 categories.
    -- We need a 5x5 pattern (or bigger) so that the medoid (2,2)
    -- can have all 8 knight moves inside the pattern.
    local knight = neighbourhood.knight()
    self:commonTest(knight, 8, self.pattern_3)
end
