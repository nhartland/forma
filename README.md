forma
=====

This package is intended for the generation and manipulation of shapes on a two
dimensional grid. It came about as part of my experiments in making roguelike
games, and is therefore particuarly suited for the generation of roguelike
environments.

Along with a set of useful tools, forma comes with a different way of thinking
algorithmically about the generation of shapes, in terms of operations upon
patterns.

Several such operations are provided, such as pattern addition, subtraction,
enlargement, smearing, reflection. Finding the outer hull of a pattern using an
arbitary neighbourhood, finding the voronoi tesselation of a set of points in a
pattern or finding the largest rectangle that can fit in a pattern are also
useful tools provided.

Requirements
------------

Basic lua@5.1 should be all that is required to use this module.
See the examples folder for some demonstration.

Documentation
-------------

Documentation is provided by *LDoc*. Simply running ```ldoc .``` in the root directory
should generate all the required pages.

Testing
-------

Unit tests are provided for some methods with the *busted* framework. To run the
tests use ``` busted ./tests/* ```
