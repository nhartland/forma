--- Tests of basic forma category functions
local lu = require('tests/luaunit')
local neighbourhood = require("neighbourhood")
local categories    = require("categories")

testCategory = {}

-- There should be 2^n categories for a neighbourhood with n elements
function testCategoryGenerate_VonNeumann()
     local von_neumann    = neighbourhood.von_neumann()
     local vn_categories  = categories.generate(von_neumann)
     lu.assertEquals(16, #vn_categories )
end

function testCategoryGenerate_Moore()
     local moore            = neighbourhood.moore()
     local moore_categories = categories.generate(moore)
     lu.assertEquals(256, #moore_categories)
end

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
