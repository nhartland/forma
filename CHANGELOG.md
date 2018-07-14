0.1
---
- Initial release

0.2b
---------

- Improved circle raster (no longer repeats points)
- Fixed bug with subpattern.enclosed which would generate more than one enclosed
  point for a primitive.circle
- Integrated all tests into a single test script, and added luacov coverage
- Implemented a 'mask' subpattern that masks out cells according to a provided
  function
- Converted subpattern.random to take as an argument a fixed integer number of
  desired samples rather than a fraction of the domain size.
- Added Voronoi relaxation via Lloyd's algorithm
- Fixed default initialisation of RNG in automata.async_iterate
- Removed special handling of '-0' coordinate in cell: No longer required with
  integer spatial hash in patterns.
- Made pattern coordinate limits explicit in MAX_COORDINATE
- Changed internal structure of `pattern`, from a list of cells to a list of
  coordinate hashes
- Added pattern.cells: an iterator over the constituent cells in a pattern
- Added cell_coordinates iterator, returning an (x,y) pair rather than a cell
- Added shuffled_cells iterator, similar to cells but in a randomised order
- Added example of Worley noise
- Various optimisations
- Added centroid and medoid (with general distance measure) methods and tests
- Added a Poisson-disc sampling subpattern
- Removed some (confusing) functionality from `cell`, namely addition and
  multiplication with a number value.
- Added isoline drawing example
- Added Mitchell's Best-Candidate sampling (approximate Poisson-Disc)
- Renamed pretty_print to print_patterns
