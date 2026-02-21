---@meta

--- A collection of pattern objects.
---@class forma.multipattern
local multipattern = {}

--- Create a new multipattern from a list of patterns.
---@param components? forma.pattern[]
---@return forma.multipattern
function multipattern.new(components) end

--- Clone the multipattern.
---@param mp forma.multipattern
---@return forma.multipattern
function multipattern.clone(mp) end

--- Merge multipatterns.
---@param ... forma.multipattern|forma.multipattern[]
---@return forma.multipattern
function multipattern.merge(...) end

--- Insert a pattern into the multipattern.
---@param mp forma.multipattern
---@param ip forma.pattern
---@return forma.multipattern
function multipattern.insert(mp, ip) end

--- Count the number of components.
---@param mp forma.multipattern
---@return integer
function multipattern.n_components(mp) end

--- Map a function over all patterns.
---@param mp forma.multipattern
---@param fn fun(pat: forma.pattern, index: integer): forma.pattern
---@return forma.multipattern
function multipattern.map(mp, fn) end

--- Filter sub-patterns by predicate.
---@param mp forma.multipattern
---@param fn fun(pat: forma.pattern): boolean
---@return forma.multipattern
function multipattern.filter(mp, fn) end

--- Apply a named pattern method to each sub-pattern.
---@param mp forma.multipattern
---@param method string
---@param ... any
---@return forma.multipattern
function multipattern.apply(mp, method, ...) end

--- Union all sub-patterns into a single pattern.
---@param mp forma.multipattern
---@return forma.pattern
function multipattern.union_all(mp) end

--- Print a multipattern.
---@param mp forma.multipattern
---@param chars? string[]
---@param domain? forma.pattern
function multipattern.print(mp, chars, domain) end

return multipattern
