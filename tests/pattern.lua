--- Tests of basic forma pattern functions
require 'busted.runner'()

describe("pattern test", function()
    local pattern
    local test_point_1 -- First test point
    local test_point_2 -- Second test point
    local test_point_3 -- Clone of the first point

    setup(function()
        pattern = require("pattern")
        test_pattern_1 = pattern.new()
        test_pattern_2 = pattern.square(5)
    end)

    teardown(function()
        pattern = nil
        test_pattern_1 = nil
        test_pattern_2 = nil
    end)

    test("forma.point.new", function()
        assert.are_equals(pattern.size(test_pattern_1),0)
        assert.are_equals(pattern.size(test_pattern_2),25)
    end)

    test("forma.point.insert", function()
        pattern.insert(test_pattern_1, 1, -1)
        pattern.insert(test_pattern_1, -1, 1)
        assert.are_equals(pattern.size(test_pattern_1),2)
        assert.are_equals(test_pattern_1.max.x,1)
        assert.are_equals(test_pattern_1.max.y,1)
        assert.are_equals(test_pattern_1.min.x,-1)
        assert.are_equals(test_pattern_1.min.y,-1)
    end)

end)
