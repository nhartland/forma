# Getting Started

**forma** is built on three concepts: **cells**, **patterns**, and
**neighbourhoods**. Everything else in the library is built on top of these.

## Cells

A **cell** is an integer 2D point with `x` and `y` fields.

```lua
local cell = require('forma.cell')

local a = cell.new(3, 4)
local b = cell.new(1, 2)

local c = a + b             -- cell.new(4, 6)
local d = a - b             -- cell.new(2, 2)
print(a == cell.new(3, 4))  --> true (structural equality)
```

The `cell` module also provides distance measures; `cell.manhattan`,
`cell.chebyshev`, and `cell.euclidean` which are used by sampling, Voronoi
tessellation, and other operations that need a notion of proximity.

## Patterns

A **pattern** is a set of cells — the central data structure of forma. It uses
spatial hashing internally, so lookups, insertions, and removals are all O(1).

```lua
local pattern = require('forma.pattern')

local p = pattern.new()
p:insert(0, 0)
p:insert(1, 0)
p:insert(2, 0)

print(p:has_cell(1, 0))  --> true
print(p:size())          --> 3
```

The `primitives` module provides convenient constructors for common shapes:

```lua
local primitives = require('forma.primitives')

local square = primitives.square(80, 20)       -- 80×20 rectangle
local circle = primitives.circle(10)           -- circle of radius 10
local line   = primitives.line(cell.new(0,0), cell.new(20,10))
```

All pattern functions can be called as functions or as methods:

```lua
-- These are equivalent
local hull = pattern.exterior_hull(p, nbh)
local hull = p:exterior_hull(nbh)
```

### Set operations

Patterns support set operations, both as functions and as operators:

```lua
local a = primitives.square(10)
local b = primitives.circle(5):translate(5, 5)

local combined    = a + b    -- union
local overlap     = a * b    -- intersection
local difference  = a - b    -- subtraction
local symmetric   = a ^ b    -- XOR
```

These return new patterns — forma never modifies a pattern in place (except for
`insert` and `remove`).

### Transforms

Patterns can be translated, rotated, reflected, and enlarged:

```lua
local moved   = square:translate(10, 5)
local rotated = square:rotate()       -- 90° clockwise
local flipped = square:hreflect()     -- horizontal mirror
local bigger  = square:enlarge(2)     -- scale by 2×
```

### Printing

For quick visualisation, patterns can be printed to the terminal:

```lua
primitives.circle(8):print()
```

### Iteration

To use a pattern's cells in your own code, iterate over them directly:

```lua
for icell in p:cells() do
    place_tile(icell.x, icell.y)
end

-- Or just the coordinates
for x, y in p:cell_coordinates() do
    place_tile(x, y)
end
```

## Neighbourhoods

A **neighbourhood** defines which cells are considered adjacent. This definition
is used by many pattern operations. For example finding borders, flood fills,
connected components, cellular automata, and morphological operations all depend
on a neighbourhood.

```lua
local neighbourhood = require('forma.neighbourhood')

local moore = neighbourhood.moore()         -- 8 surrounding cells
local vn    = neighbourhood.von_neumann()   -- 4 cardinal neighbours
```

Custom neighbourhoods can also be defined from a list of relative cell positions
using `neighbourhood.new()`.

Here's an example using a neighbourhood to find the exterior border of a shape:

```lua
local domain = primitives.square(10)
local border = domain:exterior_hull(neighbourhood.von_neumann())
```

## Multipatterns

Several operations decompose a pattern into component pieces. The result is a
**multipattern**: a collection of patterns.

```lua
-- Find the 4-connected regions of a pattern
local regions = p:connected_components(neighbourhood.von_neumann())

-- Access individual sub-patterns
local first = regions[1]

-- Filter to regions above a size threshold
local big = regions:filter(function(r) return r:size() > 20 end)

-- Recombine into a single pattern
local merged = big:union_all()
```

## What next

The [API reference](api/pattern.md) covers the full set of operations available
on patterns. The [automata](api/automata.md) module documents cellular automata.
The [examples](examples/readme.md) demonstrate how these combine to produce
interesting structures.
