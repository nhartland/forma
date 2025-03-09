local noise = {}
local rutils        = require('forma.utils.random')

--- Generates a permutation vector with a random seed
function noise.init(rng)
    local p = {}
    for i = 0, 255, 1 do
        p[i] = i
    end
    -- Shuffle permutation vector randomly
    rutils.shuffle(p, rng)
    return p
end

--- Internal perlin noise function
-- Takes as arguments p: permutation vector, (x, y) coordinates, frequency and
-- sampling depth. Returns a noise value [0,1].
function noise.perlin(p, x, y, freq, depth)
    -- Adapted from https://github.com/max1220/lua-perlin [MIT License]
    local function permute(_x, _y) return p[(p[_y % 256] + _x) % 256]; end
    local function lin_inter(_x, _y, s) return _x + s * (_y - _x) end
    local function smooth_inter(_x, _y, s) return lin_inter(_x, _y, s * s * (3 - 2 * s)) end

    local function noise2d(_x, _y)
        local x_int = math.floor(_x);
        local y_int = math.floor(_y);
        local x_frac = _x - x_int;
        local y_frac = _y - y_int;
        local s = permute(x_int, y_int);
        local t = permute(x_int + 1, y_int);
        local u = permute(x_int, y_int + 1);
        local v = permute(x_int + 1, y_int + 1);
        local low = smooth_inter(s, t, x_frac);
        local high = smooth_inter(u, v, x_frac);
        return smooth_inter(low, high, y_frac);
    end

    local xa = x * freq;
    local ya = y * freq;
    local amp = 1.0;
    local fin = 0;
    local div = 0.0;

    for _ = 1, depth, 1 do
        div = div + 256 * amp;
        fin = fin + noise2d(xa, ya) * amp;
        amp = amp / 2;
        xa = xa * 2;
        ya = ya * 2;
    end

    return fin / div;
end

return noise
