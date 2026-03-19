--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

-- Helper functions

local function movePlayer(command)
	for _, block in pairs(Puzzl3D["World"]["Blocks"]) do
		if block["Type"] == "Player" then
			block["Movement"] = command
			
--			if command == "North" and block["Position"][3] ~= Puzzl3D["World"]["Size"][3] - 1 then
--				block["Position"][3] = block["Position"][3] + 1
--			elseif command == "South" and block["Position"][3] > 0 then
--				block["Position"][3] = block["Position"][3] - 1
--			elseif command == "East" and block["Position"][1] ~= Puzzl3D["World"]["Size"][1] - 1 then
--				block["Position"][1] = block["Position"][1] + 1
--			elseif command == "West" and block["Position"][1] > 0 then
--				block["Position"][1] = block["Position"][1] - 1
--			elseif command == "Up" and block["Position"][2] ~= Puzzl3D["World"]["Size"][2] - 1 then
--				block["Position"][2] = block["Position"][2] + 1
--			elseif command == "Down" and block["Position"][2] > 0 then
--				block["Position"][2] = block["Position"][2] - 1
--			end
		end
	end
end

local function getLayer(block)
	for name, info in pairs(Puzzl3D["Block Types"]) do
		if name == block["Type"] then
			return info["Layer"]
		end
	end
end

---Gets all the blocks at a specific location
---@param position {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number}
---@param layer? number
---@return table|Block
local function getBlocks(position, layer)
	local foundBlocks = {}
	
	for _, block in pairs(Puzzl3D["World"]["Blocks"]) do
		if block["Position"][1] == position[1] and block["Position"][2] == position[2] and block["Position"][3] == position[3] then
			if layer then
				local blockLayer = getLayer(block)
				
				if blockLayer == layer then
					return block
				end
			else
				table.insert(foundBlocks, block)
			end
		end
	end
	
	if not layer then
		return foundBlocks
	end
	return false
end

local function checkRule(rule)
	local farthestX = 0
	local farthestY = 0
	local farthestZ = 0
	for _, block in pairs(rule["Before"]) do
		if block["Position"][1] > farthestX then
			farthestX = block["Position"][1]
		end
		if block["Position"][2] > farthestY then
			farthestY = block["Position"][2]
		end
		if block["Position"][3] > farthestZ then
			farthestZ = block["Position"][3]
		end
	end
	
	local changeMadeOnce = false
	while true do
		local changeMade = false
		for x = 0, Puzzl3D["World"]["Size"][1] - farthestX do
		for y = 0, Puzzl3D["World"]["Size"][2] - farthestY do
		for z = 0, Puzzl3D["World"]["Size"][3] - farthestZ do
			local checkPassed = true
			for _, block in pairs(rule["Before"]) do
				local layer = getLayer(block)
				local foundBlock = getBlocks({x + block["Position"][1], y + block["Position"][2], z + block["Position"][3]}, layer)
				
				if not foundBlock or foundBlock["Type"] ~= block["Type"] or foundBlock["Movement"] ~= block["Movement"] then
					checkPassed = false
					break
				end
			end
			
			if checkPassed then
				print("Ran a rule at "..x..", "..y..", "..z)
				changeMade = true
				changeMadeOnce = true
				
				-- Turn `before` into `after`
				local toRemove = {}
				for _, beforeBlock in pairs(rule["Before"]) do
					local position = {x + beforeBlock["Position"][1], y + beforeBlock["Position"][2], z + beforeBlock["Position"][3]}
					local layer = getLayer(beforeBlock)
					
					for index, block in pairs(Puzzl3D["World"]["Blocks"]) do
						if block["Position"][1] == position[1] and block["Position"][2] == position[2] and block["Position"][3] == position[3] and getLayer(block) == layer then
							table.insert(toRemove, index)
						end
					end
				end
				
				for i = #toRemove, 1, -1 do
					table.remove(Puzzl3D["World"]["Blocks"], toRemove[i])
				end
				
				for _, afterBlock in pairs(rule["After"]) do
					local updatedAfterBlock = {
						["Type"] = afterBlock["Type"],
						["Position"] = {x + afterBlock["Position"][1], y + afterBlock["Position"][2], z + afterBlock["Position"][3]},
						["Movement"] = afterBlock["Movement"]
					}
					
					table.insert(Puzzl3D["World"]["Blocks"], updatedAfterBlock)
				end
			end
		end end end
		
		if not changeMade then
			return changeMadeOnce
		end
	end
end

local function checkRuleGroup(ruleGroup)
	while true do
		local changeMade = false
		
		for _, rule in pairs(ruleGroup) do
			changeMade = checkRule(rule) or changeMade
		end
		
		if not changeMade then
			return
		end
	end
end

-- Cool stuff

local function runEarlyRules()
	for _, ruleGroup in pairs(Puzzl3D["Rules"]) do
		checkRuleGroup(ruleGroup)
	end
end

local function runMovement()
	while true do
		local changeMade = false
		
		for _, block in pairs(Puzzl3D["World"]["Blocks"]) do
			local layer = getLayer(block)
			
			if block["Movement"] == "North" then
				local otherBlock = getBlocks({block["Position"][1], block["Position"][2], block["Position"][3] + 1}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][3] < Puzzl3D["World"]["Size"][3] - 1 and not otherBlock then
					changeMade = true
					block["Position"][3] = block["Position"][3] + 1
					block["Movement"] = "None"
				end
			elseif block["Movement"] == "South" then
				local otherBlock = getBlocks({block["Position"][1], block["Position"][2], block["Position"][3] - 1}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][3] > 0 and not otherBlock then
					changeMade = true
					block["Position"][3] = block["Position"][3] - 1
					block["Movement"] = "None"
				end
			elseif block["Movement"] == "East" then
				local otherBlock = getBlocks({block["Position"][1] + 1, block["Position"][2], block["Position"][3]}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][1] < Puzzl3D["World"]["Size"][1] - 1 and not otherBlock then
					changeMade = true
					block["Position"][1] = block["Position"][1] + 1
					block["Movement"] = "None"
				end
			elseif block["Movement"] == "West" then
				local otherBlock = getBlocks({block["Position"][1] - 1, block["Position"][2], block["Position"][3]}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][1] > 0 and not otherBlock then
					changeMade = true
					block["Position"][1] = block["Position"][1] - 1
					block["Movement"] = "None"
				end
			elseif block["Movement"] == "Up" then
				local otherBlock = getBlocks({block["Position"][1], block["Position"][2] + 1, block["Position"][3]}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][2] < Puzzl3D["World"]["Size"][2] - 1 and not otherBlock then
					changeMade = true
					block["Position"][2] = block["Position"][2] + 1
					block["Movement"] = "None"
				end
			elseif block["Movement"] == "Down" then
				local otherBlock = getBlocks({block["Position"][1], block["Position"][2] - 1, block["Position"][3]}, layer)
				
				if otherBlock and otherBlock["Movement"] == "None" then
					block["Movement"] = "None"
				elseif block["Position"][2] > 0 and not otherBlock then
					changeMade = true
					block["Position"][2] = block["Position"][2] - 1
					block["Movement"] = "None"
				end
			end
		end
		
		if not changeMade then
			return
		end
	end
end

local function runLateRules()
	
end

local function runTurn(command)
	print("Applying rules")
	movePlayer(command)
	print("Turn starts with input of "..string.lower(command)..".")
	
	runEarlyRules()
	
	runMovement()
	print("Processed movements.")
	
	runLateRules()
	
	print("Turn commplete\n")
end

return {
	runTurn = runTurn
}