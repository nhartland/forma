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
-- @param prototype (optional) a N*N 2D table of ones and zeros to initialise
-- pattern. If unset, an empty pattern is returned. If set with the prototype
-- table {{1,0},{0,1}} will initialise the pattern:
--  10
--  01
-- @return new pattern
function pattern.new(prototype)
    local np = {}

	np.max = point.new()
	np.min = point.new()

	np.offchar = '0'
	np.onchar  = '1'

	np.pointset = {}
    np.pointmap = {}

    np = setmetatable(np, pattern)

    if prototype ~= nil then
	    assert(type(prototype) == 'table', 'pattern.new requires either no arguments or a N*N matrix as a prototype')
        local N = #prototype
        for i=1,N,1 do
            local row = prototype[i]
	        assert(type(row) == 'table', 'pattern.new requires either no arguments or a N*N matrix as a prototype')
	        assert(#row == N, 'pattern.new requires a N*N matrix when using a prototype, you requested '..N..'*'.. #row)
            for j=1,N,1 do
                local cell = row[j]
                if cell == 1 then
                    np:insert(i-1,j-1) -- Patterns start from zero
                else
	                assert(cell == 0, 'pattern.new: invalid prototype entry (must be 1 or 0): '.. cell)
                end
            end
        end
    end

	return np
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
	if a:size() ~= b:size() then return false end
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
-- Re-returns the provided point to enable cascading.
-- e.g `pattern.new():insert(x,y)` returns a pattern with
-- a single point at (x,y).
-- @param ip pattern for point insertion
-- @param x first coordinate of new point
-- @param y second coordinate of new point
-- @return ip for method cascading
function pattern.insert( ip, x, y )
	assert(getmetatable(ip) == pattern, "pattern.insert requires a pattern as the first argument")
	assert(type(x) == 'number', 'pattern.insert requires a number for the x coordinate')
	assert(type(y) == 'number', 'pattern.insert requires a number for the y coordinate')

	local key = coordinates_to_key(x, y)
	assert(ip.pointmap[key] == nil, "pattern.insert cannot duplicate points")
	ip.pointmap[key] = point.new(x,y)
    table.insert(ip.pointset, ip.pointmap[key])

	-- reset pattern extent
	ip.max.x = math.max(ip.max.x, x)
	ip.max.y = math.max(ip.max.y, y)
	ip.min.x = math.min(ip.min.x, x)
	ip.min.y = math.min(ip.min.y, y)

    return ip
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
	assert(ip:size() > 0, 'pattern.rpoint requires a filled pattern!')

	-- Check RNG
	if rng == nil then rng = math.random end
	local ipoint = rng(#ip.pointset)
	return point.clone(ip.pointset[ipoint])
end

--- Pattern centre of mass point method.
-- Returns the point closes to the mass-centre of the pattern.
-- @param ip pattern for centre of mass retrieval
-- @return the centre of mass point in the pattern
function pattern.com(ip)
	assert(getmetatable(ip) == pattern, "pattern.com requires a pattern as the first argument")
	assert(ip:size() > 0, 'pattern.com requires a filled pattern!')

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
-- @return pa:size() > pb:size()
function pattern.size_sort(pa, pb)
    return pa:size() > pb:size()
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
	local patterns = {...} table.sort(patterns, function(a,b) return a:size() < b:size() end)
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

--- Enlarges a pattern by a specific factor
-- Based on an input pattern, this method returns a new pattern in which each
-- input cell is converted to a f*f cell block. The returned pattern is
-- therfore an 'enlarged' version of the input pattern, by a scale factor of
-- 'f' in both x and y.
-- @param ip pattern to be enlarged
-- @param f factor of enlargement
-- @return enlarged pattern
function pattern.enlarge(ip, f)
	assert(getmetatable(ip) == pattern, "pattern.enlarge requires a pattern as the first argument")
	assert(type(f) == 'number', 'pattern.enlarge requires a number as the enlargement factor')

    local ep = pattern.new()
    for _, iv in ipairs(ip:pointlist()) do
        local sv = f*iv
        for i=0, f-1, 1 do
            for j=0, f-1, 1 do
                ep:insert(sv.x+i, sv.y+j)
            end
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
	assert(a:size() > 0 , "pattern.packtile requires a non-empty pattern as a first argument")
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
