--- Tests of basic forma pattern functions
local lu = require('tests/luaunit')
local pattern    = require("pattern")
local primitives = require("primitives")

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

-- Test insert methods
-- Note insert *mutates* patterns, so here we test a clone
function testPattern:testInsert()
    -- Test both insert methods
    local pattern_1_clone = self.pattern_1:clone()
    pattern.insert(pattern_1_clone, 1, -1)
    pattern_1_clone:insert(-1, 1)

    lu.assertEquals(pattern.size(pattern_1_clone),2)
    lu.assertEquals(pattern_1_clone.max.x,1)
    lu.assertEquals(pattern_1_clone.max.y,1)
    lu.assertEquals(pattern_1_clone.min.x,-1)
    lu.assertEquals(pattern_1_clone.min.y,-1)
end

function testPattern:testEnlarge()
    local enlarged_pattern_1 = self.pattern_1:enlarge(2)
    local enlarged_pattern_2 = self.pattern_2:enlarge(2)
    lu.assertEquals(enlarged_pattern_1:size(),0)
    lu.assertEquals(enlarged_pattern_2:size(),100)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
