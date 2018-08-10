-- Generates the example gallery
-- Usage: lua gallery.lua ./*.lua
local args = {...}

-- Sort files by length and get headers
local sort_by_size = function(i, j)
    local ifile = io.open( i, "r" )
    local jfile = io.open( j, "r" )
    local sort = ifile:seek("end") < jfile:seek("end")
    ifile:close(); jfile:close();
    return sort
end

table.sort(args, sort_by_size)
print("# *forma* example gallery")
for _,v in ipairs(args) do
    if v ~= "gallery.lua" then
        local file = io.open( v, "r" )
        local head = file:read("*line")
        -- Trim leading '--'
        local start = string.find(head, "%w+")
        head = head:sub(start)
        local link = string.lower(head):gsub(" ","-")
        print("* ["..head.."](#"..link..")")
        file:close()
    end
end
print()

local headers = {}
for _,v in ipairs(args) do
    if v ~= "gallery.lua" then
        local name = v:match("(.+)%.")
        local header = true
        local title  = true
        for line in io.lines(v) do
            if header == true then
                if line:sub(1,2) == '--' then
                    local start = string.find(line, "%w+")
                    line = line:sub(start)
                else
                    header = false
                    print()
                    print("```lua")
                end
            end
            if title == true then
                table.insert(headers, line)
                line = "## " .. line
                title = false
            end
            print(line)
        end
        print("```")
        print("### Output")
        print("![foo](img/"..name..".png )")
    end
end

