--- Tests of basic forma category functions
require 'busted.runner'()
local neighbourhood = require("neighbourhood")
local categories    = require("categories")

-- There should be 2^n categories for a neighbourhood with n elements
describe("category test", function()
    test("forma.categories.generate (von neumann)", function()
        local von_neumann    = neighbourhood.von_neumann()
        local vn_categories  = categories.generate(von_neumann)
        assert.are_equals(16, #vn_categories )
    end)
    test("forma.categories.generate (moore)", function()
        local moore            = neighbourhood.moore()
        local moore_categories = categories.generate(moore)
        assert.are_equals(256, #moore_categories)
    end)
end)
