--- Sampling methods
-- Demonstrations of various methods for sampling from a pattern.
-- 1. `pattern.sample` generates white noise, it's fast and irreguarly distributed.
-- 2. Lloyd's algorithm when a specific number of uniform samples are desired.
-- 3. Mitchell's algorithm is a good (fast) approximation of (2).
-- 3. Poisson-disc when a minimum separation between samples is the only requirement.

local cell          = require('forma.cell')
local primitives    = require('forma.primitives')
local multipattern  = require('forma.multipattern')

-- Domain and seed
local measure = cell.chebyshev
local domain   = primitives.square(80,20)

-- Random samples, uncomment these turn by turn to see the differences
local random  = domain:sample_poisson(measure, 4)
--local random  = domain:sample_mitchell(measure, 100, 100)
--local random   = domain:sample(40)
--local _, random = domain:voronoi_relax(random, domain, measure)

multipattern.new({random}):print({'#'}, domain)
