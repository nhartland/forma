--- A class contain a collection of `pattern` objects.
-- Many pattern operations generate a set of patterns. This
-- class aims to provide a convenient collection with some
-- common methods for handling them.
--
-- @module forma.multipattern
local multipattern = {}
local pattern = require('forma.pattern')


-- Multipattern indexing
-- For enabling syntax sugar multipattern:method
multipattern.__index = multipattern


--- Create a new multipattern from a list of patterns.
-- @param subpatterns an array of `pattern` objects.
-- @return a new multipattern containing those patterns.
function multipattern.new(subpatterns)
    local mp = {
        subpatterns = subpatterns or {}
    }

    mp = setmetatable(mp, multipattern)
    return mp
end

--- Clone the multipattern.
-- @param mp multipattern to clone.
-- @return the cloned multipattern.
function multipattern.clone(mp)
    local subpatterns = {}
    for i, p in ipairs(mp.subpatterns) do
        subpatterns[i] = p:clone()
    end

    return multipattern.new(subpatterns)
end

--- Insert a pattern into the multipattern.
-- @param mp multipattern to be operated upon.
-- @param ip the new pattern to insert.
-- @return the new multipattern.
function multipattern.insert(mp, ip)
    assert(getmetatable(mp) == multipattern, "multipattern.insert requires a multipattern as the first argument")
    assert(getmetatable(ip) == pattern, "multipattern.insert requires a pattern as the second argument")
    table.insert(mp.subpatterns, ip)
end

--- Count the number of subpatterns in a multipattern.
-- @param mp the multipattern to count.
-- @return the number of subpatterns.
function multipattern.n_subpatterns(mp)
    assert(getmetatable(mp) == multipattern, "multipattern.n_subpatterns requires a multipattern as the first argument")
    return #mp.subpatterns
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
-- @param mp the multipattern upon which to map the function.
-- @param fn a function taking `(pattern, index)` and returning a new `pattern`.
-- @return a new multipattern of the mapped results.
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
-- @param mp the multipattern upon which to filter.
-- @param fn a function `(pattern) -> boolean`.
-- @return a new multipattern containing only the sub-patterns passing the test.
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
-- @param mp the multipattern upon which to apply the method.
-- @param method the name of a function in `pattern`.
-- @param ... additional arguments to pass to that method.
-- @return a new multipattern of the method's results.
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
-- @param mp the multipattern to union over.
-- @return a single pattern combining all sub-patterns.
function multipattern.union_all(mp)
    return pattern.union(mp.subpatterns)
end

--- Utilities
-- @section multipattern_utils

--- Print a multipattern.
-- Prints a multipattern to `io.output`. If provided, a table of subpattern labels
-- can be used, with one entry per subpattern.
-- @param mp the multipattern to be drawn.
-- @param chars the characters to be printed for each subpattern (optional).
-- @param domain the domain in which to print (optional).
function multipattern.print(mp, chars, domain)
    assert(getmetatable(mp) == multipattern, "multipattern.print requires a multipattern as a first argument")
    domain = domain or mp:union_all()
    assert(domain:size() > 0, "multipattern.print: domain must have at least one cell")
    local n = mp:n_subpatterns()
    -- If no dictionary is supplied generate a new one (starting from '0')
    if chars == nil then
        local start_char = 47
        assert(n < (200 - start_char), "multipattern.print: too many subpatterns")
        chars = {}
        for i = 1, n, 1 do
            table.insert(chars, string.char(i + start_char))
        end
    end
    assert(n == #chars,
        "multipattern.print: there must be as many character table entries as subpatterns")
    -- Print out the segments to a map
    for i = domain.min.y, domain.max.y, 1 do
        local string = ''
        for j = domain.min.x, domain.max.x, 1 do
            local token = ' '
            for k, v in ipairs(mp.subpatterns) do
                if v:has_cell(j, i) then token = chars[k] end
            end
            string = string .. token
        end
        io.write(string .. '\n')
    end
end

return multipattern
