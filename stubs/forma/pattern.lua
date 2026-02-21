---@meta

--- A class containing a set (or pattern) of cells.
---@class forma.pattern
---@field max forma.cell Bounding box maximum.
---@field min forma.cell Bounding box minimum.
---@field offchar string Character for inactive cells in tostring.
---@field onchar string Character for active cells in tostring.
---@operator add(forma.pattern): forma.pattern
---@operator sub(forma.pattern): forma.pattern
---@operator mul(forma.pattern): forma.pattern
---@operator pow(forma.pattern): forma.pattern
local pattern = {}

--- Pattern constructor.
---@param prototype? integer[][] An N×M table of ones and zeros.
---@return forma.pattern
function pattern.new(prototype) end

--- Creates a copy of an existing pattern.
---@param ip forma.pattern
---@return forma.pattern
function pattern.clone(ip) end

--- Inserts a new cell into the pattern.
---@param ip forma.pattern
---@param x integer
---@param y integer
---@return forma.pattern # The updated pattern (for chaining).
function pattern.insert(ip, x, y) end

--- Removes a cell from the pattern.
---@param ip forma.pattern
---@param x integer
---@param y integer
---@return forma.pattern # The updated pattern (for chaining).
function pattern.remove(ip, x, y) end

--- Checks if a cell at (x, y) is active in the pattern.
---@param ip forma.pattern
---@param x integer
---@param y integer
---@return boolean
function pattern.has_cell(ip, x, y) end

--- Filters the pattern using a boolean callback.
---@param ip forma.pattern
---@param fn fun(cell: forma.cell): boolean
---@return forma.pattern
function pattern.filter(ip, fn) end

--- Returns the number of active cells in the pattern.
---@param ip forma.pattern
---@return integer
function pattern.size(ip) end

--- Recalculates the bounding box of the pattern.
---@param ip forma.pattern
function pattern.recalculate_bounding_box(ip) end

--- Comparator: sort patterns by size (descending).
---@param pa forma.pattern
---@param pb forma.pattern
---@return boolean
function pattern.size_sort(pa, pb) end

--- Comparator: sort patterns by size (ascending).
---@param pa forma.pattern
---@param pb forma.pattern
---@return boolean
function pattern.inverse_size_sort(pa, pb) end

--- Computes how densely the bounding box is filled.
---@param ip forma.pattern
---@return number
function pattern.bounding_box_density(ip) end

--- Computes the asymmetry of the pattern's bounding box.
---@param ip forma.pattern
---@return number
function pattern.bounding_box_asymmetry(ip) end

--- Counts active neighbors around a specified cell within the pattern.
---@param p forma.pattern
---@param nbh forma.neighbourhood
---@param arg1 forma.cell|integer A cell or x-coordinate.
---@param arg2? integer y-coordinate if arg1 is an integer.
---@return integer
function pattern.count_neighbors(p, nbh, arg1, arg2) end

--- Returns a list (table) of active cells in the pattern.
---@param ip forma.pattern
---@return forma.cell[]
function pattern.cell_list(ip) end

--- Computes the edit distance between two patterns.
---@param a forma.pattern
---@param b forma.pattern
---@return integer
function pattern.edit_distance(a, b) end

--- Returns the union of a set of patterns.
---@param ... forma.pattern|forma.pattern[]
---@return forma.pattern
function pattern.union(...) end

--- Returns the intersection of multiple patterns.
---@param ... forma.pattern
---@return forma.pattern
function pattern.intersect(...) end

--- Returns the symmetric difference (XOR) of two patterns.
---@param a forma.pattern
---@param b forma.pattern
---@return forma.pattern
function pattern.xor(a, b) end

--- Iterator over active cells in the pattern.
---@param ip forma.pattern
---@return fun(): forma.cell?
function pattern.cells(ip) end

--- Iterator over active cell coordinates in the pattern.
---@param ip forma.pattern
---@return fun(): integer?, integer?
function pattern.cell_coordinates(ip) end

--- Returns an iterator over active cells in randomized order.
---@param ip forma.pattern
---@param rng? fun(m: integer, n: integer): integer
---@return fun(): forma.cell?
function pattern.shuffled_cells(ip, rng) end

--- Returns an iterator over active cell coordinates in randomized order.
---@param ip forma.pattern
---@param rng? fun(m: integer, n: integer): integer
---@return fun(): integer?, integer?
function pattern.shuffled_coordinates(ip, rng) end

--- Renders the pattern as a string.
---@param ip forma.pattern
---@return string
function pattern.__tostring(ip) end

--- Union via '+' operator.
---@param a forma.pattern
---@param b forma.pattern
---@return forma.pattern
function pattern.__add(a, b) end

--- Subtraction via '-' operator.
---@param a forma.pattern
---@param b forma.pattern
---@return forma.pattern
function pattern.__sub(a, b) end

--- Intersection via '*' operator.
---@param a forma.pattern
---@param b forma.pattern
---@return forma.pattern
function pattern.__mul(a, b) end

--- XOR via '^' operator.
---@param a forma.pattern
---@param b forma.pattern
---@return forma.pattern
function pattern.__pow(a, b) end

--- Equality test.
---@param a forma.pattern
---@param b forma.pattern
---@return boolean
function pattern.__eq(a, b) end

--- Computes the centroid of the pattern.
---@param ip forma.pattern
---@return forma.cell
function pattern.centroid(ip) end

--- Computes the medoid cell of the pattern.
---@param ip forma.pattern
---@param measure? fun(a: forma.cell, b: forma.cell): number
---@return forma.cell
function pattern.medoid(ip, measure) end

--- Returns a random cell from the pattern.
---@param ip forma.pattern
---@param rng? fun(n: integer): integer
---@return forma.cell
function pattern.rcell(ip, rng) end

