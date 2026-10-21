--- A class containing a collection of `pattern` objects.
--- Many pattern operations generate a set of patterns. This
--- class aims to provide a convenient collection with some
--- common methods for handling them.
---@class forma.multipattern
---@field components forma.pattern[] the list of sub-patterns
local multipattern = {}


-- Multipattern indexing
-- For enabling syntax sugar multipattern:method
-- This retains the ability to index by number.
multipattern.__index = function(mp, key)
    if type(key) == "number" then
        return mp.components[key]
    else
        return multipattern[key]
    end
end


--- Create a new multipattern from a list of patterns.
---
--- ```lua
--- local mp = multipattern.new()
--- local mp2 = multipattern.new({p1, p2, p3})
--- ```
---@param components? forma.pattern[] an array of pattern objects
---@return forma.multipattern mp a new multipattern containing those patterns
function multipattern.new(components)
    local mp = {
        components = components or {}
    }
    mp = setmetatable(mp, multipattern)
    return mp
end

--- Clone the multipattern.
---
---@param mp forma.multipattern multipattern to clone
---@return forma.multipattern clone the cloned multipattern
function multipattern.clone(mp)
    local components = {}
    for i, p in ipairs(mp.components) do
        components[i] = p:clone()
    end
    return multipattern.new(components)
end

--- Merge multipatterns.
---
---@param ... forma.multipattern a table of multipatterns or a list of multipattern arguments
---@return forma.multipattern mp a new multipattern consisting of the set of all input components
function multipattern.merge(...)
    local multipatterns = { ... }
    if #multipatterns == 1 then
        -- Handle case where the input is a table of multipatterns
        if type(multipatterns[1]) == 'table' and getmetatable(multipatterns[1]) == nil then
            multipatterns = multipatterns[1]
        end
    end
    if #multipatterns == 1 then
        return multipatterns[1]
    end
    local total = multipattern.new()
    for _, v in ipairs(multipatterns) do
        assert(getmetatable(v) == multipattern, "multipattern.merge requires multipatterns as arguments")
        for _, p in ipairs(v.components) do
            total:insert(p)
        end
    end
    return total
end

--- Insert a pattern into the multipattern.
---
---@param mp forma.multipattern multipattern to be operated upon
---@param ip forma.pattern the new pattern to insert
---@return forma.multipattern mp the multipattern
function multipattern.insert(mp, ip)
    assert(getmetatable(mp) == multipattern, "multipattern.insert requires a multipattern as the first argument")
    table.insert(mp.components, ip)
    return mp
end

--- Count the number of components in a multipattern.
---
---@param mp forma.multipattern the multipattern to count
---@return integer count the number of components
function multipattern.n_components(mp)
    assert(getmetatable(mp) == multipattern, "multipattern.n_components requires a multipattern as the first argument")
    return #mp.components
end

--- Map a function over all patterns in this multipattern.
--- Calls `fn(pattern, index)` for each sub-pattern, returning a new multipattern
--- of their results.
---
--- ```lua
--- local bigger = mp:map(function(p) return p:enlarge(2) end)
--- ```
---@param mp forma.multipattern the multipattern upon which to map the function
---@param fn fun(p: forma.pattern, i: integer): forma.pattern a function taking (pattern, index) and returning a new pattern
---@return forma.multipattern result a new multipattern of the mapped results
function multipattern.map(mp, fn)
    assert(getmetatable(mp) == multipattern, "multipattern.map requires a multipattern as an argument")
    local new_components = {}
    for i, pat in ipairs(mp.components) do
        new_components[i] = fn(pat, i)
    end
    return multipattern.new(new_components)
end

