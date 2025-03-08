-- Rasterising isolines
-- Here we generate a pattern randomly filled with points, and take as a scalar
-- field `N(cell) = F_2(cell) - F_1(cell)`, where `F_n` is the Chebyshev distance
-- to the nth nearest neighbour. Isolines at `N = 0` are drawn by thresholding `N`
-- at 1 and taking the interior hull.

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')
local multipattern  = require('forma.multipattern')

-- Distance measure
local measure = cell.chebyshev

-- Domain and list of seed cells
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 20):cell_list()

-- Worley noise mask
local mask = function(tcell)
    local sortfn = function(a,b)
        return measure(tcell, a) < measure(tcell, b)
    end
    table.sort(rn, sortfn)
    local F1 = measure(rn[1], tcell)
    local F2 = measure(rn[2], tcell)
    return F2 - F1  > 1
end

-- Compute the thresholded pattern and print its interior hull
local noise = subpattern.mask(sq, mask)
multipattern.new({noise:interior_hull()}):print({'#'}, sq)

