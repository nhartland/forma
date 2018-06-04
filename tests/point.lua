--- Tests of basic forma point functions
local lu = require('luaunit')
local point = require("forma.point")

testPoint = {}

function testPoint:setUp()
    self.test_point_1 = point.new(1,2)            -- First test point
    self.test_point_2 = point.new(2,3)            -- Second test point
    self.test_point_3 = point.clone(self.test_point_1) -- Clone of the first point
    self.test_point_4 = self.test_point_1:clone() -- Clone of the first point (method style)
end

function testPoint:testConstructor()
    lu.assertEquals(self.test_point_1.x,1)
    lu.assertEquals(self.test_point_1.y,2)
end

function testPoint:testClone()
    lu.assertEvalToTrue(self.test_point_1.x == self.test_point_3.x)
    lu.assertEvalToTrue(self.test_point_1.y == self.test_point_3.y)
    lu.assertEvalToTrue(self.test_point_1.v == self.test_point_3.v)
    lu.assertEvalToTrue(self.test_point_1 == self.test_point_3)
    lu.assertEvalToTrue(self.test_point_1 == self.test_point_4)
end

function testPoint:testManhattan()
    local d1 = point.manhattan(self.test_point_1, self.test_point_2)
    local d2 = self.test_point_1:manhattan(self.test_point_2)
    lu.assertEquals(d1, 2)
    lu.assertEquals(d1, d2)
end

function testPoint:testChebyshev()
    local d1 = point.chebyshev(self.test_point_1, self.test_point_2)
    local d2 = self.test_point_1:chebyshev(self.test_point_2)
    lu.assertEquals(d1, 1)
    lu.assertEquals(d1, d2)
end

function testPoint:testEuclidean2()
    local d1 = point.euclidean2(self.test_point_1, self.test_point_2)
    local d2 = self.test_point_1:euclidean2(self.test_point_2)
    lu.assertEquals(d1, 2)
    lu.assertEquals(d1, d2)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
