-- Convex hull finder
-- This generates a messy random pattern, and finds its convex hull.

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate a domain and a random set of points
local domain = primitives.square(80, 20)
local points = subpattern.random(domain, 30)

-- Find the convex hull
local c_hull = subpattern.convex_hull(points)
subpattern.print_patterns(domain,{c_hull, points}, {'x', 'o'})
