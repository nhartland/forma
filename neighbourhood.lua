--- Definition of neighbourhoods
-- @module forma.neighbourhood
local neighbourhood = {}
local thispath = select('1', ...):match(".+%.") or ""
local point = require(thispath .. 'point')
-- Von Neumann neighbourhood (Manhattan distance 1)
function neighbourhood.von_neumann()
    local nbh = {}
    table.insert(nbh, point.new(1,0))
    table.insert(nbh, point.new(0,1))
    table.insert(nbh, point.new(-1,0))
    table.insert(nbh, point.new(0,-1))
    return nbh
end
-- Diagonal neighbourhood (Moore - von Neumann)
function neighbourhood.diagonal()
    local nbh = {}
    table.insert(nbh, point.new(1,1))
    table.insert(nbh, point.new(1,-1))
    table.insert(nbh, point.new(-1,-1))
    table.insert(nbh, point.new(-1,1))
    return nbh
end
-- 2 * Diagonal neighbourhood
function neighbourhood.diagonal_2()
    local nbh = {}
    table.insert(nbh, point.new(2,2))
    table.insert(nbh, point.new(2,-2))
    table.insert(nbh, point.new(-2,-2))
    table.insert(nbh, point.new(-2,2))
    return nbh
end
-- Moore neighbourhood (Chebyshev distance 1)
function neighbourhood.moore()
    local nbh = {}
    table.insert(nbh, point.new(1,0))
    table.insert(nbh, point.new(0,1))
    table.insert(nbh, point.new(-1,0))
    table.insert(nbh, point.new(0,-1))
    table.insert(nbh, point.new(1,1))
    table.insert(nbh, point.new(1,-1))
    table.insert(nbh, point.new(-1,-1))
    table.insert(nbh, point.new(-1,1))
    return nbh
end
return neighbourhood


