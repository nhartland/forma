#!/usr/bin/env lua
--- Generates MkDocs example pages from examples/*.lua.
--- Usage: lua scripts/extract_examples.lua [output_dir]

local output_dir = arg[1] or "docs/examples"

os.execute('mkdir -p "' .. output_dir .. '/img"')
os.execute('cp -f examples/img/*.png "' .. output_dir .. '/img/" 2>/dev/null')

local handle = assert(io.popen('ls examples/*.lua 2>/dev/null'))
local files = {}
for line in handle:lines() do
    files[#files+1] = line
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
            desc[#desc+1] = comment
        end
    end
    while #desc > 0 and desc[#desc]:match("^%s*$") do desc[#desc] = nil end

    local slug = path:match("([^/]+)%.lua$"):gsub("_", "-")
    local img_file = slug:gsub("-", "_") .. ".png"

    local md = { "# " .. (title or slug), "" }
    if #desc > 0 then
        for _, line in ipairs(desc) do md[#md+1] = line end
        md[#md+1] = ""
    end
    local img = io.open("examples/img/" .. img_file, "r")
    if img then
        img:close()
        md[#md+1] = "![" .. (title or slug) .. "](img/" .. img_file .. ")"
        md[#md+1] = ""
    end
    md[#md+1] = "```lua"
    md[#md+1] = source:gsub("\n+$", "")
    md[#md+1] = "```"

    local outpath = output_dir .. "/" .. slug .. ".md"
    local out = assert(io.open(outpath, "w"))
    out:write(table.concat(md, "\n"))
    out:close()
    print("Generated: " .. outpath)
end
