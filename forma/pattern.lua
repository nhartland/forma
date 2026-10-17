--- A class containing a set (or *pattern*) of cells.
---
--- The **pattern** class is the central class of `forma`, representing a set of
--- points or *cells*. It can be initialized empty or using a prototype (an N×M
--- matrix of 1's and 0's). Helper methods for initialization are provided in the
--- `primitives` module. Once created, a pattern is modified only via the `insert`
--- method—other manipulations return new patterns.
---
--- Pattern manipulators include methods like `translate`, `enlarge`, `rotate`,
--- `hreflect`, and `vreflect`. Other operations, such as computing the `exterior_hull`
--- or `interior_hull`, help determine the boundaries of a pattern.
--- Coordinates are maintained reliably in the range [-65536, 65536], which can be
--- adjusted via the `MAX_COORDINATE` constant.
---
--- Functions can be invoked either as functions:
---
---     pattern.method(input_pattern, ... )
---
--- or as methods:
---
---     input_pattern:method(... )
---
--- ```lua
--- -- Procedural style:
--- local p1 = pattern.new()
--- pattern.insert(p1, 1, 1)
---
--- -- Method chaining:
--- local p2 = pattern.new():insert(1, 1)
---
--- -- Prototype style:
--- local p3 = pattern.new({{1,1,1}, {1,0,1}, {1,1,1}})
---
--- -- Retrieve a random cell and the medoid cell:
--- local random_cell = p1:rcell()
--- local medoid_cell = p1:medoid()
---
--- -- Compute the exterior hull using the Moore neighbourhood:
--- local outer_hull = p1:exterior_hull(neighbourhood.moore())
--- -- or equivalently:
--- outer_hull = pattern.exterior_hull(p1, neighbourhood.moore())
--- ```
---@class forma.pattern
---@field max forma.cell maximum bounding box corner
---@field min forma.cell minimum bounding box corner
---@field offchar string character for inactive cells in tostring
---@field onchar string character for active cells in tostring
---@field cellkey table list of coordinate keys
---@field cellmap table spatial hash of coordinate key to index
local pattern = {}

local min   = math.min
local max   = math.max
local floor = math.floor

local cell          = require('forma.cell')
local neighbourhood = require('forma.neighbourhood')
local rutils        = require('forma.utils.random')
local multipattern  = require('forma.multipattern')
local symmetry      = require('forma.symmetry')

-- Pattern indexing.
-- Enables the syntax sugar pattern:method.
pattern.__index = pattern

-- Pattern coordinates (either x or y) must be within ± MAX_COORDINATE.
local MAX_COORDINATE  = 65536
local COORDINATE_SPAN = 2 * MAX_COORDINATE + 1

--- Generates the cellmap key from coordinates.
---@param x number the x-coordinate
---@param y number the y-coordinate
---@return number key a unique key representing the cell
local function coordinates_to_key(x, y)
    return (x + MAX_COORDINATE) * COORDINATE_SPAN + (y + MAX_COORDINATE)
end

--- Generates the coordinates from the key.
---@param key number the spatial hash key
---@return number x the x-coordinate
---@return number y the y-coordinate
local function key_to_coordinates(key)
    local yp = (key % COORDINATE_SPAN)
    local xp = (key - yp) / COORDINATE_SPAN
    return xp - MAX_COORDINATE, yp - MAX_COORDINATE
end

-- @section Basic

--- Pattern constructor.
--- Returns a new pattern. If a prototype is provided (an N×M table of 1's and 0's),
--- the corresponding active cells are inserted.
---
--- ```lua
--- local p = pattern.new()
--- local p2 = pattern.new({{1,1,1}, {1,0,1}, {1,1,1}})
--- ```
---@param prototype? table an N×M table of ones and zeros
---@return forma.pattern pattern a new pattern according to the prototype
function pattern.new(prototype)
    local np = {}

    np.max = cell.new(-math.huge, -math.huge)
    np.min = cell.new(math.huge, math.huge)

    -- Characters to be used with tostring metamethod.
    np.offchar = ' '
    np.onchar  = 'x'

    np.cellkey = {} -- Table consisting of a list of coordinate keys.
    np.cellmap = {} -- Spatial hash of coordinate key to its index in cellkey.

    np = setmetatable(np, pattern)

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
---
---@param ip forma.pattern input pattern to clone
---@return forma.pattern pattern a new pattern that is a duplicate of ip
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
--- Returns the modified pattern to allow for method chaining.
---
--- ```lua
--- local p = pattern.new():insert(1, 1):insert(2, 2)
--- ```
---@param ip forma.pattern pattern to modify
---@param x integer x-coordinate of the new cell
---@param y integer y-coordinate of the new cell
---@param strict? boolean fail on duplicate cell (default: true)
---@return forma.pattern ip the updated pattern
function pattern.insert(ip, x, y, strict)
    local _x, _y = floor(x), floor(y)
    assert(x == _x, 'pattern.insert requires an integer for the x coordinate')
    assert(y == _y, 'pattern.insert requires an integer for the y coordinate')

    local key = coordinates_to_key(_x, _y)
    if ip.cellmap[key] == nil then
        local new_index = #ip.cellkey + 1
        ip.cellkey[new_index] = key
        ip.cellmap[key] = new_index

        -- Reset pattern extent.
        ip.max.x = max(ip.max.x, _x)
        ip.max.y = max(ip.max.y, _y)
        ip.min.x = min(ip.min.x, _x)
        ip.min.y = min(ip.min.y, _y)

        return ip
    else
        if strict ~= false then
            error('pattern.insert cannot duplicate cells', 2)
        else
            return ip
        end
    end
