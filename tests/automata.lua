--- Tests of forma cellular-automata implementation
local lu = require('luaunit')
local pattern       = require("forma.pattern")
local automata      = require("forma.automata")
local primitives    = require("forma.primitives")
local neighbourhood = require("forma.neighbourhood")

testAutomata = {}

function testAutomata:setUp()
    -- Ruleset for Conway's GOL
    self.life_rule= automata.rule(neighbourhood.moore(), "B3/S23")

    -- Domain
    self.sixbysix   = primitives.square(6)

    -- Still lifes in GOL
    self.block   = pattern.new({{0,0,0,0,0,0},
                                {0,1,1,0,0,0},
                                {0,1,1,0,0,0},
                                {0,0,0,0,0,0},
                                {0,0,0,0,0,0},
                                {0,0,0,0,0,0}})

    self.beehive = pattern.new({{0,0,0,0,0,0},
                                {0,0,1,1,0,0},
                                {0,1,0,0,1,0},
                                {0,0,1,1,0,0},
                                {0,0,0,0,0,0},
                                {0,0,0,0,0,0}})

    self.loaf    = pattern.new({{0,0,0,0,0,0},
                                {0,0,1,1,0,0},
                                {0,1,0,0,1,0},
                                {0,0,1,0,1,0},
                                {0,0,0,1,0,0},
                                {0,0,0,0,0,0}})
    self.stills = {self.block, self.beehive, self.loaf}

    -- Period 2 oscillators in GOL
    self.blinker = pattern.new({{0,0,0,0,0,0},
                                {0,0,1,0,0,0},
                                {0,0,1,0,0,0},
                                {0,0,1,0,0,0},
                                {0,0,0,0,0,0},
                                {0,0,0,0,0,0}})

    self.toad    = pattern.new({{0,0,0,0,0,0},
                                {0,0,0,0,0,0},
                                {0,0,1,1,1,0},
                                {0,1,1,1,0,0},
                                {0,0,0,0,0,0},
                                {0,0,0,0,0,0}})

    self.beacon  = pattern.new({{0,0,0,0,0,0},
                                {0,1,1,0,0,0},
                                {0,1,1,0,0,0},
                                {0,0,0,1,1,0},
                                {0,0,0,1,1,0},
                                {0,0,0,0,0,0}})
    self.oscillators = {self.blinker, self.toad, self.beacon}

end

-- Test that all still lives immediately converge
function testAutomata:testStillLifes()
    for _, still in ipairs(self.stills) do
        local newstill, converged = automata.iterate(still, self.sixbysix, {self.life_rule})
        lu.assertTrue(converged)
        lu.assertEquals(newstill, still)
    end
end

-- Test that all oscillators have period 2
function testAutomata:testOscillators()
    for _, oscillator in ipairs(self.oscillators) do
        local newoscillator, converged = automata.iterate(oscillator, self.sixbysix, {self.life_rule})
        newoscillator, converged = automata.iterate(newoscillator, self.sixbysix, {self.life_rule})
        lu.assertFalse(converged)
        lu.assertEquals(newoscillator, oscillator)
    end
end

-- Test the asynchronous CA update
function testAutomata:testAsynchronous()
    -- Verify all synchronous oscillators differ only by one cell
    for _, oscillator in ipairs(self.oscillators) do
        local newoscillator, converged = automata.async_iterate(oscillator, self.sixbysix, {self.life_rule})
        lu.assertFalse(converged)
        lu.assertEquals(math.abs(newoscillator:size() - oscillator:size()), 1)
    end
    -- Verify block CA remains a still-life in asynchronous update
    local _, converged = automata.async_iterate(self.block, self.sixbysix, {self.life_rule})
    lu.assertTrue(converged)
end

