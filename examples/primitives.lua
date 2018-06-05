-- primitives.lua
-- Examples of geometry primitives

local cell      = require('forma.cell')
local primitives = require('forma.primitives')

local tp = primitives.circle(1)
local radii = {2,4,5,15}
for _, r in ipairs(radii) do
    tp = tp + primitives.circle(r)
end

tp = tp + primitives.line(cell.new(-15,0), cell.new(15,0))
tp = tp + primitives.line(cell.new(0,-15), cell.new(0,15))

tp = tp + primitives.line(cell.new(0,-15), cell.new(-15,0))
tp = tp + primitives.line(cell.new(0,15),  cell.new(15,0))

tp = tp + primitives.line(cell.new(-15,0), cell.new(0,15))
tp = tp + primitives.line(cell.new(0,-15), cell.new(15,0))

tp.onchar='X'
tp.offchar=' '
print (tp)
