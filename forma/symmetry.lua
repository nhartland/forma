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

-- Elements of square lattice symmetry groups
local elements = {
    id        = transform.new(1, 0, 0, 1),
    rot90     = transform.new(0, 1, -1, 0),
    rot180    = transform.new(-1, 0, 0, -1),
    rot270    = transform.new(0, -1, 1, 0),
    vreflect  = transform.new(1, 0, 0, -1),
    dreflect  = transform.new(0, 1, 1, 0),
    hreflect  = transform.new(-1, 0, 0, 1),
    adreflect = transform.new(0, -1, -1, 0),
}


-- Symmetry groups of the lattice
local groups = {
    -- Trivial group
    C1 = { elements.id },
    -- Cyclic group of order 2
    C2 = {
        elements.id,
        elements.rot180
    },
    -- Cyclic group of order 4
    C4 = {
        elements.id,
        elements.rot90,
        elements.rot180,
        elements.rot270
    },
    -- Klein four-group (axis reflections)
    V4a = {
        elements.id,
        elements.rot180,
        elements.hreflect,
        elements.vreflect
    },
    -- Klein four-group (diagonal reflections)
    V4d = {
        elements.id,
        elements.rot180,
        elements.dreflect,
        elements.adreflect
    },
    -- Dihedral mirror groups
    D1h = {
        elements.id,
        elements.hreflect
    },
    D1v = {
        elements.id,
        elements.vreflect
    },
    D1d = {
        elements.id,
        elements.dreflect
    },
    D1ad = {
        elements.id,
        elements.adreflect
    },
    -- Dihedral group (rotations + all reflections)
    D4 = {
        elements.id,
        elements.rot90,
        elements.rot180,
        elements.rot270,
        elements.hreflect,
        elements.vreflect,
        elements.dreflect,
        elements.adreflect
    },
}


return { elements = elements, groups = groups }
