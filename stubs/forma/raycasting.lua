---@meta

--- Ray tracing algorithms for visibility computation.
local ray = {}

--- Casts a ray from a start to an end cell.
---@param v0 forma.cell Starting cell.
---@param v1 forma.cell End cell.
---@param domain forma.pattern
---@return boolean success
function ray.cast(v0, v1, domain) end

--- Casts rays from a start cell across an octant.
---@param v0 forma.cell Starting cell.
---@param domain forma.pattern
---@param oct integer Octant identifier (1-8).
---@param ray_length number Maximum ray length.
---@return forma.pattern
function ray.cast_octant(v0, domain, oct, ray_length) end

--- Casts rays from a starting cell in all directions.
---@param v0 forma.cell Starting cell.
---@param domain forma.pattern
---@param ray_length number Maximum ray length.
---@return forma.pattern
function ray.cast_360(v0, domain, ray_length) end

return ray
