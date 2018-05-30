# TODO

- Correct bresenham circle algorithm to not duplicate points 
- Add bresenham line drawing to raster
- Improve documentation - specify how all pattern.X methods can also be
  called with standard lua sugar - ip:X
  
- Decouple a bit pattern methods from the underlying data structure
- Move pattern packing (tesselation) into separate module

- Add wrapper functions so that
  point.insert(ip, z, y)
  can use
  point.insert(ip, cell(z,y))

- Improve testing:
  More tests!
  coveralls.io
