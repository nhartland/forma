#!/usr/bin/env lua
--- Generates MkDocs pages from LuaLS doc.json (API) and examples/*.lua.
---
--- Prerequisites: lua-language-server --doc=. --doc_out_path=.docgen
--- Usage: lua docs/extract.lua

local json = require("dkjson")

local module_names = {
    "forma.cell", "forma.pattern", "forma.primitives", "forma.automata",
    "forma.neighbourhood", "forma.multipattern", "forma.raycasting",
}

local function write_file(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
    print("Generated: " .. path)
end

local function trim(s)
    if not s or s == "" then return nil end
    return s:gsub("\n ", "\n"):gsub("^%s+", ""):gsub("%s+$", "")
end

local function table_row(name, typ, desc)
    return "| `" .. (name or "") .. "` | `" .. (typ or "any") .. "` | " .. (desc or "") .. " |"
end

-- API doc generation --------------------------------------------------------

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

local function generate_api()
    local f = assert(io.open(".docgen/doc.json", "r"))
    local data = json.decode(f:read("*a"))
    f:close()

    local by_class = {}
    for _, entry in ipairs(data) do
        if entry.name then by_class[entry.name] = entry end
    end

    os.execute("mkdir -p docs/api")
    for _, name in ipairs(module_names) do
        local entry = by_class[name]
        if not entry then
            io.stderr:write("Warning: No data for " .. name .. "\n")
        else
            local slug = name:match("%.(%w+)$")
            write_file("docs/api/" .. slug .. ".md", render_module(entry, name))
        end
    end
end

-- Examples generation -------------------------------------------------------

local function generate_examples()
    os.execute("mkdir -p docs/examples/img")
    os.execute("cp -f examples/img/*.png docs/examples/img/ 2>/dev/null")

    local handle = assert(io.popen("ls examples/*.lua 2>/dev/null"))
    local files = {}
    for line in handle:lines() do
        files[#files + 1] = line
    end
    handle:close()
    table.sort(files)

    for _, path in ipairs(files) do
        local f = assert(io.open(path, "r"))
        local source = f:read("*a")
        f:close()

        -- Extract title and description from leading comments
        local title, desc = nil, {}
        for line in source:gmatch("([^\n]*)\n?") do
            local comment = line:match("^%-%-%-?%s?(.*)$")
            if not comment then break end
            if not title then
                title = comment:match("^%s*(.+)")
            else
                desc[#desc + 1] = comment
            end
        end
        while #desc > 0 and desc[#desc]:match("^%s*$") do desc[#desc] = nil end

        local slug = path:match("([^/]+)%.lua$"):gsub("_", "-")
        local img_file = slug:gsub("-", "_") .. ".png"

        local out = { "# " .. (title or slug), "" }
        local function emit(s) out[#out + 1] = s end

        if #desc > 0 then
            for _, line in ipairs(desc) do emit(line) end
            emit("")
        end
        local img = io.open("examples/img/" .. img_file, "r")
        if img then
            img:close()
            emit("![" .. (title or slug) .. "](img/" .. img_file .. ")")
            emit("")
        end
        emit("```lua")
        emit(source:gsub("\n+$", ""))
        emit("```")

        write_file("docs/examples/" .. slug .. ".md", table.concat(out, "\n"))
    end
end

-- Main ----------------------------------------------------------------------

generate_api()
generate_examples()
