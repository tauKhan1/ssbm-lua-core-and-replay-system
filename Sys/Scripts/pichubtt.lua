
local c = require "Melee_core"
local input_runner = require "input_runner"

function onScriptStart()
    input_runner.interpretInputFile("pichubttinputs")
end

function onStateLoaded()
    c.timerRestart()
end

function onStateSaved()
end

function onScriptCancel()
end

function onScriptUpdate()
    c.timerUpdate()
    nextInputs = c.timerNextInput()
    input_runner.executeInputs(nextInputs)	
end