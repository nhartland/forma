local noise  = {}
local rutils = require('forma.utils.random')

--- Generates a permutation vector with a random seed
function noise.init(rng)
    local p = {}
    for i = 1, 256, 1 do
        p[i] = i - 1
    end
    -- Shuffle permutation vector randomly
    rutils.shuffle(p, rng)
    return p
end

-- Adapted from https://github.com/max1220/lua-perlin [MIT License]
local floor = math.floor

local function permute(p, x, y) return p[(p[y % 256 + 1] + x) % 256 + 1] end
local function lin_inter(x, y, s) return x + s * (y - x) end
local function smooth_inter(x, y, s) return lin_inter(x, y, s * s * (3 - 2 * s)) end

local function noise2d(p, x, y)
    local x_int  = floor(x)
    local y_int  = floor(y)
    local x_frac = x - x_int
    local y_frac = y - y_int
    local s      = permute(p, x_int, y_int)
    local t      = permute(p, x_int + 1, y_int)
    local u      = permute(p, x_int, y_int + 1)
    local v      = permute(p, x_int + 1, y_int + 1)
    local low    = smooth_inter(s, t, x_frac)
    local high   = smooth_inter(u, v, x_frac)
    return smooth_inter(low, high, y_frac)
end

--- Internal perlin noise function
-- Takes as arguments p: permutation vector, (x, y) coordinates, frequency and
-- sampling depth. Returns a noise value [0,1].
function noise.perlin(p, x, y, freq, depth)
    local xa = x * freq;
    local ya = y * freq;
    local amp = 1.0;
    local fin = 0;
    local div = 0.0;

    for _ = 1, depth, 1 do
        div = div + 256 * amp;
        fin = fin + noise2d(p, xa, ya) * amp;
        amp = amp / 2;
        xa = xa * 2;
        ya = ya * 2;
    end

    return fin / div;
end

return noise
