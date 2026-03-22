--- API doc generation — converts LuaLS doc.json into per-module markdown.

local json = require("dkjson")

local M = {}

local function trim(s)
    if not s or s == "" then return nil end
    return s:gsub("\n ", "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end

local function table_row(name, typ, desc)
    return "| `" .. (name or "") .. "` | `" .. (typ or "any") .. "` | " .. (desc or "") .. " |"
end

local function render_module(entry, name)
    local short = name:match("%.(%w+)$") or name
    local out = { "# " .. short, "" }
    local function emit(s) out[#out + 1] = s end

    for _, def in ipairs(entry.defines or {}) do
        local desc = trim(def.rawdesc)
        if desc then emit(desc); emit("") end
    end

    local fields, funcs = {}, {}
    for _, f in ipairs(entry.fields or {}) do
        if f.visible == "public" and f.name ~= "__index" then
            if f.extends and f.extends.type == "function" then
                funcs[#funcs + 1] = f
            else
                fields[#fields + 1] = f
            end
        end
    end

    -- Sort by source line number to preserve the author's ordering
    local by_line = function(a, b) return (a.start or {})[1] < (b.start or {})[1] end
    table.sort(fields, by_line)
    table.sort(funcs, by_line)

    if #fields > 0 then
        emit("## Fields")
        emit("")
        emit("| Name | Type | Description |")
        emit("|------|------|-------------|")
        for _, f in ipairs(fields) do
            emit(table_row(f.name, f.view, f.rawdesc))
        end
        emit("")
    end

    if #funcs > 0 then
        emit("## Functions")
        emit("")
        for _, f in ipairs(funcs) do
            local fn = f.extends
            emit("### `" .. short .. "." .. f.name .. "`")
            emit("")
            local desc = trim(fn.rawdesc)
            if desc then emit(desc); emit("") end

            if fn.args and #fn.args > 0 then
                emit("**Parameters:**")
                emit("")
                emit("| Name | Type | Description |")
                emit("|------|------|-------------|")
                for _, a in ipairs(fn.args) do
                    emit(table_row(a.name, a.view, a.rawdesc))
                end
                emit("")
            end

            if fn.returns and #fn.returns > 0 then
                emit("**Returns:**")
                emit("")
                for _, r in ipairs(fn.returns) do
                    emit("- `" .. (r.view or "any") .. "` — " .. (r.rawdesc or ""))
                end
                emit("")
            end
        end
    end

    return table.concat(out, "\n")
end

--- Generate API markdown files from LuaLS doc.json.
---@param json_path string path to the doc.json file
---@param output_dir string output directory for markdown files
---@param module_names string[] list of module names to generate docs for
---@param write_file fun(path: string, content: string) file writer
function M.generate(json_path, output_dir, module_names, write_file)
    local f = assert(io.open(json_path, "r"))
    local data = json.decode(f:read("*a"))
    f:close()

    local by_class = {}
    for _, entry in ipairs(data) do
        if entry.name then by_class[entry.name] = entry end
    end

    os.execute("mkdir -p " .. output_dir)
    for _, name in ipairs(module_names) do
        local entry = by_class[name]
        if not entry then
            io.stderr:write("Warning: No data for " .. name .. "\n")
        else
            local slug = name:match("%.(%w+)$")
            write_file(output_dir .. "/" .. slug .. ".md", render_module(entry, name))
        end
    end
end

return M
