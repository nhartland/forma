--- Pattern tables.
-- @module forma.pattern
local pattern = {}

local thispath = select('1', ...):match(".+%.") or ""
local neighbourhood = require(thispath .. 'neighbourhood')
local point         = require(thispath .. 'point')

--- Pattern indexing
-- For enabling syntax sugar pattern:method
pattern.__index = pattern

-------------------------- Pattern creation ------------------------------

--- Initialise a forma.pattern.
-- @return new pattern
function pattern.new()
	local self = {}

	self.max = point.new()
	self.min = point.new()

	self.offchar = '0'
	self.onchar  = '1'

    self.size = 0 -- Compatibility
	self.pointset = {}
    self.pointmap = {}
	return setmetatable(self, pattern)
end


--- Basic square pattern
-- @param x size in x
-- @param y size in y (default y = x)
-- @return square forma.pattern of size {x,y}
function pattern.square(x,y)
	assert(type(x) == "number")
	y = y ~= nil and y or x

	local sqPattern = pattern.new()
	for i=0, x-1, 1 do
		for j=0, y-1, 1 do
			pattern.insert(sqPattern, i,j)
		end
	end

	return sqPattern
end

--- Basic circular pattern
-- http://willperone.net/Code/codecircle.php suggests a faster method
-- might be worth a look
-- @param r the radius of the circle to be drawn
-- @return circular forma.pattern of radius r
function pattern.circle(r)
	assert(type(r) == 'number', 'pattern.circle requires a number for the radius')
	assert(r >= 0, 'pattern.circle requires a positive number for the radius')

    local cp = pattern.new()
    local x, y = 0, r
    local p = 3 - 2*r
    if r == 0 then return cp end

    -- insert_over needed here because this algorithm duplicates some points
    while (y >= x) do
        pattern.insert_over(cp, -x, -y)
        pattern.insert_over(cp, -y, -x)
        pattern.insert_over(cp,  y, -x)
        pattern.insert_over(cp,  x, -y)
        pattern.insert_over(cp, -x,  y)
        pattern.insert_over(cp, -y,  x)
        pattern.insert_over(cp,  y,  x)
        pattern.insert_over(cp,  x,  y)

        x = x + 1
        if p < 0 then
            p = p + 4*x + 6
        else
            y = y - 1
            p = p + 4*(x - y) + 10
        end
    end
    return cp
end

-------------------------- Pattern methods -------------------------------

--- Pattern tostring.
-- Prints the stored pattern to string, using pattern.onchar
-- for points and pattern.offchar for unactivated points
-- @return pattern as string
function pattern.__tostring(self)
	local string = ' '

	-- Header
	for _ = self.min.x, self.max.x, 1 do
		string = string .. '.'
	end
	string = string .. '\n'

	for y = self.min.y, self.max.y, 1 do
		string = string .. '.'
		for x = self.min.x, self.max.x, 1 do
            string = string .. (self:has_cell(x,y) and self.onchar or self.offchar)
		end
		string = string .. '\n'
	end

	return string
end

--- Pattern addition
-- @param a first pattern to be added
-- @param b second pattern to be added
-- @return new forma.pattern consisting of the superset of patterns a and b
function pattern.__add(a,b)
	assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
	assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")

	local c = pattern.clone(a)
	for i=1, #b.pointset, 1 do
        local v = b.pointset[i]
		if c:has_cell(v.x, v.y) == false then
			pattern.insert(c, v.x, v.y)
		end
	end

	return c
end

--- Pattern subtraction
-- @param a base pattern
-- @param b pattern to be subtracted from a
-- @return new forma.pattern consisting of the subset of points in a which are not in b
function pattern.__sub(a,b)
	assert(getmetatable(a) == pattern, "pattern addition requires a pattern as the first argument")
	assert(getmetatable(b) == pattern, "pattern addition requires a pattern as the second argument")

	local c = pattern.new()
	c.onchar = a.onchar
	c.offchar = a.offchar

	for i=1, #a.pointset, 1 do
        local v = a.pointset[i]
		if b:has_cell(v.x, v.y) == false then
			pattern.insert(c, v.x, v.y)
		end
	end

	return c
