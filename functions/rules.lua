--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

print("Successful Compilation\n")

local function movePlayer(command)
	for _, block in pairs(Puzzl3D["World"]["Blocks"]) do
		if block["Type"] == "Player" then
			if command == "North" and block["Position"][3] ~= Puzzl3D["World"]["Size"][3] - 1 then
				block["Position"][3] = block["Position"][3] + 1
			elseif command == "South" and block["Position"][3] > 0 then
				block["Position"][3] = block["Position"][3] - 1
			elseif command == "East" and block["Position"][1] ~= Puzzl3D["World"]["Size"][1] - 1 then
				block["Position"][1] = block["Position"][1] + 1
			elseif command == "West" and block["Position"][1] > 0 then
				block["Position"][1] = block["Position"][1] - 1
			elseif command == "Up" and block["Position"][2] ~= Puzzl3D["World"]["Size"][2] - 1 then
				block["Position"][2] = block["Position"][2] + 1
			elseif command == "Down" and block["Position"][2] > 0 then
				block["Position"][2] = block["Position"][2] - 1
			end
		end
	end
end

local function runEarlyRules()
	
end

local function runMovement()
	
end

local function runLateRules()
	
end

local function runTurn(command)
	print("Applying rules")
	print("Turn starts with input of "..string.lower(command)..".")
	
	movePlayer(command)
	print("Processed movements.")
	
	print("Turn commplete\n")
end

return {
	runTurn = runTurn
}