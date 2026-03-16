--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

Puzzl3D = {}

-- For testing
Puzzl3D["Block Types"] = {
	["Player"] = {
		["Color"] = colors.purple
	},
	["Wall"] = {
		["Color"] = colors.brown
	},
	["Box"] = {
		["Color"] = colors.orange
	}
}

Puzzl3D["World"] = {
	["Size"] = {7, 5, 3},
	["Blocks"] = {
		{
			["Type"] = "Player",
			["Position"] = {0, 0, 0}
		},
		{
			["Type"] = "Wall",
			["Position"] = {3, 0, 0}
		},
		{
			["Type"] = "Wall",
			["Position"] = {3, 0, 1}
		},
		{
			["Type"] = "Box",
			["Position"] = {2, 0, 1}
		}
	}
}

local renderer = require("functions.renderer")
local inputs = require("functions.inputs")
local data = require("functions.rules")

term.setGraphicsMode(1)

term.clear()

local stepSize = 6
while true do
	renderer.buildWorld(Puzzl3D["World"], Puzzl3D["Block Types"])
	
	local key = inputs.waitForInput()
	if key == keys.up or key == keys.right or key == keys.down or key == keys.left then
		if key == keys.up then
			renderer.moveCamera("Up")
		elseif key == keys.right then
			renderer.moveCamera("Right")
		elseif key == keys.down then
			renderer.moveCamera("Down")
		elseif key == keys.left then
			renderer.moveCamera("Left")
		end
	end
	
--	sleep(0.1)
end