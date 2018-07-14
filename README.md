[![Build Status](https://travis-ci.org/nhartland/forma.svg?branch=master)](https://travis-ci.org/nhartland/forma)
[![Coverage Status](https://coveralls.io/repos/github/nhartland/forma/badge.svg?branch=master)](https://coveralls.io/github/nhartland/forma?branch=master)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

forma
=====

__2D grid shape generation in Lua__ 

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/si0FhKN.png">
</p>

**forma** is a utility library for the procedural generation and manipulation of
shapes on a two dimensional grid or lattice. It came about as part of
experiments in making roguelike games. **forma** is therefore particularly
suited for (but not limited to) the generation of roguelike environments.


## Features

- **A spatial-hashing pattern** class for fast lookup of active cells.
- **Pattern manipulators** such as addition, subtraction and reflection for the
  generation of symmetrical patterns.
- **Rasterisation algorithms** for 2D primitives, e.g lines, circles, squares.
- A very flexible **cellular automata** implementation with
    - Synchronous and asynchronous updates
    - Combination of multiple rule sets
- **Pattern sampling** algorithms including
    - Random (white noise) sampling
    - Poisson-disc sampling
    - Mitchell's best-candidate sampling
- **Algorithms for subpattern finding** including
    - Flood-fill contiguous segment finding
    - Pattern edge and surface finding
    - Binary space partitioning
    - Voronoi tessellation / Lloyd's algorithm

With all of these methods able to use custom definitions of the cellular
**neighbourhood** (e.g
[Moore](https://en.wikipedia.org/wiki/Moore_neighborhood), [von
Neumann](https://en.wikipedia.org/wiki/Von_Neumann_neighborhood)) and distance
measures. Results can also be nested to produce complex results.

## Examples
* [Example Gallery](examples/)
```lua
-- Generate a square box to run the CA inside
local domain = primitives.square(80,20)

-- CA initial condition: 800-point random sample of the domain
local ca = subpattern.random(domain, 800)

-- Moore (8-cell) neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")

-- Run the CA until converged or 1000 iterations
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, domain, {moore})
    ite = ite+1
end

-- Access a subpattern's cell coordinates for external use
for icell in ca:cells() do
    -- local foo = bar(cell)
    -- or
    -- local foo = bar(cell.x, cell.y)
end

-- Find all 4-contiguous segments of the CA pattern
-- Uses the von-neumann neighbourhood to determine 'connectedness'
-- but any custom neighbourhood can be used)
local segments = subpattern.segments(ca, neighbourhood.von_neumann())

-- Print a representation to io.output
subpattern.print_patterns(domain, segments)
```

## Installation

**forma** is compatible with Lua 5.1, 5.2, 5.3 and LuaJIT 2.0, 2.1. The library
is written in pure Lua, no compilation is required. Including the project is as
simple as including the `forma` directory in your project or Lua path.

The easiest way to do this is via LuaRocks:

```Shell
    luarocks install forma
```

## Generating documentation

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
