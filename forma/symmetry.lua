--- Symmetries of the 2-d square lattice
---
--- This module describes the various symmetries available to patterns in `forma`,
--- at the level of individual transforms and symmetry groups.
---
--- The main symmetry groups available are
---
---     D4: The dihedral group (rotations + reflections)
---     C4: The cyclic group of order 4 (rotations)
---
---     Two forms of the Klein four-group
---     V4a: Axis reflections
---     V4d: Diagonal reflections
---
--- Wallpaper groups can be formed by composing D4 with translations
local transform = require('forma.transform')

-- Forward declare
local groups

-- Elements of square lattice symmetry groups
local elements = {
    id        = transform.new("id", 1, 0, 0, 1),
    rot90     = transform.new("rot90", 0, 1, -1, 0),
    rot180    = transform.new("rot180", -1, 0, 0, -1),
    rot270    = transform.new("rot270", 0, -1, 1, 0),
    vreflect  = transform.new("vreflect", 1, 0, 0, -1),
    hreflect  = transform.new("hreflect", -1, 0, 0, 1),
    dreflect  = transform.new("dreflect", 0, 1, 1, 0),
    adreflect = transform.new("adreflect", 0, -1, -1, 0),
}

---@class forma.symmetry.group
---@field name string
---@field elements forma.transform[]
local group = {}
group.__index = group

local function identify(test_elements)
    for _, H in pairs(groups) do
        if #(H.elements) == #test_elements
            and H:contains(test_elements) then
            return H.name
        end
    end
    return nil
end

-- TODO: annotations
function group.new(e, name)
    return setmetatable({
        name = name or identify(e),
        elements = e
    }, group)
end

-- Check if a group contains all of a list of elements
function group.contains(G, test_elements)
    if #test_elements > #(G.elements) then return false end
    for _, h in ipairs(test_elements) do
        local match = false
        for _, g in ipairs(G.elements) do
            if g == h then
                match = true
                break
            end
        end
        if not match then return false end
    end
    return true
end

function group.__eq(G, H)
    return G:contains(H.elements) and H:contains(G.elements)
end

function group.__tostring(G)
    if G.name ~= nil then
        return "G[" .. G.name .. "]"
    else
        local names = {}
        for i, g in ipairs(G.elements) do
            names[i] = g.name
        end
        return "G[" .. table.concat(names, '-') .. "]"
    end
end

-- Symmetry groups of the lattice
groups = {
    -- Trivial group
    C1 = group.new({ elements.id }, "C1"),
    -- Cyclic group of order 2
    C2 = group.new({
        elements.id,
        elements.rot180
    }, "C2"),
    -- Cyclic group of order 4
    C4 = group.new({
        elements.id,
        elements.rot90,
        elements.rot180,
        elements.rot270
    }, "C4"),
    -- Klein four-group (axis reflections)
    V4a = group.new({
        elements.id,
        elements.rot180,
        elements.hreflect,
        elements.vreflect
    }, "V4a"),
    -- Klein four-group (diagonal reflections)
    V4d = group.new({
        elements.id,
        elements.rot180,
        elements.dreflect,
        elements.adreflect
    }, "V4d"),
    -- Dihedral mirror groups
    D1h = group.new({
        elements.id,
        elements.hreflect
    }, "D1h"),
    D1v = group.new({
        elements.id,
        elements.vreflect
    }, "D1v"),
    D1d = group.new({
        elements.id,
        elements.dreflect
    }, "D1d"),
    D1ad = group.new({
        elements.id,
        elements.adreflect
    }, "D1ad"),
    -- Dihedral group (rotations + all reflections)
    D4 = group.new({
        elements.id,
        elements.rot90,
        elements.rot180,
        elements.rot270,
        elements.hreflect,
        elements.vreflect,
        elements.dreflect,
        elements.adreflect
    }, "D4"),
}

return { elements = elements, group = group, groups = groups }
