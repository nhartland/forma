--- Lazy import into global space of all forma modules.
-- The more rigourous procedure of
--  local cell = require('forma.cell')
-- is recommended.
cell          = require('forma.cell')
pattern       = require('forma.pattern')
primitives    = require('forma.primitives')
automata      = require('forma.automata')
neighbourhood = require('forma.neighbourhood')
raycasting    = require('forma.raycasting')
