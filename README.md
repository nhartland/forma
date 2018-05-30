forma
=====

__2D grid shape generation in lua__ 

![Example](img/header.png)

This package is intended for the generation and manipulation of shapes on a two
dimensional grid or lattice. It came about as part of experiments in making
roguelike games. **forma** is therefore particularly suited for the generation
of roguelike environments.

While there are methods for the generation and manipulation of primitive shapes
(rectangles, circle rasters etc.) The more interesting shapes are, for the
most part, generated by [Cellular Automata](https://en.wikipedia.org/wiki/Cellular_automaton)
(CA). A basic CA implementation is provided that can generate shapes such as the
classic 4-5 rule 'cave' systems:

> ![4-5 Rule caves](img/caves.png)

More complicated structures can be formed by combining different CA rule sets
with different neighbourhoods (including
[Moore](https://en.wikipedia.org/wiki/Moore_neighborhood), [von
Neumann](https://en.wikipedia.org/wiki/Von_Neumann_neighborhood) and more). For
example a 'corridor' structure:

> ![Corridors](img/corridor.png)

On top of the CA implementation, there are a great deal of methods for the
manipulation of these 2D patterns. From basic operations such as pattern
addition or subtraction, enlargement and reflection:

> ![Reflections](img/carpet.png)

To more complication operations such as sub-pattern finding by flood-filling,
Voronoi tessellation of patterns, hull finding or Binary Space Partitioning. All
operations being defined on various choices of 2D neighbourhoods (e.g Moore, Von
Neumann).

Requirements
------------

A lua@5.1 or luajit installation should be all that is required to use this module.
See the examples folder for some demonstration.

Documentation
-------------

Documentation is provided by [LDoc](https://github.com/stevedonovan/LDoc).
Simply running ```ldoc .``` in the root directory should generate all the
required pages.

Testing
-------

Unit tests are provided for some methods with the
[luaunit](https://github.com/bluebird75/luaunit) framework. To run the tests use
``` lua ./tests/<test>.lua ```
