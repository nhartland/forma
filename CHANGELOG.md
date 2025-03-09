# 0.1
Initial release

# 0.2

## Features
- Implemented a 'mask' subpattern that masks out cells according to a provided
  function
- Added Voronoi relaxation via Lloyd's algorithm
- Added pattern.cells: an iterator over the constituent cells in a pattern
- Added cell_coordinates iterator, returning an (x,y) pair rather than a cell
- Added shuffled_cells iterator, similar to cells but in a randomised order
- Added centroid and medoid (with general distance measure) methods and tests
- Added a Poisson-disc sampling subpattern
- Added Mitchell's Best-Candidate sampling (approximate Poisson-Disc)

## Bugfix
- Fixed bug with subpattern.enclosed which would generate more than one enclosed
  point for a primitive.circle
- Fixed default initialisation of RNG in `automata.async_iterate`

## Misc
- Improved circle raster (no longer repeats points)
- Integrated all tests into a single test script, and added luacov coverage
- Converted subpattern.random to take as an argument a fixed integer number of
  desired samples rather than a fraction of the domain size.
- Removed special handling of '-0' coordinate in cell: No longer required with
  integer spatial hash in patterns.
- Made pattern coordinate limits explicit in `MAX_COORDINATE`
- Changed internal structure of `pattern`, from a list of cells to a list of
  coordinate hashes
- Various optimisations
- Removed some (confusing) functionality from `cell`, namely addition and
  multiplication with a number value.
- Added isoline drawing example
- Renamed `pretty_print` to `print_patterns`

# 0.3

## Features
- Pattern rotation operator
- Shuffled version of `cell_coordinates` iterator
- Generalised pattern prototype constructor to allow `NxM` matrices 

## Bugfix
- Fixed lazy initialisation through 'require ("forma")'
- Corrected assert error message in pattern subtraction

## Misc
- Improved pattern documentation
- Greatly expanded test coverage
- Slightly streamlined corridors example
- Much faster `subpattern.floodfill`
- Much faster construction of neighbourhoods
- Slightly faster pattern surface/enlarge/reflect
- Slightly faster `subpattern.random`
- Slightly faster convergence check for `automata.iterate`
- Harmonised coordinate handling between pattern prototype and tostring
  

# 0.4

## Features
- Perlin noise sampling
- Quadratic Bezier curve drawing.

## Misc
 - Check that CA rule sets don't have neighbourhoods that are too large for 
   the rule signature format (>10 neighbours)
 - Fixed some typos in usage examples
 - Setup forma documentation example checking with `ldoctest`

# 0.5

## Features
 - Convex hull computation
 - Edit distance between patterns

## Bugfix
 - Including the circle raster unit test.
 - Require a radius of at least 1 for primitives.circle

## Misc
 - Ordering the example neighbourhood vector lists clockwise
 - Improved error messages on some subpattern methods
 - Slightly improved example gallery generation
 - Changed to using LuaRocks as test runner

# 1.0 (WIP)

## Breaking
 - Renamed `pattern.sum` to `pattern.union` to avoid confusion with the
   `+` operator.
 - Renamed `pattern.shift` to `pattern.translate` to improve clarity.
 - Renamed `pattern.edge` to `pattern.exterior_hull` to improve clarity.
 - Renamed `pattern.surface` to `pattern.interior_hull` to improve clarity.
 - Renamed `pattern.segments` to `pattern.connected_components` to improve clarity.
 - Renamed `pattern.enclosed` to `pattern.interior_holes` to improve clarity.
 - Renamed `maxrectangle` to `max_rectangle` to improve consistency.
 - Renamed `packtile` to `find_packing_position` to improve clarity.
 - Renamed `packtile_centre` to `find_central_packing_position` to improve clarity.
 - Subpattern module merged into pattern module to enable more fluent chaining.
 - Renamed `subpattern.random` to `pattern.sample` to improve clarity.
 - Renamed `subpattern.poisson_disc` to `pattern.sample_poisson` to improve clarity.
 - Renamed `subpattern.mitchell_sample` to `pattern.sample_mitchell` to improve clarity.
 - Removed `subpattern.convex_hull_points` in favour of a utility function.
 - Many subpattern methods that used to return a table of subpatterns, now return a multipattern.

## Features
 - A multipattern class for handling collections of patterns.
 - A raycasting tool for determining 'visible' areas of a pattern
   from a source cell.
 - A knight neighbourhood for knight-piece moves.
 - Pattern methods `dilate` and `erode` for morphological operations.
 - Pattern morphological operations `opening`, `closing`, `gradient`.
 - A pattern XOR method and a^b operator.
 - A pattern metamethod for intersection (a*b)
 - A naive pattern thinning/skeletonisation operation

## Bugfix
 - Fixed GitHub actions workflows by bumping `gh-action-lua` and
   `gh-action-luarocks` versions.
 - Fixed luaunit at v3.3 

## Misc
 - Adjust `pattern.union_all` so that it can also take a single table of patterns as
   an argument (pattern.union_all({a,b,c}) instead of just pattern.union_all(a,b,c)).
 - Relaxed the assertions on the nature of distance measures in Mitchell
   sampling / Poisson disc sampling.
