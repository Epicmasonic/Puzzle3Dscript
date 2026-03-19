--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

Puzzl3D = {}

-- For testing
Puzzl3D["Block Types"] = {
	["Player"] = {
		["Color"] = colors.purple,
		["Layer"] = 0
	},
	["Wall"] = {
		["Color"] = colors.brown,
		["Layer"] = 0
	},
	["Box"] = {
		["Color"] = colors.orange,
		["Layer"] = 0
	},
	["Target"] = {
		["Color"] = colors.blue,
		["Layer"] = 1
	}
}

Puzzl3D["Rules"] = { -- This is actually rule GROUPS but...
	{
		{
			["Before"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "North"
				},
				{
					["Type"] = "Box",
					["Position"] = {0, 0, 1},
					["Movement"] = "None"
				}
			},
			["After"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "North"
				},
				{
					["Type"] = "Box",
					["Position"] = {0, 0, 1},
					["Movement"] = "North"
				}
			}
		},
		{
			["Before"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "East"
				},
				{
					["Type"] = "Box",
					["Position"] = {1, 0, 0},
					["Movement"] = "None"
				}
			},
			["After"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "East"
				},
				{
					["Type"] = "Box",
					["Position"] = {1, 0, 0},
					["Movement"] = "East"
				}
			}
		},
		{
			["Before"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 1},
					["Movement"] = "South"
				},
				{
					["Type"] = "Box",
					["Position"] = {0, 0, 0},
					["Movement"] = "None"
				}
			},
			["After"] = {
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 1},
					["Movement"] = "South"
				},
				{
					["Type"] = "Box",
					["Position"] = {0, 0, 0},
					["Movement"] = "South"
				}
			}
		},
		{
			["Before"] = {
				{
					["Type"] = "Player",
					["Position"] = {1, 0, 0},
					["Movement"] = "West"
				},
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "None"
				}
			},
			["After"] = {
				{
					["Type"] = "Player",
					["Position"] = {1, 0, 0},
					["Movement"] = "West"
				},
				{
					["Type"] = "Player",
					["Position"] = {0, 0, 0},
					["Movement"] = "West"
				}
			}
		}
	}
}

Puzzl3D["World"] = {
	["Size"] = {4, 3, 5},
	["Blocks"] = {
		{
			["Type"] = "Player",
			["Position"] = {1, 0, 2},
			["Movement"] = "None"
		},
		{
			["Type"] = "Target",
			["Position"] = {0, 0, 2},
			["Movement"] = "None"
		},
		{
			["Type"] = "Box",
			["Position"] = {2, 0, 1},
			["Movement"] = "None"
		},
		{
			["Type"] = "Box",
			["Position"] = {0, 0, 2},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {2, 0, 0},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {3, 0, 0},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {3, 0, 4},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {2, 0, 4},
			["Movement"] = "None"
		},
		{
			["Type"] = "Target",
			["Position"] = {1, 0, 4},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {2, 0, 3},
			["Movement"] = "None"
		},
		{
			["Type"] = "Wall",
			["Position"] = {3, 0, 3},
			["Movement"] = "None"
		}
	}
}

print("\n=================================\n")
term.setGraphicsMode(1)
term.clear()

local renderer = require("functions.renderer")
local inputs = require("functions.inputs")
local rules = require("functions.rules")

local stepSize = 6
while true do
	renderer.buildWorld(Puzzl3D["World"], Puzzl3D["Block Types"])
	
	local key = inputs.waitForInput()
	--Camera Movement
	if key == keys.up then
		renderer.moveCamera("Up")
	elseif key == keys.right then
		renderer.moveCamera("Right")
	elseif key == keys.down then
		renderer.moveCamera("Down")
	elseif key == keys.left then
		renderer.moveCamera("Left")
	elseif key == keys.e then
		rules.runTurn("Up")
	elseif key == keys.q then
		rules.runTurn("Down")
	elseif key == keys.w then
		rules.runTurn(inputs.normalizeMovement(Puzzl3D["Camera"], "North"))
	elseif key == keys.a then
		rules.runTurn(inputs.normalizeMovement(Puzzl3D["Camera"], "West"))
	elseif key == keys.s then
		rules.runTurn(inputs.normalizeMovement(Puzzl3D["Camera"], "South"))
	elseif key == keys.d then
		rules.runTurn(inputs.normalizeMovement(Puzzl3D["Camera"], "East"))
	end
	
--	sleep(0.1)
end