end

--- Recalculates the bounding box of the pattern from its cells.
local function recalculate_bounding_box(ip)
    ip.max.x, ip.max.y = -math.huge, -math.huge
    ip.min.x, ip.min.y = math.huge, math.huge
    for x, y in ip:cell_coordinates() do
        ip.max.x = max(ip.max.x, x)
        ip.max.y = max(ip.max.y, y)
        ip.min.x = min(ip.min.x, x)
        ip.min.y = min(ip.min.y, y)
    end
end

--- Removes a cell from the pattern.
--- Returns the modified pattern to allow for method chaining.
---
--- ```lua
--- p:remove(1, 1)
--- ```
---@param ip forma.pattern pattern to modify
---@param x integer x-coordinate of the cell to remove
---@param y integer y-coordinate of the cell to remove
---@return forma.pattern ip the updated pattern (for cascading calls)
function pattern.remove(ip, x, y)
    local key_to_remove = coordinates_to_key(x, y)
    local index_to_remove = ip.cellmap[key_to_remove]

    if index_to_remove then
        local last_index = #ip.cellkey
        local last_key = ip.cellkey[last_index]

        -- Swap with last element
        ip.cellkey[index_to_remove] = last_key
        ip.cellmap[last_key] = index_to_remove

        -- Pop last element
        ip.cellkey[last_index] = nil
        ip.cellmap[key_to_remove] = nil

        -- Recompute bounding box if removed cell was on the boundary
        if x == ip.min.x or x == ip.max.x or y == ip.min.y or y == ip.max.y then
            recalculate_bounding_box(ip)
        end
    end

    return ip
end

--- Checks if a cell at (x, y) is active in the pattern.
---
---@param ip forma.pattern pattern to check
---@param x integer x-coordinate
---@param y integer y-coordinate
---@return boolean active true if the cell is active, false otherwise
function pattern.has_cell(ip, x, y)
    local key = coordinates_to_key(x, y)
    return ip.cellmap[key] ~= nil
end

--- Filters the pattern using a boolean callback, returning a subpattern.
---
---@param ip forma.pattern the original pattern
---@param fn fun(cell: forma.cell): boolean function that determines if a cell is kept
---@return forma.pattern pattern a new pattern containing only the cells that pass the filter
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
---
---@param ip forma.pattern pattern to measure
---@return integer count count of active cells
function pattern.size(ip)
    assert(getmetatable(ip) == pattern, "pattern.size requires a pattern as the first argument")
    return #ip.cellkey
end

