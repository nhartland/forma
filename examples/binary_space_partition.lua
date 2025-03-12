-- Binary space partitioning
local primitives = require('forma.primitives')

-- Generate an 80x20 square and partition it into segments of maximally 50 cells
local square = primitives.square(80,20)
local bsp = square:bsp(50)

-- Print the BSP
bsp:print()
