--- Sub-pattern finders.
-- Functions for the selection of **sub-patterns** of various forms from a parent
-- `pattern`. The simplest of these is the `random` sampling of a fraction of
-- `cell`s from the parent.
--
-- Several of these finders return a multipattern of all relevant sub-patterns. For
-- example the `connected_components` method which returns a multipattern of all contiguous
-- (according to some `neighbourhood`) sub-patterns by using a `floodfill`.
--
-- In addition to the subpattern finders, a `print_patterns` utility is provided
-- to render these tables of sub-patterns into text.
--
-- @module forma.subpattern

local subpattern    = {}

local cell          = require('forma.cell')
local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local neighbourhood = require('forma.neighbourhood')
local multipattern  = require('forma.multipattern')
local rutils        = require('forma.utils.random')

--- Sub-patterns
-- @section subpatterns

--- Masked subpattern.
-- Generate a subpattern by applying a boolean mask to an input pattern.
-- @param ip the pattern to be masked.
-- @param mask a function that takes a `cell` and returns true if the cell passes the mask
-- @return A pattern consisting only of those cells in `domain` which pass the `mask` argument.
function subpattern.mask(ip, mask)
    assert(getmetatable(ip) == pattern, "subpattern.mask requires a pattern as the first argument")
    assert(type(mask) == 'function', 'subpattern.mask requires a function for the mask')
    local np = pattern.new()
    for icell in ip:cells() do
        if mask(icell) == true then
            np:insert(icell.x, icell.y)
        end
    end
    return np
end

--- Random subpattern.
-- For a given domain, returns a pattern sampling randomly from it, generating a random
-- subset with a fixed fraction of the size of the domain.
-- @param ip pattern for sampling a random pattern from
-- @param ncells the number of desired cells in the sample
-- @param rng (optional) a random number generator, following the signature of math.random.
-- @return a pattern of `ncells` cells sampled randomly from `domain`
function subpattern.random(ip, ncells, rng)
    assert(getmetatable(ip) == pattern, "subpattern.random requires a pattern as the first argument")
    assert(type(ncells) == 'number', "subpattern.random requires an integer number of cells as the second argument")
    assert(math.floor(ncells) == ncells, "subpattern.random requires an integer number of cells as the second argument")
    assert(ncells > 0, "subpattern.random requires at least one sample to be requested")
    assert(ncells <= ip:size(), "subpattern.random requires a domain larger than the number of requested samples")
    if rng == nil then rng = math.random end
    local p = pattern.new()
    local next_coords = ip:shuffled_coordinates(rng)
    for _ = 1, ncells, 1 do
        local x, y = next_coords()
        p:insert(x, y)
    end
    return p
end

--- Poisson-disc random subpattern.
-- Sample a domain according to the Poisson-disc procedure. For a given
-- distance measure `distance`, this generates samples that are never closer
-- together than a specified radius.  While much slower than `subpattern.random`,
-- it provides a more uniform distribution of points in the domain (similar to
-- that of `subpattern.voronoi_relax`).
-- @param ip domain pattern to sample from
-- @param distance a measure  of distance between two cells d(a,b) e.g cell.euclidean
-- @param radius the minimum separation in `distance` between two sample points.
-- @param rng (optional) a random number generator, following the signature of math.random.
-- @return a Poisson-disc sample of `domain`
function subpattern.poisson_disc(ip, distance, radius, rng)
    assert(getmetatable(ip) == pattern, "subpattern.poisson_disc requires a pattern as the first argument")
    assert(type(distance) == 'function', "subpattern.poisson_disc requires a distance measure as an argument")
    assert(type(radius) == "number", "subpattern.poisson_disc requires a number as the target radius")
    if rng == nil then rng = math.random end
    local sample = pattern.new()
    local domain = ip:clone()
    while domain:size() > 0 do
        local dart = domain:rcell(rng)
        local mask = function(icell) return distance(icell, dart) >= radius end
        domain = subpattern.mask(domain, mask)
        sample:insert(dart.x, dart.y)
    end
    return sample
