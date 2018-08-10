project = 'forma'
title = 'forma Reference'
description = 'A 2D grid shape generation package'
kind_names={topic='Readme'}
format = 'markdown' 
readme = 'README.md'
not_luadoc = true

examples = {'examples',
             exclude = {'examples/README.md', 'examples/gallery.lua'}}

file = {
        './forma/cell.lua',
        './forma/pattern.lua',
        './forma/primitives.lua',
        './forma/subpattern.lua',
        './forma/automata.lua',
        './forma/neighbourhood.lua'
    }
