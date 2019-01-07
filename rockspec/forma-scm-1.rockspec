package = "forma"
version = "scm-1"
source = {
   url = "git://github.com/nhartland/forma",
   branch = "dev",
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
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      forma = "forma/init.lua",
      ["forma.automata"]      = "forma/automata.lua",
      ["forma.cell"]          = "forma/cell.lua",
      ["forma.neighbourhood"] = "forma/neighbourhood.lua",
      ["forma.pattern"]       = "forma/pattern.lua",
      ["forma.primitives"]    = "forma/primitives.lua",
      ["forma.subpattern"]    = "forma/subpattern.lua",
   },
   copy_directories = {
      "docs",
      "examples"
   }
}