--- Returns a new pattern translated by (sx, sy).
---@param ip forma.pattern
---@param sx integer
---@param sy integer
---@return forma.pattern
function pattern.translate(ip, sx, sy) end

--- Normalizes the pattern so its minimum coordinate is (0,0).
---@param ip forma.pattern
---@return forma.pattern
function pattern.normalise(ip) end

--- Returns an enlarged version of the pattern.
---@param ip forma.pattern
---@param f number Enlargement factor.
---@return forma.pattern
function pattern.enlarge(ip, f) end

--- Returns a new pattern rotated 90° clockwise.
---@param ip forma.pattern
---@return forma.pattern
function pattern.rotate(ip) end

--- Returns a vertically reflected pattern.
---@param ip forma.pattern
---@return forma.pattern
function pattern.vreflect(ip) end

--- Returns a horizontally reflected pattern.
---@param ip forma.pattern
---@return forma.pattern
function pattern.hreflect(ip) end

--- Returns a random subpattern of fixed size.
---@param ip forma.pattern
---@param ncells integer
---@param rng? fun(m: integer, n: integer): integer
---@return forma.pattern
function pattern.sample(ip, ncells, rng) end

--- Returns a Poisson-disc sampled subpattern.
---@param ip forma.pattern
---@param distance fun(a: forma.cell, b: forma.cell): number
---@param radius number
---@param rng? fun(m: integer, n: integer): integer
---@return forma.pattern
function pattern.sample_poisson(ip, distance, radius, rng) end

--- Returns an approximate Poisson-disc sample (Mitchell's best candidate).
---@param ip forma.pattern
---@param distance fun(a: forma.cell, b: forma.cell): number
---@param n integer Number of samples.
---@param k integer Number of candidates per iteration.
---@param rng? fun(m: integer, n: integer): integer
---@return forma.pattern
function pattern.sample_mitchell(ip, distance, n, k, rng) end

--- Returns the connected component starting from a given cell.
---@param ip forma.pattern
---@param icell forma.cell
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.floodfill(ip, icell, nbh) end

--- Finds the largest contiguous rectangular subpattern.
---@param ip forma.pattern
---@param alpha? number Squareness parameter (0=max rect, 1=max square).
---@return forma.pattern
function pattern.max_rectangle(ip, alpha) end

--- Computes the convex hull of the pattern.
---@param ip forma.pattern
---@return forma.pattern
function pattern.convex_hull(ip) end

--- Returns a thinned (skeletonized) version of the pattern.
---@param ip forma.pattern
---@return forma.pattern
function pattern.thin(ip) end

--- Returns the erosion of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.erode(ip, nbh) end

--- Returns the dilation of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.dilate(ip, nbh) end

--- Returns the morphological gradient of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.gradient(ip, nbh) end

--- Returns the morphological opening of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.opening(ip, nbh) end

--- Returns the morphological closing of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.closing(ip, nbh) end

--- Returns the interior hull of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.interior_hull(ip, nbh) end

--- Returns the exterior hull of the pattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.pattern
function pattern.exterior_hull(ip, nbh) end

--- Finds a packing offset where pattern a fits within domain b.
---@param a forma.pattern
---@param b forma.pattern
---@param rng? fun(n: integer): integer
---@return forma.cell?
function pattern.find_packing_position(a, b, rng) end

--- Finds a center-weighted packing offset.
---@param a forma.pattern
---@param b forma.pattern
---@param c? forma.cell
---@return forma.cell?
function pattern.find_central_packing_position(a, b, c) end

--- Returns connected components as a multipattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.multipattern
function pattern.connected_components(ip, nbh) end

--- Returns interior holes as a multipattern.
---@param ip forma.pattern
---@param nbh? forma.neighbourhood
---@return forma.multipattern
function pattern.interior_holes(ip, nbh) end

--- Partitions the pattern using binary space partitioning.
---@param ip forma.pattern
---@param th_volume number Threshold volume.
---@param alpha? number Squareness parameter.
---@return forma.multipattern
function pattern.bsp(ip, th_volume, alpha) end

--- Categorizes cells by neighbourhood configuration.
---@param ip forma.pattern
---@param nbh forma.neighbourhood
---@return forma.multipattern
function pattern.neighbourhood_categories(ip, nbh) end

--- Applies Perlin noise sampling to the pattern.
---@param ip forma.pattern
---@param freq number
---@param depth integer
---@param thresholds number[]
---@param rng? fun(m: integer, n: integer): integer
---@return forma.multipattern
function pattern.perlin(ip, freq, depth, thresholds, rng) end

--- Generates Voronoi tessellation segments.
---@param seeds forma.pattern
---@param domain forma.pattern
---@param measure fun(a: forma.cell, b: forma.cell): number
---@return forma.multipattern
function pattern.voronoi(seeds, domain, measure) end

--- Performs centroidal Voronoi tessellation (Lloyd's algorithm).
---@param seeds forma.pattern
---@param domain forma.pattern
---@param measure fun(a: forma.cell, b: forma.cell): number
---@param max_ite? integer
---@return forma.multipattern segments
---@return forma.pattern relaxed_seeds
---@return boolean converged
function pattern.voronoi_relax(seeds, domain, measure, max_ite) end

--- Returns the maximum allowed coordinate for spatial hashing.
---@return integer
function pattern.get_max_coordinate() end

--- Tests coordinate-to-key conversion.
---@param x number
---@param y number
---@return boolean
function pattern.test_coordinate_map(x, y) end

--- Prints the pattern.
---@param ip forma.pattern
---@param char? string
---@param domain? forma.pattern
---@param printer? fun(line: string)
function pattern.print(ip, char, domain, printer) end

return pattern
