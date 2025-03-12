-- Circle primitives
local cell         = require('forma.cell')
local pattern      = require('forma.pattern')
local primitives   = require('forma.primitives')
local multipattern = require('forma.multipattern')

local max_radius = 4

-- Setup domain and some random seeds
local domain = primitives.square(80,20)
local seeds  = domain:sample_poisson(cell.euclidean, 2*max_radius)
local shapes = pattern.new()

-- Randomly generate some circles in the domain
for seed in seeds:cells() do
    local circle = primitives.circle(math.random(2, max_radius))
    shapes = shapes + circle:translate(seed.x, seed.y)
end

multipattern.new({shapes}):print({'o'}, domain)

