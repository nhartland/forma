Since 0.1
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