end

--- Mitchell's best candidate sampling.
-- Generates an approximate Poisson-disc sampling by Mitchell's algorithm.
-- Picks 'k' sample point attempts at every iteration, and picks the candidate
-- that maximises the distance to existing samples. Halts when `n` samples are
-- picked.
-- @param ip domain pattern to sample from
-- @param distance a measure of distance between two cells d(a,b) e.g cell.euclidean
-- @param n the requested number of samples
-- @param k the number of candidates samples at each iteration
-- @param rng (optional) a random number generator, following the signature of math.random.
-- @return an approximate Poisson-disc sample of `domain`
function subpattern.mitchell_sample(ip, distance, n, k, rng)
    -- Bridson's Poisson Disk would be better, but it's hard to implement as it
    -- needs a rasterised form of an isosurface for a general distance matric.
    assert(getmetatable(ip) == pattern,
        "subpattern.mitchell_sample requires a pattern as the first argument")
    assert(ip:size() >= n,
        "subpattern.mitchell_sample requires a pattern with at least as many points as in the requested sample")
    assert(type(distance) == 'function', "subpattern.mitchell_sample requires a distance measure as an argument")
    assert(type(n) == "number", "subpattern.mitchell_sample requires a target number of samples")
    assert(type(k) == "number", "subpattern.mitchell_sample requires a target number of candidate tries")
    if rng == nil then rng = math.random end
    local seed = ip:rcell()
    local sample = pattern.new():insert(seed.x, seed.y)
    for _ = 2, n, 1 do
        local min_distance = 0
        local min_sample   = nil

        -- Generate k samples, keeping the furthest
        for _ = 1, k, 1 do
            local jcell = ip:rcell(rng)
            while sample:has_cell(jcell.x, jcell.y) do
                jcell = ip:rcell(rng)
            end
            local jdistance = math.huge
            for vcell in sample:cells() do
                jdistance = math.min(jdistance, distance(jcell, vcell))
            end
            if jdistance > min_distance then
                min_sample   = jcell
                min_distance = jdistance
            end
        end
        -- Push selected sample
        sample:insert(min_sample.x, min_sample.y)
    end
    return sample
end

-- Internal perlin noise function
-- Adapted from https://github.com/max1220/lua-perlin [MIT License]
-- Takes as arguments p: permutation vector, (x, y) coordinates, frequency and
-- sampling depth. Returns a noise value [0,1].
local function perlin_noise(p, x, y, freq, depth)
    local function permute(_x, _y) return p[(p[_y % 256] + _x) % 256]; end
    local function lin_inter(_x, _y, s) return _x + s * (_y - _x) end
    local function smooth_inter(_x, _y, s) return lin_inter(_x, _y, s * s * (3 - 2 * s)) end

    local function noise2d(_x, _y)
        local x_int = math.floor(_x);
        local y_int = math.floor(_y);
        local x_frac = _x - x_int;
        local y_frac = _y - y_int;
        local s = permute(x_int, y_int);
        local t = permute(x_int + 1, y_int);
        local u = permute(x_int, y_int + 1);
        local v = permute(x_int + 1, y_int + 1);
        local low = smooth_inter(s, t, x_frac);
        local high = smooth_inter(u, v, x_frac);
        return smooth_inter(low, high, y_frac);
    end

    local xa = x * freq;
    local ya = y * freq;
    local amp = 1.0;
    local fin = 0;
    local div = 0.0;

    for _ = 1, depth, 1 do
        div = div + 256 * amp;
        fin = fin + noise2d(xa, ya) * amp;
        amp = amp / 2;
        xa = xa * 2;
        ya = ya * 2;
    end

    return fin / div;
end

