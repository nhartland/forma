--- Tests of basic forma point functions
require 'busted.runner'()

describe("point test", function()
    local point
    local test_point_1 -- First test point
    local test_point_2 -- Second test point
    local test_point_3 -- Clone of the first point

    setup(function()
        point = require("point")
        test_point_1 = point.new(1,2)
        test_point_2 = point.new(2,3)
        test_point_3 = point.clone(test_point_1)
    end)

    teardown(function()
        point = nil
        test_point_1 = nil
        test_point_2 = nil
    end)

    test("forma.point.new", function()
        assert.are_equals(test_point_1.x,1)
        assert.are_equals(test_point_1.y,2)
    end)

    test("forma.point.clone", function()
        assert.is_true(test_point_1.x == test_point_3.x)
        assert.is_true(test_point_1.y == test_point_3.y)
        assert.is_true(test_point_1.v == test_point_3.v)
        assert.is_true(test_point_1 == test_point_3)
    end)

    test("forma.point.minkowski", function()
        local d = point.minkowski(test_point_1, test_point_2)
        assert.is_true(d == 2)
    end)

    test("forma.point.chebyshev", function()
        local d = point.chebyshev(test_point_1, test_point_2)
        assert.is_true(d == 1)
    end)

    test("forma.point.euclidean2", function()
        local d = point.euclidean2(test_point_1, test_point_2)
        assert.is_true(d == 2)
    end)

end)
