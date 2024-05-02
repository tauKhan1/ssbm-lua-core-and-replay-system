
function onScriptStart()
	startFrame = GetFrameCount()
end

function onScriptCancel()
end

function onScriptUpdate()
	frameDiff = GetFrameCount() - startFrame
	if frameDiff > 200 then 
		save_identifier = ReadValue8(0x8006ad30)
		if save_identifier ~= 0x4B then
			MsgBox("Warning, input saver is not enabled")
		end
		CancelScript()
	end
			
end