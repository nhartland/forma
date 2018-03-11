--- geometry.lua
-- Some examples of geometry by rasterisation

local pattern = require('pattern')

local tp = pattern.new()
local radii = {0,1,2,3,4,5,15}
for _, r in ipairs(radii) do
    tp = tp + pattern.circle(r)
end

tp.onchar='X'
tp.offchar=' '
print (tp)
