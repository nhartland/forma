-- binary_space_partition.lua
-- Example and benchmark of binary space partitioning

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')
math.randomseed(0)

-- stress loops for benchmarking
for i=1,100,1 do
    -- Generate an 80x20 square and partition it into segments of maximally 50 cells
    local square = primitives.square(80,20)
    local bsp = subpattern.bsp(square, 50)
    -- On the last loop, pretty print the segments
    if i==100 then subpattern.pretty_print(square,bsp) end
end

