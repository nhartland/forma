--- Sub-pattern finders.
-- Functions for the selection of sub-patterns of various forms from a parent
-- pattern. The simplest of these is the `random` sampling of a fraction of
-- cells from the parent.
--
-- Several of these finders return a list of all relevant sub-patterns. For
-- example the `segments` method which returns a list of all contiguous
-- (according to some `neighbourhood`) sub-patterns by using a `floodfill`.
--
-- In addition to the subpattern finders, a `pretty_print` utility is provided
-- to render these lists of sub-patterns into text.
--
-- @module forma.subpattern

local subpattern = {}

local util          = require('forma.util')
local cell         = require('forma.cell')
local pattern       = require('forma.pattern')
local primitives    = require('forma.primitives')
local neighbourhood = require('forma.neighbourhood')

--- Random subpattern.
-- For a given domain, returns a pattern sampling randomly from it, generating a random
-- subset with a fixed fraction of the size of the domain.
-- @param ip pattern for sampling a random pattern from
-- @param fr the fraction of the domain to be sampled
-- @param rng (optional ) a random number generator, following the signature of math.random.
-- @return a pattern of `fr*domain.size` cells sampled randomly from domain
function subpattern.random(ip, fr, rng)
	assert(getmetatable(ip) == pattern, "subpattern.random requires a pattern as the first argument")
	assert(type(fr) == 'number', 'subpattern.random requires a number for the probability')
	assert(fr >= 0 and fr <= 1 , 'subpattern.random requires a fraction 0 <= p <= 1')
    local n_subset = math.floor(fr*ip:size()) -- Number of cells in returned pattern
	assert(n_subset > 0,  'subpattern.random requires a fraction and domain large enough to return a non-empty pattern')
	if rng == nil then rng = math.random end
    local cells = ip:cell_list()
    util.fisher_yates(cells, rng)
	local p = pattern.new()
    for i = 1, n_subset, 1 do
	    p:insert(cells[i].x, cells[i].y)
	end
	return p
end

--- Returns the contiguous sub-pattern of ip that surrounts cell pt
-- @param ip pattern upon which the flood fill is to be performed
-- @param ipt specifies where the flood fill should begin
-- @param dirs defines which neighbourhood to scan in while flood-filling (default 8/moore)
-- @return a forma.pattern consisting of the contiguous segment about cell
function subpattern.floodfill(ip, ipt, dirs)
	assert(getmetatable(ip) == pattern, "subpattern.floodfill requires a pattern as the first argument")
	assert(ipt, "subpattern.floodfill requires a cell as the second argument")
	dirs = dirs or neighbourhood.moore()
	local retpat = pattern.new()
	local function ff(pt)
		if ip:has_cell(pt.x, pt.y) and retpat:has_cell(pt.x, pt.y) == false then
		    pattern.insert(retpat, pt.x, pt.y)
			for i=1, #dirs, 1 do ff(pt + dirs[i]) end
		end
		return
	end
	ff(ipt)
	return retpat
end

