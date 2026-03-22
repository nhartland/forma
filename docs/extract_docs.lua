#!/usr/bin/env lua
--- Generates MkDocs API docs from LuaLS doc.json.
---
--- Prerequisites: lua-language-server --doc=. --doc_out_path=.docgen
--- Usage: lua scripts/extract_docs.lua [json_path] [output_dir]

local json = require("dkjson")

local json_path  = arg[1] or ".docgen/doc.json"
local output_dir = arg[2] or "docs/api"

local module_names = {
    "forma.cell", "forma.pattern", "forma.primitives", "forma.automata",
    "forma.neighbourhood", "forma.multipattern", "forma.raycasting",
}

local function trim_desc(s)
    if not s or s == "" then return nil end
    -- LuaLS rawdesc has a leading space on each line; strip it
    s = s:gsub("\n ", "\n")
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function render_module(entry, name)
    local short = name:match("%.(%w+)$") or name
    local md = { "# " .. short, "" }

    -- Module description
    for _, def in ipairs(entry.defines or {}) do
        local desc = trim_desc(def.rawdesc)
        if desc then md[#md+1] = desc; md[#md+1] = "" end
    end

    -- Split fields vs functions
    local fields, funcs = {}, {}
    for _, f in ipairs(entry.fields or {}) do
        if f.visible == "public" and f.name ~= "__index" then
            if f.extends and f.extends.type == "function" then
                funcs[#funcs+1] = f
            else
                fields[#fields+1] = f
            end
        end
    end

    -- Fields table
    if #fields > 0 then
        md[#md+1] = "## Fields"
        md[#md+1] = ""
        md[#md+1] = "| Name | Type | Description |"
        md[#md+1] = "|------|------|-------------|"
        for _, f in ipairs(fields) do
            md[#md+1] = "| `" .. f.name .. "` | `" .. (f.view or "any") .. "` | " .. (f.rawdesc or "") .. " |"
        end
        md[#md+1] = ""
    end

    -- Functions
    if #funcs > 0 then
        md[#md+1] = "## Functions"
        md[#md+1] = ""
        for _, f in ipairs(funcs) do
            local fn = f.extends
            md[#md+1] = "### `" .. short .. "." .. f.name .. "`"
            md[#md+1] = ""
            local desc = trim_desc(fn.rawdesc)
            if desc then md[#md+1] = desc; md[#md+1] = "" end

            if fn.args and #fn.args > 0 then
                md[#md+1] = "**Parameters:**"
                md[#md+1] = ""
                md[#md+1] = "| Name | Type | Description |"
                md[#md+1] = "|------|------|-------------|"
                for _, a in ipairs(fn.args) do
                    md[#md+1] = "| `" .. (a.name or "") .. "` | `" .. (a.view or "any") .. "` | " .. (a.rawdesc or "") .. " |"
                end
                md[#md+1] = ""
            end

            if fn.returns and #fn.returns > 0 then
                md[#md+1] = "**Returns:**"
                md[#md+1] = ""
                for _, r in ipairs(fn.returns) do
                    md[#md+1] = "- `" .. (r.view or "any") .. "` — " .. (r.rawdesc or "")
                end
                md[#md+1] = ""
            end
        end
    end

    return table.concat(md, "\n")
end

-- Main
local f = assert(io.open(json_path, "r"))
local data = json.decode(f:read("*a"))
f:close()

local by_class = {}
for _, entry in ipairs(data) do
    if entry.name then by_class[entry.name] = entry end
end

os.execute('mkdir -p "' .. output_dir .. '"')

for _, name in ipairs(module_names) do
    local entry = by_class[name]
    if not entry then
        io.stderr:write("Warning: No data for " .. name .. "\n")
    else
        local slug = name:match("%.(%w+)$")
        local path = output_dir .. "/" .. slug .. ".md"
        local out = assert(io.open(path, "w"))
        out:write(render_module(entry, name))
        out:close()
        print("Generated: " .. path)
    end
end
