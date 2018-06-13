-- maxrectangle.lua
-- Example and benchmark of maximum rectangle finding

local pattern    = require('forma.pattern')
local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')
math.randomseed(0)

local total_pattern = pattern.new()
for _=1,100,1 do
    local tp = primitives.square(math.random(5)):shift(math.random(20), math.random(20))
    total_pattern = total_pattern + tp
end

local mxrect
for _=1,5000,1 do -- test loops for timing
    mxrect = subpattern.maxrectangle(total_pattern)
end
local rest_pattern = total_pattern - mxrect
subpattern.pretty_print(total_pattern,{rest_pattern, mxrect}, {'.','#'})
