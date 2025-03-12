-- Voronoi tessellation
local cell       = require('forma.cell')
local primitives = require('forma.primitives')

-- Generate a random pattern in a specified domain
local sq = primitives.square(80,20)
local rn = sq:sample(10)

-- Compute the corresponding voronoi tesselation
local measure  = cell.chebyshev
local segments = rn:voronoi(sq, measure)

-- Print the tesselation
segments:print()
