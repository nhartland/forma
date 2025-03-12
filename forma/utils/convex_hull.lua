local convex_hull = {}

--- Compute the points lying on the convex hull of a pattern.
-- This computes the points lying on a pattern's convex hull with Andrew's
-- monotone chain convex hull algorithm. 
-- @param ip input pattern for generating the convex hull.
-- @return A clockwise-ordered table of cells on the convex hull.
function convex_hull.points(ip)
    -- Adapted from sixFinger's implementation at:
    -- https://gist.github.com/sixFingers/ee5c1dce72206edc5a42b3246a52ce2e
    assert(ip:size() > 0,
        "convex_hull.points: input pattern must have at least one cell")
    local function cross(p, q, r)
        return (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    end
    -- Build and sort list of existing cells
    local points = ip:cell_list()
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
    return upper
end

return convex_hull
