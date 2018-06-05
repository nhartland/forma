-- Utility functions - for internal use.

local util = {}

--- Fisher-Yates shuffle.
-- Performs an in-place shuffle of the input table
-- @param table the table to be shuffled.
-- @param rng a random number generator (syntax as per math.random).
function util.fisher_yates(table, rng)
  if rng == nil then rng = math.random end
  for i=#table,1,-1 do
    local j = rng(#table)
    table[i], table[j] = table[j], table[i]
  end
end

return util
