--- Tests of basic forma pattern functions
local lu = require('tests/luaunit')
local pattern    = require("pattern")
local primitives = require("primitives")

testPattern = {}

function testPattern:setUp()
    self.test_pattern_1 = pattern.new()
    self.test_pattern_2 = primitives.square(5)
    self.test_pattern_3 = primitives.square(1)
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

function testPattern:testEnlarge()
    local enlarged_pattern_1 = self.test_pattern_1:enlarge(2)
    local enlarged_pattern_2 = self.test_pattern_2:enlarge(2)
    lu.assertEquals(enlarged_pattern_1:size(),0)
    lu.assertEquals(enlarged_pattern_2:size(),100)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
