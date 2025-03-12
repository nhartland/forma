-- Convex hull finder
-- This generates a messy random pattern, and finds its convex hull.

local primitives   = require('forma.primitives')
local multipattern = require('forma.multipattern')

-- Generate a domain and a random set of points
local domain = primitives.square(80, 20)
local points = domain:sample(30)

-- Find the convex hull
local c_hull = points:convex_hull()
multipattern.new({domain, c_hull, points}):print({' ', 'x', 'o'})
