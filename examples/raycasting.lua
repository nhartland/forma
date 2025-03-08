-- Raycasting
-- This generates a messy random blocking pattern, selects a random point
-- within it, and casts rays from that point to identify a 'visible' area.

local subpattern   = require('forma.subpattern')
local primitives   = require('forma.primitives')
local raycasting   = require("forma.raycasting")
local multipattern = require("forma.multipattern")

-- Generate a domain and a messy 'blocking' pattern
local domain = primitives.square(80, 20)
local blocks = subpattern.random(domain, 100)
domain = domain - blocks

-- Cast rays in all direction from a random point in the domain
local traced = raycasting.cast_360(domain:rcell(), domain, 10)
multipattern.new({blocks, traced}):print({'#', '+'}, domain)
