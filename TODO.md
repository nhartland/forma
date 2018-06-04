# TODO
- Rename point->cell

- Move point.neighbours somewhere else: neighbours

- Correct Bresenham circle algorithm to not duplicate points 
  
- Decouple a bit pattern methods from the underlying data structure
- Move pattern packing (tessellation) into separate module

- Add wrapper functions so that
  point.insert(ip, z, y)
  can use
  point.insert(ip, cell(z,y))

- Improve documentation - specify how all pattern.X methods can also be
  called with standard lua sugar - ip:X
    explain method cascading of pattern:insert
    explains which methods mutate a pattern (only insert?) and which return a
    new pattern (all of them?)
  More docs for examples

- Improve testing:
  More tests!
  coveralls.io
