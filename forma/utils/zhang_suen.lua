--- Utilites for the Zhang-Suen thinning algorithm
--
-- The Zhang-Suen thinning algorithm is a two-pass algorithm for thinning
-- binary images. It is used to reduce the width of lines in a binary image
-- while preserving the overall shape and connectivity of the lines. The
-- algorithm works by iteratively removing pixels from the image based on
-- certain conditions until no more pixels can be removed.


-- The algorithm works only on a Moore neighbourhood
local moore_neighborhood = require("forma.neighbourhood").moore()

local zhang_suen = {}

function zhang_suen.neighbors(p, x, y)
    local result = {}
    for _, delta in ipairs(moore_neighborhood) do
        table.insert(result, p:has_cell(x + delta.x, y + delta.y))
    end
    return result
end

-- Returns number of active neighbors and number of 0→1 transitions
function zhang_suen.neighbor_info(nb)
    -- nb is an array of 8 booleans, each true=(occupied), false=(empty)
    -- B = count of active neighbors
    local B = 0
    for i = 1, 8 do
        if nb[i] then B = B + 1 end
    end
    -- A = number of transitions from inactive→active in the sequence nb[1..8, wrap to 1]
    local A = 0
    for i = 1, 8 do
        local i_next = (i % 8) + 1
        if (not nb[i]) and nb[i_next] then
            A = A + 1
        end
    end
    return B, A
end

function zhang_suen.passA_conditions(nb)
    local B, A = zhang_suen.neighbor_info(nb)
    -- Conditions:
    -- 1) 2 <= B <= 6
    -- 2) A == 1
    -- 3) nb[1]*nb[3]*nb[5] == 0  (i.e. top * right * bottom == false)
    -- 4) nb[3]*nb[5]*nb[7] == 0  (i.e. right * bottom * left == false)
    if B >= 2 and B <= 6 and A == 1 then
        if (nb[1] and nb[3] and nb[5]) == false and
            (nb[3] and nb[5] and nb[7]) == false then
            return true
        end
    end
    return false
end

function zhang_suen.passB_conditions(nb)
    local B, A = zhang_suen.neighbor_info(nb)
    -- Conditions for pass B:
    -- 1) 2 <= B <= 6
    -- 2) A == 1
    -- 3) nb[1]*nb[3]*nb[7] == 0  (top * right * left == false)
    -- 4) nb[1]*nb[5]*nb[7] == 0  (top * bottom * left == false)
    if B >= 2 and B <= 6 and A == 1 then
        if (nb[1] and nb[3] and nb[7]) == false and
            (nb[1] and nb[5] and nb[7]) == false then
            return true
        end
    end
    return false
end

-- Utility function to return a Zhang-Suen pass
-- Returns true if the pass made a change, false otherwise
function zhang_suen.pass(p, conditions, change_callback)
    local to_remove = {}
    for x, y in p:cell_coordinates() do
        local nb = zhang_suen.neighbors(p, x, y)
        if conditions(nb) then
            to_remove[#to_remove + 1] = { x, y }
        end
    end
    if #to_remove > 0 then
        change_callback(to_remove)
        return true
    end
    return false
end

return zhang_suen
