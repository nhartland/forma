-- Voronoi tessellation
local cell       = require('forma.cell')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')

-- Generate a random pattern in a specified domain
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 10)

-- Compute the corresponding voronoi tesselation
local measure  = cell.chebyshev
local segments = subpattern.voronoi(rn, sq, measure)

-- Print the tesselation
segments:print()
