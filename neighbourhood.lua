--- Definition of neighbourhoods
-- @module forma.neighbourhood
local neighbourhood = {}
local thispath = select('1', ...):match(".+%.") or ""
local point = require(thispath .. 'point')

--- The Moore neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/Moore_neighborhood).
--
-- Contains all points with Chebyshev distance 1
-- from origin. Used in Conway's Game of Life.
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

--- The von Neumann neighbourhood.
-- [Wikipedia entry](https://en.wikipedia.org/wiki/von_Neumann_neighborhood).
--
-- Contains all points with Manhattan distance 1 from origin.
function neighbourhood.von_neumann()
    local nbh = {}
    table.insert(nbh, point.new(1,0))
    table.insert(nbh, point.new(0,1))
    table.insert(nbh, point.new(-1,0))
    table.insert(nbh, point.new(0,-1))
    return nbh
end

--- The diagonal neighbourhood.
--
-- Contains all points diagonally bordering the origin. i.e the Moore
-- neighbourhood with the von Neumann subtracted.
function neighbourhood.diagonal()
    local nbh = {}
    table.insert(nbh, point.new(1,1))
    table.insert(nbh, point.new(1,-1))
    table.insert(nbh, point.new(-1,-1))
    table.insert(nbh, point.new(-1,1))
    return nbh
end

--- The twice diagonal neighbourhood.
--
-- Contains all points two cells away from the origin
-- along the diagonal axes.
function neighbourhood.diagonal_2()
    local nbh = {}
    table.insert(nbh, point.new(2,2))
    table.insert(nbh, point.new(2,-2))
    table.insert(nbh, point.new(-2,-2))
    table.insert(nbh, point.new(-2,2))
    return nbh
end

return neighbourhood