--- Filter out sub-patterns according to a predicate.
--- Keeps only those patterns for which `predicate(pattern) == true`.
---
--- ```lua
--- local bigSegs = mp:filter(function(p) return p:size() >= 10 end)
--- ```
---@param mp forma.multipattern the multipattern upon which to filter
---@param fn fun(p: forma.pattern): boolean a predicate function
---@return forma.multipattern result a new multipattern containing only the sub-patterns passing the test
function multipattern.filter(mp, fn)
    assert(getmetatable(mp) == multipattern, "multipattern.filter requires a multipattern as an argument")
    local new_components = {}
    for _, pat in ipairs(mp.components) do
        if fn(pat) then
            new_components[#new_components + 1] = pat
        end
    end
    return multipattern.new(new_components)
end

--- Apply a named method to each pattern, returning a new multipattern.
--- This is an alternative to `:map(...)` for calling an *existing* pattern method
--- by name on all sub-patterns. You may also supply arguments to that method.
---
--- Note that when used with a method that generates multipatterns (e.g. `connected_components`),
--- the results will be 'flattened' into a single multipattern.
---
--- ```lua
--- local translated = mp:apply("translate", 10, 5)
--- -- calls p:translate(10,5) on each pattern p
--- ```
---@param mp forma.multipattern the multipattern upon which to apply the method
---@param method string the name of a function in `pattern`
---@param ... any additional arguments to pass to that method
---@return forma.multipattern result a new multipattern of the method's results
function multipattern.apply(mp, method, ...)
    assert(getmetatable(mp) == multipattern, "multipattern.apply requires a multipattern as an argument")
    local pattern_mt = require('forma.pattern')
    local new_components = {}
    for _, pat in ipairs(mp.components) do
        local m = pat[method]
        assert(type(m) == "function", "No method named '" .. tostring(method) .. "' on pattern")
        local return_value = m(pat, ...)
        if getmetatable(return_value) == multipattern then
            for _, v in ipairs(return_value.components) do
                table.insert(new_components, v)
            end
        elseif getmetatable(return_value) == pattern_mt then
            table.insert(new_components, return_value)
        else
            assert(false, "Method must return a pattern or multipattern")
        end
    end
    return multipattern.new(new_components)
end

--- Union all sub-patterns into a single pattern.
--- Folds over the sub-patterns with the union (`+`) operator,
--- returning a single `pattern`.
---
--- ```lua
--- local combined = mp:union_all()
--- ```
---@param mp forma.multipattern the multipattern to union over
---@return forma.pattern pattern a single pattern combining all sub-patterns
function multipattern.union_all(mp)
    -- Require here to avoid circular dependency.
    local pattern = require('forma.pattern')
    if mp:n_components() == 0 then
        return pattern.new()
    else
        return pattern.union(mp.components)
    end
end

--- Return only the distinct components of a multipattern.
---
--- ```lua
--- local combined = mp:distinct()
--- ```
---@param mp forma.multipattern the multipattern to deduplicate
---@return forma.multipattern multipattern a multipattern containly only distinct components
function multipattern.distinct(mp)
    local is_present = {}
    local nmp = multipattern.new()
    for _, pat in ipairs(mp.components) do
        local hash = pat:hash()
        if is_present[hash] ~= true then
            nmp:insert(pat)
            is_present[hash] = true
        end
    end
    return nmp
end

--- Print a multipattern.
--- Prints a multipattern to `io.output`. If provided, a table of subpattern labels
--- can be used, with one entry per subpattern.
---
---@param mp forma.multipattern the multipattern to be drawn
---@param chars? string[] the characters to be printed for each subpattern
---@param domain? forma.pattern the domain in which to print
function multipattern.print(mp, chars, domain)
    assert(getmetatable(mp) == multipattern, "multipattern.print requires a multipattern as a first argument")
    domain = domain or mp:union_all()
    assert(domain:size() > 0, "multipattern.print: domain must have at least one cell")

    local n = mp:n_components()
    -- If no dictionary is supplied generate a new one (starting from '0')
    if chars == nil then
        local start_char = 47
        assert(n < (200 - start_char), "multipattern.print: too many components")
        chars = {}
        for i = 1, n, 1 do
            table.insert(chars, string.char(i + start_char))
        end
    end
    assert(n == #chars,
        "multipattern.print: there must be as many character table entries as components")
    -- Print out the segments to a map
    for i = domain.min.y, domain.max.y, 1 do
        local row = {}
        for j = domain.min.x, domain.max.x, 1 do
            local token = ' '
            for k, v in ipairs(mp.components) do
                if v:has_cell(j, i) then token = chars[k] end
            end
            row[#row + 1] = token
        end
        io.write(table.concat(row) .. '\n')
    end
end

return multipattern
