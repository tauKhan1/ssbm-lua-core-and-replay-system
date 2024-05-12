
local r = {}
local inputs = {}
local num_inputs = 0 
local x_orig = 0
local y_orig = 0
local cx_orig = 0
local cy_orig = 0


function parseCommand(command)
	if command[1] == "all" then
		for _ = 1, command[2] do
			num_inputs = num_inputs + 1
			inputs[num_inputs] = {}
			inputs[num_inputs][1] = command[3]
                        inputs[num_inputs][2] = command[4]
			inputs[num_inputs][3] = command[5]
			inputs[num_inputs][4] = command[6]
  			inputs[num_inputs][5] = command[7]
--			inputs[num_inputs][6] = command[8]
--			inputs[num_inputs][7] = command[9]
		end
	elseif command[1] == "idle" then
		for _ = 1, command[2] do
			num_inputs = num_inputs + 1
			inputs[num_inputs] = {}
			inputs[num_inputs][1] = ""
			inputs[num_inputs][2] = 128
			inputs[num_inputs][3] = 128
			inputs[num_inputs][4] = 128
			inputs[num_inputs][5] = 128
		end

	elseif command[1] == "up" or command[1] == "down" then
		for _ = 1, command[2] do
			num_inputs = num_inputs + 1
			inputs[num_inputs] = {}
			inputs[num_inputs][1] = ""
			inputs[num_inputs][2] = 128
			inputs[num_inputs][3] = command[3]
			inputs[num_inputs][4] = 128
			inputs[num_inputs][5] = 128
		end

	elseif command[1] == "left" or command[1] == "right" then
		for _ = 1, command[2] do
			num_inputs = num_inputs + 1
			inputs[num_inputs] = {}
			inputs[num_inputs][1] = ""
			inputs[num_inputs][2] = command[3]
			inputs[num_inputs][3] = 128
			inputs[num_inputs][4] = 128
			inputs[num_inputs][5] = 128
		end

	elseif command[1] == "sticks" then
		for _ = 1, command[2] do
			num_inputs = num_inputs + 1
			inputs[num_inputs] = {}
			inputs[num_inputs][1] = ""
                        inputs[num_inputs][2] = command[3]
			inputs[num_inputs][3] = command[4]
			inputs[num_inputs][4] = command[5]
  			inputs[num_inputs][5] = command[6]

		end
	end


	
end

r.parseCommand = parseCommand

function interpretInputFile(f)
	inputs = {}
	local script_name = f .. ".lua"
	package.path = GetScriptsDir() .. "/inputfiles/" .. script_name
	local input_script = require(script_name)
        
	for _ , entry in ipairs(input_script) do

		parseCommand(entry)
	end
end

r.interpretInputFile = interpretInputFile

function toSInt8(val)
	if val > 127 then
		val = val - 256
	end
	return val
end

function updateOrigin()
	
	x_orig = toSInt8(ReadValue8(0x804a89b2))
	y_orig = toSInt8(ReadValue8(0x804a89b3))
	cx_orig = toSInt8(ReadValue8(0x804a89b4))
	cy_orig = toSInt8(ReadValue8(0x804a89b5))
	-- SetScreenText(string.format("%s, %s, %s, %s", x_orig, y_orig, cx_orig, cy_orig))
end

	

function executeInputs(index)

	updateOrigin()
	if inputs[index] ~= nil then
		input = inputs[index]
		buttons = input[1]
 		if string.find(buttons, "A") ~= nil then
			PressButton("A")		
		end
 		if string.find(buttons, "B") ~= nil then
			PressButton("B")		
		end
 		if string.find(buttons, "X") ~= nil then
			PressButton("X")		
		end	
 		if string.find(buttons, "Y") ~= nil then
			PressButton("Y")		
		end
 		if string.find(buttons, "Z") ~= nil then
			PressButton("Z")		
		end
 		if string.find(buttons, "L") ~= nil then
			PressButton("L")		
		end		
 		if string.find(buttons, "R") ~= nil then
			PressButton("R")		
		end
 		if string.find(buttons, "S") ~= nil then
			PressButton("Start")		
		end
 		SetMainStickX(input[2] + x_orig)
		SetMainStickY(input[3] + y_orig)

		SetCStickX(input[4] + cx_orig)
		SetCStickY(input[5] + cy_orig)

		
	end
end
r.executeInputs = executeInputs

return r