forma
=====

[![Build Status](https://github.com/nhartland/forma/actions/workflows/tests.yaml/badge.svg)](https://github.com/nhartland/forma/actions/workflows/tests.yaml)
[![Coverage Status](https://coveralls.io/repos/github/nhartland/forma/badge.svg?branch=master)](https://coveralls.io/github/nhartland/forma?branch=master)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)


__2D grid shape generation in Lua__ 

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/si0FhKN.png">
</p>

**forma** is a utility library for the procedural generation and manipulation of
shapes on a two dimensional grid or lattice. It came about as part of
experiments in making roguelike games. **forma** is therefore particularly
suited (but not limited) to the generation of roguelike environments.


## Features

- **A spatial-hashing pattern** class for fast lookup of active cells.
- **Pattern manipulators** such as the addition, subtraction, rotation and reflection of patterns.
- **Rasterisation algorithms** for 2D primitives, e.g lines, circles, squares and Bezier curves.
- A very flexible **cellular automata** implementation with
    - Synchronous and asynchronous updates
    - Combination of multiple rule sets
- **Pattern sampling** algorithms including
    - Random (white noise) sampling
    - Perlin noise sampling
    - Poisson-disc sampling
    - Mitchell's best-candidate sampling
- **Algorithms for subpattern finding** including
    - Flood-fill contiguous segment finding
    - Convex hull finding
    - Pattern edge and surface finding
    - Binary space partitioning
    - Voronoi tessellation / Lloyd's algorithm

Results can be nested to produce complex patterns, and all of these methods are
able to use custom distance measures and definitions of the cellular
**neighbourhood** (e.g
[Moore](https://en.wikipedia.org/wiki/Moore_neighborhood), [von
Neumann](https://en.wikipedia.org/wiki/Von_Neumann_neighborhood)).

## Examples
* [Example Gallery](examples/)
```lua
-- Generate a square box to run the CA inside
local domain = primitives.square(80,20)

-- CA initial condition: 800-point random sample of the domain
local ca = domain:sample(800)

-- Moore (8-cell) neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")

-- Run the CA until converged or 1000 iterations
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, domain, {moore})
    ite = ite+1
end

-- Access cell coordinates for external use
for icell in ca:cells() do
    -- local foo = bar(icell)
    -- or
    -- local foo = bar(icell.x, icell.y)
end

-- Find all 4-contiguous connected components of the CA pattern
-- Uses the von Neumann neighbourhood to determine 'connectedness'
-- but any custom neighbourhood can be used.
local connected_components = ca:connected_components(neighbourhood.von_neumann())

-- Print a representation to io.output
connected_components:print(nil, domain)
```

## Installation

**forma** is compatible with Lua 5.1, 5.2, 5.3 and LuaJIT 2.0, 2.1. The library
is written in pure Lua, no compilation is required. Including the project is as
simple as including the `forma` directory in your project or Lua path.

The easiest way to do this is via LuaRocks. To install the latest stable version
use:

```Shell
    luarocks install forma
```

Alternatively you can try the dev branch with:

```Shell
    luarocks install --server=http://luarocks.org/dev forma
```

## Documentation

Documentation is hosted [here](https://nhartland.github.io/forma/).

Generating the documentation requires
 - [LDoc](https://github.com/stevedonovan/LDoc)

Simply running 

    ldoc --output contents --dir docs .

in the root directory should generate all the required pages.

## Testing

Unit tests and coverage reports are provided. The test suite requires
 - [LuaCov](https://keplerproject.github.io/luacov/)
 - [luaunit](https://github.com/bluebird75/luaunit)

To run the tests use

    ./run_tests.sh
