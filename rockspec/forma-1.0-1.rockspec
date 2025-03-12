package = "forma"
version = "1.0-1"
rockspec_format = "3.0"
source = {
    url = "git://github.com/nhartland/forma",
    tag = "v1.0",
}

description = {
    summary = "Cellular automata and geometry in Lua.",
    detailed = [[
forma is a utility library for the procedural generation and manipulation of
shapes on a two dimensional grid or lattice.

The library provides a flexible Cellular Automata implementation, along with a
great deal of standard methods from computational geometry. For example 2-D
sampling by Poisson-disc or Lloyd's algorithm, Contiguous segment finding by
flood-filling, Binary space partitioning, Voronoi tessellation, hull finding
and more.
]],
    homepage = "https://nhartland.github.io/forma/",
    license = "MIT"
}
dependencies = {
    "lua >= 5.1", "lua < 5.4"
}
build = {
    type = "builtin",
    modules = {
        forma                       = "forma/init.lua",
        ["forma.automata"]          = "forma/automata.lua",
        ["forma.cell"]              = "forma/cell.lua",
        ["forma.neighbourhood"]     = "forma/neighbourhood.lua",
        ["forma.pattern"]           = "forma/pattern.lua",
        ["forma.primitives"]        = "forma/primitives.lua",
        ["forma.multipattern"]      = "forma/multipattern.lua",
        ["forma.raycasting"]        = "forma/raycasting.lua",
        ["forma.utils.random"]      = "forma/utils/random.lua",
        ["forma.utils.noise"]       = "forma/utils/noise.lua",
        ["forma.utils.convex_hull"] = "forma/utils/convex_hull.lua",
        ["forma.utils.bsp"]         = "forma/utils/bsp.lua",
    },
    copy_directories = {
        "docs",
        "tests"
    }
}
test = {
    type = "command",
    script = "tests/run.lua",
    flags = { "-v" }
}
test_dependencies = {
    "luaunit ==3.3"
}
