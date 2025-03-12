-- Perlin noise sampling
-- Here we sample a square domain pattern according to perlin noise,
-- generating three new patterns consisting of the noise thresholded at
-- values of 0, 0.5 and 0.7.

local primitives = require('forma.primitives')

local domain = primitives.square(80,20)
local frequency, depth = 0.2, 1
local thresholds = {0, 0.5, 0.7}
local noise  = domain:perlin(frequency, depth, thresholds)

-- Print resulting pattern segments
noise:print({'.', '+', 'o'}, domain)
