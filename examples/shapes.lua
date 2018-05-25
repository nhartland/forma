-- shapes.lua
-- Use of a few different functions to generate shapes

local pattern = require('pattern')
math.randomseed( os.time() )

-- Generate some basic shape as a sum of rectangles
local function generate_shape()
    local rn = pattern.new()
    while rn.size < 35 do
        local sqx, sqy = math.random(3) , math.random(3)
        local sq = pattern.square(sqx,sqy)
        local pqx, pqy = math.random(5) , math.random(5)
        rn = rn + pattern.shift(sq, pqx, pqy)
    end
    return rn
end

-- Add some symmetry and smear pattern
local rn = generate_shape()
rn = pattern.hreflect(rn)
local sm = pattern.smear(rn, 2)

-- Print to stdout
rn.onchar, rn.offchar = "X"," "
sm.onchar, sm.offchar = "X"," "
print(rn)
print(sm)


