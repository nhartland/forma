--- A class contain a collection of `pattern` objects.
-- Many pattern operations generate a set of patterns. This
-- class aims to provide a convenient collection with some
-- common methods for handling them.
--

---
-- A class representing a *collection* of `pattern` objects.
-- Each multipattern holds an array of patterns, along with methods
-- for operating on them in a *fluent* style (chaining).
-- @classmod multipattern
local multipattern = {}
local pattern = require('forma.pattern')


-- Multipattern indexing
-- For enabling syntax sugar multipattern:method
multipattern.__index = multipattern


--- Create a new multipattern from a list of patterns.
-- @param {pattern,...} list_of_patterns an array of `pattern` objects
-- @return multipattern a new multipattern containing those patterns
function multipattern.new(subpatterns)
    local mp = {
        subpatterns = subpatterns or {}
    }

    mp = setmetatable(mp, multipattern)
    return mp
end

--- Clone the multipattern.
-- @param mp multipattern to clone
-- @return cloned multipattern
function multipattern.clone(mp)
    local subpatterns = {}
    for i, p in ipairs(mp.subpatterns) do
        subpatterns[i] = p:clone()
    end

    return multipattern.new(subpatterns)
end

function multipattern.insert(mp, ip)
    assert(getmetatable(mp) == multipattern, "multipattern.insert requires a pattern as the first argument")
    table.insert(mp.subpatterns, ip)
end

--- Map a function over all patterns in this multipattern.
-- Calls `fn(pattern, index)` for each sub-pattern, returning a new multipattern
-- of their results.
--
-- **Example**:
--  ```
--  local bigger = mp:map(function(p) return p:enlarge(2) end)
--  ```
--
-- @param function fn a function taking `(pattern, index)` and returning a new `pattern`
-- @return multipattern a new multipattern of the mapped results
function multipattern.map(mp, fn)
    assert(getmetatable(mp) == multipattern, "multipattern.map requires a multipattern as an argument")
    -- Applies `fn` to each pattern in this multipattern,
    -- returning a new multipattern of results.
    -- fn is a function(pat, index) -> (some pattern)
    local new_subpatterns = {}
    for i, pat in ipairs(mp.subpatterns) do
        new_subpatterns[i] = fn(pat, i)
    end
    return multipattern.new(new_subpatterns)
end

--- Filter out sub-patterns according to a predicate.
-- Keeps only those patterns for which `predicate(pattern) == true`.
--
-- **Example**:
--  ```
--  local bigSegs = mp:filter(function(p) return p:size() >= 10 end)
--  ```
-- @param function predicate a function `(pattern) -> boolean`
-- @return multipattern a new multipattern containing only the sub-patterns passing the test
function multipattern.filter(mp, fn)
    assert(getmetatable(mp) == multipattern, "multipattern.filter requires a multipattern as an argument")
    -- Keeps only those patterns for which fn(pat) == true.
    local new_subpatterns = {}
    for _, pat in ipairs(mp.subpatterns) do
        if fn(pat) then
            new_subpatterns[#new_subpatterns+1] = pat
        end
    end
    return multipattern.new(new_subpatterns)
end

--- Apply a named method to each pattern, returning a new multipattern.
-- This is an alternative to `:map(...)` for calling an *existing* pattern method
-- by name on all sub-patterns. You may also supply arguments to that method.
--
-- **Example**:
--   ```
--   local shifted = mp:apply("shift", 10, 5)
--   -- calls p:shift(10,5) on each pattern p
--   ```
-- @param string method the name of a function in `pattern`
-- @param ... additional arguments to pass to that method
-- @return multipattern a new multipattern of the method's results
function multipattern.apply(mp, method, ...)
    assert(getmetatable(mp) == multipattern, "multipattern.apply requires a multipattern as an argument")
    local new_subpatterns = {}
    for i, pat in ipairs(mp.subpatterns) do
        local m = pat[method]
        assert(type(m) == "function", "No method named '"..tostring(method).."' on pattern")
        new_subpatterns[i] = m(pat, ...)
    end
    return multipattern.new(new_subpatterns)
end

--- Union all sub-patterns into a single pattern.
-- Folds over the sub-patterns with the union (`+`) operator,
-- returning a single `pattern`.
--
-- **Example**:
--   ```
--   local combined = mp:union_all()
--   ```
-- @return pattern a single pattern combining all sub-patterns
function multipattern.union_all(mp)
    return pattern.union(mp.subpatterns)
end

return multipattern
