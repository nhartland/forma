-- voronoi.lua
-- Demonstration of voronoi tesselation

local point      = require('forma.point')
local util       = require('forma.util')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')
math.randomseed(os.time())

-- Generate a random pattern and its voronoi tesselation
local sq = primitives.square(60,20)
local rn = subpattern.random(sq, 0.01)

-- Compute voronoi tesselation for various measures
local measures = {}
measures.Chebyshev = point.chebyshev
measures.Euclidean = point.euclidean
measures.Manhattan = point.manhattan

for label, measure in pairs(measures) do
    local segments = subpattern.voronoi(rn, sq, measure)
    print(label)
    util.pretty_print(sq, segments)
end
