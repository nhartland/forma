--- Rockspec loader — extracts public module names.

local M = {}

--- Load a rockspec file into a table.
---@param path string path to the rockspec file
---@return table env the rockspec environment
local function load_rockspec(path)
    local env = {}
    local fn = assert(loadfile(path))
    if setfenv then
        setfenv(fn, env)
    else
        debug.setupvalue(fn, 1, env)
    end
    fn()
    return env
end

--- Return sorted public module names from a rockspec.
--- Excludes the top-level "forma" init module and internal utils.
---@param path string path to the rockspec file
---@return string[] names sorted list of module names
function M.module_names(path)
    local spec = load_rockspec(path)
    local names = {}
    for name in pairs(spec.build.modules) do
        if name ~= "forma" and not name:match("^forma%.utils%.") then
            names[#names + 1] = name
        end
    end
    table.sort(names)
    return names
end

return M
