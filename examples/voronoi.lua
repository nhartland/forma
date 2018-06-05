-- voronoi.lua
-- Demonstration of voronoi tesselation

local cell      = require('forma.cell')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')
math.randomseed(os.time())

-- Generate a random pattern and its voronoi tesselation
local sq = primitives.square(60,20)
local rn = subpattern.random(sq, 0.01)

-- Compute voronoi tesselation for various measures
local measures = {}
measures.Chebyshev = cell.chebyshev
measures.Euclidean = cell.euclidean
measures.Manhattan = cell.manhattan

for label, measure in pairs(measures) do
    local segments = subpattern.voronoi(rn, sq, measure)
    print(label)
    subpattern.pretty_print(sq, segments)
end
