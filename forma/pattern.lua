--- A class containing a set or *pattern* of cells.
--
-- The **pattern** class is the central class of `forma`, representing a set of
-- points or *cells*. This set can be initialised as empty, or according to a
-- 'prototype' consisting of a NxM table matrix of 1's or 0's. Several helper
-- methods for the initialisation of a `pattern` are provided in the
-- `primitives` module.  Once initialised, a pattern can only be modified by
-- the `insert` method, used to add active cells. All other pattern
-- manipulations return a new, modified pattern rather than modifying patterns
-- in-place.
--
-- Several pattern manipulators are provided here. For example a `translate`
-- manipulator which translates the coordinates of an entire pattern, manipulators
-- that `enlarge` a pattern by a scale factor and modifiers than can `rotate`
-- or reflect patterns in the x (`hreflect`) or y (`vreflect`) axes.
-- Particuarly useful are manipulators which generate new patterns such as the
-- `exterior_hull` or `interior_hull` of other patterns. These manipulators can
-- be used with custom definitions of a cell's `neighbourhood`.
--
-- Pattern coordinates should be reliable in [-65536, 65536]. This is
-- adjustable through the `MAX_COORDINATE` constant.
--
-- Through an abuse of metatables, all functions can be used either 'procedurally' as
--      pattern.method(input_pattern, ... )
-- or as a class method
--      input_pattern:method(...)
--
-- @usage
-- -- 'Procedural' style pattern creation
-- local p1 = pattern.new()
-- pattern.insert(p1, 1,1)
--
-- -- 'Method' style with chaining used for :insert
-- local p2 = pattern.new():insert(1,1) -- Idential as to p1
--
-- -- 'Prototype' style
-- local p3 = pattern.new({{1,1,1},
--                         {1,0,1},
--                         {1,1,1}})
--
-- -- Fetch a random cell and the medoid (centre-of-mass) cell from a pattern
-- local random_cell = p1:rcell()
-- local medoid_cell = p1:medoid()
--
-- -- Compute the outer (outside the existing pattern) hull
-- -- Using 8-direction (Moore) neighbourhood
-- local outer_hull = p1:exterior_hull(neighbourhood.moore())
-- -- or equivalently
-- outer_hull = pattern.exterior_hull(p1, neighbourhood.moore())
--
-- @module forma.pattern
local pattern         = {}

local min             = math.min
local max             = math.max
local floor           = math.floor

local cell            = require('forma.cell')
local neighbourhood   = require('forma.neighbourhood')

-- Pattern indexing
-- For enabling syntax sugar pattern:method
pattern.__index       = pattern

-- Pattern coordinates (either x or y) must be within ± MAX_COORDINATE
local MAX_COORDINATE  = 65536
local COORDINATE_SPAN = 2 * MAX_COORDINATE + 1

--- Generate the cellmap key from coordinates
local function coordinates_to_key(x, y)
    return (x + MAX_COORDINATE) * COORDINATE_SPAN + (y + MAX_COORDINATE)
end

--- Generate the coordinates from the key
local function key_to_coordinates(key)
    local yp = (key % COORDINATE_SPAN)
    local xp = (key - yp) / COORDINATE_SPAN
    return xp - MAX_COORDINATE, yp - MAX_COORDINATE
end

-- Copies an input table in a randomly shuffled order
local function shuffled_copy(intable, rng)
    -- Copy and Fisher-Yates shuffle
    local extable = {}
    for i = 1, #intable, 1 do
        local j = rng(1, i)
        if j ~= i then
            extable[i] = extable[j]
        end
        extable[j] = intable[i]
    end
    return extable
end

--- Basic methods.
-- Methods for the creation, copying and adding of cells to a pattern.
--@section basic