--- Perlin noise sampling.
-- Samples an input pattern by thresholding a Perlin-noise pattern in the
-- domain.  This function takes an initial sampling frequency, and computes
-- perlin noise over the input pattern by taking the product of `depth`
-- successively halved frequencies. A multipattern is then returned,
-- consisting of the perlin noise function thresholded at requested levels.
-- @param ip pattern upon which the thresholded noise sampling is to be performed.
-- @param freq (float) frequency of desired perlin noise
-- @param depth (int), sampling depth.
-- @param thresholds table of sampling thresholds (between 0 and 1).
-- @param rng (optional) a random number generator, following the signature of math.random.
-- @return a `multipattern`, one subpattern per threshold entry.
function subpattern.perlin(ip, freq, depth, thresholds, rng)
    if rng == nil then rng = math.random end
    assert(getmetatable(ip) == pattern,
        "subpattern.perlin requires a pattern as the first argument")
    assert(type(freq) == "number",
        "subpattern.perlin requires a numerical frequency value.")
    assert(math.floor(depth) == depth,
        "subpattern.perlin requires an integer sampling depth.")
    assert(type(thresholds) == "table",
        "subpattern.perlin requires a table of requested thresholds.")

    for _, th in ipairs(thresholds) do
        assert(th >= 0 and th <= 1,
            "subpattern.perlin requires thresholds between 0 and 1.")
    end
    --
    -- Generate permutation vector
    local p = {}
    for i = 0, 255, 1 do p[i] = i end
    rutils.shuffle(p, rng)

    -- Generate sample patterns
    local samples = {}
    for i = 1, #thresholds, 1 do
        samples[i] = pattern.new()
    end

    -- Fill sample patterns
    for ix, iy in ip:cell_coordinates() do
        local nv = perlin_noise(p, ix, iy, freq, depth)
        for ith, th in ipairs(thresholds) do
            if nv >= th then
                samples[ith]:insert(ix, iy)
            end
        end
    end
    return multipattern.new(samples)
end

-- Helper function for subpattern.floodfill
local function floodfill(x, y, nbh, domain, retpat)
    if domain:has_cell(x, y) and retpat:has_cell(x, y) == false then
        retpat:insert(x, y)
        for i = 1, #nbh, 1 do
            local nx = nbh[i].x + x
            local ny = nbh[i].y + y
            floodfill(nx, ny, nbh, domain, retpat)
        end
    end
end

--- Returns the contiguous sub-pattern of ip that surrounts `cell` ipt
-- @param ip pattern upon which the flood fill is to be performed.
-- @param ipt a `cell` specifying the origin of the flood fill.
-- @param nbh defines which neighbourhood to scan in while flood-filling (default 8/moore).
-- @return a forma.pattern consisting of the contiguous subpattern about `ipt`.
function subpattern.floodfill(ip, ipt, nbh)
    assert(getmetatable(ip) == pattern, "subpattern.floodfill requires a pattern as the first argument")
    assert(ipt, "subpattern.floodfill requires a cell as the second argument")
    if nbh == nil then nbh = neighbourhood.moore() end
    local retpat = pattern.new()
    floodfill(ipt.x, ipt.y, nbh, ip, retpat)
    return retpat
end

