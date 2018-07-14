-- Maximum rectangle finding
-- This generates a messy random pattern, and finds the largest contiguous
-- rectangle of active cells within it.

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate a domain and a messy 'blocking' pattern
local domain = primitives.square(80, 20)
local blocks = subpattern.random(domain, 80)

-- Find the largest contiguous 'unblocked' rectangle in the base pattern
local mxrect = subpattern.maxrectangle(domain - blocks)
subpattern.print_patterns(domain,{blocks, mxrect}, {'o','#'})