--- Pattern constructor.
--  This method returns a new pattern, according to a prototype. If no
--  prototype is used, then an empty pattern is returned. For example, if
--  called with the prototype `{{1,0},{0,1}}` this method will return the
--  pattern:
--  `
--    10
--    01
--  `
-- Active cells are stored in the pattern in a standard integer keyed table, and
-- also as elements in a spatial hash map for fast look-up of active cells.
-- @param prototype (optional) an N*M 2D table of ones and zeros
-- @return a new pattern according to the prototype
function pattern.new(prototype)
    local np   = {}

    np.max     = cell.new(-math.huge, -math.huge)
    np.min     = cell.new(math.huge, math.huge)

    -- Characters to be used with tostring metamethod
    np.offchar = '0'
    np.onchar  = '1'

    np.cellkey = {} -- Table consisting of a list of coordinate keys
    np.cellmap = {} -- Spatial hash of coordinate key to bool (active/inactive cell)

    np         = setmetatable(np, pattern)

    if prototype ~= nil then
        assert(type(prototype) == 'table',
            'pattern.new requires either no arguments or a N*N matrix as a prototype')
        local N, M = #prototype, nil
        for i = 1, N, 1 do
            local row = prototype[i]
            assert(type(row) == 'table',
                'pattern.new requires either no arguments or a N*N matrix as a prototype')
            if i == 1 then
                M = #row
            else
                assert(#row == M,
                    'pattern.new requires a N*M matrix as prototype when called with an argument')
            end
            for j = 1, M, 1 do
                local icell = row[j]
                if icell == 1 then
                    np:insert(j - 1, i - 1) -- Patterns start from zero
                else
                    assert(icell == 0, 'pattern.new: invalid prototype entry (must be 1 or 0): ' .. icell)
                end
            end
        end
    end

    return np
end

--- Copy an existing pattern.
-- @param ip input pattern for cloning
-- @return a copy of the pattern ip
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

--- Insert a new cell into a pattern.
-- Re-returns the provided cell to enable cascading.
-- e.g `pattern.new():insert(x,y)` returns a pattern with
-- a single cell at (x,y).
-- @param ip pattern for cell insertion
-- @param x first coordinate of new cell
-- @param y second coordinate of new cell
-- @return ip for method cascading
function pattern.insert(ip, x, y)
    assert(floor(x) == x, 'pattern.insert requires an integer for the x coordinate')
    assert(floor(y) == y, 'pattern.insert requires an integer for the y coordinate')

    local key = coordinates_to_key(x, y)
    assert(ip.cellmap[key] == nil, "pattern.insert cannot duplicate cells")
    ip.cellmap[key] = true
    ip.cellkey[#ip.cellkey + 1] = key

    -- reset pattern extent
    ip.max.x = max(ip.max.x, x)
    ip.max.y = max(ip.max.y, y)
    ip.min.x = min(ip.min.x, x)
    ip.min.y = min(ip.min.y, y)

    return ip
end

--- Check if a cell is active in a pattern.
-- This has fewer checks than usual as it's a common inner-loop call.
-- @param ip pattern for cell check
-- @param x first coordinate of cell to be returned
-- @param y second coordinate of cell to be returned
-- @return True if pattern `ip` includes the cell at (x,y), False otherwise
function pattern.has_cell(ip, x, y)
    local key = coordinates_to_key(x, y)
    return ip.cellmap[key] ~= nil
end

--- Return a list of cells active in the pattern.
-- @param ip source pattern for active cell list.
function pattern.cell_list(ip)
    assert(getmetatable(ip) == pattern, "pattern.cell_list requires a pattern as the first argument")
    local newlist = {}
    for icell in ip:cells() do
        newlist[#newlist + 1] = icell
    end
    return newlist
end

--- Return the number of cells active in a pattern.
-- @param ip pattern for size check
function pattern.size(ip)
    assert(getmetatable(ip) == pattern, "pattern.size requires a pattern as the first argument")
    return #ip.cellkey
end

--- Size comparator for two patterns.
-- Useful for table.sort to rank patterns by size (number of cells)
-- @param pa the first pattern for comparison
-- @param pb the second pattern for comparison
-- @return pa:size() > pb:size()
function pattern.size_sort(pa, pb)
    return pa:size() > pb:size()
end

--- Count how many active neighbors are around a given position in a pattern,
-- based on a specified neighbourhood.
-- This can be invoked in two ways:
--    1) pattern.count_neighbors(p, nbh, c)
--    2) pattern.count_neighbors(p, nbh, x, y)
-- @param p   A forma.pattern
-- @param nbh A forma.neighbourhood
-- @param arg1 Either a cell object or the x-coordinate
-- @param arg2 (optional) The y-coordinate if arg1 is x
-- @return The integer count of active neighbors around that position
function pattern.count_neighbors(p, nbh, arg1, arg2)
    -- Validate arguments
    assert(getmetatable(p) == pattern,
        "count_neighbors: first argument must be a forma.pattern")
    assert(getmetatable(nbh),
        "count_neighbors: second argument must be a neighbourhood")

    -- Figure out whether arg1 is a cell or an x-coordinate
    local x, y
    if type(arg1) == 'table' and arg1.x and arg1.y then
        -- arg1 is a cell-like table
        x, y = arg1.x, arg1.y
    else
        -- arg1, arg2 are x,y
        x, y = arg1, arg2
    end

    -- Compute neighbor count
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

