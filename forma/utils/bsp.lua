local bsp = {}
local cell = require('forma.cell')
local primitives = require('forma.primitives')

-- Find the (lower-left and upper-right) coordinates of the maximal contiguous
-- rectangular area within a pattern.
-- @param ip the input pattern.
-- @return the minimum and maxium coordinates of the area.
function bsp.max_rectangle_coordinates(ip)
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

-- Binary space partitioning - internal function
function bsp.split(min, max, th_volume, mp)
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
        bsp.split(min, r1max, th_volume, mp)
        bsp.split(r2min, max, th_volume, mp)
    else -- Passes threshold volume
        local np = primitives.square(size.x, size.y):translate(min.x, min.y)
        mp:insert(np)
    end
end


return bsp
