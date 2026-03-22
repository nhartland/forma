#!/usr/bin/env lua
--- Generates MkDocs pages from LuaLS annotations and examples/*.lua.
--- Usage: lua docs/extract.lua

local rockspec = require("docs.extract.rockspec")
local api      = require("docs.extract.api")
local examples = require("docs.extract.examples")

local function write_file(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
    print("Generated: " .. path)
end

-- Generate LuaLS doc.json
os.execute("mkdir -p docs/source")
assert(os.execute("lua-language-server --doc=. --doc_out_path=docs/source"),
    "lua-language-server failed (is it installed?)")

local modules = rockspec.module_names("rockspec/forma-scm-1.rockspec")
api.generate("docs/source/doc.json", "docs/api", modules, write_file)
examples.generate("docs/examples", write_file)
