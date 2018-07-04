-- worley.lua
-- Demonstration of thresholded Worley noise
-- https://en.wikipedia.org/wiki/Worley_noise

-- Here we take the noise field N = F_2 - F_1,
-- where F_n is the chebyshev distance to the nth
-- nearest neighbour, and take the threshold N > 1

-- Makes a good ice floe generator

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
math.randomseed( os.time() )

-- Distance measure and threshold
local measure = cell.chebyshev
local threshold = 1

-- Domain and seeds
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, math.floor(sq:size()*0.01)):cell_list()

-- Worley noise mask
local mask = function(tcell)
    local sortfn = function(a,b)
        return measure(tcell, a) < measure(tcell, b)
    end
    table.sort(rn, sortfn)
    local d1 = measure(rn[1], tcell)
    local d2 = measure(rn[2], tcell)
    return d2 - d1  > threshold
end

local noise = subpattern.mask(sq, mask)
noise.offchar = '~'
noise.onchar  = '▓'
print(noise)
