-- maxrectangle.lua
-- Example of maximum rectangle finding in a general domain

local pattern    = require('forma.pattern')
local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

math.randomseed( os.time() )

-- Generate a messy pattern inside a domain
local domain = primitives.square(80, 20)
local total_pattern = pattern.new()
for _=1,200,1 do
    -- Generate a randomly sized square at a random point of the domain
    local rpoint = domain:rcell()
    local tp = primitives.square(math.random(7)):shift(rpoint.x, rpoint.y)
    total_pattern = total_pattern + tp
end

-- Find the largest contiguous rectangle in the base pattern
local mxrect = subpattern.maxrectangle(total_pattern)
local rest_pattern = total_pattern - mxrect
subpattern.pretty_print(total_pattern,{rest_pattern, mxrect}, {'.','#'})