end

--- Pattern equality
-- @param a first pattern for equality check
-- @param b second pattern for equality check
-- @return true if patterns are identical, false if not
function pattern.__eq(a,b)
	assert(getmetatable(a) == pattern, "pattern equality test requires a pattern as the first argument")
	assert(getmetatable(b) == pattern, "pattern equality test requires a pattern as the second argument")
	-- Easy and fast checks
	if pattern.size(a) ~= pattern.size(b) then return false end
	if a.min.x ~= b.min.x then return false end
	if a.min.y ~= b.min.y then return false end
	if a.max.x ~= b.max.x then return false end
	if a.max.y ~= b.max.y then return false end
	-- Slower checks
	for i=1, #a.pointset, 1 do
        local v = a.pointset[i]
		if b:has_cell(v.x, v.y) == false then return false end
	end
	return true
end

-------------------------- Pattern methods -------------------------------

--- Copy an existing forma.pattern.
-- @param ip input pattern for cloning
-- @return new forma.pattern copy of ip
function pattern.clone(ip)
	assert(getmetatable(ip) == pattern, "pattern cloning requires a pattern as the first argument")
	local self = pattern.new()

	for i=1, #ip.pointset, 1 do
        local v = ip.pointset[i]
		pattern.insert(self, v.x, v.y)
	end

    -- This is important, keep the stored limits, not the actual ones
	self.max = point.new(ip.max.x, ip.max.y)
	self.min = point.new(ip.min.x, ip.min.y)

	self.offchar = ip.offchar
	self.onchar  = ip.onchar

	return self
end

--- Determine the number of points in a pattern
-- @param ip pattern for size check
function pattern.size( ip )
    return #ip.pointset
end

-- Return a copy of the internal pointset
-- @param ip pattern for copying
function pattern.pointlist(ip)
    local newlist = {}
    for i=1, #ip.pointset, 1 do
        table.insert(newlist, ip.pointset[i])
    end
    return newlist
end

--- Generate the pointmap key from coordinates
-- This handles the wierd -0 behaviour
local function coordinates_to_key(x, y)
    if x == -0 then x = 0 end
    if y == -0 then y = 0 end
	return x..':'..y
end

--- Point insertion into a pattern.
-- @param ip pattern for point insertion
-- @param x first coordinate of new point
-- @param y second coordinate of new point
function pattern.insert( ip, x, y )
	assert(getmetatable(ip) == pattern, "pattern.insert requires a pattern as the first argument")
	assert(type(x) == 'number', 'pattern.insert requires a number for the x coordinate')
	assert(type(y) == 'number', 'pattern.insert requires a number for the y coordinate')

	local key = coordinates_to_key(x, y)
	assert(ip.pointmap[key] == nil, "pattern.insert cannot duplicate points")
	ip.pointmap[key] = point.new(x,y)
    table.insert(ip.pointset, ip.pointmap[key])
    ip.size = ip.size + 1

	-- reset pattern extent
	ip.max.x = math.max(ip.max.x, x)
	ip.max.y = math.max(ip.max.y, y)
	ip.min.x = math.min(ip.min.x, x)
	ip.min.y = math.min(ip.min.y, y)
end

--- Point insertion into a pattern without failing if point already exists.
-- This function differs only from pattern.insert by first checking if the point
-- already exists in the pointset. Therefore bypassing the assert.
-- @param ip pattern for point insertion
-- @param x first coordinate of new point
-- @param y second coordinate of new point
-- @return true if the insert was sucessful, false if not
function pattern.insert_over( ip, x, y )
    if ip:has_cell(x, y) == false then
       pattern.insert(ip, x, y)
       return true
    end
    return false
