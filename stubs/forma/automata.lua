---@meta

--- Pattern manipulation with Cellular Automata.
local automata = {}

--- A cellular automata rule.
---@class forma.rule
---@field neighbourhood forma.neighbourhood
---@field B table<integer, boolean> Birth conditions.
---@field S table<integer, boolean> Survival conditions.

--- Define a cellular automata rule.
---@param nbh forma.neighbourhood
---@param rule_string string Rule in Golly format (e.g. "B3/S23").
---@return forma.rule
function automata.rule(nbh, rule_string) end

--- Synchronous cellular automata iteration.
---@param prevp forma.pattern
---@param domain forma.pattern
---@param ruleset forma.rule[]
---@return forma.pattern result
---@return boolean converged
function automata.iterate(prevp, domain, ruleset) end

--- Asynchronous cellular automata iteration.
---@param prevp forma.pattern
---@param domain forma.pattern
---@param ruleset forma.rule[]
---@param rng? fun(m: integer, n: integer): integer
---@return forma.pattern result
---@return boolean converged
function automata.async_iterate(prevp, domain, ruleset, rng) end

return automata