--- Return the total number of differing cells between two patterns.
-- @param a first pattern for edit distance calculation
-- @param b second pattern for edit distance calculation
function pattern.edit_distance(a, b)
    assert(getmetatable(a) == pattern, "pattern.edit_distance requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.edit_distance requires a pattern as the second argument")
    local common = pattern.intersection(a, b)
    local edit_distance = (a - common):size() + (b - common):size()
    return edit_distance
end

-----------------------
--- Iterators.
-- @section Iterators

--- Iterator over active cells in the pattern.
-- @param ip source pattern for active cell iterator
-- @return an iterator returning a `cell` for every active cell in the pattern
-- @usage
-- local ipattern = primitives.square(10)
-- for icell in ipattern:cells() do
--     print(icell.x, icell.y)
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

--- Iterator over active cell coordinates in the pattern.
-- Simmilar to `pattern.cells` but provides an iterator that runs over (x,y)
-- coordinates instead of `cell` instances. Normally faster than
-- `pattern.cells` as no tables are created here.
-- @param ip source pattern for active cell iterator
-- @return an iterator returning active cell (x,y) coordinates
-- @usage
-- local ipattern = primitives.square(10)
-- for ix, iy in ipattern:cell_coordinates() do
--     print(ix, iy)
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

--- Shuffled iterator over active cells in the pattern.
-- Simmilar to `pattern.cells` but provides an iterator that returns cells in a
-- randomised order, according to a provided random number generator. See
-- `pattern.cells` for usage.
-- @param ip source pattern for active cell iterator
-- @param rng (optional) A random number generating table, following the signature of math.random
-- @return an iterator returning a `cell` for every active cell in the pattern, in a randomised order
function pattern.shuffled_cells(ip, rng)
    assert(getmetatable(ip) == pattern,
        "pattern.shuffled_cells requires a pattern as the first argument")
    if rng == nil then rng = math.random end
    local icell, ncells = 0, ip:size()

    -- Copy and Fisher-Yates shuffle
    local cellkeys = ip.cellkey
    local skeys = shuffled_copy(cellkeys, rng)

    -- Return iterator
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = skeys[icell]
            local x, y = key_to_coordinates(ikey)
            return cell.new(x, y)
        end
    end
end

--- Shuffled iterator over active cell coordinates in the pattern.
-- Simmilar to `pattern.cell_coordinates` but returns cell (x,y) coordinates in
-- a randomised order according to a provided random number generator. See
-- `pattern.cell_coordinates` for usage.
-- @param ip source pattern for active cell
-- iterator
-- @param rng (optional) A random number generating table, following the signature of math.random
-- @return an iterator returning active cell (x,y) coordinates, randomly shuffled
function pattern.shuffled_coordinates(ip, rng)
    assert(getmetatable(ip) == pattern,
        "pattern.shuffled_coordinates requires a pattern as the first argument")
    if rng == nil then rng = math.random end
    local icell, ncells = 0, ip:size()

    -- Copy and Fisher-Yates shuffle
    local cellkeys = ip.cellkey
    local skeys = shuffled_copy(cellkeys, rng)

    -- Return iterator
    return function()
        icell = icell + 1
        if icell <= ncells then
            local ikey = skeys[icell]
            return key_to_coordinates(ikey)
        end
    end