end

--- Check for occupied cell
-- @param ip pattern for point check
-- @param x first coordinate of point to be returned
-- @param y second coordinate of point to be returned
-- @return True if pattern `ip` includes the point at (x,y), False otherwise
function pattern.has_cell(ip, x, y)
	assert(getmetatable(ip) == pattern, "pattern.has_cell requires a pattern as the first argument")
	assert(type(x) == 'number', 'pattern.has_cell requires a number for the x coordinate')
	assert(type(y) == 'number', 'pattern.has_cell requires a number for the y coordinate')

	local key = coordinates_to_key(x, y)
	return ip.pointmap[key] ~= nil
end

--- Pattern random point method.
-- Returns a point at random from the pattern.
-- @param ip pattern for random point retrieval
-- @param rng (optional )A random number generating table, following the signature of math.random.
-- @return a random point in the pattern
function pattern.rpoint(ip, rng)
	assert(getmetatable(ip) == pattern, "pattern.rpoint requires a pattern as the first argument")
	assert(pattern.size(ip) > 0, 'pattern.rpoint requires a filled pattern!')

	-- Check RNG
	if rng == nil then rng = math.random end
	local ipoint = rng(#ip.pointset)
	return point.clone(ip.pointset[ipoint])
end

--- Random pattern method.
-- For a given domain, returns a pattern sampling uniformly from it with probability pr.
-- @param domain pattern for generating a random pattern on
-- @param pr the probability of sampling a point in the domain
-- @param rng (optional )A random number generating table, following the signature of math.random.
-- @return a pattern sampled uniformly from domain with probability pr
function pattern.random(domain, pr, rng)
	assert(getmetatable(domain) == pattern, "pattern.random requires a pattern as the first argument")
	assert(type(pr) == 'number', 'pattern.random requires a number for the probability')
	assert(pr >= 0 and pr <= 1 , 'pattern.random requires a probability 0 <= p <= 1')
	if rng == nil then rng = math.random end
	local p = pattern.new()
    for i = 1, #domain.pointset, 1 do
		if rng() < pr then
            local rpoint = domain.pointset[i]
			pattern.insert(p, rpoint.x, rpoint.y)
		end
	end
	return p
end

--- Pattern centre of mass point method.
-- Returns the point closes to the mass-centre of the pattern.
-- @param ip pattern for centre of mass retrieval
-- @return the centre of mass point in the pattern
function pattern.com(ip)
	assert(getmetatable(ip) == pattern, "pattern.com requires a pattern as the first argument")
	assert(pattern.size(ip) > 0, 'pattern.com requires a filled pattern!')

	local com = point.new()
	local allpoints = ip.pointset
	for i=1, #allpoints, 1 do com = com + allpoints[i] end
	local comx, comy = com.x / #allpoints, com.y / #allpoints

	local function distance_to_com(a,b)
		local adist = (a.x-comx)*(a.x-comx) + (a.y-comy)*(a.y-comy)
		local bdist = (b.x-comx)*(b.x-comx) + (b.y-comy)*(b.y-comy)
		return adist < bdist
	end
	table.sort(allpoints, distance_to_com)
	return point.clone(allpoints[1])
end
-------------------- Sorting helpers -------------------------------------

--- Size comparator for two patterns.
-- Useful for table.sort to rank patterns by size (number of points)
-- @param pa the first pattern for comparison
-- @param pb the second pattern for comparison
-- @return pa.size > pb.size
function pattern.size_sort(pa, pb)
    return pa.size > pb.size
end

-------------------- Patterns based on other patterns --------------------

--- Generate a pattern consisting of edge tiles to a provided pattern.
-- Note that this will *not* necessarily generate a hull, it just returns the
-- inactive neighbours of the provided pattern.
-- @param ip pattern for which the edges should be calculated
-- @param dirs defines which neighbourhood to scan in to determine edges (default 8/moore)
-- @return the forma.pattern represeting the edge of ip
function pattern.edge(ip, dirs)
	assert(getmetatable(ip) == pattern, "pattern.edge requires a pattern as the first argument")

	local ep = pattern.new()
	ep.onchar  = ip.onchar
	ep.offchar = ip.offchar

	-- Default is eight
	dirs = dirs or neighbourhood.moore()
	for i=1, #ip.pointset, 1 do
		for j=1, #dirs, 1 do
			local vpr = ip.pointset[i] + dirs[j]
			if ip:has_cell(vpr.x, vpr.y) == false then
				if ep:has_cell(vpr.x, vpr.y) == false then
					pattern.insert(ep, vpr.x, vpr.y)
				end
			end
		end
	end

	return ep
end

--- Generate a pattern consisting of surface to a provided pattern.
-- This is simmilar to pattern.edge, but will return tiles that are /internal/
-- to the provided pattern.
-- @param ip pattern for which the surface should be calculated
-- @param dirs defines which neighbourhood to scan in to determine edges (default 8/moore)
-- @return the forma.pattern represeting the surface of ip
function pattern.surface(ip, dirs)
	assert(getmetatable(ip) == pattern, "pattern.edge requires a pattern as the first argument")

	local sp = pattern.new()
	sp.onchar  = ip.onchar
	sp.offchar = ip.offchar

	-- Default is eight
	dirs = dirs or neighbourhood.moore()
	for i=1, #ip.pointset, 1 do
		local foundEdge = false
        local v = ip.pointset[i]
		for j=1, #dirs, 1 do
			local vpr = v + dirs[j]
			if ip:has_cell(vpr.x, vpr.y) == false then
				foundEdge = true
				break
			end
		end

		if foundEdge == true then
			pattern.insert(sp, v.x, v.y)
		end
	end

	return sp
end

--- Generate a pattern consisting of the intersection of existing patterns
-- @param ... patterns for intersection calculation
-- @return the forma.pattern representing the intersection of the arguments
function pattern.intersection(...)
	local patterns = {...} table.sort(patterns, function(a,b) return pattern.size(a) < pattern.size(b) end)
    assert(#patterns > 1, "pattern.intersection requires at least two patterns as arguments")
	local intpat = pattern.clone(patterns[1])
	for i=2, #patterns, 1 do
        local tpattern = patterns[i]
		assert(getmetatable(tpattern) == pattern, "pattern.intersection requires a pattern as an argument")
		local newint = pattern.new()
		for j=1, #intpat.pointset, 1 do
            local v2 = intpat.pointset[j]
			if tpattern:has_cell(v2.x, v2.y) then
				pattern.insert(newint, v2.x, v2.y)
			end
		end
		intpat = newint
	end
	return intpat
end

--- Generate a pattern consisting of the sum of existing patterns
-- @param ... patterns for summation
-- @return the forma.pattern represeting the sum of the arguments
function pattern.sum(...)
    local patterns = {...}
    assert(#patterns > 1, "pattern.sum requires at least two patterns as arguments")
	local sum = pattern.clone(patterns[1])
	for i=2, #patterns, 1 do
        local v = patterns[i]
		assert(getmetatable(v) == pattern, "pattern.sum requires a pattern as an argument")
		for j=1, #v.pointset, 1 do
            local v2 = v.pointset[j]
			if sum:has_cell(v2.x, v2.y) == false then
				pattern.insert(sum, v2.x, v2.y)
			end
		end
	end
	return sum
end

----------------------------- Pattern modifiers --------------------------

--- Re-evaluate pattern limits.
-- The limits are usually set to the maximum extent
-- (ignoring removed points), to maintain consistency with subpatterns.
-- @param ip pattern for which the limits should be re-evaluated.
-- @return the shift in origin and maximum as forma.points - dmin, dmax
function pattern.limiteval(ip)

	local nmin = nil
	local nmax = nil
	for i=1, #ip.pointset, 1 do
        local v = ip.pointset[i]
		if nmin == nil or nmax == nil then
			nmin = point.clone(v)
			nmax = point.clone(v)
		else
			nmin.x = math.min(nmin.x, v.x)
			nmin.y = math.min(nmin.y, v.y)
			nmax.x = math.max(nmax.x, v.x)
			nmax.y = math.max(nmax.y, v.y)
		end
	end

	local minshift = ip.min - nmin
	local maxshift = ip.max - nmax

	ip.min = nmin
	ip.max = nmax

	return minshift, maxshift
end

--- Normalise a pattern such that it's origin is (0,0)
-- @param ip pattern to be normalised
-- @return a new normalised forma.pattern
function pattern.normalise(ip)
	assert(getmetatable(ip) == pattern, "pattern.normalise requires a pattern as the first argument")
	return pattern.shift(ip, -ip.min.x, -ip.min.y)
end

--- Shift a pattern by (x,y)
-- @param ip pattern to be shifted
-- @param x first coordinate of shift
-- @param y second coordinate of shift
-- @return a new forma.pattern consisting of ip shifted by (x,y)
function pattern.shift(ip, x, y)
	assert(getmetatable(ip) == pattern, "pattern.shift requires a pattern as the first argument")
	assert(type(x) == 'number', 'pattern.shift requires a number for the x coordinate')
	assert(type(y) == 'number', 'pattern.shift requires a number for the y coordinate')

	local sp = pattern.new()
	sp.onchar = ip.onchar
	sp.offchar = ip.offchar

	for i=1, #ip.pointset, 1 do
        local v = ip.pointset[i]
		pattern.insert(sp, v.x+x, v.y+y)
	end

	return sp
end

--- Smear a pattern out by converting all points to blocks of size ss
-- @param ip pattern for smearing
-- @param ss size of pattern smear
-- @return smeared pattern
function pattern.smear(ip, ss)
	assert(getmetatable(ip) == pattern, "pattern.smear requires a pattern as the first argument")
	assert(type(ss) == 'number', 'pattern.smear requires a number as the smearsize')

	local sp = pattern.new()
	sp.onchar = ip.onchar
	sp.offchar = ip.offchar

	local block = pattern.square(ss)
	for i=1, #ip.pointset, 1 do
		for j=1, #block.pointset, 1 do
			local iv = ip.pointset[i] + block.pointset[j]
			if sp:has_cell(iv.x,iv.y) == false then
				pattern.insert(sp, iv.x, iv.y)
			end
		end
	end

	return sp
end

--- Inverse operation of pattern.smear.
-- Note that the process is not invertible, the best you can do is return
-- a pattern, which under smearing, will give you the original pattern.
-- @param ip pattern for unsmearing
-- @param ss size of pattern smear
-- @return unsmeared pattern
function pattern.unsmear(ip, ss)
	assert(getmetatable(ip) == pattern, "pattern.unsmear requires a pattern as the first argument")
	assert(type(ss) == 'number', 'pattern.unsmear requires a number as the smearsize')

	local block  = pattern.square(ss)
	local remove = pattern.new()

	local foundTile = true
	while foundTile == true do
		foundTile = false
		for i=1, #ip.pointset, 1 do
            local v = ip.pointset[i]
            if remove:has_cell(v.x, v.y) == false then
			    for j=1, #block.pointset, 1 do
                    local iv = v + block.pointset[j]
                    if ip:has_cell(iv.x, iv.y) == false then
                       pattern.insert(remove, v.x, v.y)
                       foundTile = true
                       break
                    end
			    end
            end
		end
	end
    local unsmeared = ip - remove
	return unsmeared
end

--- Enlarges a pattern by a specific factor
-- @param ip pattern to be enlarged
-- @param f factor of enlargement
-- @return enlarged pattern
function pattern.enlarge(ip, f)
	assert(getmetatable(ip) == pattern, "pattern.enlarge requires a pattern as the first argument")
	assert(type(f) == 'number', 'pattern.enlarge requires a number as the enlargement factor')

	local block = pattern.square(f)
	local ep = pattern.new()
	ep.onchar = ip.onchar
	ep.offchar = ip.offchar

	for i=1, #ip.pointset, 1 do
		for j=1, #block.pointset, 1 do
			local iv = f*ip.pointset[i] + block.pointset[j]
			pattern.insert(ep, iv.x, iv.y)
		end
	end

	return ep
end

-- Reflect a pattern vertically
-- @param ip pattern for reflection
-- @return pattern which is reflected vertically
function pattern.vreflect(ip)
	assert(getmetatable(ip) == pattern, "pattern.vreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
	for i=1, #ip.pointset, 1 do
        local new_y = 2*ip.max.y - ip.pointset[i].y + 1
        pattern.insert(np, ip.pointset[i].x, new_y)
    end
    return np
end


-- Reflect a pattern horizontally
-- @param ip pattern for reflection
-- @return pattern which is reflected horizontally
function pattern.hreflect(ip)
	assert(getmetatable(ip) == pattern, "pattern.hreflect requires a pattern as the first argument")
    local np = pattern.clone(ip)
	for i=1, #ip.pointset, 1 do
        local new_x = 2*ip.max.x - ip.pointset[i].x + 1
        pattern.insert(np, new_x, ip.pointset[i].y)
    end
    return np
end

--------------------------------------------------------------------------

--- Returns a point where one pattern can fit into another.
-- This operation does not allow for rotations
-- @param a the tile to be packed
-- @param b the domain which we are searching for packing solutions
-- @return a point in b where a can be placed
function pattern.packtile(a,b)
	assert(getmetatable(a) == pattern, "pattern.packtile requires a pattern as a first argument")
	assert(getmetatable(b) == pattern, "pattern.packtile requires a pattern as a second argument")
	assert(pattern.size(a) > 0 , "pattern.packtile requires a non-empty pattern as a first argument")
	-- point to fix coordinate systems
	local hinge = pattern.rpoint(a)
	-- Loop over possible positions in b
	for i=1, #b.pointset, 1 do
		local coordshift = b.pointset[i] - hinge -- Get coordinate transformation
		local tiles = true
		for j=1, #a.pointset, 1 do
			local shifted = a.pointset[j] + coordshift
			if b:has_cell(shifted.x, shifted.y) == false then
				tiles = false
				break
			end
		end
		if tiles == true then
			return coordshift
		end
	end
	return nil
end

--- Center-weighted version of pattern.packtile.
-- Tries to fit pattern a into as close as possible to pattern b's centre
-- @param a the tile to be packed
-- @param b the domain which we are searching for packing solutions
-- @return a point in b where a can be placed, nil if no solution found
function pattern.packtile_centre(a,b)
	-- point to fix coordinate systems
	local hinge = pattern.com(a)
	local com   = pattern.com(b)
	local allpoints = b.pointset
	local function distance_to_com(k,j)
		local adist = (k.x-com.x)*(k.x-com.x) + (k.y-com.y)*(k.y-com.y)
		local bdist = (j.x-com.x)*(j.x-com.x) + (j.y-com.y)*(j.y-com.y)
		return adist < bdist
	end
	table.sort(allpoints, distance_to_com)
	for i=1,#allpoints,1 do
		local coordshift = allpoints[i] - hinge -- Get coordinate transformation
		local tiles = true
		for j=1, #a.pointset, 1 do
			local shifted = a.pointset[j] + coordshift
			if b:has_cell(shifted.x, shifted.y) == false then
				tiles = false
				break
			end
		end
		if tiles == true then
			return coordshift
		end
	end
	return nil
end

return pattern
