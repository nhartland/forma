-- Perlin noise sampling
-- Here we sample a square domain pattern according to perlin noise,
-- generating three new patterns consisting of the noise thresholded at
-- values of 0, 0.5 and 0.7.

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

local domain = primitives.square(80,20)
local frequency, depth = 0.2, 1
local thresholds = {0, 0.5, 0.7}
local noise  = subpattern.perlin(domain, frequency, depth, thresholds)

-- Print resulting pattern segments
subpattern.print_patterns(domain, noise, {'.', '+', 'o'})
