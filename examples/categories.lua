-- voronoi.lua
-- Demonstration of voronoi tesselation 

local point   = require('point')
local pattern = require('pattern')
math.randomseed(os.time())

-- Generate a random pattern and its voronoi tesselation
local sq = pattern.square(40,20)
local rn = pattern.random(sq, 0.01)
local segments = pattern.voronoi(rn, sq, point.euclidean)

-- Print out the segments to a map
for i=sq.min.y, sq.max.y,1 do
    local string = ''
    for j=sq.min.x, sq.max.x,1 do
        local token = ' '
        for k,v in ipairs(segments) do
        if pattern.point(v, j, i) ~= nil then token = string.char(k+47) end end
        string = string .. token
    end 
    print(string)
end
