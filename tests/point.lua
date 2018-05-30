--- Tests of basic forma point functions
local lu = require('tests/luaunit')

testPoint = {}

function testPoint:setUp()
    point = require("point")
    self.test_point_1 = point.new(1,2)            -- First test point
    self.test_point_2 = point.new(2,3)            -- Second test point
    self.test_point_3 = point.clone(self.test_point_1) -- Clone of the first point
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
end

function testPoint:testMinkowski()
    local d = point.minkowski(self.test_point_1, self.test_point_2)
    lu.assertEvalToTrue(d == 2)
end

function testPoint:testChebyshev()
    local d = point.chebyshev(self.test_point_1, self.test_point_2)
    lu.assertEvalToTrue(d == 1)
end

function testPoint:testEuclidean2()
    local d = point.euclidean2(self.test_point_1, self.test_point_2)
    lu.assertEvalToTrue(d == 2)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