end

-----------------------
--- Metamethods.
-- @section Metamethods

--- Render pattern as a string.
-- Prints the stored pattern to string, rendered using the character stored in
-- pattern.onchar for activated cells and pattern.offchar for unactivated cells.
-- @param ip The pattern to be rendered as a string
-- @return pattern as string
function pattern.__tostring(ip)
    local string = '- pattern origin: ' .. tostring(ip.min) .. '\n'
    for y = ip.min.y, ip.max.y, 1 do
        for x = ip.min.x, ip.max.x, 1 do
            local char = ip:has_cell(x, y) and ip.onchar or ip.offchar
            string = string .. char
        end
        string = string .. '\n'
    end
    return string
end

--- Add two patterns to each other.
-- @param a first pattern to be added
-- @param b second pattern to be added
-- @return New pattern consisting of the union of patterns a and b
function pattern.__add(a, b)
    assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")
    return pattern.union(a,b)
end

--- Subtract one pattern from another.
-- @param a base pattern
-- @param b pattern to be subtracted from a
-- @return New pattern consisting of the subset of cells in a which are not in b
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

--- Pattern intersection using the * operator
-- Returns the set of cells active in both patterns a and b.
-- @param a first pattern
-- @param b second pattern
-- @return a new pattern which is the intersection of a and b
function pattern.__mul(a, b)
    assert(getmetatable(a) == pattern, "pattern multiplication requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern multiplication requires a pattern as the second argument")
    return pattern.intersection(a, b)
end

--- Symmetric difference (XOR) of two patterns using ^ operator.
-- Cells present in A or B but not both.
-- @param a first pattern
-- @param b second pattern
-- @return new pattern which is the symmetric difference of a and b
function pattern.__pow(a, b)
    assert(getmetatable(a) == pattern, "pattern exponent (XOR) requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern exponent (XOR) requires a pattern as the second argument")
    return pattern.xor(a, b)
end

--- Pattern equality test.
-- @param a first pattern for equality check
-- @param b second pattern for equality check
-- @return true if patterns are identical, false if not
function pattern.__eq(a, b)
    assert(getmetatable(a) == pattern, "pattern equality test requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern equality test requires a pattern as the second argument")
    -- Easy and fast checks
    if a:size() ~= b:size() then return false end
    if a.min ~= b.min then return false end
    if a.max ~= b.max then return false end
    -- Slower checks
    for x, y in a:cell_coordinates() do
        if b:has_cell(x, y) == false then return false end
    end
    return true
end

-----------------------------------------------------
--- Pattern cell selectors.
-- These methods select certain cells from a pattern.
-- @section cellselectors

