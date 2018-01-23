-- voronoi.lua
-- Demonstration of voronoi tesselation 

local point   = require('point')
local util    = require('util')
local pattern = require('pattern')
math.randomseed(os.time())

-- Generate a random pattern and its voronoi tesselation
local sq = pattern.square(40,20)
local rn = pattern.random(sq, 0.01)
local segments = pattern.voronoi(rn, sq, point.euclidean)
util.pretty_print(sq, segments)
