--- Tests of basic forma cell functions
local lu = require('luaunit')
local cell = require("forma.cell")

testCell = {}

function testCell:setUp()
    self.test_cell_1 = cell.new(1,2)            -- First test cell
    self.test_cell_2 = cell.new(2,3)            -- Second test cell
    self.test_cell_3 = cell.clone(self.test_cell_1) -- Clone of the first cell
    self.test_cell_4 = self.test_cell_1:clone() -- Clone of the first cell (method style)
end

function testCell:testConstructor()
    lu.assertEquals(self.test_cell_1.x,1)
    lu.assertEquals(self.test_cell_1.y,2)
end

function testCell:testClone()
    lu.assertEvalToTrue(self.test_cell_1.x == self.test_cell_3.x)
    lu.assertEvalToTrue(self.test_cell_1.y == self.test_cell_3.y)
    lu.assertEvalToTrue(self.test_cell_1.v == self.test_cell_3.v)
    lu.assertEvalToTrue(self.test_cell_1 == self.test_cell_3)
    lu.assertEvalToTrue(self.test_cell_1 == self.test_cell_4)
end

function testCell:testToString()
    lu.assertEquals(tostring(self.test_cell_1), "(1,2)")
end

function testCell:testManhattan()
    local d1 = cell.manhattan(self.test_cell_1, self.test_cell_2)
    local d2 = self.test_cell_1:manhattan(self.test_cell_2)
    lu.assertEquals(d1, 2)
    lu.assertEquals(d1, d2)
end

function testCell:testChebyshev()
    local d1 = cell.chebyshev(self.test_cell_1, self.test_cell_2)
    local d2 = self.test_cell_1:chebyshev(self.test_cell_2)
    lu.assertEquals(d1, 1)
    lu.assertEquals(d1, d2)
end

function testCell:testEuclidean2()
    local d1 = cell.euclidean2(self.test_cell_1, self.test_cell_2)
    local d2 = self.test_cell_1:euclidean2(self.test_cell_2)
    lu.assertEquals(d1, 2)
    lu.assertEquals(d1, d2)
end
