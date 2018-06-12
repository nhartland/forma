--- A class containing a set or *pattern* of cells.
--
-- The **pattern** class is the central class of this module, representing a
-- set of `cell`s. This set can be initialised as empty, or according to
-- geometric `primitives`. Once initialised, a pattern can only be modified by
-- the `insert` method, used to add active cells. All other pattern manipulations
-- return a new, modified pattern rather than modifying patterns in-place.
--
-- Several pattern manipulators are provided here. For example as a `shift` of
-- an entire pattern, manipulators that `enlarge` a pattern by a scale factor
-- or performing reflections in the x or y axes. Particuarly useful are
-- manipulators which generate new patterns as the `edge` (outer hull) or
-- `surface` (inner-hull) of other patterns. These manipulators can be used
-- with different definitions of a cell's `neighbourhood`.
--
-- Pattern coordinates should be reasonably reliable in [-65536, 65536] and
-- probably beyond. But don't push your luck.
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
-- -- Fetch a random cell and the centre-of-mass cell from a pattern
-- local random_cell = p1:rcell()
-- local com_cell = p1:com()
--
-- -- Compute the outer (outside the existing pattern) hull
-- -- Using 8-direction (Moore) neighbourhood
-- local outer_hull = p1:edge(neighbourhood.moore())
-- -- or equivalently
-- outer_hull = pattern.edge(p1, neighbourhood.moore())
--
-- @module forma.pattern
local pattern = {}

local cell          = require('forma.cell')
local neighbourhood = require('forma.neighbourhood')

-- Pattern indexing
-- For enabling syntax sugar pattern:method
pattern.__index = pattern

--- Generate the cellmap key from coordinates
local function coordinates_to_key(x, y)
    return (x - 65536)*65536 + (y - 65536)
end

--- Basic methods.
-- Methods for the creation, copying and adding of cells to a pattern.
--@section basic

