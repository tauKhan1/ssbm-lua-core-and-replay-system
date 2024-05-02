
local inputs = {}
local added = 0
local last_input_high = 0
local last_input_low = 0

local pending_entry = {"none"}

function isDZ(num)

	return (105 < num) and (num < 151)
end

function isNotSkipFrame(num)

	return not((num%1000 == 499) or ((num%1000 == 500) and (num%2000 == 1500)))
	
end

function interpretEntry(high, low)
	local entry = {}
	local buttons = ""
	if (high & (1 << 25)) ~= 0 then
		buttons = buttons .. "A"
	end

	if (high & (1 << 26))  ~= 0 then
		buttons = buttons .. "B"
	end
	if (high & (1 << 27))  ~= 0 then
		buttons = buttons .. "X"
	end
	if (high & (1 << 28))  ~= 0 then
		buttons = buttons .. "Y"	
	end
	if (high & (1 << 29))  ~= 0 then
		buttons = buttons .. "Z"	
	end

	if (high & (1 << 18))  ~= 0 then

		buttons = buttons .. "L"	
	end

	if (high & (1 << 19))  ~= 0 then
		buttons = buttons .. "R"	
	end
	if (high & (1 << 24))  ~= 0 then
		buttons = buttons .. "S"	
	end

	if (high & (1 << 30))  ~= 0 then
		buttons = buttons .. "DU"	
	end
	if (high & (1 << 31))  ~= 0 then
		buttons = buttons .. "DD"	
	end
	if (high & (1 << 16))  ~= 0 then
		buttons = buttons .. "DF"	
	end
	if (high & (1 << 17))  ~= 0 then
		buttons = buttons .. "DG"	
	end

	local stickX = (low >> 24) & 255
	local stickY = (low >> 16) & 255
	local stickCX = (low >> 8) & 255
	local stickCY = low & 255


	if (buttons == "") then
		if isDZ(stickY) and isDZ(stickCY) and isDZ(stickCX) then
			if isDZ(stickX) then
				entry[1] = "idle"
				entry[2] = 1
			elseif stickX > 150 then

				entry[1] = "right"
				entry[2] = 1
				entry[3] = stickX
			else
				entry[1] = "left"
				entry[2] = 1
				entry[3] = stickX
			end
		
		elseif isDZ(stickX) and isDZ(stickCY) and isDZ(stickCX) then
			
			if stickY > 150 then

				entry[1] = "up"
				entry[2] = 1
				entry[3] = stickY

			else

				entry[1] = "down"
				entry[2] = 1
				entry[3] = stickY
			end
		
		else
				entry[1] = "sticks"
				entry[2] = 1
				entry[3] = stickX
				entry[4] = stickY
				entry[5] = stickCX
				entry[6] = stickCY
		end

	else 
		entry[1] = "all"
		entry[2] = 1
		entry[3] = buttons
		entry[4] = stickX
		entry[5] = stickY
		entry[6] = stickCX
		entry[7] = stickCY
	end

	return entry
end

function onScriptStart()

	num_inputs = ReadValue32(0x804E6BF0)
	current = 169

	while current < num_inputs do

		new_entry_high = ReadValue32(0x804E6BF4 + current*8)
		new_entry_low = ReadValue32(0x804E6BF4 + current*8 + 4)		
		
		if pending_entry[1] == "none" then
			last_input_high = new_entry_high
			last_input_low = new_entry_low
			pending_entry = interpretEntry(new_entry_high, new_entry_low)

		elseif (new_entry_high == last_input_high) and (new_entry_low == last_input_low) then
			pending_entry[2] = pending_entry[2] + 1
		
		else
			added = added + 1
			inputs[added] = pending_entry
			pending_entry = interpretEntry(new_entry_high, new_entry_low)
			last_input_high = new_entry_high
			last_input_low = new_entry_low
		end

		if isNotSkipFrame(current) then
			current = current + 1
		end
		current = current + 1
	
	end
	
	added = added + 1
	inputs[added] = pending_entry
	
	inputfile = io.open("Sys/Scripts/inputfiles/inputs.lua", "w")
	io.output(inputfile)
	io.write("local inputs = {")

	
	for entry_index, input_entry in ipairs(inputs) do
		local outputString = ""
		if entry_index ~= 1 then outputString = outputString .. ","
		end
		
		if input_entry[1] == "up" or input_entry[1] == "down" or input_entry[1] == "left" or input_entry[1] =="right" then
			outputString = outputString .. string.format("\n{%q, %u, %u}",input_entry[1], input_entry[2], input_entry[3])
		elseif input_entry[1] == "idle" then 
			outputString = outputString .. string.format("\n{%q, %u}",input_entry[1], input_entry[2])

		elseif input_entry[1] == "sticks" then
			outputString = outputString .. string.format("\n{%q, %u, %u, %u, %u, %u}",input_entry[1], input_entry[2], input_entry[3], input_entry[4], input_entry[5], input_entry[6])
		elseif input_entry[1] == "all" then
			outputString = outputString .. string.format("\n{%q, %u, %q, %u, %u, %u, %u}", input_entry[1], input_entry[2], input_entry[3], input_entry[4], input_entry[5], input_entry[6], input_entry[7])

		else
			outputString = outputString .. tostring(input_entry)
		end
		io.write(outputString)
	end

	io.write("\n}\nreturn inputs")
	io.close()
			
end

function onScriptCancel()
end

function onScriptUpdate()
end