--- Generate a list of contiguous 'segments' or sub-patterns.
-- This performs a series of flood-fill operations until all
-- pattern cells are accounted for in the sub-patterns
-- @param ip pattern for which the segments are to be extracted
-- @param dirs defines which neighbourhood to scan in while flood-filling (default 8/moore)
-- @return a table of forma.patterns consisting of contiguous sub-patterns of ip
function subpattern.segments(ip, dirs)
	assert(getmetatable(ip) == pattern, "subpattern.segments requires a pattern as the first argument")
	dirs = dirs or neighbourhood.moore()
	local wp = pattern.clone(ip)
	local segs = {}
	while pattern.size(wp) > 0 do
		local rancell = pattern.rcell(wp)
		table.insert(segs, subpattern.floodfill(wp, rancell, dirs))
		wp = wp - segs[#segs]
	end
	return segs
end

--- Returns a list of 'enclosed' segments of a pattern.
-- Enclosed areas are the inactive areas of a pattern which are
-- completely surrounded by active areas
-- @param ip pattern for which the enclosed areas should be computed
-- @param dirs defines which directions to scan in while flood-filling (default 4/vn)
-- @return a list of forma.patterns comprising the enclosed areas of ip
function subpattern.enclosed(ip, dirs)
	assert(getmetatable(ip) == pattern, "subpattern.enclosed requires a pattern as the first argument")
	dirs = dirs or neighbourhood.von_neumann()
    local size = ip.max - ip.min + 1
    local interior = primitives.square(size.x, size.y):shift(ip.min.x, ip.min.y) - ip
    local segments = subpattern.segments(interior, dirs)
    local enclosed = {}
    for i=1, #segments,1 do
        local segment = segments[i]
        if segment.min.x >= ip.min.x and segment.min.y >= ip.min.y
        and segment.max.x <= ip.max.x-1 and segment.max.y <= ip.max.y-1 then
            table.insert(enclosed, segment)
        end
    end
    return enclosed
end

--- Generate voronoi tesselations of cells in a domain.
-- @param cells the set of seed cells for the tesselation
-- @param domain the domain of the tesselation
-- @param measure the measure used to judge distance between cells
-- @return a list of voronoi segments
function subpattern.voronoi(cells, domain, measure)
	assert(getmetatable(cells) == pattern,  "subpattern.voronoi requires a pattern as a first argument")
	assert(getmetatable(domain) == pattern, "subpattern.voronoi requires a pattern as a second argument")
    assert(pattern.size(cells) > 0, "subpattern.voronoi requires at least one target cell/seed")
    local domaincells = domain:cell_list()
    local seedcells   = cells:cell_list()
    local segments  = {}
	for i=1, #seedcells, 1 do
        local v = seedcells[i]
        assert(domain:has_cell(v.x, v.y), "forma.voronoi: cell outside of domain: " .. tostring(v))
        segments[i] = pattern.new()
    end
	for i=1, #domaincells, 1 do
        local dp = domaincells[i]
        local min_cell = 1
        local min_dist  = measure(dp, seedcells[1])
	    for j=2, #seedcells, 1 do
            local distance = measure(dp, seedcells[j])
            if distance < min_dist then
                min_cell = j
                min_dist = distance
            end
        end
        segments[min_cell]:insert(dp.x,dp.y)
    end
    return segments
end

-- Find the (lower-left and upper-right) coordinates of the maximal contiguous
-- rectangular area within a pattern.
-- Algorithm from http://www.drdobbs.com/database/the-maximal-rectangle-problem/184410529.
-- @param ip the input pattern
-- @return the minimum and maxium coordinates of the area
local function maxrectangle_coordinates(ip)

	local best_ll = cell.new()
	local best_ur = cell.new(-1,-1)
	local best_area = 0

	local stack = {}
	local function push(y,w) table.insert(stack,{y,w}) end
	local function pop() return unpack(table.remove(stack)) end

	local cache = {}
	for y = ip.min.y, ip.max.y+1, 1 do cache[y] = 0 end -- One extra element (closes all rectangles)

	local function updateCache(x)
		for y = ip.min.y, ip.max.y, 1 do
			if ip:has_cell(x,y) then
				cache[y] = cache[y] + 1
			else
				cache[y] = 0
			end
		end
	end

	for x=ip.max.x, ip.min.x, -1 do
		updateCache(x)
		local width = 0 -- Width of widest opened rectangle
		for y = ip.min.y, ip.max.y+1, 1 do
			if cache[y]>width then-- Opening new rectangle(s)?
				push(y, width)
				width = cache[y]
	        end
			if cache[y]<width then  --// Closing rectangle(s)?
				local y0, w0
				repeat
					y0, w0= pop()
					if width*(y-y0)> best_area then
						best_ll = cell.new(x, y0)
						best_ur = cell.new(x+width-1, y - 1)
						best_area = width*(y-y0)
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
-- @param ip the input pattern
-- @return the subpattern of `ip` consisting of its largest contiguous rectangular area.
function subpattern.maxrectangle(ip)
	assert(getmetatable(ip) == pattern, "subpattern.maxrectangle requires a pattern as an argument")
    local min, max = maxrectangle_coordinates(ip)
    local size = max - min + 1
    return primitives.square(size.x, size.y):shift(min.x, min.y)
end


-- Binary space partitioning - internal function
local function bspSplit(min, max, th_volume, outpatterns)
	local size = max - min + cell.new(1,1)
	local volume = size.x*size.y

	if volume > th_volume then
		local r1max, r2min
		if size.x > size.y then
			local xch = math.floor((size.x-1)*0.5)
			r1max = min + cell.new( xch, size.y-1)
			r2min = min + cell.new( xch + 1, 0)
		else
			local ych = math.floor((size.y-1)*0.5)
			r1max = min + cell.new( size.x-1, ych)
			r2min = min + cell.new( 0, ych + 1)
		end

		-- Recurse on both new partitions
		bspSplit(min, r1max, th_volume, outpatterns)
		bspSplit(r2min, max, th_volume, outpatterns)

	else -- Passes threshold volume
		local np = primitives.square(size.x, size.y)
		np = pattern.shift(np, min.x, min.y)
		table.insert(outpatterns, np)
	end
end

--- Generate subpatterns by binary space partition.
-- This works by finding all the contiguous rectangular volumes in the input
-- pattern and running a binary space partition on all of them. The partitions
-- are then returned in a table.
--
-- The BSP is controlled by the `threshold volume` parameter. The algorithm
-- will recursively subdivide every rectangular area evenly in two until the
-- volume of the largest remaining area is less than `th_volume`.
--
-- @param ip the pattern for which the BSP will be run over
-- @param th_volume the highest acceptable volume for each final partition
function subpattern.bsp(ip, th_volume)
	assert(getmetatable(ip) == pattern, "subpattern.bsp requires a pattern as an argument")
	assert(th_volume,     "subpattern.bsp rules must specify a threshold volume for partitioning")
	assert(th_volume > 0, "subpattern.bsp rules must specify positive threshold volume for partitioning")
	local bsp_subpatterns = {}
	local available = ip
	while pattern.size(available) > 0 do -- Keep finding maxrectangles and BSP them
		local min, max = maxrectangle_coordinates(available)
		bspSplit(min, max, th_volume, bsp_subpatterns)
		for i=1, #bsp_subpatterns, 1 do
            available = available - bsp_subpatterns[i]
        end
	end
    return bsp_subpatterns
end

--- Determine subpatterns for all `neighbourhood` categories.
-- Each neighbourhood has a number of possible combinations or `categories`
-- of active cells. This function categorises each cell in an input pattern
-- into one of the neighbourhood's categories.
-- @param ip the pattern in which cells are to be categorised
-- @param nbh the forma.neighbourhood used for the categorisation
-- @return a table of #nbh patterns, where each cell in ip is categorised
function subpattern.neighbourhood_categories(ip, nbh)
    assert(getmetatable(ip) == pattern,
           "subpattern.neighbourhood_categories requires a pattern as a first argument")
    assert(getmetatable(nbh) == neighbourhood,
           "subpattern.neighbourhood_categories requires a neighbourhood as a second argument")
    local category_patterns = {}
    for i=1, #nbh.categories, 1 do
        category_patterns[i] = pattern.new()
    end
    for i=1, #ip.cellset, 1 do
        local cat = nbh:categorise(ip, ip.cellset[i])
        pattern.insert(category_patterns[cat], ip.cellset[i].x, ip.cellset[i].y)
    end
    return category_patterns
end

--- Pretty print a list of forma.pattern segments.
-- Prints a list of pattern segments to `io.output`. If provided, a table of
-- segment labels can be used, with one entry per segment.
-- @param domain the basic pattern from which the segments were generated.
-- @param segments the table of segments to be drawn.
-- @param chars the characters to be printed for each segment (optional).
function subpattern.pretty_print(domain, segments, chars)
    -- If no dictionary is supplied generate a new one (starting from '0')
    if chars == nil then
        local start_char = 47
        assert(#segments < (200 - start_char), "subpattern.pretty_print: too many segments")
        chars = {}
        for i=1, #segments, 1 do
            table.insert(chars, string.char(i+start_char))
        end
    end
    assert(#segments == #chars,
           "subpattern.pretty_print: there must be as many character list entries as segments")
    -- Print out the segments to a map
    for i=domain.min.y, domain.max.y,1 do
        local string = ''
        for j=domain.min.x, domain.max.x,1 do
            local token = ' '
            for k,v in ipairs(segments) do
            if v:has_cell(j, i) then token = chars[k] end end
            string = string .. token
        end
        io.write(string .. '\n')
    end
end

return subpattern