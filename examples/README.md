# *forma* example gallery
* [Binary space partitioning](#binary-space-partitioning)
* [Voronoi tesselation](#voronoi-tesselation)
* [Perlin noise sampling](#perlin-noise-sampling)
* [Maximum rectangle finding](#maximum-rectangle-finding)
* [Circle primitives](#circle-primitives)
* [Cellular automata](#cellular-automata)
* [Sampling methods](#sampling-methods)
* [Rasterising isolines](#rasterising-isolines)
* [Combining cellular automata rules](#combining-cellular-automata-rules)
* [Readme example](#readme-example)
* [Asynchronous cellular automata](#asynchronous-cellular-automata)

## Binary space partitioning

```lua
local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate an 80x20 square and partition it into segments of maximally 50 cells
local square = primitives.square(80,20)
local bsp = subpattern.bsp(square, 50)

-- Print resulting pattern segments
subpattern.print_patterns(square,bsp)

```
### Output
![foo](img/binary_space_partition.png )
## Voronoi tesselation

```lua
local cell       = require('forma.cell')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')

-- Generate a random pattern in a specified domain
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 10)

-- Compute the corresponding voronoi tesselation
local measure  = cell.chebyshev
local segments = subpattern.voronoi(rn, sq, measure)

subpattern.print_patterns(sq, segments)
```
### Output
![foo](img/voronoi.png )
## Perlin noise sampling
Here we sample a square domain pattern according to perlin noise,
generating three new patterns consisting of the noise thresholded at
values of 0, 0.5 and 0.7.

```lua

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

local domain = primitives.square(80,20)
local frequency, depth = 0.2, 1
local thresholds = {0, 0.5, 0.7}
local noise  = subpattern.perlin(domain, frequency, depth, thresholds)

-- Print resulting pattern segments
subpattern.print_patterns(domain, noise, {'.', '+', 'o'})
```
### Output
![foo](img/perlin.png )
## Maximum rectangle finding
This generates a messy random pattern, and finds the largest contiguous
rectangle of active cells within it.

```lua

local subpattern = require('forma.subpattern')
local primitives = require('forma.primitives')

-- Generate a domain and a messy 'blocking' pattern
local domain = primitives.square(80, 20)
local blocks = subpattern.random(domain, 80)

-- Find the largest contiguous 'unblocked' rectangle in the base pattern
local mxrect = subpattern.maxrectangle(domain - blocks)
subpattern.print_patterns(domain,{blocks, mxrect}, {'o','#'})
```
### Output
![foo](img/maxrectangle.png )
## Circle primitives

```lua
local cell       = require('forma.cell')
local pattern    = require('forma.pattern')
local primitives = require('forma.primitives')
local subpattern = require('forma.subpattern')

local max_radius = 4

-- Setup domain and some random seeds
local domain = primitives.square(80,20)
local seeds  = subpattern.poisson_disc(domain, cell.euclidean, 2*max_radius)
local shapes = pattern.new()

-- Randomly generate some circles in the domain
for seed in seeds:cells() do
    local circle = primitives.circle(math.random(2, max_radius))
    shapes = shapes + circle:shift(seed.x, seed.y)
end

subpattern.print_patterns(domain, {shapes}, {'o'})


```
### Output
![foo](img/bubbles.png )
## Cellular automata
Demonstration of classic cellular-automata cave generation (4-5 rule).

```lua
local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')

-- Domain for CA
local sq = primitives.square(80,20)

-- CA initial condition: sample at random from the domain
local ca = subpattern.random(sq, 800)

-- Moore neighbourhood 4-5 rule
local moore = automata.rule(neighbourhood.moore(), "B5678/S45678")
local ite, converged = 0, false
while converged == false and ite < 1000 do
    ca, converged = automata.iterate(ca, sq, {moore})
    ite = ite+1
end

ca.onchar, ca.offchar = "#", " "
print(ca)
```
### Output
![foo](img/cellular_automata.png )
## Sampling methods
Demonstrations of various methods for sampling from a pattern.
1. `pattern.random` generates white noise, it's fast and irreguarly distributed.
2. Lloyd's algorithm when a specific number of uniform samples are desired.
3. Mitchell's algorithm is a good (fast) approximation of (2).
3. Poisson-disc when a minimum separation between samples is the only requirement.

```lua

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')

-- Domain and seed
local measure = cell.chebyshev
local domain   = primitives.square(80,20)

-- Random samples, uncomment these turn by turn to see the differences
local random  = subpattern.poisson_disc(domain, measure, 4)
--local random  = subpattern.mitchell_sample(domain, measure, 100, 100)
--local random   = subpattern.random(domain, 40)
--local _, random = subpattern.voronoi_relax(random, domain, measure)

subpattern.print_patterns(domain, {random}, {'#'})
```
### Output
![foo](img/sampling.png )
## Rasterising isolines
Here we generate a pattern randomly filled with points, and take as a scalar
field `N(cell) = F_2(cell) - F_1(cell)`, where `F_n` is the Chebyshev distance
to the nth nearest neighbour. Isolines at `N = 0` are drawn by thresholding `N`
at 1 and taking the surface.

```lua

local cell          = require('forma.cell')
local subpattern    = require('forma.subpattern')
local primitives    = require('forma.primitives')

-- Distance measure
local measure = cell.chebyshev

-- Domain and list of seed cells
local sq = primitives.square(80,20)
local rn = subpattern.random(sq, 20):cell_list()

-- Worley noise mask
local mask = function(tcell)
    local sortfn = function(a,b)
        return measure(tcell, a) < measure(tcell, b)
    end
    table.sort(rn, sortfn)
    local F1 = measure(rn[1], tcell)
    local F2 = measure(rn[2], tcell)
    return F2 - F1  > 1
end

-- Compute the thresholded pattern and print its surface
local noise = subpattern.mask(sq, mask)
subpattern.print_patterns(sq, {noise:surface()}, {'#'})

```
### Output
![foo](img/isolines.png )
## Combining cellular automata rules
Here the way multiple CA rules can be combined into a single ruleset is
demonstrated. A asynchronous cellular automata with a complicated ruleset
generates an interesting 'corridor' like pattern.

```lua

local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

-- Generate a domain, and an initial state ca with one random seed cell
local domain = primitives.square(80,20)
local ca = subpattern.random(domain, 1)

-- Complicated ruleset, try leaving out or adding more rules
local moore = automata.rule(neighbourhood.moore(),      "B12/S012345678")
local diag  = automata.rule(neighbourhood.diagonal_2(), "B01/S01234")
local vn    = automata.rule(neighbourhood.von_neumann(),"B12/S01234")
local ruleset = {vn, moore, diag}

repeat
    local converged
    ca, converged = automata.async_iterate(ca, domain, ruleset)
until converged

local nbh = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(ca, nbh)
subpattern.print_patterns(domain, segments, nbh:category_label())
```
### Output
![foo](img/corridors.png )
## Readme example
This generates the example used in the readme. Runs a 4-5 rule CA for 'cave
generation and then computes the contiguous sub-patterns and prints them.

```lua

-- Load forma modules, lazy init is also available, i.e
-- require('forma')
local primitives    = require('forma.primitives')
local subpattern    = require('forma.subpattern')
local automata      = require('forma.automata')
local neighbourhood = require('forma.neighbourhood')

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
    -- local foo = bar(icell)
    -- or
    -- local foo = bar(icell.x, icell.y)
end

-- Find all 4-contiguous segments of the CA pattern
-- Uses the von-neumann neighbourhood to determine 'connectedness'
-- but any custom neighbourhood can be used)
local segments = subpattern.segments(ca, neighbourhood.von_neumann())

-- Print a representation to io.output
subpattern.print_patterns(domain, segments)

```
### Output
![foo](img/readme.png )
## Asynchronous cellular automata
Here the use of an asynchronous cellular automata is demonstrated, making
use also of symmetrisation methods to generate a final, symmetric pattern.

```lua

local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local automata      = require('forma.automata')
local subpattern    = require('forma.subpattern')
local neighbourhood = require('forma.neighbourhood')

-- Domain for CA to operate in
local sq = primitives.square(10,5)

-- Make a new pattern consisting of a single random cell from the domain
local start_point = sq:rcell() -- Select a random point
local ca_pattern  = pattern.new():insert(start_point.x, start_point.y)

-- Moore neighbourhood rule for CA
local moore = automata.rule(neighbourhood.moore(), "B12/S012345678")

-- Perform asynchronous CA update until convergence
local converged = false
while converged == false do
    ca_pattern, converged = automata.async_iterate(ca_pattern, sq, {moore})
end

-- Add some symmetry by mirroring the basic pattern a couple of times
local symmetrised_pattern = ca_pattern:hreflect()
symmetrised_pattern = symmetrised_pattern:vreflect():vreflect()
symmetrised_pattern = symmetrised_pattern:hreflect():hreflect()

-- Categorise the pattern according to possible vN neighbours and print to screen
-- This turns the basic pattern into standard 'box-drawing' characters
local vn = neighbourhood.von_neumann()
local segments = subpattern.neighbourhood_categories(symmetrised_pattern, vn)
subpattern.print_patterns(symmetrised_pattern, segments, vn:category_label())
```
### Output
![foo](img/async_automata.png )
