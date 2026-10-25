--- Simple two-dimensional affine transformations.
---
--- A transform is a affine map applied to a 2-d vector v:
---
---     v' = A.v + t
---
--- where
---     v: the original vector
---     v': the transformed vector
---     t: a translation vector
---     A = ( a, b )
---         ( c, d )
---      : the tranform matrix
---
---@class forma.transform
---@field name string
---@field a integer
---@field b integer
---@field c integer
---@field d integer
---@field tx integer
---@field ty integer
local transform = {}
transform.__index = transform

--- Create a new transform.
---
--- The transformation matrix A must have determinant of ±1.
--- This is in order to ensure that the transformation preserves
--- the overall number of activated cells.
---
--- ```lua
--- -- The identity transform
--- local I = transform.new("identity", 1,0,0,1)
--- ```
---@param name string
---@param a integer
---@param b integer
---@param c integer
---@param d integer
---@param _tx? integer
---@param _ty? integer
---@return forma.transform o new transform Ax + t
function transform.new(name, a, b, c, d, _tx, _ty)
    local tx = _tx or 0
    local ty = _ty or 0
    assert(math.floor(a) == a, "forma.transform.new: requires an integer for a")
    assert(math.floor(b) == b, "forma.transform.new: requires an integer for b")
    assert(math.floor(c) == c, "forma.transform.new: requires an integer for c")
    assert(math.floor(d) == d, "forma.transform.new: requires an integer for d")
    assert(math.floor(tx) == tx, "forma.transform.new: requires an integer for tx")
    assert(math.floor(ty) == ty, "forma.transform.new: requires an integer for ty")
    local op = {
        name = name,
        a = a,
        b = b,
        c = c,
        d = d,
        tx = tx,
        ty = ty
    }
    op = setmetatable(op, transform)
    assert(
        math.abs(a * d - b * c) == 1,
        "forma.transform.new: linear part of the transform must have determinant ± 1"
    )
    return op
end

--- Create a pure translation.
---
--- This function is a helper to create a simple translation.
---
--- ```lua
--- local g = transform.translate(5,6)
--- ```
---@param tx integer
---@param ty integer
---@return forma.transform o new transform Ix + t
function transform.translate(tx, ty)
    assert(math.floor(tx) == tx, "transform.translate: requires an integer for tx " .. tx)
    assert(math.floor(ty) == ty, "transform.translate: requires an integer for ty " .. ty)
    return transform.new("translate(" .. tx .. "," .. ty .. ")", 1, 0, 0, 1, tx, ty)
end

--- Transform about a specified point.
---
--- This function is helpful when trying to translate *about a point*, e.g
--- rotation about the midpoint of a pattern. It transforms the origin to the
--- to the given point, runs the transformation, then transforms back.
---
--- A quirk of the algebra means that this can (dependent on the transform)
--- handle half-integer translations, e,g
---
---     g:about(1.5,1.5),
---
--- enabling transformations about the midpoint of a pattern even when that
--- falls in the centre of a cell. This requires that the resulting transform
--- maps origin cells to another cell location.
---
--- ```lua
--- local g = transform.translate(5,6):about(1,1)
--- ```
---@param g forma.transform
---@param x integer first coordinate to transform about
---@param y integer second coordinate to transform about
---@return forma.transform
function transform.about(g, x, y)
    local nx = (g.a - 1) * x + g.b * y
    local ny = g.c * x + (g.d - 1) * y
    assert(math.floor(nx) == nx and math.floor(ny) == ny,
        "transform.about: " .. g.name .. " about (" .. x .. "," .. y .. ") does not map the lattice onto itself")
    return transform.translate(-math.floor(nx), -math.floor(ny)) * g
end

--- Apply a transform to a vector.
---
--- Acts the transformation `o` on the vector `(x, y)`
---
--- ```lua
--- local vpx, vpy = o(v.x, v.y)
--- ```
---@param g forma.transform
---@param x integer first coordinate of the vector
---@param y integer second coordinate of the vector
---@return integer xp transformed first coordinate
---@return integer yp transformed second coordinate
function transform.__call(g, x, y)
    return g.a * x + g.b * y + g.tx, g.c * x + g.d * y + g.ty
end

--- Render the transform to a string
---
---@param g forma.transform the transform to print
---@return string name the name of the transform
function transform.__tostring(g)
    return "T[" .. g.name .. "]"
end

--- Compose two transforms into a single transform
---
---@param g forma.transform first transform
---@param h forma.transform second transform
---@return forma.transform c a new transform composing (g.h)
function transform.__mul(g, h)
    assert(getmetatable(g) == transform, "transform composition requires a transform as the first argument")
    assert(getmetatable(h) == transform, "transform composition requires a transform as the second argument")
    local tx, ty = g(h.tx, h.ty)

    local a = g.a * h.a + g.b * h.c
    local b = g.a * h.b + g.b * h.d
    local c = g.c * h.a + g.d * h.c
    local d = g.c * h.b + g.d * h.d

    return transform.new(g.name .. '.' .. h.name, a, b, c, d, tx, ty)
end

--- Equality check of two transformations
---
---@param g forma.transform first transform
---@param h forma.transform second transform
---@return boolean c true if the two transforms are identical
function transform.__eq(g, h)
    return (
        g.a == h.a
        and g.b == h.b
        and g.c == h.c
        and g.d == h.d
        and g.tx == h.tx
        and g.ty == h.ty
    )
end

return transform
