local rutils = {}

--- Returns a shuffled copy of the input table (non-destructive).
-- @param tbl The table to copy and shuffle.
-- @param rng (optional) Random number generator; defaults to math.random.
-- @return A new shuffled table.
function rutils.shuffled_copy(tbl, rng)
    if rng == nil then rng = math.random end
    local shuffled_tbl = {}
    for i = 1, #tbl do
        local j = rng(1, i)
        if j ~= i then
            shuffled_tbl[i] = shuffled_tbl[j]
        end
        shuffled_tbl[j] = tbl[i]
    end
    return shuffled_tbl
end

--- Shuffles the input table in-place (destructive).
-- @param tbl The table to shuffle in-place.
-- @param rng (optional) Random number generator; defaults to math.random.
function rutils.shuffle(tbl, rng)
    if rng == nil then rng = math.random end
    for i = #tbl, 2, -1 do
        local j = rng(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

return rutils
