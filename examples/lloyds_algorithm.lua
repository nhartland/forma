-- voronoi.lua
-- Demonstration of voronoi relaxation by lloyds algorithm

local cell      = require('forma.cell')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')
math.randomseed(os.time())

-- Domain for tesselation
local sq = primitives.square(80,20)
local seeds = primitives.square(3)

-- Compute voronoi tesselation for various measures
local measure = cell.manhattan

-- Perform voronoi relaxation at incrementing imax
-- Note this isn't very efficient as we are displaying intermediate steps,
-- normally you would only call this function once.
local imax = 1
repeat
    print("Step "..imax)
    local segments, _, converged  = subpattern.voronoi_relax(seeds, sq, measure, imax)
    table.sort(segments, function(a,b) return a:com().x < b:com().x end)
    subpattern.pretty_print(sq, segments)
    imax = imax + 1
until converged == true or imax == 100
