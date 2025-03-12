local lu = require('luaunit')
local pattern = require('forma.pattern')
local multipattern = require('forma.multipattern')

TestMultipattern = {}

function TestMultipattern:setUp()
    -- We'll define a couple of small pattern examples:
    -- single cell p1 at (0,0)
    self.p1 = pattern.new():insert(0,0)

    -- 2x2 block p2:
    -- (0,0),(1,0),
    -- (0,1),(1,1)
    self.p2 = pattern.new({
        {1,1},
        {1,1},
    })

    -- 3x1 bar p3:
    -- (0,0),(1,0),(2,0)
    self.p3 = pattern.new({
        {1,1,1},
    })
end

function TestMultipattern:testNew()
    -- Create a multipattern from a list of patterns
    local mp = multipattern.new({self.p1, self.p2})
    lu.assertEquals(#mp.components, 2)
    lu.assertTrue(mp.components[1]==self.p1)
    lu.assertTrue(mp.components[2]==self.p2)
    -- Test indexing
    lu.assertTrue(mp[1]==mp.components[1])
    lu.assertTrue(mp[2]==mp.components[2])
end

function TestMultipattern:testMap()
    -- We'll enlarge each pattern by factor of 2
    local mp = multipattern.new({self.p1, self.p2})
    local mp_mapped = mp:map(function(p)
        return p:enlarge(2)
    end)
    -- Check that each sub-pattern is now bigger
    lu.assertEquals(mp_mapped[1]:size(), self.p1:size()*4)  -- enlarge(2) => factor^2
    lu.assertEquals(mp_mapped[2]:size(), self.p2:size()*4)
end

function TestMultipattern:testFilter()
    -- Suppose we only keep patterns with size == 3
    local mp = multipattern.new({self.p1, self.p2, self.p3})
    local filtered = mp:filter(function(pat) return pat:size() == 3 end)
    lu.assertEquals(#filtered.components, 1)  -- only p3 has size=3
    lu.assertTrue(filtered[1]==self.p3)
end

function TestMultipattern:testApply()
    -- We want to call :translate(10,10) on each pattern
    local mp = multipattern.new({self.p1, self.p2})
    local shifted = mp:apply("translate", 10, 10)
    -- Now p1 is at (10,10); p2 is from (10,10)..(11,11)
    lu.assertTrue(shifted[1]:has_cell(10, 10))
    lu.assertFalse(shifted[1]:has_cell(0, 0))

    lu.assertTrue(shifted[2]:has_cell(10, 10))
    lu.assertTrue(shifted[2]:has_cell(11, 11))
    lu.assertFalse(shifted[2]:has_cell(0, 0))
end

function TestMultipattern:testUnionAll()
    -- p1 has a single cell at (0,0)
    -- p2 has (0,0),(1,0),(0,1),(1,1)
    -- union_all of p1 + p2 is just p2
    local mp = multipattern.new({self.p1, self.p2})
    local unioned = mp:union_all()
    lu.assertEquals(unioned:size(), self.p2:size())  -- p2 covers p1 anyway
    lu.assertTrue(unioned==self.p2)

    -- Add p3 => (0,0),(1,0),(2,0)
    -- union of p2 + p3 => total 5 cells:
    --   block 2x2 => (0,0),(1,0),(0,1),(1,1)
    --   plus the point (2,0)
    local mp2 = multipattern.new({self.p2, self.p3})
    local unioned2 = mp2:union_all()
    lu.assertEquals(unioned2:size(), 5)
    lu.assertTrue(unioned2:has_cell(2,0))
end


return TestMultipattern
