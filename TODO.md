# TODO

- Correct Bresenham circle algorithm to not duplicate points 
- Add Bresenham line drawing to raster
  
- Decouple a bit pattern methods from the underlying data structure
- Move pattern packing (tessellation) into separate module
- Move primitives (square, circle) into separate module

- Add wrapper functions so that
  point.insert(ip, z, y)
  can use
  point.insert(ip, cell(z,y))

- Add pattern import/export to json

- Improve documentation - specify how all pattern.X methods can also be
  called with standard lua sugar - ip:X

- Improve testing:
  More tests! (Still lifes, oscillators for CA)
  coveralls.io
