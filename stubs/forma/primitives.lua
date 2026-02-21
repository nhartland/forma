---@meta

--- Primitive (line, rectangle and circle) patterns.
local primitives = {}

--- Generate a square/rectangle pattern.
---@param x number Size in x.
---@param y? number Size in y (default: x).
---@return forma.pattern
function primitives.square(x, y) end

--- Generate a line pattern (Bresenham's algorithm).
---@param start forma.cell
---@param finish forma.cell
---@return forma.pattern
function primitives.line(start, finish) end

--- Draw a quadratic Bézier curve.
---@param start forma.cell
---@param control forma.cell
---@param finish forma.cell
---@param N? integer Number of line segments (default: 20).
---@return forma.pattern
---@return forma.cell[] points Ordered points along the curve.
function primitives.quad_bezier(start, control, finish, N) end

--- Generate a circle pattern (Bresenham's algorithm).
---@param r number Radius.
---@return forma.pattern
function primitives.circle(r) end

return primitives
