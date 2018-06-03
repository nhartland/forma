-- geometry.lua
-- Some examples of geometry by rasterisation

local point = require('point')
local pattern = require('pattern')
local primitives = require('primitives')

local tp = pattern.new()
local radii = {1,2,4,5,15}
for _, r in ipairs(radii) do
    tp = tp + primitives.circle(r)
end

tp = tp + primitives.line(point.new(-15,0), point.new(15,0))
tp = tp + primitives.line(point.new(0,-15), point.new(0,15))

tp = tp + primitives.line(point.new(0,-15), point.new(-15,0))
tp = tp + primitives.line(point.new(0,15), point.new(15,0))

tp = tp + primitives.line(point.new(-15,0), point.new(0,15))
tp = tp + primitives.line(point.new(0,-15), point.new(15,0))

tp.onchar='X'
tp.offchar=' '
print (tp)