--- Computes a string hash of the pattern.
--- Optionally normalises the pattern (setting it's origin to 0) before hashing
---
---@param ip forma.pattern pattern to hash
---@param opts? {normal?: boolean} options table
---@return string hash the resulting canonical hash
function pattern.hash(ip, opts)
    if ip:size() == 0 then return '' end
    opts = opts or { normal = false }
    -- If the normal flag is set to true, shift all coordinates such that the origin is at 0,0
    local offset = opts.normal and (
        coordinates_to_key(ip.min.x, ip.min.y) - coordinates_to_key(0, 0)
    ) or 0
    local keys = {}
    for i = 1, #ip.cellkey do keys[i] = ip.cellkey[i] - offset end
    table.sort(keys)
    return table.concat(keys, '.')
end

-- @section Utilities

--- Comparator function to sort patterns by their size (descending).
---
---@param pa forma.pattern first pattern
---@param pb forma.pattern second pattern
---@return boolean result true if pa's size is greater than pb's
function pattern.size_sort(pa, pb)
    return pa:size() > pb:size()
end

--- Comparator function to sort patterns by their size (ascending).
---
---@param pa forma.pattern first pattern
---@param pb forma.pattern second pattern
---@return boolean result true if pa's size is less than pb's
function pattern.inverse_size_sort(pa, pb)
    return pa:size() < pb:size()
end

--- Computes how densely the bounding box is filled.
--- Returns zero for an empty pattern.
---
---@param ip forma.pattern input pattern
---@return number density the fraction of the bounding box that is occupied
function pattern.bounding_box_density(ip)
    assert(getmetatable(ip) == pattern,
        "bounding_box_density: first argument must be a forma.pattern")
    if ip:size() == 0 then return 0 end
    local bb_area = (ip.max.x - ip.min.x + 1) * (ip.max.y - ip.min.y + 1)
    return ip:size() / bb_area
end

--- Computes the asymmetry of the pattern's bounding box.
--- Returns zero in the case of an empty pattern.
---
---@param ip forma.pattern input pattern
---@return number asymmetry the ratio of the bounding box's longest to shortest edge
function pattern.bounding_box_asymmetry(ip)
    assert(getmetatable(ip) == pattern,
        "bounding_box_asymmetry: first argument must be a forma.pattern")
    if ip:size() == 0 then return 0 end
    return (
        (max((ip.max.x - ip.min.x), (ip.max.y - ip.min.y)) + 1)
        / (min((ip.max.x - ip.min.x), (ip.max.y - ip.min.y)) + 1)
    )
end

--- Counts active neighbors around a specified cell within the pattern.
--- Can be invoked with either a cell object or with x and y coordinates.
---
---@param p forma.pattern a pattern
---@param nbh forma.neighbourhood a neighbourhood (e.g., neighbourhood.moore())
---@param arg1 forma.cell|integer either a cell or the x-coordinate
---@param arg2? integer the y-coordinate if arg1 is not a cell
---@return integer count count of active neighbouring cells
function pattern.count_neighbors(p, nbh, arg1, arg2)
    assert(getmetatable(p) == pattern,
        "count_neighbors: first argument must be a forma.pattern")
    assert(getmetatable(nbh) == neighbourhood,
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
---
---@param ip forma.pattern pattern to list cells from
---@return forma.cell[] cells table of cell objects
function pattern.cell_list(ip)
    assert(getmetatable(ip) == pattern, "pattern.cell_list requires a pattern as the first argument")
    local newlist = {}
    for icell in ip:cells() do
        newlist[#newlist + 1] = icell
    end
    return newlist
end

--- Computes the edit distance between two patterns (the total number of differing cells).
---
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return integer distance the edit distance
function pattern.edit_distance(a, b)
    assert(getmetatable(a) == pattern, "pattern.edit_distance requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.edit_distance requires a pattern as the second argument")
    local common = pattern.intersect(a, b)
    local edit_distance = (a - common):size() + (b - common):size()
    return edit_distance
end

-- @section Set operations

--- Returns the union of a set of patterns.
---
--- ```lua
--- local combined = pattern.union(p1, p2, p3)
--- ```
---@param ... forma.pattern a table of patterns or a list of pattern arguments
---@return forma.pattern pattern a new pattern that is the union of the provided patterns
function pattern.union(...)
    local patterns = { ... }
    -- Handle case where the input is a table of patterns
    if #patterns == 1 and type(patterns[1]) == 'table' and getmetatable(patterns[1]) == nil then
        patterns = patterns[1]
    end

    if #patterns == 0 then return pattern.new() end
    if #patterns == 1 then return patterns[1]:clone() end

    local total = pattern.clone(patterns[1])
    for i = 2, #patterns, 1 do
        local v = patterns[i]
        assert(getmetatable(v) == pattern, "pattern.union requires a pattern as an argument")
        for x, y in v:cell_coordinates() do
            total:insert(x, y, false)
        end
    end
    return total
end

--- Returns the intersection of multiple patterns (cells common to all).
---
--- ```lua
--- local common = pattern.intersect(p1, p2)
--- ```
---@param ... forma.pattern two or more patterns to intersect
---@return forma.pattern pattern a new pattern of cells that exist in every input pattern
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
--- Cells are included if they exist in either pattern but not in both.
---
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return forma.pattern pattern a new pattern representing the symmetric difference
function pattern.xor(a, b)
    assert(getmetatable(a) == pattern, "pattern.xor requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.xor requires a pattern as the second argument")
    return (a + b) - (a * b)
end

-- @section Iterators

--- Iterator over active cells in the pattern.
---
--- ```lua
--- for cell in p:cells() do
---     print(cell.x, cell.y)
--- end
--- ```
---@param ip forma.pattern pattern to iterate over
---@return fun(): forma.cell? iterator that returns each active cell as a cell object
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
---
--- ```lua
--- for x, y in p:cell_coordinates() do
---     print(x, y)
--- end
--- ```
---@param ip forma.pattern pattern to iterate over
---@return fun(): integer?, integer? iterator that returns the x and y coordinates of each active cell
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
---
--- ```lua
--- for cell in pattern.shuffled_cells(p) do
---     print(cell.x, cell.y)
--- end
--- ```
---@param ip forma.pattern pattern to iterate over
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return fun(): forma.cell? iterator that yields each active cell in a random order
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
---
--- ```lua
--- for x, y in pattern.shuffled_coordinates(p) do
---     print(x, y)
--- end
--- ```
---@param ip forma.pattern pattern to iterate over
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return fun(): integer?, integer? iterator that yields x and y coordinates in random order
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

-- @section Metamethods

--- Renders the pattern as a string.
--- Active cells are shown with pattern.onchar and inactive cells with pattern.offchar.
---
--- ```lua
--- print(p)
--- ```
---@param ip forma.pattern pattern to render
---@return string str string representation of the pattern
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
---
--- ```lua
--- local combined = p1 + p2
--- ```
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return forma.pattern pattern a new pattern representing the union of a and b
function pattern.__add(a, b)
    assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")
    return pattern.union(a, b)
end

--- Subtracts one pattern from another using the '-' operator.
--- Returns a new pattern with cells in a that are not in b.
---
--- ```lua
--- local diff = p1 - p2
--- ```
---@param a forma.pattern base pattern
---@param b forma.pattern pattern to subtract from a
---@return forma.pattern pattern a new pattern with the difference
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
---
--- ```lua
--- local common = p1 * p2
--- ```
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return forma.pattern pattern a new pattern containing only the cells common to both
function pattern.__mul(a, b)
    assert(getmetatable(a) == pattern, "pattern multiplication requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern multiplication requires a pattern as the second argument")
    return pattern.intersect(a, b)
end

--- Computes the symmetric difference (XOR) of two patterns using the '^' operator.
---
--- ```lua
--- local xor_pattern = p1 ^ p2
--- ```
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return forma.pattern pattern a new pattern with cells present in either a or b, but not both
function pattern.__pow(a, b)
    assert(getmetatable(a) == pattern, "pattern exponent (XOR) requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern exponent (XOR) requires a pattern as the second argument")
    return pattern.xor(a, b)
end

--- Tests whether two patterns are identical.
---
--- ```lua
--- if p1 == p2 then
---     -- patterns are identical
--- end
--- ```
---@param a forma.pattern first pattern
---@param b forma.pattern second pattern
---@return boolean equal true if the patterns are equal, false otherwise
function pattern.__eq(a, b)
    assert(getmetatable(a) == pattern, "pattern equality test requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern equality test requires a pattern as the second argument")
    if a:size() ~= b:size() then return false end
    if a.min ~= b.min then return false end
    if a.max ~= b.max then return false end
    for i = 1, #a.cellkey do
        if b.cellmap[a.cellkey[i]] == nil then
            return false
        end
    end
    return true
end

-- @section Cell accessors

--- Computes the centroid (arithmetic mean) of all cells in the pattern.
--- The result is rounded to the nearest integer coordinate.
---
--- ```lua
--- local center = p:centroid()
--- ```
---@param ip forma.pattern pattern to process
---@return forma.cell centroid a cell representing the centroid (which may not be active)
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
--- The medoid minimizes the total distance to all other cells (using Euclidean distance by default).
---
--- ```lua
--- local medoid = p:medoid()
--- ```
---@param ip forma.pattern pattern to process
---@param measure? fun(a: forma.cell, b: forma.cell): number distance function (default: Euclidean)
---@return forma.cell medoid the medoid cell of the pattern
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
---
--- ```lua
--- local random_cell = p:rcell()
--- ```
---@param ip forma.pattern pattern to sample from
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.cell cell a random cell from the pattern
function pattern.rcell(ip, rng)
    assert(getmetatable(ip) == pattern, "pattern.rcell requires a pattern as the first argument")
    assert(ip:size() > 0, 'pattern.rcell requires a filled pattern!')
    if rng == nil then rng = math.random end
    local icell = rng(#ip.cellkey)
    local ikey = ip.cellkey[icell]
    local x, y = key_to_coordinates(ikey)
    return cell.new(x, y)
end

-- @section Transformations

--- Returns a new pattern translated by a vector (sx, sy).
---
--- ```lua
--- local p_translated = p:translate(2, 3)
--- ```
---@param ip forma.pattern pattern to translate
---@param sx integer translation along the x-axis
---@param sy integer translation along the y-axis
---@return forma.pattern pattern a new pattern shifted by (sx, sy)
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

--- Returns a new pattern transformed by an operation.
---
--- ```lua
--- local p_transformed = p:transform(forma.symmetry.operation.rot90)
--- ```
---@param ip forma.pattern pattern to transform
---@param g forma.transform the transformation to apply
---@return forma.pattern pattern a new pattern transformed by 'g'
function pattern.transform(ip, g)
    assert(getmetatable(ip) == pattern, "pattern.transform requires a pattern as the first argument")
    local sp = pattern.new()
    for tx, ty in ip:cell_coordinates() do
        sp:insert(g(tx, ty))
    end
    return sp
end

--- Normalises the pattern by translating it such that its minimum coordinate is (0,0).
---
--- ```lua
--- local p_norm = p:normalise()
--- ```
---@param ip forma.pattern pattern to normalize
---@return forma.pattern pattern a new normalized pattern
function pattern.normalise(ip)
    assert(getmetatable(ip) == pattern, "pattern.normalise requires a pattern as the first argument")
    return ip:translate(-ip.min.x, -ip.min.y)
end

--- Returns an enlarged version of the pattern.
--- Each active cell is replaced by an f×f block.
---
--- ```lua
--- local p_big = p:enlarge(2)
--- ```
---@param ip forma.pattern pattern to enlarge
---@param f number enlargement factor
---@return forma.pattern pattern a new enlarged pattern
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
---
--- ```lua
--- local p_rotated = p:rotate()
--- ```
---@param ip forma.pattern pattern to rotate
---@return forma.pattern pattern a rotated pattern
function pattern.rotate(ip)
    assert(getmetatable(ip) == pattern, "pattern.rotate requires a pattern as the first argument")
    return ip:transform(symmetry.elements.rot90)
end

--- Returns a new pattern that is a vertical reflection of the original.
---
--- ```lua
--- local p_vreflected = p:vreflect()
--- ```
---@param ip forma.pattern pattern to reflect vertically
---@return forma.pattern pattern a vertically reflected pattern
function pattern.vreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.vreflect requires a pattern as the first argument")
    local np = pattern.new()
    for vx, vy in ip:cell_coordinates() do
        local new_y = ip.min.y + ip.max.y - vy
        np:insert(vx, new_y)
    end
    return np
end

--- Returns a new pattern that is a horizontal reflection of the original.
---
--- ```lua
--- local p_hreflected = p:hreflect()
--- ```
---@param ip forma.pattern pattern to reflect horizontally
---@return forma.pattern pattern a horizontally reflected pattern
function pattern.hreflect(ip)
    assert(getmetatable(ip) == pattern, "pattern.hreflect requires a pattern as the first argument")
    local np = pattern.new()
    for vx, vy in ip:cell_coordinates() do
        local new_x = ip.min.x + ip.max.x - vx
        np:insert(new_x, vy)
    end
    return np
end

-- @section Sampling

--- Returns a random subpattern containing a fixed number of cells.
---
--- ```lua
--- local sample = p:sample(10)
--- ```
---@param ip forma.pattern pattern (domain) to sample from
---@param ncells integer number of cells to sample
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.pattern pattern a new pattern with ncells randomly selected cells
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
        assert(x and y)
        p:insert(x, y)
    end
    return p
end

--- Returns a Poisson-disc sampled subpattern.
--- Ensures that no two sampled cells are closer than the given radius.
---
--- ```lua
--- local poisson_sample = p:sample_poisson(cell.euclidean, 5)
--- ```
---@param ip forma.pattern pattern (domain) to sample from
---@param distance fun(a: forma.cell, b: forma.cell): number distance function (e.g., cell.euclidean)
---@param radius number minimum separation
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.pattern pattern a new pattern sampled with Poisson-disc criteria
function pattern.sample_poisson(ip, distance, radius, rng)
    assert(getmetatable(ip) == pattern, "pattern.sample_poisson requires a pattern as the first argument")
    assert(type(distance) == 'function', "pattern.sample_poisson requires a distance measure as an argument")
    assert(type(radius) == "number", "pattern.sample_poisson requires a number as the target radius")
    if rng == nil then rng = math.random end
    local sample = pattern.new()
    local domain = ip:clone()
    while domain:size() > 0 do
        local dart = domain:rcell(rng)
        sample:insert(dart.x, dart.y)
        local to_remove = {}
        for cell_to_check in domain:cells() do
            if distance(cell_to_check, dart) < radius then
                table.insert(to_remove, cell_to_check)
            end
        end
        for _, cell_to_remove in ipairs(to_remove) do
            domain:remove(cell_to_remove.x, cell_to_remove.y)
        end
    end
    return sample
end

--- Returns an approximate Poisson-disc sample using Mitchell's best candidate algorithm.
---
--- ```lua
--- local mitchell_sample = p:sample_mitchell(cell.euclidean, 10, 5)
--- ```
---@param ip forma.pattern the input pattern to sample from
---@param distance fun(a: forma.cell, b: forma.cell): number distance function (e.g., cell.euclidean)
---@param n integer number of samples
---@param k integer number of candidate attempts per iteration
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.pattern pattern a new pattern with n samples chosen via the algorithm
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
        local min_sample = nil
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
                min_sample = jcell
                min_distance = jdistance
            end
        end
        if min_sample then
            sample:insert(min_sample.x, min_sample.y)
        end
    end
    return sample
end

--- Returns the contiguous subpattern (connected component) starting from a given location.
local function floodfill(x, y, nbh, domain, retpat)
    local q = { x, y }
    local head = 1
    local tail = 2
    retpat:insert(x, y)

    while head < tail do
        local cx, cy = q[head], q[head + 1]
        head = head + 2

        for i = 1, #nbh do
            local nx = nbh[i].x + cx
            local ny = nbh[i].y + cy
            if domain:has_cell(nx, ny) and not retpat:has_cell(nx, ny) then
                retpat:insert(nx, ny)
                q[tail + 1] = nx
                q[tail + 2] = ny
                tail = tail + 2
            end
        end
    end
end

-- @section Subpattern finding

--- Returns the contiguous subpattern (connected component) starting from a given cell.
---
--- ```lua
--- local component = p:floodfill(cell.new(2, 3))
--- ```
---@param ip forma.pattern pattern upon which the flood fill is to be performed
---@param icell forma.cell a cell specifying the origin of the flood fill
---@param nbh? forma.neighbourhood neighbourhood to use (default: neighbourhood.moore())
---@return forma.pattern pattern a new pattern containing the connected component
function pattern.floodfill(ip, icell, nbh)
    assert(getmetatable(ip) == pattern, "pattern.floodfill requires a pattern as the first argument")
    assert(icell, "pattern.floodfill requires a cell as the second argument")
    if nbh == nil then nbh = neighbourhood.moore() end
    local retpat = pattern.new()
    if ip:has_cell(icell.x, icell.y) then
        floodfill(icell.x, icell.y, nbh, ip, retpat)
    end
    return retpat
end

--- Finds the largest contiguous rectangular subpattern within the pattern.
---
--- ```lua
--- local rect = p:max_rectangle()
--- ```
---@param ip forma.pattern pattern to analyze
---@param alpha? number 'squareness' parameter. 0 for max rectangle, 1 for max square
---@return forma.pattern pattern a subpattern representing the maximal rectangle
function pattern.max_rectangle(ip, alpha)
    assert(getmetatable(ip) == pattern, "pattern.max_rectangle requires a pattern as an argument")
    local primitives = require('forma.primitives')
    local bsp = require('forma.utils.bsp')
    local min_rect, max_rect = bsp.max_rectangle_coordinates(ip, alpha)
    local size = max_rect - min_rect + cell.new(1, 1)
    return primitives.square(size.x, size.y):translate(min_rect.x, min_rect.y)
end

--- Computes the convex hull of the pattern.
--- The hull points are connected using line rasterization.
---
--- ```lua
--- local hull = p:convex_hull()
--- ```
---@param ip forma.pattern pattern to process
---@return forma.pattern pattern a new pattern representing the convex hull
function pattern.convex_hull(ip)
    assert(getmetatable(ip) == pattern, "pattern.convex_hull requires a pattern as the first argument")
    assert(ip:size() > 0, "pattern.convex_hull: input pattern must have at least one cell")
    local convex_hull = require('forma.utils.convex_hull')
    local primitives = require('forma.primitives')
    local hull_points = convex_hull.points(ip)
    local chull = pattern.new()
    local function add_line(p1, p2)
        local line = primitives.line(p1, p2)
        for x, y in line:cell_coordinates() do
            chull:insert(x, y, false)
        end
    end
    for i = 1, #hull_points - 1, 1 do
        add_line(hull_points[i], hull_points[i + 1])
    end
    add_line(hull_points[#hull_points], hull_points[1])
    return chull
end

--- Returns a thinned (skeletonized) version of the pattern.
--- Iteratively removes border cells whose Moore neighbours remain a single
--- connected component under `nbh`.
---
--- ```lua
--- local thin_p = p:thin()
--- local thin_4 = p:thin(neighbourhood.von_neumann())
--- ```
---@param ip forma.pattern pattern to thin
---@param nbh? forma.neighbourhood neighbourhood for connectivity (default: neighbourhood.moore())
---@return forma.pattern pattern a new, thinned pattern
function pattern.thin(ip, nbh)
    assert(getmetatable(ip) == pattern,
        "pattern.thin requires a pattern as the first argument")
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(nbh) == neighbourhood,
        "pattern.thin requires a neighbourhood as the second argument")

    -- Moore neighbourhood used for border detection and local pruning
    local moore = neighbourhood.moore()
    -- Each iteration does one sub-pass per cardinal direction, only removing
    -- cells exposed on that side.
    local von_neumann = neighbourhood.von_neumann()

    local p = ip:clone()
    local function can_delete(x, y, border_cell)
        -- Cell must be exposed on the border side
        if p:has_cell(x + border_cell.x, y + border_cell.y) then return false end
        -- Don't delete endpoints
        if pattern.count_neighbors(p, nbh, x, y) < 2 then return false end
        -- All Moore neighbours must form a single nbh-connected component
        local nbrs = pattern.new()
        local seed = nil
        for i = 1, #moore do
            if p:has_cell(x + moore[i].x, y + moore[i].y) then
                nbrs:insert(moore[i].x, moore[i].y)
                seed = seed or cell.new(moore[i].x, moore[i].y)
            end
        end
        -- If there are no Moore neighbours, we cannot safely delete this cell
        if not seed then
            return false
        end
        return pattern.floodfill(nbrs, seed, nbh):size() == nbrs:size()
    end
    local changed = true
    while changed do
        changed = false
        for _, border_cell in ipairs(von_neumann) do
            local to_remove = {}
            for x, y in p:cell_coordinates() do
                if can_delete(x, y, border_cell) then
                    to_remove[#to_remove + 1] = { x, y }
                end
            end
            for _, xy in ipairs(to_remove) do
                p:remove(xy[1], xy[2])
                changed = true
            end
        end
    end

    return p
end

-- @section Morphological operations

--- Returns the erosion of the pattern.
--- A cell is retained only if all of its neighbours (as defined by nbh) are active.
---
--- ```lua
--- local eroded = p:erode(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to erode
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new, eroded pattern
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
--- Each active cell contributes its neighbours (as defined by nbh) to the result.
---
--- ```lua
--- local dilated = p:dilate(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to dilate
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new, dilated pattern
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
            np:insert(nx, ny, false)
        end
    end
    return np
end

--- Returns the morphological gradient of the pattern.
--- Computes the difference between the dilation and erosion.
---
--- ```lua
--- local grad = p:gradient(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to process
---@param nbh? forma.neighbourhood neighbourhood for dilation/erosion (default: neighbourhood.moore())
---@return forma.pattern pattern a new pattern representing the gradient
function pattern.gradient(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.gradient requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.gradient requires a neighbourhood as the second argument")
    return pattern.dilate(ip, nbh) - pattern.erode(ip, nbh)
end

--- Returns the morphological opening of the pattern.
--- Performs erosion followed by dilation to remove small artifacts.
---
--- ```lua
--- local opened = p:opening(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to process
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new, opened pattern
function pattern.opening(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.opening requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.opening requires a neighbourhood as the second argument")
    local eroded = pattern.erode(ip, nbh)
    return pattern.dilate(eroded, nbh)
end

--- Returns the morphological closing of the pattern.
--- Performs dilation followed by erosion to fill small holes.
---
--- ```lua
--- local closed = p:closing(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to process
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new, closed pattern
function pattern.closing(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.closing requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.closing requires a neighbourhood as the second argument")
    local dilated = pattern.dilate(ip, nbh)
    return pattern.erode(dilated, nbh)
end

--- Returns a pattern of cells that form the interior hull.
--- These are cells that neighbor inactive cells while still belonging to the pattern.
---
--- ```lua
--- local interior = p:interior_hull(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to process
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new pattern representing the interior hull
function pattern.interior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.interior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.interior_hull requires a neighbourhood as an argument")
    return (ip - pattern.erode(ip, nbh))
end

--- Returns a pattern of cells that form the exterior hull.
--- This consists of inactive neighbours of the pattern, useful for enlarging or
--- determining non-overlapping borders.
---
--- ```lua
--- local exterior = p:exterior_hull(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to process
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.pattern pattern a new pattern representing the exterior hull
function pattern.exterior_hull(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.exterior_hull requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "pattern.exterior_hull requires a neighbourhood as an argument")
    return (pattern.dilate(ip, nbh) - ip)
end

-- Check if pattern a fits entirely within domain b when shifted by coordshift
local function can_pack_at(a, b, coordshift)
    for acell in a:cells() do
        local shifted = acell + coordshift
        if not b:has_cell(shifted.x, shifted.y) then
            return false
        end
    end
    return true
end

-- @section Packing

--- Finds a packing offset where pattern a fits entirely within domain b.
--- Returns a coordinate shift that, when applied to a, makes it tile inside b.
---
--- ```lua
--- local offset = pattern.find_packing_position(p, domain)
--- ```
---@param a forma.pattern pattern to pack
---@param b forma.pattern domain pattern in which to pack a
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.cell? shift a cell (as a coordinate shift) if a valid position is found; nil otherwise
function pattern.find_packing_position(a, b, rng)
    assert(getmetatable(a) == pattern, "pattern.find_packing_position requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.find_packing_position requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.find_packing_position requires a non-empty pattern as the first argument")
    local hinge = a:rcell(rng)
    for bcell in b:shuffled_cells(rng) do
        local coordshift = bcell - hinge
        if can_pack_at(a, b, coordshift) then
            return coordshift
        end
    end
    return nil
end

--- Finds a center-weighted packing offset to place pattern a within pattern
--- b as close as possible to the cell c. If no `c` is provided, then the centroid
--- of pattern b is used.
---
--- ```lua
--- local central_offset = pattern.find_central_packing_position(p, domain, c)
--- ```
---@param a forma.pattern pattern to pack
---@param b forma.pattern domain pattern
---@param c? forma.cell cell to act as a center for packing
---@return forma.cell? shift a coordinate shift if a valid position is found; nil otherwise
function pattern.find_central_packing_position(a, b, c)
    assert(getmetatable(a) == pattern, "pattern.find_central_packing_position requires a pattern as the first argument")
    assert(getmetatable(b) == pattern, "pattern.find_central_packing_position requires a pattern as a second argument")
    assert(a:size() > 0, "pattern.find_central_packing_position requires a non-empty pattern as the first argument")
    if b:size() == 0 or a:size() > b:size() then return nil end
    if c == nil then c = b:centroid() end
    local hinge    = a:medoid()
    local allcells = b:cell_list()
    local function distance_to_c(k, j)
        local adist = (k.x - c.x) * (k.x - c.x) + (k.y - c.y) * (k.y - c.y)
        local bdist = (j.x - c.x) * (j.x - c.x) + (j.y - c.y) * (j.y - c.y)
        return adist < bdist
    end
    table.sort(allcells, distance_to_c)
    for i = 1, #allcells do
        local coordshift = allcells[i] - hinge
        if can_pack_at(a, b, coordshift) then
            return coordshift
        end
    end
    return nil
end

-- @section Decomposition

--- Returns a multipattern of the connected components within the pattern.
--- Uses flood-fill to extract contiguous subpatterns.
---
--- ```lua
--- local components = p:connected_components(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern to analyze
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.moore())
---@return forma.multipattern multipattern containing each connected component as a subpattern
function pattern.connected_components(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "pattern.connected_components requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood,
        "pattern.connected_components requires a neighbourhood as the second argument")
    local wp = pattern.clone(ip)
    local mp = multipattern.new()
    while pattern.size(wp) > 0 do
        local seed_cell = assert(wp:cells()())
        local segment = pattern.floodfill(wp, seed_cell, nbh)
        mp:insert(segment)
        for x, y in segment:cell_coordinates() do
            wp:remove(x, y)
        end
    end
    return mp
end

--- Returns a multipattern of the interior holes of the pattern.
--- Interior holes are inactive regions completely surrounded by active cells.
---
--- ```lua
--- local holes = p:interior_holes(neighbourhood.von_neumann())
--- ```
---@param ip forma.pattern pattern to analyze
---@param nbh? forma.neighbourhood neighbourhood (default: neighbourhood.von_neumann())
---@return forma.multipattern multipattern of interior hole subpatterns
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
--- Recursively subdivides contiguous rectangular areas until each partition's volume is below th_volume.
---
--- ```lua
--- local partitions = p:bsp(50)
--- ```
---@param ip forma.pattern pattern to partition
---@param th_volume number threshold volume for final partitions
---@param alpha? number parameter for squareness of BSP
---@return forma.multipattern multipattern of BSP subpatterns
function pattern.bsp(ip, th_volume, alpha)
    assert(getmetatable(ip) == pattern, "pattern.bsp requires a pattern as an argument")
    assert(th_volume, "pattern.bsp rules must specify a threshold volume for partitioning")
    assert(th_volume > 0, "pattern.bsp rules must specify positive threshold volume for partitioning")
    local available = ip:clone()
    local mp = multipattern.new()
    local bsp = require('forma.utils.bsp')
    while pattern.size(available) > 0 do
        local min_rect, max_rect = bsp.max_rectangle_coordinates(available, alpha)
        if max_rect.x < min_rect.x then break end
        bsp.split(min_rect, max_rect, th_volume, mp)
        available = available - mp:union_all()
    end
    return mp
end

--- Categorizes cells in the pattern based on neighbourhood configurations.
--- Returns a multipattern with one subpattern per neighbourhood category.
---
--- ```lua
--- local categories = p:neighbourhood_categories(neighbourhood.moore())
--- ```
---@param ip forma.pattern pattern whose cells are to be categorized
---@param nbh forma.neighbourhood neighbourhood used for categorization
---@return forma.multipattern multipattern with each category represented as a subpattern
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
--- Generates a multipattern by thresholding Perlin noise values at multiple levels.
---
--- ```lua
--- local noise_samples = p:perlin(0.1, 4, {0.3, 0.5, 0.7})
--- ```
---@param ip forma.pattern pattern (domain) to sample from
---@param freq number frequency for Perlin noise
---@param depth integer sampling depth
---@param thresholds number[] table of threshold values (each between 0 and 1)
---@param rng? fun(m: integer): integer random number generator (e.g., math.random)
---@return forma.multipattern multipattern with one component per threshold level
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
---
--- ```lua
--- local segments = pattern.voronoi(seeds, domain, cell.euclidean)
--- ```
---@param seeds forma.pattern pattern containing seed cells
---@param domain forma.pattern pattern defining the tessellation domain
---@param measure fun(a: forma.cell, b: forma.cell): number distance function (e.g., cell.euclidean)
---@return forma.multipattern multipattern of Voronoi segments
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
--- Iteratively relaxes seed positions until convergence or a maximum number of iterations.
---
--- ```lua
--- local segments, relaxed_seeds, converged = pattern.voronoi_relax(seeds, domain, cell.euclidean)
--- ```
---@param seeds forma.pattern initial seed pattern
---@param domain forma.pattern tessellation domain pattern
---@param measure fun(a: forma.cell, b: forma.cell): number distance function (e.g., cell.euclidean)
---@param max_ite? integer maximum iterations (default: 30)
---@return forma.multipattern segments a multipattern of Voronoi segments
---@return forma.pattern seeds a pattern of relaxed seed positions
---@return boolean converged whether the algorithm converged
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
                    next_seeds:insert(cent.x, cent.y, false)
                else
                    local med = tesselation[iseg]:medoid()
                    next_seeds:insert(med.x, med.y, false)
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
    error("This should not be reachable")
end

-- @section Display and utilities

--- Returns the maximum allowed coordinate for spatial hashing.
---
---@return number max_coordinate maximum coordinate value
function pattern.get_max_coordinate()
    return MAX_COORDINATE
end

--- Tests the conversion between (x, y) coordinates and the spatial hash key.
---
---@param x number test x-coordinate
---@param y number test y-coordinate
---@return boolean valid true if the conversion is correct, false otherwise
function pattern.test_coordinate_map(x, y)
    assert(type(x) == 'number' and type(y) == 'number',
        "pattern.test_coordinate_map requires two numbers as arguments")
    local key = coordinates_to_key(x, y)
    local tx, ty = key_to_coordinates(key)
    return (x == tx) and (y == ty)
end

--- Prints the pattern within an optional domain, line-by-line.
---
---@param ip forma.pattern pattern to render
---@param char? string single-character to draw "on" cells
---@param domain? forma.pattern pattern defining the bounding box
---@param printer? fun(line: string) function for printing each line; defaults to io.write(line.."\n")
function pattern.print(ip, char, domain, printer)
    assert(getmetatable(ip) == pattern, "pattern.print requires a pattern as the first argument")
    local onchar  = char or ip.onchar
    local offchar = ip.offchar
    domain        = domain or ip
    assert(getmetatable(domain) == pattern, "pattern.print requires a pattern as the domain argument")

    local print_line = printer
        or function(line) io.write(line .. "\n") end

    for y = domain.min.y, domain.max.y, 1 do
        local chars = {}
        for x = domain.min.x, domain.max.x, 1 do
            chars[#chars + 1] = ip:has_cell(x, y) and onchar or offchar
        end
        print_line(table.concat(chars))
    end
end

return pattern
