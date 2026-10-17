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
--- The transformation matrix A must have nonzero determinant.
---
--- ```lua
--- -- The identity transform
--- local I = transform.new(1,0,0,1)
--- ```
---@param a integer
---@param b integer
---@param c integer
---@param d integer
---@param _tx? integer
---@param _ty? integer
---@return forma.transform o new transform Ax + t
function transform.new(a, b, c, d, _tx, _ty)
    local tx = _tx or 0
    local ty = _ty or 0
    assert(math.floor(a) == a, "forma.transform.new: requires an integer for a")
    assert(math.floor(b) == b, "forma.transform.new: requires an integer for b")
    assert(math.floor(c) == c, "forma.transform.new: requires an integer for c")
    assert(math.floor(d) == d, "forma.transform.new: requires an integer for d")
    assert(math.floor(tx) == tx, "forma.transform.new: requires an integer for tx")
    assert(math.floor(ty) == ty, "forma.transform.new: requires an integer for ty")
    local op = {
        a = a,
        b = b,
        c = c,
        d = d,
        tx = tx,
        ty = ty
    }
    op = setmetatable(op, transform)
    assert(a * d - b * c ~= 0, "forma.transform.new: linear part of the transform must have nonzero determinant")
    return op
end

--- Create a pure translation.
---
--- This function is a helper to create a simple translation.
---
--- ```lua
--- -- The identity transform
--- local g = transform.translate(5,6)
--- ```
---@param tx integer
---@param ty integer
---@return forma.transform o new transform Ix + t
function transform.translate(tx, ty)
    assert(math.floor(tx) == tx, "forma.transform.translate: requires an integer for tx")
    assert(math.floor(ty) == ty, "forma.transform.translate: requires an integer for ty")
    return transform.new(1, 0, 0, 1, tx, ty)
end

--- Apply a transform to a vector.
---
--- Acts the transformation `o` on the vector `(x, y)`
---
--- ```lua
--- local vpx, vpy = o(v.x, v.y)
--- ```
---@param o forma.transform
---@param x integer first coordinate of the vector
---@param y integer second coordinate of the vector
---@return integer xp transformed first coordinate
---@return integer yp transformed second coordinate
function transform.__call(o, x, y)
    return o.a * x + o.b * y + o.tx, o.c * x + o.d * y + o.ty
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

    return transform.new(a, b, c, d, tx, ty)
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
