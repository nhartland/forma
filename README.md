`forma`
=======

This package is intended for the generation and manipulation of shapes on a two
dimensional grid. It came about as part of experiments in making roguelike
games, and is therefore particularly suited for the generation of roguelike
environments.

`forma` provides a basic data structure for 2-D grid shapes or `patterns` and a
number of useful tools for their manipulation. Several such operations are
provided, starting with basic operations such as pattern addition, subtraction
and reflection. More involved operations, such as the finding of hulls using
various neighbourhoods (e.g Moore, Von Neumann), or finding the Voronoi
tesselation of a set of points in a pattern are also provided.

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
