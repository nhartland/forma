-- binary_space_partition.lua
-- Example of binary space partitioning

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate an 80x20 square and partition it into segments of maximally 50 cells
local square = primitives.square(80,20)
local bsp = subpattern.bsp(square, 50)

-- Pretty print resulting pattern segments
subpattern.pretty_print(square,bsp)

