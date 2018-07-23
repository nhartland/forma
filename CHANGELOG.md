0.1
---
- Initial release

0.2
---------

### Features
- Implemented a 'mask' subpattern that masks out cells according to a provided
  function
- Added Voronoi relaxation via Lloyd's algorithm
- Added pattern.cells: an iterator over the constituent cells in a pattern
- Added cell_coordinates iterator, returning an (x,y) pair rather than a cell
- Added shuffled_cells iterator, similar to cells but in a randomised order
- Added centroid and medoid (with general distance measure) methods and tests
- Added a Poisson-disc sampling subpattern
- Added Mitchell's Best-Candidate sampling (approximate Poisson-Disc)

### Bugfix
- Fixed bug with subpattern.enclosed which would generate more than one enclosed
  point for a primitive.circle
- Fixed default initialisation of RNG in automata.async_iterate

### Misc
- Improved circle raster (no longer repeats points)
- Integrated all tests into a single test script, and added luacov coverage
- Converted subpattern.random to take as an argument a fixed integer number of
  desired samples rather than a fraction of the domain size.
- Removed special handling of '-0' coordinate in cell: No longer required with
  integer spatial hash in patterns.
- Made pattern coordinate limits explicit in MAX_COORDINATE
- Changed internal structure of `pattern`, from a list of cells to a list of
  coordinate hashes
- Various optimisations
- Removed some (confusing) functionality from `cell`, namely addition and
  multiplication with a number value.
- Added isoline drawing example
- Renamed pretty_print to print_patterns

Since 0.2
---------

# Features
- Shuffled version of cell_coordinates iterator
- Pattern rotation operator

# Misc
- Slightly faster convergence check for automata.iterate
- Slightly streamlined corridors example
