--- Routines for the generation of sub-patterns
-- @module forma.subpattern

local subpattern = {}

local thispath      = select('1', ...):match(".+%.") or ""
local point         = require(thispath .. 'point')
local pattern       = require(thispath .. 'pattern')
local neighbourhood = require(thispath .. 'neighbourhood')

--- Returns the contiguous sub-pattern of ip that surrounts point pt
-- @param ip pattern upon which the flood fill is to be performed
-- @param ipt specifies where the flood fill should begin
-- @param dirs defines which neighbourhood to scan in while flood-filling (default 8/moore)
-- @return a forma.pattern consisting of the contiguous segment about point
function subpattern.floodfill(ip, ipt, dirs)
	assert(getmetatable(ip) == pattern, "pattern.floodfill requires a pattern as the first argument")
	assert(ipt, "pattern.floodfill requires a point as the second argument")
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
	assert(getmetatable(ip) == pattern, "pattern.segments requires a pattern as the first argument")
	dirs = dirs or neighbourhood.moore()
	local wp = pattern.clone(ip)
	local segs = {}
	while pattern.size(wp) > 0 do
		local ranpoint = pattern.rpoint(wp)
		table.insert(segs, subpattern.floodfill(wp, ranpoint, dirs))
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
	assert(getmetatable(ip) == pattern, "pattern.edge requires a pattern as the first argument")
	dirs = dirs or neighbourhood.von_neumann()
    local xs = ip.max.x - ip.min.x
    local ys = ip.max.y - ip.min.y
    local sq = pattern.square(xs, ys)
    sq = pattern.shift(sq, ip.min.x, ip.min.y)
    sq = sq - ip
    local segments = subpattern.segments(sq, dirs)
    local enclosed = {}
    for i=1, #segments,1 do
        local segment = segments[i]
        pattern.limiteval(segment)
        if segment.min.x > ip.min.x and segment.min.y > ip.min.y
        and segment.max.x < ip.max.x-1 and segment.max.y < ip.max.y-1 then
            table.insert(enclosed, segment)
        end
    end
    return enclosed
end

--- Generate voronoi tesselations of points in a domain.
-- @param points the set of seed points for the tesselation
-- @param domain the domain of the tesselation
-- @param measure the measure used to judge distance between points
-- @return a list of voronoi segments
function subpattern.voronoi(points, domain, measure)
	assert(getmetatable(points) == pattern,  "forma.voronoi: segments requires a pattern as a first argument")
	assert(getmetatable(domain) == pattern,  "forma.voronoi: segments requires a pattern as a second argument")
    assert(pattern.size(points) > 0, "forma.voronoi: segments requires at least one target point/seed")
    local domainset = domain.pointset
    local pointset  = points.pointset
    local segments  = {}
	for i=1, #pointset, 1 do
        local v = pointset[i]
        assert(domain:has_cell(v.x, v.y), "forma.voronoi: point outside of domain: " .. tostring(v))
        segments[i] = pattern.new()
    end
	for i=1, #domainset, 1 do
        local dp = domainset[i]
        local min_point = 1
        local min_dist  = measure(dp, pointset[1])
	    for j=2, #pointset, 1 do
            local distance = measure(dp, pointset[j])
            if distance < min_dist then
                min_point = j
                min_dist = distance
            end
        end
        pattern.insert(segments[min_point], dp.x,dp.y)
    end
    return segments
end

--- Find the maximal rectangular area within a pattern.
-- Algorithm from http://www.drdobbs.com/database/the-maximal-rectangle-problem/184410529
-- @param ip pattern for rectangle finding
-- @return min, max of largest subrectangle
function subpattern.maxrectangle(ip)
	assert(getmetatable(ip) == pattern, "pattern.maxrectangle requires a pattern as an argument")

	local best_ll = point.new()
	local best_ur = point.new(-1,-1)
	local best_area = 0

	local stack = {}
	local function push(y,w) table.insert(stack,{y,w}) end
	local function pop() return unpack(table.remove(stack)) end

	local cache = {}
	for y = ip.min.y, ip.max.y+1, 1 do cache[y] = 0 end -- One extra element (closes all rectangles)

	local function updateCache(x)
		for y = ip.min.y, ip.max.y, 1 do
			if ip:has_cell(ip,x,y) then
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
						best_ll = point.new(x, y0)
						best_ur = point.new(x+width-1, y - 1)
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

--- Returns the maximum rectangle of a source pattern.
-- The returned pattern is in the same coordinate system as the parent.
-- @param ip pattern for rectangle finding
-- @return rectangle pattern followed by it's min, max
function subpattern.maxrectangle_pattern(ip)
	local min, max = subpattern.maxrectangle(ip)
	local sqpattern = pattern.square(max.x - min.x + 1, max.y - min.y + 1)
	sqpattern = pattern.shift(sqpattern, min.x, min.y)
	return sqpattern, min, max
end

-- Binary space partition splitting - internal function
local function bspSplit(rng, rules, min, max, outpatterns)
	local size = max - min + point.new(1,1)
	local volume = size.x*size.y
	local deviat = math.max(size.x, size.y)/math.min(size.x, size.y)

	if  deviat > rules.deviat or volume > rules.volume then
		local r1max, r2min
		local ran = 0.2*rng()+ 0.4
		if size.x > size.y then
			local xch = math.floor((size.x-1)*ran)
			r1max = min + point.new( xch, size.y-1)
			r2min = min + point.new( xch + 1, 0)
		else
			local ych = math.floor((size.y-1)*ran)
			r1max = min + point.new( size.x-1, ych)
			r2min = min + point.new( 0, ych + 1)
		end

		-- Recurse
		bspSplit(rules, min, r1max, outpatterns)
		bspSplit(rules, r2min, max, outpatterns)

	else -- just right
		local np = pattern.square(size.x, size.y)
		np = pattern.shift(np, min.x, min.y)
		table.insert(outpatterns, np)
	end
end

--- Performs a binary space partition upon a given pattern.
-- This works by finding all the contiguous rectangular volumes in the input
-- pattern and running a binary space partition on all of them. The partitions
-- are inserted into a provided table.
-- @param rules the set of rules for the BSP - threshold room asymmetry (deviat) and threshold volume (volume)
-- @param ip the pattern for which the BSP will be run over
-- @param sps a table of subpatterns into which the BSP subpatterns will be inserted
-- @param rng (optional) A random number generating table, following the signature of math.random.
function subpattern.bsp(rules, ip, sps, rng)
	assert(rules, "pattern.bsp requires a ruleset!")
	assert(rules.deviat, "pattern.bsp rules must specify a deviat")
	assert(rules.volume, "pattern.bsp rules must specify a volume")
	assert(getmetatable(ip) == pattern, "pattern.maxrectangle requires a pattern as an argument")
	if rng == nil then rng = math.random end
	if sps == nil then sps = {} end
	local available = pattern.clone(ip)
	while pattern.size(available) > 0 do -- Keep finding maxrectangles and BSP them
		local min, max = subpattern.maxrectangle(available)
		bspSplit(rng, rules, min, max, sps)
		for i=1, #sps, 1 do available = available - sps[i] end
	end
end

return subpattern
