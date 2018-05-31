--- Tests of basic forma pattern functions
local lu = require('tests/luaunit')
local pattern    = require("pattern")
local primitives = require("primitives")

testPattern = {}

function testPattern:setUp()
    self.test_pattern_1 = pattern.new()
    self.test_pattern_2 = primitives.square(5)
end

function testPattern:testConstructor()
    lu.assertEquals(pattern.size(self.test_pattern_1),0)
    lu.assertEquals(pattern.size(self.test_pattern_2),25)
end

function testPattern:testInsert()
    -- Test both insert methods
    pattern.insert(self.test_pattern_1, 1, -1)
    self.test_pattern_1:insert(-1, 1)

    lu.assertEquals(pattern.size(self.test_pattern_1),2)
    lu.assertEquals(self.test_pattern_1.max.x,1)
    lu.assertEquals(self.test_pattern_1.max.y,1)
    lu.assertEquals(self.test_pattern_1.min.x,-1)
    lu.assertEquals(self.test_pattern_1.min.y,-1)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