--- Pattern random cell method.
-- Returns a cell at random from the pattern.
-- @param ip pattern for random cell retrieval
-- @param rng (optional) A random number generating table, following the signature of math.random.
-- @return a random cell in the pattern
function pattern.rcell(ip, rng)
    assert(getmetatable(ip) == pattern, "pattern.rcell requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.rcell requires a filled pattern!')

    -- Check RNG
    if rng == nil then rng = math.random end
    local icell = rng(#ip.cellkey)
    local ikey = ip.cellkey[icell]
    local x, y = key_to_coordinates(ikey)
    return cell.new(x, y)
end

--- Compute the centroid of a pattern.
-- Returns the (arithmetic) mean position of all cells in an input pattern.
-- The centroid is rounded to the nearest integer-coordinate cell. Note this
-- does not neccesarily correspond to an /active/ cell in the input pattern.
-- If you need the closest active cell to the centroid, use `pattern.medoid`.
-- @param ip input pattern
-- @return the cell-coordinate centroid of `ip`
function pattern.centroid(ip)
    assert(getmetatable(ip) == pattern, "pattern.centroid requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.centroid requires a filled pattern!')

    local sumx, sumy = 0, 0
    for x, y in ip:cell_coordinates() do
        sumx = sumx + x
        sumy = sumy + y
    end

    -- Clamp to integer coordinates
    local n = ip:size()
    local intx = floor(sumx / n + 0.5)
    local inty = floor(sumy / n + 0.5)

    return cell.new(intx, inty)
end

--- Compute the medoid cell of a pattern.
-- Returns the cell with the minimum distance to all other cells in the
-- pattern, judged by any valid distance measure (default is Euclidean). The
-- medoid cell represents the centremost active cell of a pattern, for a given
-- distance metric.
-- @param ip input pattern
-- @param measure (optional) distance measure, default euclidean
-- @return the medoid cell of `ip` for distance metric `measure`
function pattern.medoid(ip, measure)
    assert(getmetatable(ip) == pattern, "pattern.medoid requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.medoid requires a filled pattern!')
    measure = measure or cell.euclidean2

    local ncells = ip:size()
    local cell_list = ip:cell_list()

    -- Initialise distance table
    local distance = {}
    for _ = 1, ncells, 1 do distance[#distance + 1] = 0 end

    local minimal_distance = math.huge
    local minimal_index = -1
    for i = 1, ncells, 1 do
        for j = i, ncells, 1 do -- Could be i+1, but simpler to not (saves ncells=1)
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

---------------------------------------------------------------------------
--- Pattern manipulators.
-- These methods generate different 'child' patterns from an input pattern.
-- @section manipulators

--- Generate a copy of a pattern translated by a vector(x,y)
-- @param ip pattern to be shifted
-- @param sx amount to translate x-coordinates by
-- @param sy amount to translate y-coordinates by
-- @return New pattern consisting of ip translated by (sx,sy)
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

--- Copy a pattern, translating its origin to (0,0).
-- @param ip pattern to be normalised
-- @return A new normalised pattern
function pattern.normalise(ip)
    assert(getmetatable(ip) == pattern, "pattern.normalise requires a pattern as the first argument")
    return ip:translate(-ip.min.x, -ip.min.y)
end

--- Generate an enlarged version of a pattern.
-- This returns a new pattern in which each cell in an input pattern is
-- converted to a f*f cell block. The returned pattern is in such a way an
-- 'enlarged' version of the input pattern, by a scale factor of 'f' in both x
-- and y.
-- @param ip pattern to be enlarged
-- @param f factor of enlargement
-- @return enlarged pattern
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

--- Rotate a pattern by 90° clockwise about the origin
-- @param ip pattern to be rotated
-- @return copy of `ip` which has been rotated by 90°
function pattern.rotate(ip)
    assert(getmetatable(ip) == pattern, "pattern.rotate requires a pattern as the first argument")
    local np = pattern.new()
    for x, y in ip:cell_coordinates() do
        np:insert(y, -x)
    end
    return np
end

--- Generate a copy of a pattern, mirroring it vertically.
-- @param ip pattern for reflection
-- @return copy of `ip` which has been is reflected vertically
function pattern.vreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.vreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
    for vx, vy in ip:cell_coordinates() do
        local new_y = 2 * ip.max.y - vy + 1
        np:insert(vx, new_y)
    end
    return np
end

--- Generate a copy of a pattern, mirroring it horizontally.
-- Reflect a pattern horizontally
-- @param ip pattern for reflection
-- @return copy of `ip` which has been reflected horizontally
function pattern.hreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.hreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
    for vx, vy in ip:cell_coordinates() do
        local new_x = 2 * ip.max.x - vx + 1
        np:insert(new_x, vy)
    end
    return np
end

--- Erode a pattern according to a given neighborhood.
-- Each cell remains active only if all of its neighbors in `nbh`
-- are also active.
-- @param ip input pattern to be eroded
-- @param nbh a neighbourhood (list of relative offsets),
--        e.g. neighbourhood.moore() or neighbourhood.von_neumann()
-- @return a new pattern which is the erosion of ip
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

--- Dilate a pattern according to a given neighborhood.
-- Each active cell in `ip` contributes its neighbors (as defined by `nbh`)
-- to the resulting pattern. The resulting pattern consists of the union of the
-- initial pattern and its exterior hull.
-- @param ip input pattern to be dilated
-- @param nbh a neighbourhood (list of relative offsets),
--        e.g. neighbourhood.moore() or neighbourhood.von_neumann()
-- @return a new pattern which is the dilation of `ip`
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


--- Morphological gradient of a pattern.
-- This returns a new pattern consisting of the difference between the dilation
-- and erosion of an input pattern. This is useful for determining the 'edges'
-- of a pattern, as it returns the cells that are active in the dilation but not
-- in the erosion.
-- @param ip input pattern
-- @param nbh neighbourhood used for dilation/erosion
-- @return new pattern which is the gradient of ip
function pattern.gradient(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.gradient requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.gradient requires a neighbourhood as the second argument")
    return pattern.dilate(ip, nbh) - pattern.erode(ip, nbh)
end

--- Morphological opening of a pattern: erosion -> dilation.
-- This removes small artifacts and "opens" narrow connections.
-- @param ip input pattern
-- @param nbh neighbourhood used for erosion/dilation
-- @return new pattern after opening
function pattern.opening(ip, nbh)
    assert(getmetatable(ip) == pattern, "pattern.opening requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.opening requires a neighbourhood as the second argument")
    local eroded = pattern.erode(ip, nbh)
    return pattern.dilate(eroded, nbh)
end

--- Morphological closing of a pattern: dilation -> erosion.
-- This fills in small holes and "closes" gaps in the pattern.
-- @param ip input pattern
-- @param nbh neighbourhood used for dilation/erosion
-- @return new pattern after closing
function pattern.closing(ip, nbh)
    assert(getmetatable(ip) == pattern, "pattern.closing requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.closing requires a neighbourhood as the second argument")
    local dilated = pattern.dilate(ip, nbh)
    return pattern.erode(dilated, nbh)
end

--- Generate a pattern consisting of cells on the interior_hull of a provided pattern.
-- This returns a new pattern consisting of all active cells in an input pattern
-- that *neighbour* inactive cells. It is therefore very simmilar to `pattern.exterior_hull` but
-- returns a pattern which intersects with the input pattern. This is therefore
-- useful when *shrinking* a pattern by removing a cell from its surface, or
-- determining a *border* of a pattern which consists of cells that are present
-- in the original pattern.
-- @param ip pattern for which the interior hull should be calculated
-- @param nbh defines which neighbourhood to scan in to determine the hull (default 8/moore)
-- @return A pattern representing the interior hull of ip
function pattern.interior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.interior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.interior_hull requires a neighbourhood as an argument")
    return (ip - pattern.erode(ip, nbh))
end

--- Generate a pattern consisting of all cells on the exterior hull of a provided pattern.
-- This returns a new pattern consisting of the inactive neighbours of an input
-- pattern, for a given definition of neighbourhood. Therefore the `exterior_hull`
-- method is useful for either enlarging patterns along their surface, or
-- determining a *border* of a pattern that does not overlap with the pattern
-- itself.
-- @param ip pattern for which the exterior_hull should be calculated
-- @param nbh defines which neighbourhood to scan in to determine exterior (default 8/moore)
-- @return A pattern representing the exterior hull of ip
function pattern.exterior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.exterior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.exterior_hull requires a neighbourhood as an argument")
    return (pattern.dilate(ip, nbh) - ip)
end

--- Generate a pattern consisting of the overlapping intersection of existing patterns
-- @param ... patterns for intersection calculation
-- @return A pattern consisting of the overlapping cells of the input patterns
function pattern.intersection(...)
    local patterns = { ... }
    assert(#patterns > 1, "pattern.intersection requires at least two patterns as arguments")
    table.sort(patterns, pattern.size_sort)
    -- Use smallest pattern as domain
    local domain = patterns[#patterns]
    local inter  = pattern.new()
    for x, y in domain:cell_coordinates() do
        local foundCell = true
        for i = #patterns - 1, 1, -1 do
            local tpattern = patterns[i]
            assert(getmetatable(tpattern) == pattern,
                "pattern.intersection requires a pattern as an argument")
            if not tpattern:has_cell(x, y) then
                foundCell = false
                break
            end
        end
        -- Cell exists in all patterns
        if foundCell == true then
            inter:insert(x, y)
        end
    end
    return inter
end

--- Symmetric difference of two patterns: cells in A or B, but not both.
-- @param a first pattern
-- @param b second pattern
-- @return new pattern which is the symmetric difference of a and b
function pattern.xor(a, b)
    assert(getmetatable(a) == pattern, "pattern.xor requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.xor requires a pattern as the second argument")
    return (a+b) - (a*b)
end

--- Generate a pattern consisting of the union of a set of patterns
-- @param ... patterns to union, can be either a table ({a,b}) or a list of arguments (a,b)
-- @return A pattern consisting of the union of the input patterns
function pattern.union(...)
    local patterns = { ... }
    -- Handle a single, table argument of patterns ({a,b,c}) rather than (a,b,c)
    if #patterns == 1 then
        if type(patterns[1]) == 'table' then
            patterns = patterns[1]
        end
    end
    assert(#patterns > 1, "pattern.union requires at least two patterns as arguments")
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

---------------------------------------------------------------------------
--- Packing methods.
-- These methods are used to find locations where one pattern overlaps with
-- another. They can therefore be used to 'pack' a set of pattern into another.
-- Note that these methods are not intended to be anything like optimal packing
-- algorithms.
-- @section Packing methods

--- Returns a cell where pattern `a` overlaps with pattern `b`.
-- The returned point has no particular properties w.r.t ordering of possible
-- solutions. Solutions are returned 'first-come-first-served'.
-- @param `a` the pattern to be packed in `b`.
-- @param `b` the domain which we are searching for packing solutions.
-- @return a cell in `b` where `a` can be placed, `nil` if impossible.
function pattern.packtile(a, b)
    assert(getmetatable(a) == pattern, "pattern.packtile requires a pattern as a first argument")
    assert(getmetatable(b) == pattern, "pattern.packtile requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.packtile requires a non-empty pattern as a first argument")
    -- cell to fix coordinate systems
    local hinge = a:rcell()
    -- Loop over possible positions in b
    for bcell in b:cells() do
        local coordshift = bcell - hinge -- Get coordinate transformation
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

--- Center-weighted version of pattern.packtile.
-- Tries to fit pattern `a` as close as possible to pattern `b`'s centre.
-- @param a the pattern to be packed into pattern `b`.
-- @param b the domain which we are searching for packing solutions
-- @return a cell in `b` where `a` can be placed, nil if no solution found.
function pattern.packtile_centre(a, b)
    assert(getmetatable(a) == pattern, "pattern.packtile_centre requires a pattern as a first argument")
    assert(getmetatable(b) == pattern, "pattern.packtile_centre requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.packtile_centre requires a non-empty pattern as a first argument")
    if b:size() == 0 then return nil end
    -- cell to fix coordinate systems
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
        local coordshift = allcells[i] - hinge -- Get coordinate transformation
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

--- Test methods
-- @section Testing

--- Returns the maximum hashable coordinate.
-- @return MAX_COORDINATE
function pattern.get_max_coordinate()
    return MAX_COORDINATE
end

--- Test the coordinate transform between (x,y) and spatial hash.
-- @param x test coordinate x
-- @param y test coordinate y
-- @return true if the spatial hash is functioning correctly, false if not
function pattern.test_coordinate_map(x, y)
    assert(type(x) == 'number' and type(y) == 'number',
        "pattern.test_coordinate_map requires two numbers as arguments")
    local key = coordinates_to_key(x, y)
    local tx, ty = key_to_coordinates(key)
    return (x == tx) and (y == ty)
end

return pattern