--- forma.pattern constructor.
-- Points are stored in the pattern in a standard integer keyed table, and
-- also as elements in a spatial hash map.
-- @param prototype (optional) an N*N 2D table of ones and zeros.
-- Returns a new forma.pattern. If no prototype is used, then an empty pattern
-- is returned. If set with the prototype table {{1,0},{0,1}} will initialise
-- the pattern:
--  10
--  01
-- @return new pattern
function pattern.new(prototype)
    local np = {}

    np.max = cell.new()
    np.min = cell.new()

    np.offchar = '0'
    np.onchar  = '1'

    np.cellset = {}
    np.cellmap = {}

    np = setmetatable(np, pattern)

    if prototype ~= nil then
        assert(type(prototype) == 'table',
        'pattern.new requires either no arguments or a N*N matrix as a prototype')
        local N = #prototype
        for i=1,N,1 do
            local row = prototype[i]
            assert(type(row) == 'table',
            'pattern.new requires either no arguments or a N*N matrix as a prototype')
            assert(#row == N,
            'pattern.new requires a N*N matrix when using a prototype, you requested '..N..'*'.. #row)
            for j=1,N,1 do
                local icell = row[j]
                if icell == 1 then
                    np:insert(i-1,j-1) -- Patterns start from zero
                else
                    assert(icell == 0, 'pattern.new: invalid prototype entry (must be 1 or 0): '.. icell)
                end
            end
        end
    end

    return np
end

--- Copy an existing forma.pattern.
-- @param ip input pattern for cloning
-- @return new forma.pattern copy of ip
function pattern.clone(ip)
    assert(getmetatable(ip) == pattern, "pattern cloning requires a pattern as the first argument")
    local self = pattern.new()

    for i=1, #ip.cellset, 1 do
        local v = ip.cellset[i]
        pattern.insert(self, v.x, v.y)
    end

    -- This is important, keep the stored limits, not the actual ones
    self.max = cell.new(ip.max.x, ip.max.y)
    self.min = cell.new(ip.min.x, ip.min.y)

    self.offchar = ip.offchar
    self.onchar  = ip.onchar

    return self
end

--- Insert a new cell into a pattern.
-- Re-returns the provided cell to enable cascading.
-- e.g `pattern.new():insert(x,y)` returns a pattern with
-- a single cell at (x,y).
-- @param ip pattern for cell insertion
-- @param x first coordinate of new cell
-- @param y second coordinate of new cell
-- @return ip for method cascading
function pattern.insert( ip, x, y )
    assert(getmetatable(ip) == pattern, "pattern.insert requires a pattern as the first argument")
    assert(type(x) == 'number', 'pattern.insert requires a number for the x coordinate')
    assert(type(y) == 'number', 'pattern.insert requires a number for the y coordinate')

    local key = coordinates_to_key(x, y)
    assert(ip.cellmap[key] == nil, "pattern.insert cannot duplicate cells")
    ip.cellmap[key] = cell.new(x,y)
    ip.cellset[#ip.cellset+1] = ip.cellmap[key]

    -- First added cell, set limits
    if ip:size() == 1 then
        ip.min = cell.new(x,y)
        ip.max = cell.new(x,y)
    end

    -- reset pattern extent
    ip.max.x = math.max(ip.max.x, x)
    ip.max.y = math.max(ip.max.y, y)
    ip.min.x = math.min(ip.min.x, x)
    ip.min.y = math.min(ip.min.y, y)

    return ip
end

--- Check if a cell is active in a pattern.
-- @param ip pattern for cell check
-- @param x first coordinate of cell to be returned
-- @param y second coordinate of cell to be returned
-- @return True if pattern `ip` includes the cell at (x,y), False otherwise
function pattern.has_cell(ip, x, y)
    assert(getmetatable(ip) == pattern, "pattern.has_cell requires a pattern as the first argument")
    assert(type(x) == 'number', 'pattern.has_cell requires a number for the x coordinate')
    assert(type(y) == 'number', 'pattern.has_cell requires a number for the y coordinate')

    local key = coordinates_to_key(x, y)
    return ip.cellmap[key] ~= nil
end

--- Return a list of cells active in the pattern.
-- @param ip source pattern for active cell list.
function pattern.cell_list(ip)
    assert(getmetatable(ip) == pattern, "pattern.cell_list requires a pattern as the first argument")
    local newlist = {}
    for i=1, #ip.cellset, 1 do
        newlist[#newlist+1] = ip.cellset[i]:clone()
    end
    return newlist
end

--- Return the number of cells active in a pattern.
-- @param ip pattern for size check
function pattern.size( ip )
    assert(getmetatable(ip) == pattern, "pattern.size requires a pattern as the first argument")
    return #ip.cellset
end

--- Size comparator for two patterns.
-- Useful for table.sort to rank patterns by size (number of cells)
-- @param pa the first pattern for comparison
-- @param pb the second pattern for comparison
-- @return pa:size() > pb:size()
function pattern.size_sort(pa, pb)
    return pa:size() > pb:size()
end

-----------------------
--- Metamethods.
-- @section Metamethods

--- Render pattern as a string.
-- Prints the stored pattern to string, rendered using the character stored in
-- pattern.onchar for activated cells and pattern.offchar for unactivated cells.
-- @param ip the forma.pattern to be rendered as a string
-- @return pattern as string
function pattern.__tostring(ip)
    local string = ''
    for y = ip.min.y, ip.max.y, 1 do
        string = string
        for x = ip.min.x, ip.max.x, 1 do
            string = string .. (ip:has_cell(x,y) and ip.onchar or ip.offchar)
        end
        string = string .. '\n'
    end

    return string
end

--- Add two patterns to each other.
-- @param a first pattern to be added
-- @param b second pattern to be added
-- @return new forma.pattern consisting of the superset of patterns a and b
function pattern.__add(a,b)
    assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")

    local c = pattern.clone(a)
    for i=1, #b.cellset, 1 do
        local v = b.cellset[i]
        if c:has_cell(v.x, v.y) == false then
            pattern.insert(c, v.x, v.y)
        end
    end

    return c
end

--- Subtract one pattern from another.
-- @param a base pattern
-- @param b pattern to be subtracted from a
-- @return new forma.pattern consisting of the subset of cells in a which are not in b
function pattern.__sub(a,b)
    assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")

    local c = pattern.new()
    c.onchar = a.onchar
    c.offchar = a.offchar

    for i=1, #a.cellset, 1 do
        local v = a.cellset[i]
        if b:has_cell(v.x, v.y) == false then
            pattern.insert(c, v.x, v.y)
        end
    end

    return c
end

--- Pattern equality test.
-- @param a first pattern for equality check
-- @param b second pattern for equality check
-- @return true if patterns are identical, false if not
function pattern.__eq(a,b)
    assert(getmetatable(a) == pattern, "pattern equality test requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern equality test requires a pattern as the second argument")
    -- Easy and fast checks
    if a:size() ~= b:size() then return false end
    if a.min.x ~= b.min.x then return false end
    if a.min.y ~= b.min.y then return false end
    if a.max.x ~= b.max.x then return false end
    if a.max.y ~= b.max.y then return false end
    -- Slower checks
    for i=1, #a.cellset, 1 do
        local v = a.cellset[i]
        if b:has_cell(v.x, v.y) == false then return false end
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
-- @param rng (optional )A random number generating table, following the signature of math.random.
-- @return a random cell in the pattern
function pattern.rcell(ip, rng)
    assert(getmetatable(ip) == pattern, "pattern.rcell requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.rcell requires a filled pattern!')

    -- Check RNG
    if rng == nil then rng = math.random end
    local icell = rng(#ip.cellset)
    return cell.clone(ip.cellset[icell])
end

--- Pattern centre of mass cell method.
-- Returns the cell closes to the mass-centre of the pattern.
-- @param ip pattern for centre of mass retrieval
-- @return the centre of mass cell in the pattern
function pattern.com(ip)
    assert(getmetatable(ip) == pattern, "pattern.com requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.com requires a filled pattern!')

    local com = cell.new()
    local allcells = ip.cellset
    for i=1, #allcells, 1 do com = com + allcells[i] end
    local comx, comy = com.x / #allcells, com.y / #allcells

    local function distance_to_com(a,b)
        local adist = (a.x-comx)*(a.x-comx) + (a.y-comy)*(a.y-comy)
        local bdist = (b.x-comx)*(b.x-comx) + (b.y-comy)*(b.y-comy)
        return adist < bdist
    end
    table.sort(allcells, distance_to_com)
    return cell.clone(allcells[1])
end

---------------------------------------------------------------------------
--- Pattern manipulators.
-- These methods generate different 'child' patterns from an input pattern.
-- @section manipulators

--- Generate a copy of a pattern shifted by a vector(x,y)
-- @param ip pattern to be shifted
-- @param x first coordinate of shift
-- @param y second coordinate of shift
-- @return a new forma.pattern consisting of ip shifted by (x,y)
function pattern.shift(ip, x, y)
    assert(getmetatable(ip) == pattern, "pattern.shift requires a pattern as the first argument")
    assert(type(x) == 'number', 'pattern.shift requires a number for the x coordinate')
    assert(type(y) == 'number', 'pattern.shift requires a number for the y coordinate')

    local sp = pattern.new()
    sp.onchar = ip.onchar
    sp.offchar = ip.offchar

    for i=1, #ip.cellset, 1 do
        local v = ip.cellset[i]
        pattern.insert(sp, v.x+x, v.y+y)
    end

    return sp
end

--- Copy a pattern, shifting its origin to (0,0).
-- @param ip pattern to be normalised
-- @return a new normalised forma.pattern
function pattern.normalise(ip)
    assert(getmetatable(ip) == pattern, "pattern.normalise requires a pattern as the first argument")
    return pattern.shift(ip, -ip.min.x, -ip.min.y)
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
    for _, iv in ipairs(ip:cell_list()) do
        local sv = f*iv
        for i=0, f-1, 1 do
            for j=0, f-1, 1 do
                ep:insert(sv.x+i, sv.y+j)
            end
        end
    end
    return ep
end

--- Generate a copy of a pattern, mirroring it vertically.
-- @param ip pattern for reflection
-- @return copy of `ip` which has been is reflected vertically
function pattern.vreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.vreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
    for i=1, #ip.cellset, 1 do
        local new_y = 2*ip.max.y - ip.cellset[i].y + 1
        pattern.insert(np, ip.cellset[i].x, new_y)
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
    for i=1, #ip.cellset, 1 do
        local new_x = 2*ip.max.x - ip.cellset[i].x + 1
        pattern.insert(np, new_x, ip.cellset[i].y)
    end
    return np
end

--- Generate a pattern consisting of edge cells to a provided pattern.
-- Note that this will *not* necessarily generate a hull, it just returns the
-- inactive neighbours of the provided pattern.
-- @param ip pattern for which the edges should be calculated
-- @param nbh defines which neighbourhood to scan in to determine edges (default 8/moore)
-- @return the forma.pattern represeting the edge of ip
function pattern.edge(ip, nbh)
    assert(getmetatable(ip) == pattern, "pattern.edge requires a pattern as the first argument")

    local ep = pattern.new()
    ep.onchar  = ip.onchar
    ep.offchar = ip.offchar

    -- Default is eight
    nbh = nbh or neighbourhood.moore()
    for i=1, #ip.cellset, 1 do
        for j=1, #nbh, 1 do
            local vpr = ip.cellset[i] + nbh[j]
            if ip:has_cell(vpr.x, vpr.y) == false then
                if ep:has_cell(vpr.x, vpr.y) == false then
                    pattern.insert(ep, vpr.x, vpr.y)
                end
            end
        end
    end

    return ep
end

--- Generate a pattern consisting of cells on the surface of a provided pattern.
-- This is simmilar to pattern.edge, but will return cells that are /internal/
-- to the provided pattern.
-- @param ip pattern for which the surface should be calculated
-- @param nbh defines which neighbourhood to scan in to determine edges (default 8/moore)
-- @return the forma.pattern represeting the surface of ip
function pattern.surface(ip, nbh)
    assert(getmetatable(ip) == pattern, "pattern.edge requires a pattern as the first argument")

    local sp = pattern.new()
    sp.onchar  = ip.onchar
    sp.offchar = ip.offchar

    -- Default is eight
    nbh = nbh or neighbourhood.moore()
    for i=1, #ip.cellset, 1 do
        local foundEdge = false
        local v = ip.cellset[i]
        for j=1, #nbh, 1 do
            local vpr = v + nbh[j]
            if ip:has_cell(vpr.x, vpr.y) == false then
                foundEdge = true
                break
            end
        end

        if foundEdge == true then
            pattern.insert(sp, v.x, v.y)
        end
    end

    return sp
end

--- Generate a pattern consisting of the intersection of existing patterns
-- @param ... patterns for intersection calculation
-- @return the forma.pattern representing the intersection of the arguments
function pattern.intersection(...)
    local patterns = {...} table.sort(patterns, function(a,b) return a:size() < b:size() end)
    assert(#patterns > 1, "pattern.intersection requires at least two patterns as arguments")
    local intpat = pattern.clone(patterns[1])
    for i=2, #patterns, 1 do
        local tpattern = patterns[i]
        assert(getmetatable(tpattern) == pattern, "pattern.intersection requires a pattern as an argument")
        local newint = pattern.new()
        for j=1, #intpat.cellset, 1 do
            local v2 = intpat.cellset[j]
            if tpattern:has_cell(v2.x, v2.y) then
                pattern.insert(newint, v2.x, v2.y)
            end
        end
        intpat = newint
    end
    return intpat
end

--- Generate a pattern consisting of the sum of existing patterns
-- @param ... patterns for summation
-- @return the forma.pattern represeting the sum of the arguments
function pattern.sum(...)
    local patterns = {...}
    assert(#patterns > 1, "pattern.sum requires at least two patterns as arguments")
    local sum = pattern.clone(patterns[1])
    for i=2, #patterns, 1 do
        local v = patterns[i]
        assert(getmetatable(v) == pattern, "pattern.sum requires a pattern as an argument")
        for j=1, #v.cellset, 1 do
            local v2 = v.cellset[j]
            if sum:has_cell(v2.x, v2.y) == false then
                pattern.insert(sum, v2.x, v2.y)
            end
        end
    end
    return sum
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
function pattern.packtile(a,b)
    assert(getmetatable(a) == pattern, "pattern.packtile requires a pattern as a first argument")
    assert(getmetatable(b) == pattern, "pattern.packtile requires a pattern as a second argument")
    assert(a:size() > 0 , "pattern.packtile requires a non-empty pattern as a first argument")
    -- cell to fix coordinate systems
    local hinge = pattern.rcell(a)
    -- Loop over possible positions in b
    for i=1, #b.cellset, 1 do
        local coordshift = b.cellset[i] - hinge -- Get coordinate transformation
        local tiles = true
        for j=1, #a.cellset, 1 do
            local shifted = a.cellset[j] + coordshift
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
-- Tries to fit pattern `a` as close as possible to pattern `b`'s centre of mass.
-- @param a the pattern to be packed into pattern `b`.
-- @param b the domain which we are searching for packing solutions
-- @return a cell in `b` where `a` can be placed, nil if no solution found.
function pattern.packtile_centre(a,b)
    -- cell to fix coordinate systems
    local hinge = pattern.com(a)
    local com   = pattern.com(b)
    local allcells = b.cellset
    local function distance_to_com(k,j)
        local adist = (k.x-com.x)*(k.x-com.x) + (k.y-com.y)*(k.y-com.y)
        local bdist = (j.x-com.x)*(j.x-com.x) + (j.y-com.y)*(j.y-com.y)
        return adist < bdist
    end
    table.sort(allcells, distance_to_com)
    for i=1,#allcells,1 do
        local coordshift = allcells[i] - hinge -- Get coordinate transformation
        local tiles = true
        for j=1, #a.cellset, 1 do
            local shifted = a.cellset[j] + coordshift
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

return pattern
