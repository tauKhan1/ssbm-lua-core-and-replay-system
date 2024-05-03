
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
    nextInputs = c.timerCurrentFrame() + 1
    iFrameCountRemainder = GetFrameCount()%4
    if iFrameCountRemainder  < 2 then 
    	input_runner.executeInputs(nextInputs)
	c.press("Z")
    end
end