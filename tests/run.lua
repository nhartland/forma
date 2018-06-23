local lu = require('luaunit')
require('tests.cell')
require('tests.pattern')
require('tests.primitives')
require('tests.neighbourhood')
require('tests.subpattern')
require('tests.automata')

math.randomseed(0)

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:run() )
--os.exit( runner:runSuite() )
