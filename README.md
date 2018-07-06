[![Build Status](https://travis-ci.org/nhartland/forma.svg?branch=master)](https://travis-ci.org/nhartland/forma)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

forma
=====

__2D grid shape generation in Lua__ 

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/si0FhKN.png">
</p>

This package is intended for the generation and manipulation of shapes on a two
dimensional grid or lattice. It came about as part of experiments in making
roguelike games. **forma** is therefore particularly suited for the generation
of roguelike environments.

Shapes can be generated in several ways. From simple rasters of primitive shapes
like circles, lines and squares, to pattern generation by a [Cellular
Automata](https://en.wikipedia.org/wiki/Cellular_automaton) (CA) implementation,
including both synchronous and asynchronous update rules. Using the CA methods,
patterns such as the classic 4-5 rule 'cave' systems can be generated:

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/r6D7hxb.png">
</p>

However the real power of the CA implementation is in its flexibility.
Different CA rules with custom cellular *neighbourhoods* (including
[Moore](https://en.wikipedia.org/wiki/Moore_neighborhood), [von
Neumann](https://en.wikipedia.org/wiki/Von_Neumann_neighborhood) and more) may
be combined. Patterns can also be recursively generated by nesting the result of
one pattern in another. Interesting structures can therefore be formed by
combining different CA rule sets with different neighbourhoods and domains. For
example a 'corridor' structure:

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/PF7cMw7.png">
</p>

In addition to pattern generation tools, **forma** implements several useful
methods for the manipulation of patterns. Basic operations such as pattern
addition or subtraction, enlargement and reflection are included. On top of
these, various useful methods are provided, such as flood-filling, Voronoi
tessellation, hull finding or Binary Space Partitioning. Once again most of
these operations can be performed under custom definitions of the cellular
neighbourhood.

Further operations upon patterns can be easily implemented making use of a
masking procedure, as shown in an example demonstrating thresholded [Worley
noise](https://en.wikipedia.org/wiki/Worley_noise):

<p align="center">
  <img width="650" height="320" src="https://i.imgur.com/Gyn4QLx.png">
</p>

All of the above examples can be generated by code in the `examples` folder.

Warning
-------
The master branch is in active development. API breaking changes may
occasionally occur.

Requirements
------------
Compatible with Lua 5.1, 5.2, 5.3 and LuaJIT 2.0, 2.1.

The test suite requires
 - [LuaCov](https://keplerproject.github.io/luacov/)
 - [luaunit](https://github.com/bluebird75/luaunit)

Generating the documentation requires
 - [LDoc](https://github.com/stevedonovan/LDoc)

Running examples
----------------

The examples require that the `forma/` directory is in the lua path. The easiest
way to try the examples is to run them from the root directory of this repo. For
example

    lua examples/game_of_life.lua

Generating documentation
------------------------

Documentation is hosted [here](https://nhartland.github.io/forma/).

Simply running 

    ldoc --output contents --dir docs .

in the root directory should generate all the required pages.

Testing
-------

Unit tests are provided for some methods with the luaunit framework, coverage is
tested using LuaCov. To run the tests use

    ./run_tests.sh
