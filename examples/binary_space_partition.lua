-- Binary space partitioning
local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate an 80x20 square and partition it into segments of maximally 50 cells
local square = primitives.square(80,20)
local bsp = subpattern.bsp(square, 50)

-- Print resulting pattern segments
subpattern.print_patterns(square,bsp)