-- Find the (lower-left and upper-right) coordinates of the maximal contiguous
-- rectangular area within a pattern.
-- @param ip the input pattern.
-- @return the minimum and maxium coordinates of the area.
local function maxrectangle_coordinates(ip)
    -- Algorithm from http://www.drdobbs.com/database/the-maximal-rectangle-problem/184410529.
    local best_ll = cell.new(0, 0)
    local best_ur = cell.new(-1, -1)
    local best_area = 0

    local stack_w = {}
    local stack_y = {}

    local function push(y, w)
        stack_y[#stack_y + 1] = y
        stack_w[#stack_w + 1] = w
    end

    local function pop()
        local y = stack_y[#stack_y]
        local w = stack_w[#stack_w]
        stack_y[#stack_y] = nil
        stack_w[#stack_w] = nil
        return y, w
    end

    local cache = {}
    for y = ip.min.y, ip.max.y + 1, 1 do cache[y] = 0 end -- One extra element (closes all rectangles)

    local function updateCache(x)
        for y = ip.min.y, ip.max.y, 1 do
            if ip:has_cell(x, y) then
                cache[y] = cache[y] + 1
            else
                cache[y] = 0
            end
        end
    end

    for x = ip.max.x, ip.min.x, -1 do
        updateCache(x)
        local width = 0            -- Width of widest opened rectangle
        for y = ip.min.y, ip.max.y + 1, 1 do
            if cache[y] > width then -- Opening new rectangle(s)?
                push(y, width)
                width = cache[y]
            end
            if cache[y] < width then --// Closing rectangle(s)?
                local y0, w0
                repeat
                    y0, w0 = pop()
                    if width * (y - y0) > best_area then
                        best_ll.x, best_ll.y = x, y0
                        best_ur.x, best_ur.y = x + width - 1, y - 1
                        best_area = width * (y - y0)
                    end
                    width = w0
                until cache[y] >= width
                width = cache[y]
                if width ~= 0 then push(y0, w0) end
            end
        end
    end

    return best_ll, best_ur
end

--- Find the maximal contiguous rectangular area within a pattern.
-- @param ip the input pattern.
-- @return The subpattern of `ip` consisting of its largest contiguous rectangular area.
function subpattern.maxrectangle(ip)
    assert(getmetatable(ip) == pattern, "subpattern.maxrectangle requires a pattern as an argument")
    local min, max = maxrectangle_coordinates(ip)
    local size = max - min + cell.new(1, 1)
    return primitives.square(size.x, size.y):translate(min.x, min.y)
end

--- Multipatterns
-- @section subpattern_lists

--- Generate a multipattern of a pattern's connected components.
-- This performs a series of flood-fill operations until all
-- pattern cells belong to a connected component.
-- @param ip pattern for which the connected_components are to be extracted.
-- @param nbh defines which neighbourhood to scan in while flood-filling (default 8/moore).
-- @return A multipattern consisting of contiguous sub-patterns of ip.
function subpattern.connected_components(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    assert(getmetatable(ip) == pattern, "subpattern.connected_components requires a pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "subpattern.connected_components requires a neighbourhood as the second argument")
    local wp = pattern.clone(ip)
    local segs = {}
    while pattern.size(wp) > 0 do
        local rancell = pattern.rcell(wp)
        table.insert(segs, subpattern.floodfill(wp, rancell, nbh))
        wp = wp - segs[#segs]
    end
    return multipattern.new(segs)
end

--- Returns a multipattern of a parent pattern's interior holes.
-- Interior holes are the inactive areas of a pattern which are completely
-- surrounded by active areas.
-- @param ip pattern for which the holes should be computed.
-- @param nbh defines which directions to scan in while flood-filling (default 4/vn).
-- @return A multipattern comprising the holes of ip.
function subpattern.interior_holes(ip, nbh)
    nbh = nbh or neighbourhood.von_neumann()
    assert(getmetatable(ip) == pattern, "subpattern.interior_holes requires a pattern as the first argument")
    assert(ip:size() > 0, "subpattern.interior_holes requires a non-empty pattern as the first argument")
    assert(getmetatable(nbh) == neighbourhood, "subpattern.interior_holes requires a neighbourhood as the second argument")
    local size = ip.max - ip.min + cell.new(1, 1)
    local interior = primitives.square(size.x, size.y):translate(ip.min.x, ip.min.y) - ip
    local connected_components = subpattern.connected_components(interior, nbh)
    -- Filter out those components that are not interior.
    local function fn(sp)
        if sp.min.x > ip.min.x and sp.min.y > ip.min.y
            and sp.max.x < ip.max.x and sp.max.y < ip.max.y then
            return true
        end
        return false
    end
    return connected_components:filter(fn)
end

-- Binary space partitioning - internal function
local function bspSplit(min, max, th_volume, outpatterns)
    local size = max - min + cell.new(1, 1)
    local volume = size.x * size.y

    if volume > th_volume then
        local r1max, r2min
        if size.x > size.y then
            local xch = math.floor((size.x - 1) * 0.5)
            r1max = min + cell.new(xch, size.y - 1)
            r2min = min + cell.new(xch + 1, 0)
        else
            local ych = math.floor((size.y - 1) * 0.5)
            r1max = min + cell.new(size.x - 1, ych)
            r2min = min + cell.new(0, ych + 1)
        end

        -- Recurse on both new partitions
        bspSplit(min, r1max, th_volume, outpatterns)
        bspSplit(r2min, max, th_volume, outpatterns)
    else -- Passes threshold volume
        local np = primitives.square(size.x, size.y)
        np = pattern.translate(np, min.x, min.y)
        table.insert(outpatterns, np)
    end
end

--- Generate subpatterns by binary space partition.
-- This works by finding all the contiguous rectangular volumes in the input
-- pattern and running a binary space partition on all of them. The partitions
-- are then returned in a multipattern.
--
-- The BSP is controlled by the `threshold volume` parameter. The algorithm
-- will recursively subdivide every rectangular area evenly in two until the
-- volume of the largest remaining area is less than `th_volume`.
--
-- @param ip the pattern for which the BSP will be run over.
-- @param th_volume the highest acceptable volume for each final partition.
-- @returns A multipattern consisting of the BSP subpatterns.
function subpattern.bsp(ip, th_volume)
    assert(getmetatable(ip) == pattern, "subpattern.bsp requires a pattern as an argument")
    assert(th_volume, "subpattern.bsp rules must specify a threshold volume for partitioning")
    assert(th_volume > 0, "subpattern.bsp rules must specify positive threshold volume for partitioning")
    local bsp_subpatterns = {}
    local available = ip
    while pattern.size(available) > 0 do -- Keep finding maxrectangles and BSP them
        local min, max = maxrectangle_coordinates(available)
        bspSplit(min, max, th_volume, bsp_subpatterns)
        for i = 1, #bsp_subpatterns, 1 do
            available = available - bsp_subpatterns[i]
        end
    end
    return multipattern.new(bsp_subpatterns)
end

--- Determine subpatterns for all `neighbourhood` categories.
-- Each neighbourhood has a number of possible combinations or `categories`
-- of active cells. This function categorises each cell in an input pattern
-- into one of the neighbourhood's categories.
-- @param ip the pattern in which cells are to be categorised.
-- @param nbh the forma.neighbourhood used for the categorisation.
-- @return A multipattern of #nbh subpatterns, where each cell in ip is categorised.
function subpattern.neighbourhood_categories(ip, nbh)
    assert(getmetatable(ip) == pattern,
        "subpattern.neighbourhood_categories requires a pattern as a first argument")
    assert(getmetatable(nbh) == neighbourhood,
        "subpattern.neighbourhood_categories requires a neighbourhood as a second argument")
    local category_patterns = {}
    for i = 1, nbh:get_ncategories(), 1 do
        category_patterns[i] = pattern.new()
    end
    for icell in ip:cells() do
        local cat = nbh:categorise(ip, icell)
        category_patterns[cat]:insert(icell.x, icell.y)
    end
    return multipattern.new(category_patterns)
end

--- Generate Voronoi tesselations of cells in a domain.
-- @param seeds the set of seed cells for the tesselation.
-- @param domain the domain of the tesselation.
-- @param measure the measure used to judge distance between cells.
-- @return A multipattern of Voronoi segments.
function subpattern.voronoi(seeds, domain, measure)
    assert(getmetatable(seeds) == pattern, "subpattern.voronoi requires a pattern as a first argument")
    assert(getmetatable(domain) == pattern, "subpattern.voronoi requires a pattern as a second argument")
    assert(pattern.size(seeds) > 0, "subpattern.voronoi requires at least one target cell/seed")
    local seedcells = {}
    local segments  = {}
    for iseed in seeds:cells() do
        assert(domain:has_cell(iseed.x, iseed.y), "forma.voronoi: cell outside of domain")
        table.insert(seedcells, iseed)
        table.insert(segments, pattern.new())
    end
    for dp in domain:cells() do
        local min_cell = 1
        local min_dist = measure(dp, seedcells[1])
        for j = 2, #seedcells, 1 do
            local distance = measure(dp, seedcells[j])
            if distance < min_dist then
                min_cell = j
                min_dist = distance
            end
        end
        segments[min_cell]:insert(dp.x, dp.y)
    end
    return multipattern.new(segments)
end

--- Generate (approx) centroidal Voronoi tessellation.
-- Given a set of prior seeds and a domain, this iterates the position of the
-- seeds until they are approximately located at the centre of their Voronoi
-- segments. Lloyd's algorithm is used.
-- @param seeds the original seed points to be relaxed.
-- @param domain the domain to be tesselated.
-- @param measure the distance measure to be used between cells.
-- @param max_ite (optional) maximum number of iterations of relaxation (default 30).
-- @return A `multipattern` of Voronoi segments after relaxation.
-- @return A `pattern` containing the relaxed seed positions (centroids).
-- @return A boolean indicating whether the algorithm converged.
function subpattern.voronoi_relax(seeds, domain, measure, max_ite)
    if max_ite == nil then max_ite = 30 end
    assert(getmetatable(seeds) == pattern, "subpattern.voronoi_relax requires a pattern as a first argument")
    assert(getmetatable(domain) == pattern, "subpattern.voronoi_relax requires a pattern as a second argument")
    assert(type(measure) == 'function', "subpattern.voronoi_relax requires a distance measure as an argument")
    assert(seeds:size() <= domain:size(), "subpattern.voronoi_relax: too many seeds for domain")
    local current_seeds = seeds:clone()
    for ite = 1, max_ite, 1 do
        local tesselation = subpattern.voronoi(current_seeds, domain, measure).subpatterns
        local next_seeds  = pattern.new()
        for iseg = 1, #tesselation, 1 do
            if tesselation[iseg]:size() > 0 then
                -- Mostly the centroid should be within the domain
                -- If not, attempt the medoid. In either case if
                -- there is a collision, drop the cell
                local cent = tesselation[iseg]:centroid()
                if domain:has_cell(cent.x, cent.y) then
                    if not next_seeds:has_cell(cent.x, cent.y) then
                        next_seeds:insert(cent.x, cent.y)
                    end
                else
                    local med = tesselation[iseg]:medoid()
                    if not next_seeds:has_cell(med.x, med.y) then
                        next_seeds:insert(med.x, med.y)
                    end
                end
            end
        end
        if current_seeds == next_seeds then
            return multipattern.new(tesselation), current_seeds, true  -- converged
        elseif ite == max_ite then
            return multipattern.new(tesselation), current_seeds, false -- max ite
        end
        current_seeds = next_seeds
    end
    assert(false, "This should not be reachable")
end

--- Compute the points lying on the convex hull of a pattern.
-- This computes the points lying on a pattern's convex hull with Andrew's
-- monotone chain convex hull algorithm. Adapted from sixFinger's
-- implementation at
-- https://gist.github.com/sixFingers/ee5c1dce72206edc5a42b3246a52ce2e
-- @param ip input pattern for generating the convex hull.
-- @return A `pattern` consisting of the points of `ip` lying on the convex hull.
-- @return A clockwise-ordered table of cells on the convex hull.
function subpattern.convex_hull_points(ip)
    assert(getmetatable(ip) == pattern,
        "subpattern.convex_hull_points requires a pattern as a first argument")
    assert(ip:size() > 0,
        "subpattern.convex_hull_points: input pattern must have at least one cell")
    -- Build list of points
    local points = ip:cell_list()
    local function cross(p, q, r)
        return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    end
    table.sort(points, function(a, b)
        return a.x == b.x and a.y > b.y or a.x > b.x
    end)
    local lower = {}
    for i = 1, #points do
        while (#lower >= 2 and cross(lower[#lower - 1], lower[#lower], points[i]) <= 0) do
            table.remove(lower)
        end
        table.insert(lower, points[i])
    end
    local upper = {}
    for i = #points, 1, -1 do
        while (#upper >= 2 and cross(upper[#upper - 1], upper[#upper], points[i]) <= 0) do
            table.remove(upper)
        end
        table.insert(upper, points[i])
    end
    table.remove(upper)
    table.remove(lower)
    for i = 1, #lower do
        table.insert(upper, lower[i])
    end
    -- Build pattern of points on the convex hull
    local convex_pattern = pattern.new()
    for i = 1, #upper do
        convex_pattern:insert(upper[i].x, upper[i].y)
    end
    return convex_pattern, upper
end

--- Compute the convex hull of a pattern.
-- This computes the points on a pattern's convex hull with
-- subpattern.convex_hull_points and connects the points with line rasters.
-- @param ip input pattern for generating the convex hull.
-- @return A `pattern` consisting of the convex hull of `ip`.
function subpattern.convex_hull(ip)
    assert(getmetatable(ip) == pattern, "subpattern.convex_hull requires a pattern as a first argument")
    assert(ip:size() > 0, "subpattern.convex_hull: input pattern must have at least one cell")
    local _, hull_points = subpattern.convex_hull_points(ip)
    local chull = pattern.new()
    for i = 1, #hull_points - 1, 1 do
        chull = chull + primitives.line(hull_points[i], hull_points[i + 1])
    end
    chull = chull + primitives.line(hull_points[#hull_points], hull_points[1])
    return chull
end

--- Naive thinning (skeletonization) of a pattern.
-- This approach repeatedly identifies "boundary" cells (using `interior_hull`),
-- then removes them one at a time if that removal does not disconnect the pattern.
-- Additionally, any cell that has exactly one neighbor (an "endpoint") is not removed,
-- preserving lines. The process repeats until no further cells can be safely removed.
--
-- This method is straightforward but can be slow for large patterns, since
-- each removal triggers a connectivity check (via subpattern.segments).
-- For advanced skeletonization, consider using algorithms like Guo–Hall.
--
-- @param ip   the input pattern to be thinned.
-- @param nbh  (optional) the neighbourhood defining adjacency (default moore).
-- @return a new pattern representing the thinned shape.
function subpattern.thin(ip, nbh)
    nbh = nbh or neighbourhood.moore()
    local current = pattern.clone(ip)

    -- Helper: how many connected components are in this pattern under nbh?
    local function num_components(pat)
        return subpattern.connected_components(pat, nbh):n_subpatterns()
    end

    local changed = true
    while changed do
        changed = false
        local comp_count = num_components(current)

        -- Identify the "boundary" cells. We can use interior_hull here:
        local boundary = current:interior_hull(nbh)

        for c in boundary:cells() do
            -- Count how many active neighbors c has
            local ncount = pattern.count_neighbors(current, nbh, c.x, c.y)
            -- Otherwise, try removing it and check if the pattern stays connected
            if ncount > 1 then
                local candidate = current - pattern.new():insert(c.x, c.y)
                if num_components(candidate) == comp_count then
                    current = candidate
                    changed = true
                    break  -- re-check boundary from scratch
                end
            end
        end
    end

    return current
end

return subpattern
