--- Examples generation — converts examples/*.lua into markdown pages.

local M = {}

--- Generate example markdown files from Lua source files.
---@param output_dir string output directory for markdown files
---@param write_file fun(path: string, content: string) file writer
function M.generate(output_dir, write_file)
    os.execute("mkdir -p " .. output_dir .. "/img")
    os.execute("cp -f examples/img/*.png " .. output_dir .. "/img/ 2>/dev/null")

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

        write_file(output_dir .. "/" .. slug .. ".md", table.concat(out, "\n"))
    end
end

return M
