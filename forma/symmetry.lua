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

---@class forma.symmetry.group
---@field name string|nil
---@field elements forma.transform[]
local group = {}
group.__index = group


local function identify_group(G)
    for _, H in pairs(groups) do
        -- Groups match, label the new group with the existing label
        if G == H then
            return H.name
        end
    end
    return nil
end

local function validate_group(G)
    assert(#G.elements > 0, "forma.group.new cannot take an empty list as argument")
    for i, g in ipairs(G.elements) do
        for j, h in ipairs(G.elements) do
            if i ~= j then
                assert(g ~= h, "forma.group.new only accepts a distinct list of transformations")
            end
            assert(G:contains(g * h), "forma.group.new: Attempted group construction does not close")
        end
    end
    -- Attempt to identify the new group with an existing one
    G.name = G.name or identify_group(G)
    return G
end

--- Create a new group of transformations.
---@param e forma.transform[] group elements
---@param name? string|nil name of the group
---@return forma.symmetry.group
function group.new(e, name)
    return validate_group(
        setmetatable({
            elements = e,
            name = name
        }, group)
    )
end

--- Check if a group contains an element.
---@param G forma.symmetry.group
---@param h forma.transform
---@return boolean contains true if h belongs to G
function group.contains(G, h)
    for _, g in ipairs(G.elements) do
        if g == h then
            return true
        end
    end
    return false
end

--- Check if a group is a subgroup of another.
---@param G forma.symmetry.group
---@param H forma.symmetry.group
---@return boolean subgroups true if G subgroups H
function group.is_subgroup_of(G, H)
    if #(G.elements) > #(H.elements) then return false end
    for _, g in ipairs(G.elements) do
        if not H:contains(g) then return false end
    end
    return true
end

--- Check if two groups are the same.
---@param G forma.symmetry.group
---@param H forma.symmetry.group
---@return boolean equals true if G == H
function group.__eq(G, H)
    return G:is_subgroup_of(H) and H:is_subgroup_of(G)
end

--- Represent a group as a string.
---@param G forma.symmetry.group
---@return string
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

-- Elements of square lattice symmetry groups
---@type table<string, forma.transform>
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

--- Symmetry groups of the lattice
---@type table<string, forma.symmetry.group>
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
