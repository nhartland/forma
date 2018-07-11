-- voronoi.lua
-- Demonstration of voronoi tesselation

local cell      = require('forma.cell')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')
math.randomseed(os.time())

-- Generate a random pattern in a specified domain
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 10)

-- Compute its voronoi tesselation
local measure  = cell.chebyshev
local segments = subpattern.voronoi(rn, sq, measure)

subpattern.pretty_print(sq, segments)
