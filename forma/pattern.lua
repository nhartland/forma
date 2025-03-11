--- A class containing a set (or *pattern*) of cells.
--
-- The **pattern** class is the central class of `forma`, representing a set of
-- points or *cells*. It can be initialized empty or using a prototype (an N×M
-- matrix of 1's and 0's). Helper methods for initialization are provided in the
-- `primitives` module. Once created, a pattern is modified only via the `insert`
-- method—other manipulations return new patterns.
--
-- Pattern manipulators include methods like `translate`, `enlarge`, `rotate`,
-- `hreflect`, and `vreflect`. Other operations, such as computing the `exterior_hull`
-- or `interior_hull`, help determine the boundaries of a pattern.
-- Coordinates are maintained reliably in the range [-65536, 65536], which can be
-- adjusted via the `MAX_COORDINATE` constant.
--
-- Functions can be invoked either procedurally:
--      pattern.method(input_pattern, ... )
-- or as methods:
--      input_pattern:method(... )
--
-- @usage
-- -- Procedural style:
-- local p1 = pattern.new()
-- pattern.insert(p1, 1, 1)
--
-- -- Method chaining:
-- local p2 = pattern.new():insert(1, 1)
--
-- -- Prototype style:
-- local p3 = pattern.new({{1,1,1}, {1,0,1}, {1,1,1}})
--
-- -- Retrieve a random cell and the medoid cell:
-- local random_cell = p1:rcell()
-- local medoid_cell = p1:medoid()
--
-- -- Compute the exterior hull using the Moore neighbourhood:
-- local outer_hull = p1:exterior_hull(neighbourhood.moore())
-- -- or equivalently:
-- outer_hull = pattern.exterior_hull(p1, neighbourhood.moore())
--
-- @module forma.pattern

local pattern         = {}

local min             = math.min
local max             = math.max
local floor           = math.floor

local cell            = require('forma.cell')
local neighbourhood   = require('forma.neighbourhood')
local rutils          = require('forma.utils.random')
local multipattern    = require('forma.multipattern')

-- Pattern indexing.
-- Enables the syntax sugar pattern:method.
pattern.__index       = pattern

-- Pattern coordinates (either x or y) must be within ± MAX_COORDINATE.
local MAX_COORDINATE  = 65536
local COORDINATE_SPAN = 2 * MAX_COORDINATE + 1

--- Generates the cellmap key from coordinates.
-- @param x the x-coordinate (number).
-- @param y the y-coordinate (number).
-- @return a unique key representing the cell.
local function coordinates_to_key(x, y)
    return (x + MAX_COORDINATE) * COORDINATE_SPAN + (y + MAX_COORDINATE)
end

--- Generates the coordinates from the key.
-- @param key the spatial hash key (number).
-- @return the x and y coordinates (numbers).
local function key_to_coordinates(key)
    local yp = (key % COORDINATE_SPAN)
    local xp = (key - yp) / COORDINATE_SPAN
    return xp - MAX_COORDINATE, yp - MAX_COORDINATE
end

--- Basic pattern functions.
-- Here are the basic functions for creating and manipulating patterns.
-- @section basic

--- Pattern constructor.
-- Returns a new pattern. If a prototype is provided (an N×M table of 1's and 0's),
-- the corresponding active cells are inserted.
--
-- @param prototype (optional) an N×M table of ones and zeros.
-- @return a new pattern according to the prototype.
function pattern.new(prototype)
    local np   = {}

    np.max     = cell.new(-math.huge, -math.huge)
    np.min     = cell.new(math.huge, math.huge)

    -- Characters to be used with tostring metamethod.
    np.offchar = '0'
    np.onchar  = '1'

    np.cellkey = {} -- Table consisting of a list of coordinate keys.
    np.cellmap = {} -- Spatial hash of coordinate key to bool (active/inactive cell).

    np         = setmetatable(np, pattern)

    if prototype ~= nil then
        assert(type(prototype) == 'table',
            'pattern.new requires either no arguments or a N*M matrix as a prototype')
        local N, M = #prototype, nil
        for i = 1, N, 1 do
            local row = prototype[i]
            assert(type(row) == 'table',
                'pattern.new requires either no arguments or a N*M matrix as a prototype')
            if i == 1 then
                M = #row
            else
                assert(#row == M,
                    'pattern.new requires a N*M matrix as prototype when called with an argument')
            end
            for j = 1, M, 1 do
                local icell = row[j]
                if icell == 1 then
                    np:insert(j - 1, i - 1) -- Patterns start from zero.
                else
                    assert(icell == 0, 'pattern.new: invalid prototype entry (must be 1 or 0): ' .. icell)
                end
            end
        end
    end

    return np
end

--- Creates a copy of an existing pattern.
--
-- @param ip input pattern to clone.
-- @return a new pattern that is a duplicate of ip.
function pattern.clone(ip)
    assert(getmetatable(ip) == pattern, "pattern cloning requires a pattern as the first argument")
    local newpat = pattern.new()

    for x, y in ip:cell_coordinates() do
        newpat:insert(x, y)
    end

    newpat.offchar = ip.offchar
    newpat.onchar  = ip.onchar

    return newpat
end

