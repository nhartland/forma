-- isolines.lua
-- Simmilar to worley.lua but showing isolines
-- of the d2-d1 scalar field.

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
math.randomseed( os.time() )

-- Distance measure
local measure = cell.chebyshev

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
    return d2 - d1  > 1
end

-- Compute the d2-d1 thresholded pattern and take its surface
local noise = subpattern.mask(sq, mask)
noise = noise:surface()

-- Print to screen
noise.offchar = '~'
noise.onchar  = '▓'
print(noise)
