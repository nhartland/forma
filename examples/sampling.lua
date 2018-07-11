--- sampling.lua
-- Demonstrations of various methods for sampling from a pattern.
-- `pattern.random` is useful when a regular and uniform sample is not
-- required, Lloyd's algorithm when a specific number of uniform samples are
-- desired, and Poisson-disc when a minimum separation between samples is the
-- only requirement.

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
math.randomseed( os.time() )

-- Domain and seed
local measure = cell.chebyshev
local domain   = primitives.square(80,20)

-- Random samples, uncomment these turn by turn to see the differences
local random  = subpattern.poisson_disc(domain, measure, 5)
--local random   = subpattern.random(domain, 40)
--local _, random = subpattern.voronoi_relax(random, domain, measure)

subpattern.pretty_print(domain, {random}, {'#'})