--- Inserts a new cell into the pattern.
-- Returns the modified pattern to allow for method chaining.
--
-- @param ip pattern to modify.
-- @param x x-coordinate (integer) of the new cell.
-- @param y y-coordinate (integer) of the new cell.
-- @return the updated pattern (for cascading calls).
function pattern.insert(ip, x, y)
    assert(floor(x) == x, 'pattern.insert requires an integer for the x coordinate')
    assert(floor(y) == y, 'pattern.insert requires an integer for the y coordinate')

    local key = coordinates_to_key(x, y)
    assert(ip.cellmap[key] == nil, "pattern.insert cannot duplicate cells")
    ip.cellmap[key] = true
    ip.cellkey[#ip.cellkey + 1] = key

    -- Reset pattern extent.
    ip.max.x = max(ip.max.x, x)
    ip.max.y = max(ip.max.y, y)
    ip.min.x = min(ip.min.x, x)
    ip.min.y = min(ip.min.y, y)

    return ip
end

--- Checks if a cell at (x, y) is active in the pattern.
--
-- @param ip pattern to check.
-- @param x x-coordinate (integer).
-- @param y y-coordinate (integer).
-- @return boolean true if the cell is active, false otherwise.
function pattern.has_cell(ip, x, y)
    local key = coordinates_to_key(x, y)
    return ip.cellmap[key] ~= nil
end

--- Filters the pattern using a boolean callback, returning a subpattern.
--
-- @param ip the original pattern.
-- @param fn a function(cell) -> boolean that determines if a cell is kept.
-- @return a new pattern containing only the cells that pass the filter.
function pattern.filter(ip, fn)
    assert(getmetatable(ip) == pattern, "pattern.filter requires a pattern as the first argument")
    assert(type(fn) == 'function', 'pattern.filter requires a function for the second argument')
    local np = pattern.new()
    for icell in ip:cells() do
        if fn(icell) == true then
            np:insert(icell.x, icell.y)
        end
    end
    return np
end

--- Returns the number of active cells in the pattern.
--
-- @param ip pattern to measure.
-- @return integer count of active cells.
function pattern.size(ip)
    assert(getmetatable(ip) == pattern, "pattern.size requires a pattern as the first argument")
    return #ip.cellkey
end

--- General pattern utilites.
-- @section utils

--- Comparator function to sort patterns by their size (number of cells).
--
-- @param pa first pattern.
-- @param pb second pattern.
-- @return boolean true if pa's size is greater than pb's.
function pattern.size_sort(pa, pb)
    return pa:size() > pb:size()
end

--- Counts active neighbors around a specified cell within the pattern.
-- Can be invoked with either a cell object or with x and y coordinates.
--
-- @param p a pattern.
-- @param nbh a neighbourhood (e.g., neighbourhood.moore()).
-- @param arg1 either a cell (with x and y fields) or the x-coordinate (integer).
-- @param arg2 (optional) the y-coordinate (integer) if arg1 is not a cell.
-- @return integer count of active neighbouring cells.
function pattern.count_neighbors(p, nbh, arg1, arg2)
    assert(getmetatable(p) == pattern,
        "count_neighbors: first argument must be a forma.pattern")
    assert(getmetatable(nbh),
        "count_neighbors: second argument must be a neighbourhood")

    local x, y
    if type(arg1) == 'table' and arg1.x and arg1.y then
        x, y = arg1.x, arg1.y
    else
        x, y = arg1, arg2
    end

    local count = 0
    for i = 1, #nbh, 1 do
        local offset = nbh[i]
        local nx, ny = x + offset.x, y + offset.y
        if p:has_cell(nx, ny) then
            count = count + 1
        end
    end
    return count
end

--- Returns a list (table) of active cells in the pattern.
--
-- @param ip pattern to list cells from.
-- @return table of cell objects.
function pattern.cell_list(ip)
    assert(getmetatable(ip) == pattern, "pattern.cell_list requires a pattern as the first argument")
    local newlist = {}
    for icell in ip:cells() do
        newlist[#newlist + 1] = icell
    end
    return newlist
end

--- Computes the edit distance between two patterns (the total number of differing cells).
--
-- @param a first pattern.
-- @param b second pattern.
-- @return integer representing the edit distance.
function pattern.edit_distance(a, b)
    assert(getmetatable(a) == pattern, "pattern.edit_distance requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.edit_distance requires a pattern as the second argument")
    local common = pattern.intersect(a, b)
    local edit_distance = (a - common):size() + (b - common):size()
    return edit_distance
end

--- Set operations.
-- @section set_ops

--- Returns the union of a set of patterns.
--
-- @param ... a table of patterns or a list of pattern arguments.
-- @return a new pattern that is the union of the provided patterns.
function pattern.union(...)
    local patterns = { ... }
    if #patterns == 1 then
        if type(patterns[1]) == 'table' then
            patterns = patterns[1]
        end
    end
    if #patterns == 1 then
        return patterns[1]
    end
    local total = pattern.clone(patterns[1])
    for i = 2, #patterns, 1 do
        local v = patterns[i]
        assert(getmetatable(v) == pattern, "pattern.union requires a pattern as an argument")
        for x, y in v:cell_coordinates() do
            if total:has_cell(x, y) == false then
                total:insert(x, y)
            end
        end
    end
    return total
end

--- Returns the intersection of multiple patterns (cells common to all).
--
-- @param ... two or more patterns to intersect.
-- @return a new pattern of cells that exist in every input pattern.
function pattern.intersect(...)
    local patterns = { ... }
    assert(#patterns > 1, "pattern.intersect requires at least two patterns as arguments")
    table.sort(patterns, pattern.size_sort)
    local domain = patterns[#patterns]
    local inter  = pattern.new()
    for x, y in domain:cell_coordinates() do
        local foundCell = true
        for i = #patterns - 1, 1, -1 do
            local tpattern = patterns[i]
            assert(getmetatable(tpattern) == pattern,
                "pattern.intersect requires a pattern as an argument")
            if not tpattern:has_cell(x, y) then
                foundCell = false
                break
            end
        end
        if foundCell == true then
            inter:insert(x, y)
        end
    end
    return inter
end

--- Returns the symmetric difference (XOR) of two patterns.
-- Cells are included if they exist in either pattern but not in both.
--
-- @param a first pattern.
-- @param b second pattern.
-- @return a new pattern representing the symmetric difference.
function pattern.xor(a, b)
    assert(getmetatable(a) == pattern, "pattern.xor requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.xor requires a pattern as the second argument")
    return (a + b) - (a * b)
end

--- Iterators
-- @section iterators

--- Iterator over active cells in the pattern.
--
-- @param ip pattern to iterate over.
-- @return iterator that returns each active cell as a cell object.
-- @usage
-- for cell in p:cells() do
--     print(cell.x, cell.y)
-- end
function pattern.cells(ip)
    assert(getmetatable(ip) == pattern, "pattern.cells requires a pattern as the first argument")
    local icell, ncells = 0, ip:size()
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = ip.cellkey[icell]
            local x, y = key_to_coordinates(ikey)
            return cell.new(x, y)
        end
    end
end

--- Iterator over active cell coordinates (x, y) in the pattern.
--
-- @param ip pattern to iterate over.
-- @return iterator that returns the x and y coordinates of each active cell.
-- @usage
-- for x, y in p:cell_coordinates() do
--     print(x, y)
-- end
function pattern.cell_coordinates(ip)
    assert(getmetatable(ip) == pattern, "pattern.cell_coordinates requires a pattern as the first argument")
    local icell, ncells = 0, ip:size()
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = ip.cellkey[icell]
            return key_to_coordinates(ikey)
        end
    end
end

--- Returns an iterator over active cells in randomized order.
--
-- @param ip pattern to iterate over.
-- @param rng (optional) random number generator (e.g., math.random).
-- @return iterator that yields each active cell (cell object) in a random order.
-- @usage
-- for cell in pattern.shuffled_cells(p) do
--     print(cell.x, cell.y)
-- end
function pattern.shuffled_cells(ip, rng)
    assert(getmetatable(ip) == pattern,
        "pattern.shuffled_cells requires a pattern as the first argument")
    if rng == nil then rng = math.random end
    local icell, ncells = 0, ip:size()
    local cellkeys = ip.cellkey
    local skeys = rutils.shuffled_copy(cellkeys, rng)
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = skeys[icell]
            local x, y = key_to_coordinates(ikey)
            return cell.new(x, y)
        end
    end
end

--- Returns an iterator over active cell coordinates in randomized order.
--
-- @param ip pattern to iterate over.
-- @param rng (optional) random number generator (e.g., math.random).
-- @return iterator that yields x and y coordinates in random order.
-- @usage
-- for x, y in pattern.shuffled_coordinates(p) do
--     print(x, y)
-- end
function pattern.shuffled_coordinates(ip, rng)
    assert(getmetatable(ip) == pattern,
        "pattern.shuffled_coordinates requires a pattern as the first argument")
    if rng == nil then rng = math.random end
    local icell, ncells = 0, ip:size()
    local cellkeys = ip.cellkey
    local skeys = rutils.shuffled_copy(cellkeys, rng)
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = skeys[icell]
            return key_to_coordinates(ikey)
        end
    end
end

--- Metamethods
-- @section metamethods

--- Renders the pattern as a string.
-- Active cells are shown with pattern.onchar and inactive cells with pattern.offchar.
--
-- @param ip pattern to render.
-- @return string representation of the pattern.
-- @usage
-- print(p)
function pattern.__tostring(ip)
    local str = '- pattern origin: ' .. tostring(ip.min) .. '\n'
    for y = ip.min.y, ip.max.y, 1 do
        for x = ip.min.x, ip.max.x, 1 do
            local char = ip:has_cell(x, y) and ip.onchar or ip.offchar
            str = str .. char
        end
        str = str .. '\n'
    end
    return str
end

--- Adds two patterns using the '+' operator (i.e. returns their union).
--
-- @param a first pattern.
-- @param b second pattern.
-- @return a new pattern representing the union of a and b.
-- @usage
-- local combined = p1 + p2
function pattern.__add(a, b)
    assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")
    return pattern.union(a, b)
end

--- Subtracts one pattern from another using the '-' operator.
-- Returns a new pattern with cells in a that are not in b.
--
-- @param a base pattern.
-- @param b pattern to subtract from a.
-- @return a new pattern with the difference.
-- @usage
-- local diff = p1 - p2
function pattern.__sub(a, b)
    assert(getmetatable(a) == pattern, "pattern subtraction requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern subtraction requires a pattern as the second argument")
    local c = pattern.new()
    for x, y in a:cell_coordinates() do
        if b:has_cell(x, y) == false then
            c:insert(x, y)
        end
    end
    return c
end

--- Computes the intersection of two patterns using the '*' operator.
--
-- @param a first pattern.
-- @param b second pattern.
-- @return a new pattern containing only the cells common to both.
-- @usage
-- local common = p1 * p2
function pattern.__mul(a, b)
    assert(getmetatable(a) == pattern, "pattern multiplication requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern multiplication requires a pattern as the second argument")
    return pattern.intersect(a, b)
end

--- Computes the symmetric difference (XOR) of two patterns using the '^' operator.
--
-- @param a first pattern.
-- @param b second pattern.
-- @return a new pattern with cells present in either a or b, but not both.
-- @usage
-- local xor_pattern = p1 ^ p2
function pattern.__pow(a, b)
    assert(getmetatable(a) == pattern, "pattern exponent (XOR) requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern exponent (XOR) requires a pattern as the second argument")
    return pattern.xor(a, b)
end

--- Tests whether two patterns are identical.
--
-- @param a first pattern.
-- @param b second pattern.
-- @return boolean true if the patterns are equal, false otherwise.
-- @usage
-- if p1 == p2 then
--     -- patterns are identical
-- end
function pattern.__eq(a, b)
    assert(getmetatable(a) == pattern, "pattern equality test requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern equality test requires a pattern as the second argument")
    if a:size() ~= b:size() then return false end
    if a.min ~= b.min then return false end
    if a.max ~= b.max then return false end
    for x, y in a:cell_coordinates() do
        if b:has_cell(x, y) == false then return false end
    end
    return true
end

--- Cell accessors
-- @section cell_accessors

--- Computes the centroid (arithmetic mean) of all cells in the pattern.
-- The result is rounded to the nearest integer coordinate.
--
-- @param ip pattern to process.
-- @return a cell representing the centroid (which may not be active).
-- @usage
-- local center = p:centroid()
function pattern.centroid(ip)
    assert(getmetatable(ip) == pattern, "pattern.centroid requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.centroid requires a filled pattern!')
    local sumx, sumy = 0, 0
    for x, y in ip:cell_coordinates() do
        sumx = sumx + x
        sumy = sumy + y
    end
    local n = ip:size()
    local intx = floor(sumx / n + 0.5)
    local inty = floor(sumy / n + 0.5)
    return cell.new(intx, inty)
end

--- Computes the medoid cell of the pattern.
-- The medoid minimizes the total distance to all other cells (using Euclidean distance by default).
--
-- @param ip pattern to process.
-- @param measure (optional) distance function (default: Euclidean).
-- @return the medoid cell of the pattern.
-- @usage
-- local medoid = p:medoid()
function pattern.medoid(ip, measure)
    assert(getmetatable(ip) == pattern, "pattern.medoid requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.medoid requires a filled pattern!')
    measure = measure or cell.euclidean2
    local ncells = ip:size()
    local cell_list = ip:cell_list()
    local distance = {}
    for _ = 1, ncells, 1 do distance[#distance + 1] = 0 end
    local minimal_distance = math.huge
    local minimal_index = -1
    for i = 1, ncells, 1 do
        for j = i, ncells, 1 do
            local ij_distance = measure(cell_list[i], cell_list[j])
            distance[i] = distance[i] + ij_distance
            distance[j] = distance[j] + ij_distance
        end
        if distance[i] < minimal_distance then
            minimal_index = i
            minimal_distance = distance[i]
        end
    end
    return cell_list[minimal_index]
end

--- Returns a random cell from the pattern.
--
-- @param ip pattern to sample from.
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a random cell from the pattern.
-- @usage
-- local random_cell = p:rcell()
function pattern.rcell(ip, rng)
    assert(getmetatable(ip) == pattern, "pattern.rcell requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.rcell requires a filled pattern!')
    if rng == nil then rng = math.random end
    local icell = rng(#ip.cellkey)
    local ikey = ip.cellkey[icell]
    local x, y = key_to_coordinates(ikey)
    return cell.new(x, y)
end

--- Transformations
-- @section transformations

--- Returns a new pattern translated by a vector (sx, sy).
--
-- @param ip pattern to translate.
-- @param sx translation along the x-axis (integer).
-- @param sy translation along the y-axis (integer).
-- @return a new pattern shifted by (sx, sy).
-- @usage
-- local p_translated = p:translate(2, 3)
function pattern.translate(ip, sx, sy)
    assert(getmetatable(ip) == pattern, "pattern.translate requires a pattern as the first argument")
    assert(floor(sx) == sx, 'pattern.translate requires an integer for the x coordinate')
    assert(floor(sy) == sy, 'pattern.translate requires an integer for the y coordinate')
    local sp = pattern.new()
    for tx, ty in ip:cell_coordinates() do
        local nx = tx + sx
        local ny = ty + sy
        sp:insert(nx, ny)
    end
    return sp
end

--- Normalizes the pattern by translating it so that its minimum coordinate is (0,0).
--
-- @param ip pattern to normalize.
-- @return a new normalized pattern.
-- @usage
-- local p_norm = p:normalise()
function pattern.normalise(ip)
    assert(getmetatable(ip) == pattern, "pattern.normalise requires a pattern as the first argument")
    return ip:translate(-ip.min.x, -ip.min.y)
end

--- Returns an enlarged version of the pattern.
-- Each active cell is replaced by an f×f block.
--
-- @param ip pattern to enlarge.
-- @param f enlargement factor (number).
-- @return a new enlarged pattern.
-- @usage
-- local p_big = p:enlarge(2)
function pattern.enlarge(ip, f)
    assert(getmetatable(ip) == pattern, "pattern.enlarge requires a pattern as the first argument")
    assert(type(f) == 'number', 'pattern.enlarge requires a number as the enlargement factor')
    local ep = pattern.new()
    for icell in ip:cells() do
        local sv = cell.new(f * icell.x, f * icell.y)
        for i = 0, f - 1, 1 do
            for j = 0, f - 1, 1 do
                ep:insert(sv.x + i, sv.y + j)
            end
        end
    end
    return ep
end

--- Returns a new pattern rotated 90° clockwise about the origin.
--
-- @param ip pattern to rotate.
-- @return a rotated pattern.
-- @usage
-- local p_rotated = p:rotate()
function pattern.rotate(ip)
    assert(getmetatable(ip) == pattern, "pattern.rotate requires a pattern as the first argument")
    local np = pattern.new()
    for x, y in ip:cell_coordinates() do
        np:insert(y, -x)
    end
    return np
end

--- Returns a new pattern that is a vertical reflection of the original.
--
-- @param ip pattern to reflect vertically.
-- @return a vertically reflected pattern.
-- @usage
-- local p_vreflected = p:vreflect()
function pattern.vreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.vreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
    for vx, vy in ip:cell_coordinates() do
        local new_y = 2 * ip.max.y - vy + 1
        np:insert(vx, new_y)
    end
    return np
end

--- Returns a new pattern that is a horizontal reflection of the original.
--
-- @param ip pattern to reflect horizontally.
-- @return a horizontally reflected pattern.
-- @usage
-- local p_hreflected = p:hreflect()
function pattern.hreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.hreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
    for vx, vy in ip:cell_coordinates() do
        local new_x = 2 * ip.max.x - vx + 1
        np:insert(new_x, vy)
    end
    return np
end

--- Random subpatterns
-- @section subpatterns

--- Returns a random subpattern containing a fixed number of cells.
--
-- @param ip pattern (domain) to sample from.
-- @param ncells number of cells to sample (integer).
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a new pattern with ncells randomly selected cells.
-- @usage
-- local sample = p:sample(10)
function pattern.sample(ip, ncells, rng)
    assert(getmetatable(ip) == pattern, "pattern.sample requires a pattern as the first argument")
    assert(type(ncells) == 'number', "pattern.sample requires an integer number of cells as the second argument")
    assert(math.floor(ncells) == ncells, "pattern.sample requires an integer number of cells as the second argument")
    assert(ncells > 0, "pattern.sample requires at least one sample to be requested")
    assert(ncells <= ip:size(), "pattern.sample requires a domain larger than the number of requested samples")
    if rng == nil then rng = math.random end
    local p = pattern.new()
    local next_coords = ip:shuffled_coordinates(rng)
    for _ = 1, ncells, 1 do
        local x, y = next_coords()
        p:insert(x, y)
    end
    return p
end

--- Returns a Poisson-disc sampled subpattern.
-- Ensures that no two sampled cells are closer than the given radius.
--
-- @param ip pattern (domain) to sample from.
-- @param distance distance function (e.g., cell.euclidean).
-- @param radius minimum separation (number).
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a new pattern sampled with Poisson-disc criteria.
-- @usage
-- local poisson_sample = p:sample_poisson(cell.euclidean, 5)
function pattern.sample_poisson(ip, distance, radius, rng)
    assert(getmetatable(ip) == pattern, "pattern.sample_poisson requires a pattern as the first argument")
    assert(type(distance) == 'function', "pattern.sample_poisson requires a distance measure as an argument")
    assert(type(radius) == "number", "pattern.sample_poisson requires a number as the target radius")
    if rng == nil then rng = math.random end
    local sample = pattern.new()
    local domain = ip:clone()
    while domain:size() > 0 do
        local dart = domain:rcell(rng)
        local mask = function(icell) return distance(icell, dart) >= radius end
        domain = pattern.filter(domain, mask)
        sample:insert(dart.x, dart.y)
    end
    return sample
end

--- Returns an approximate Poisson-disc sample using Mitchell's best candidate algorithm.
--
-- @param ip pattern (domain) to sample from.
-- @param distance distance function (e.g., cell.euclidean).
-- @param n number of samples (integer).
-- @param k number of candidate attempts per iteration (integer).
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a new pattern with n samples chosen via the algorithm.
-- @usage
-- local mitchell_sample = p:sample_mitchell(cell.euclidean, 10, 5)
function pattern.sample_mitchell(ip, distance, n, k, rng)
    assert(getmetatable(ip) == pattern,
        "pattern.sample_mitchell requires a pattern as the first argument")
    assert(ip:size() >= n,
        "pattern.sample_mitchell requires a pattern with at least as many points as in the requested sample")
    assert(type(distance) == 'function', "pattern.sample_mitchell requires a distance measure as an argument")
    assert(type(n) == "number", "pattern.sample_mitchell requires a target number of samples")
    assert(type(k) == "number", "pattern.sample_mitchell requires a target number of candidate tries")
    if rng == nil then rng = math.random end
    local seed = ip:rcell(rng)
    local sample = pattern.new():insert(seed.x, seed.y)
    for _ = 2, n, 1 do
        local min_distance = 0
        local min_sample   = nil
        for _ = 1, k, 1 do
            local jcell = ip:rcell(rng)
            while sample:has_cell(jcell.x, jcell.y) do
                jcell = ip:rcell(rng)
            end
            local jdistance = math.huge
            for vcell in sample:cells() do
                jdistance = math.min(jdistance, distance(jcell, vcell))
            end
            if jdistance > min_distance then
                min_sample   = jcell
                min_distance = jdistance
            end
        end
        sample:insert(min_sample.x, min_sample.y)
    end
    return sample
end

--- Deterministic subpatterns
-- @section det_subpatterns

--- Returns the contiguous subpattern (connected component) starting from a given location.
local function floodfill(x, y, nbh, domain, retpat)
    if domain:has_cell(x, y) and retpat:has_cell(x, y) == false then
        retpat:insert(x, y)
        for i = 1, #nbh, 1 do
            local nx = nbh[i].x + x
            local ny = nbh[i].y + y
            floodfill(nx, ny, nbh, domain, retpat)
        end
    end
end

--- Returns the contiguous subpattern (connected component) starting from a given cell.
--
-- @param ip pattern upon which the flood fill is to be performed.
-- @param icell a cell specifying the origin of the flood fill.
-- @param nbh (optional) neighbourhood to use (default: neighbourhood.moore()).
-- @return a new pattern containing the connected component.
-- @usage
-- local component = p:floodfill(cell.new(2, 3))
function pattern.floodfill(ip, icell, nbh)
    assert(getmetatable(ip) == pattern, "pattern.floodfill requires a pattern as the first argument")
    assert(icell, "pattern.floodfill requires a cell as the second argument")
    if nbh == nil then nbh = neighbourhood.moore() end
    local retpat = pattern.new()
    floodfill(icell.x, icell.y, nbh, ip, retpat)
    return retpat
end

--- Finds the largest contiguous rectangular subpattern within the pattern.
--
-- @param ip pattern to analyze.
-- @return a subpattern representing the maximal rectangle.
-- @usage
-- local rect = p:max_rectangle()
function pattern.max_rectangle(ip)
    assert(getmetatable(ip) == pattern, "pattern.max_rectangle requires a pattern as an argument")
    local primitives = require('forma.primitives')
    local bsp = require('forma.utils.bsp')
    local min_rect, max_rect = bsp.max_rectangle_coordinates(ip)
    local size = max_rect - min_rect + cell.new(1, 1)
    return primitives.square(size.x, size.y):translate(min_rect.x, min_rect.y)
end

--- Computes the convex hull of the pattern.
-- The hull points are connected using line rasterization.
--
-- @param ip pattern to process.
-- @return a new pattern representing the convex hull.
-- @usage
-- local hull = p:convex_hull()
function pattern.convex_hull(ip)
    assert(getmetatable(ip) == pattern, "pattern.convex_hull requires a pattern as the first argument")
    assert(ip:size() > 0, "pattern.convex_hull: input pattern must have at least one cell")
    local convex_hull = require('forma.utils.convex_hull')
    local primitives = require('forma.primitives')
    local hull_points = convex_hull.points(ip)
    local chull = pattern.new()
    for i = 1, #hull_points - 1, 1 do
        chull = chull + primitives.line(hull_points[i], hull_points[i + 1])
    end
    chull = chull + primitives.line(hull_points[#hull_points], hull_points[1])
    return chull
end

--- Returns a thinned (skeletonized) version of the pattern.
-- Repeatedly removes boundary cells (while preserving connectivity) until no
-- further safe removals can be made.
--
-- @param ip pattern to thin.
-- @param nbh (optional) neighbourhood for connectivity (default: neighbourhood.moore()).
-- @return a new, thinned pattern.
-- @usage
-- local thin_p = p:thin()
function pattern.thin(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.thin requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.thin requires a neighbourhood as the second argument")
    local current = pattern.clone(ip)
    local function num_components(pat)
        return pattern.connected_components(pat, nbh):n_components()
    end
    local changed = true
    while changed do
        changed = false
        local comp_count = num_components(current)
        local boundary = current:interior_hull(nbh)
        for c in boundary:cells() do
            local ncount = pattern.count_neighbors(current, nbh, c.x, c.y)
            if ncount > 1 then
                local candidate = current - pattern.new():insert(c.x, c.y)
                if num_components(candidate) == comp_count then
                    current = candidate
                    changed = true
                    break
                end
            end
        end
    end
    return current
end

--- Morphological operations
-- @section morphological

--- Returns the erosion of the pattern.
-- A cell is retained only if all of its neighbours (as defined by nbh) are active.
--
-- @param ip pattern to erode.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new, eroded pattern.
-- @usage
-- local eroded = p:erode(neighbourhood.moore())
function pattern.erode(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.erode requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.erode requires a neighbourhood as the second argument")
    local result = pattern.new()
    for x, y in ip:cell_coordinates() do
        local keep = true
        for j = 1, #nbh, 1 do
            local offset = nbh[j]
            local nx = x + offset.x
            local ny = y + offset.y
            if not ip:has_cell(nx, ny) then
                keep = false
                break
            end
        end
        if keep then
            result:insert(x, y)
        end
    end
    return result
end

--- Returns the dilation of the pattern.
-- Each active cell contributes its neighbours (as defined by nbh) to the result.
--
-- @param ip pattern to dilate.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new, dilated pattern.
-- @usage
-- local dilated = p:dilate(neighbourhood.moore())
function pattern.dilate(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.dilate requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.dilate requires a neighbourhood as the second argument")
    local np = pattern.clone(ip)
    for x, y in ip:cell_coordinates() do
        for j = 1, #nbh, 1 do
            local offset = nbh[j]
            local nx = x + offset.x
            local ny = y + offset.y
            if not np:has_cell(nx, ny) then
                np:insert(nx, ny)
            end
        end
    end
    return np
end

--- Returns the morphological gradient of the pattern.
-- Computes the difference between the dilation and erosion.
--
-- @param ip pattern to process.
-- @param nbh neighbourhood for dilation/erosion (default: neighbourhood.moore()).
-- @return a new pattern representing the gradient.
-- @usage
-- local grad = p:gradient(neighbourhood.moore())
function pattern.gradient(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.gradient requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.gradient requires a neighbourhood as the second argument")
    return pattern.dilate(ip, nbh) - pattern.erode(ip, nbh)
end

--- Returns the morphological opening of the pattern.
-- Performs erosion followed by dilation to remove small artifacts.
--
-- @param ip pattern to process.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new, opened pattern.
-- @usage
-- local opened = p:opening(neighbourhood.moore())
function pattern.opening(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.opening requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.opening requires a neighbourhood as the second argument")
    local eroded = pattern.erode(ip, nbh)
    return pattern.dilate(eroded, nbh)
end

--- Returns the morphological closing of the pattern.
-- Performs dilation followed by erosion to fill small holes.
--
-- @param ip pattern to process.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new, closed pattern.
-- @usage
-- local closed = p:closing(neighbourhood.moore())
function pattern.closing(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.closing requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.closing requires a neighbourhood as the second argument")
    local dilated = pattern.dilate(ip, nbh)
    return pattern.erode(dilated, nbh)
end

--- Returns a pattern of cells that form the interior hull.
-- These are cells that neighbor inactive cells while still belonging to the pattern.
--
-- @param ip pattern to process.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new pattern representing the interior hull.
-- @usage
-- local interior = p:interior_hull(neighbourhood.moore())
function pattern.interior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.interior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.interior_hull requires a neighbourhood as an argument")
    return (ip - pattern.erode(ip, nbh))
end

--- Returns a pattern of cells that form the exterior hull.
-- This consists of inactive neighbours of the pattern, useful for enlarging or
-- determining non-overlapping borders.
--
-- @param ip pattern to process.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a new pattern representing the exterior hull.
-- @usage
-- local exterior = p:exterior_hull(neighbourhood.moore())
function pattern.exterior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.exterior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.exterior_hull requires a neighbourhood as an argument")
    return (pattern.dilate(ip, nbh) - ip)
end

--- Packing methods
-- @section packing

--- Finds a packing offset where pattern a fits entirely within domain b.
-- Returns a coordinate shift that, when applied to a, makes it tile inside b.
--
-- @param a pattern to pack.
-- @param b domain pattern in which to pack a.
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a cell (as a coordinate shift) if a valid position is found; nil otherwise.
-- @usage
-- local offset = pattern.find_packing_position(p, domain)
function pattern.find_packing_position(a, b, rng)
    assert(getmetatable(a) == pattern, "pattern.find_packing_position requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.find_packing_position requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.find_packing_position requires a non-empty pattern as the first argument")
    local hinge = a:rcell(rng)
    for bcell in b:cells() do
        local coordshift = bcell - hinge
        local tiles = true
        for acell in a:cells() do
            local shifted = acell + coordshift
            if b:has_cell(shifted.x, shifted.y) == false then
                tiles = false
                break
            end
        end
        if tiles == true then
            return coordshift
        end
    end
    return nil
end

--- Finds a center-weighted packing offset to place pattern a as close as possible to the center of domain b.
--
-- @param a pattern to pack.
-- @param b domain pattern.
-- @return a coordinate shift if a valid position is found; nil otherwise.
-- @usage
-- local central_offset = pattern.find_central_packing_position(p, domain)
function pattern.find_central_packing_position(a, b)
    assert(getmetatable(a) == pattern, "pattern.find_central_packing_position requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.find_central_packing_position requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.find_central_packing_position requires a non-empty pattern as the first argument")
    if b:size() == 0 then return nil end
    local hinge    = a:medoid()
    local com      = b:centroid()
    local allcells = b:cell_list()
    local function distance_to_com(k, j)
        local adist = (k.x - com.x) * (k.x - com.x) + (k.y - com.y) * (k.y - com.y)
        local bdist = (j.x - com.x) * (j.x - com.x) + (j.y - com.y) * (j.y - com.y)
        return adist < bdist
    end
    table.sort(allcells, distance_to_com)
    for i = 1, #allcells, 1 do
        local coordshift = allcells[i] - hinge
        local tiles = true
        for acell in a:cells() do
            local shifted = acell + coordshift
            if b:has_cell(shifted.x, shifted.y) == false then
                tiles = false
                break
            end
        end
        if tiles == true then
            return coordshift
        end
    end
    return nil
end

--- Multipattern methods
-- @section multipatterns

--- Returns a multipattern of the connected components within the pattern.
-- Uses flood-fill to extract contiguous subpatterns.
--
-- @param ip pattern to analyze.
-- @param nbh neighbourhood (default: neighbourhood.moore()).
-- @return a multipattern containing each connected component as a subpattern.
-- @usage
-- local components = p:connected_components(neighbourhood.moore())
function pattern.connected_components(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.connected_components requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood,
        "pattern.connected_components requires a neighbourhood as the second argument")
    local wp = pattern.clone(ip)
    local mp = multipattern.new()
    while pattern.size(wp) > 0 do
        local seed_cell = wp:cells()()
        local segment = pattern.floodfill(wp, seed_cell, nbh)
        wp = wp - segment
        mp:insert(segment)
    end
    return mp
end

--- Returns a multipattern of the interior holes of the pattern.
-- Interior holes are inactive regions completely surrounded by active cells.
--
-- @param ip pattern to analyze.
-- @param nbh neighbourhood (default: neighbourhood.von_neumann()).
-- @return a multipattern of interior hole subpatterns.
-- @usage
-- local holes = p:interior_holes(neighbourhood.von_neumann())
function pattern.interior_holes(ip, nbh)
    nbh = nbh or neighbourhood.von_neumann()
    assert(getmetatable(ip) == pattern, "pattern.interior_holes requires a pattern as the first argument")
    assert(ip:size() > 0, "pattern.interior_holes requires a non-empty pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.interior_holes requires a neighbourhood as the second argument")
    local primitives = require('forma.primitives')
    local size = ip.max - ip.min + cell.new(1, 1)
    local interior = primitives.square(size.x, size.y):translate(ip.min.x, ip.min.y) - ip
    local connected_components = pattern.connected_components(interior, nbh)
    local function fn(sp)
        if sp.min.x > ip.min.x and sp.min.y > ip.min.y and sp.max.x < ip.max.x and sp.max.y < ip.max.y then
            return true
        end
        return false
    end
    return connected_components:filter(fn)
end

--- Partitions the pattern using binary space partitioning (BSP).
-- Recursively subdivides contiguous rectangular areas until each partition's volume is below th_volume.
--
-- @param ip pattern to partition.
-- @param th_volume threshold volume (number) for final partitions.
-- @return a multipattern of BSP subpatterns.
-- @usage
-- local partitions = p:bsp(50)
function pattern.bsp(ip, th_volume)
    assert(getmetatable(ip) == pattern, "pattern.bsp requires a pattern as an argument")
    assert(th_volume, "pattern.bsp rules must specify a threshold volume for partitioning")
    assert(th_volume > 0, "pattern.bsp rules must specify positive threshold volume for partitioning")
    local available = ip
    local mp = multipattern.new()
    local bsp = require('forma.utils.bsp')
    while pattern.size(available) > 0 do
        local min_rect, max_rect = bsp.max_rectangle_coordinates(available)
        bsp.split(min_rect, max_rect, th_volume, mp)
        available = available - mp:union_all()
    end
    return mp
end

--- Categorizes cells in the pattern based on neighbourhood configurations.
-- Returns a multipattern with one subpattern per neighbourhood category.
--
-- @param ip pattern whose cells are to be categorized.
-- @param nbh neighbourhood used for categorization.
-- @return a multipattern with each category represented as a subpattern.
-- @usage
-- local categories = p:neighbourhood_categories(neighbourhood.moore())
function pattern.neighbourhood_categories(ip, nbh)
    assert(getmetatable(ip) == pattern, "pattern.neighbourhood_categories requires a pattern as a first argument")
    assert(getmetatable(nbh) == neighbourhood,
        "pattern.neighbourhood_categories requires a neighbourhood as a second argument")
    local category_patterns = {}
    for i = 1, nbh:get_ncategories(), 1 do
        category_patterns[i] = pattern.new()
    end
    for icell in ip:cells() do
        local cat = nbh:categorise(ip, icell)
        category_patterns[cat]:insert(icell.x, icell.y)
    end
    return multipattern.new(category_patterns)
end

--- Applies Perlin noise sampling to the pattern.
-- Generates a multipattern by thresholding Perlin noise values at multiple levels.
--
-- @param ip pattern (domain) to sample from.
-- @param freq frequency for Perlin noise (number).
-- @param depth sampling depth (integer).
-- @param thresholds table of threshold values (each between 0 and 1).
-- @param rng (optional) random number generator (e.g., math.random).
-- @return a multipattern with one component per threshold level.
-- @usage
-- local noise_samples = p:perlin(0.1, 4, {0.3, 0.5, 0.7})
function pattern.perlin(ip, freq, depth, thresholds, rng)
    if rng == nil then rng = math.random end
    assert(getmetatable(ip) == pattern, "pattern.perlin requires a pattern as the first argument")
    assert(type(freq) == "number", "pattern.perlin requires a numerical frequency value.")
    assert(math.floor(depth) == depth, "pattern.perlin requires an integer sampling depth.")
    assert(type(thresholds) == "table", "pattern.perlin requires a table of requested thresholds.")
    for _, th in ipairs(thresholds) do
        assert(th >= 0 and th <= 1, "pattern.perlin requires thresholds between 0 and 1.")
    end
    local samples = {}
    for i = 1, #thresholds, 1 do
        samples[i] = pattern.new()
    end
    local noise = require('forma.utils.noise')
    local p_noise = noise.init(rng)
    for ix, iy in ip:cell_coordinates() do
        local nv = noise.perlin(p_noise, ix, iy, freq, depth)
        for ith, th in ipairs(thresholds) do
            if nv >= th then
                samples[ith]:insert(ix, iy)
            end
        end
    end
    return multipattern.new(samples)
end

--- Generates Voronoi tessellation segments for a domain based on seed points.
--
-- @param seeds pattern containing seed cells.
-- @param domain pattern defining the tessellation domain.
-- @param measure distance function (e.g., cell.euclidean).
-- @return a multipattern of Voronoi segments.
-- @usage
-- local segments = pattern.voronoi(seeds, domain, cell.euclidean)
function pattern.voronoi(seeds, domain, measure)
    assert(getmetatable(seeds) == pattern, "pattern.voronoi requires a pattern as the first argument")
    assert(getmetatable(domain) == pattern, "pattern.voronoi requires a pattern as a second argument")
    assert(pattern.size(seeds) > 0, "pattern.voronoi requires at least one target cell/seed")
    local seedcells = {}
    local segments  = {}
    for iseed in seeds:cells() do
        assert(domain:has_cell(iseed.x, iseed.y), "forma.voronoi: cell outside of domain")
        table.insert(seedcells, iseed)
        table.insert(segments, pattern.new())
    end
    for dp in domain:cells() do
        local min_cell = 1
        local min_dist = measure(dp, seedcells[1])
        for j = 2, #seedcells, 1 do
            local distance = measure(dp, seedcells[j])
            if distance < min_dist then
                min_cell = j
                min_dist = distance
            end
        end
        segments[min_cell]:insert(dp.x, dp.y)
    end
    return multipattern.new(segments)
end

--- Performs centroidal Voronoi tessellation (Lloyd's algorithm) on a set of seeds.
-- Iteratively relaxes seed positions until convergence or a maximum number of iterations.
--
-- @param seeds initial seed pattern.
-- @param domain tessellation domain pattern.
-- @param measure distance function (e.g., cell.euclidean).
-- @param max_ite (optional) maximum iterations (default: 30).
-- @return a multipattern of Voronoi segments, a pattern of relaxed seed positions, and a boolean convergence flag.
-- @usage
-- local segments, relaxed_seeds, converged = pattern.voronoi_relax(seeds, domain, cell.euclidean)
function pattern.voronoi_relax(seeds, domain, measure, max_ite)
    if max_ite == nil then max_ite = 30 end
    assert(getmetatable(seeds) == pattern, "pattern.voronoi_relax requires a pattern as the first argument")
    assert(getmetatable(domain) == pattern, "pattern.voronoi_relax requires a pattern as a second argument")
    assert(type(measure) == 'function', "pattern.voronoi_relax requires a distance measure as an argument")
    assert(seeds:size() <= domain:size(), "pattern.voronoi_relax: too many seeds for domain")
    local current_seeds = seeds:clone()
    for ite = 1, max_ite, 1 do
        local tesselation = pattern.voronoi(current_seeds, domain, measure)
        local next_seeds  = pattern.new()
        for iseg = 1, tesselation:n_components(), 1 do
            if tesselation[iseg]:size() > 0 then
                local cent = tesselation[iseg]:centroid()
                if domain:has_cell(cent.x, cent.y) then
                    if not next_seeds:has_cell(cent.x, cent.y) then
                        next_seeds:insert(cent.x, cent.y)
                    end
                else
                    local med = tesselation[iseg]:medoid()
                    if not next_seeds:has_cell(med.x, med.y) then
                        next_seeds:insert(med.x, med.y)
                    end
                end
            end
        end
        if current_seeds == next_seeds then
            return tesselation, current_seeds, true
        elseif ite == max_ite then
            return tesselation, current_seeds, false
        end
        current_seeds = next_seeds
    end
    assert(false, "This should not be reachable")
end

--- Test components
-- @section test

--- Returns the maximum allowed coordinate for spatial hashing.
--
-- @return maximum coordinate value (number).
-- @usage
-- local max_coord = pattern.get_max_coordinate()
function pattern.get_max_coordinate()
    return MAX_COORDINATE
end

--- Tests the conversion between (x, y) coordinates and the spatial hash key.
--
-- @param x test x-coordinate (number).
-- @param y test y-coordinate (number).
-- @return boolean true if the conversion is correct, false otherwise.
-- @usage
-- local valid = pattern.test_coordinate_map(10, 20)
function pattern.test_coordinate_map(x, y)
    assert(type(x) == 'number' and type(y) == 'number',
        "pattern.test_coordinate_map requires two numbers as arguments")
    local key = coordinates_to_key(x, y)
    local tx, ty = key_to_coordinates(key)
    return (x == tx) and (y == ty)
end

return pattern
