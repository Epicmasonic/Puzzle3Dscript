--- @diagnostic disable: undefined-global, undefined-field, lowercase-global, undefined-doc-name

local graphics = require("functions.drawing3D")
local inputs = require("functions.inputs")

term.setGraphicsMode(1)

term.clear()

x, y = graphics.simple.pixelDimensions()

local gridWidth = 7
local gridHeight = 3
local gridDepth = 5

local diagonal = math.sqrt(gridWidth ^ 2 + gridHeight ^ 2 + gridDepth ^ 2)
local radius = diagonal * 2

stepSize = 6
camera = {
	0,       -- X
	0,       -- Y
	-radius, -- Z
	0,       -- Pitch
	0        -- Yaw
}

player = {
	0, 	                         -- X
	-math.floor(gridHeight / 2), -- Y
	0,                           -- Z
}

blockTypes = {
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

world = {
	{
		["Type"] = "Player",
		["Position"] = {0, 0, 0}
	}
}

--- Draws a wireframe box with variable size (but it's a differnt so I can workaround painter's algorithm)
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param width number The width of the cube
--- @param height number The height of the cube
--- @param depth number The depth of the cube
--- @param color Color The color to draw the cube in
local function drawBorder(camera, width, height, depth, color)
	vertices = {
		   ["Top Northeast"] = {0.5 * width, 0.5 * height, 0.5 * depth},
		   ["Top Southeast"] = {0.5 * width, 0.5 * height, -0.5 * depth},
		["Bottom Northeast"] = {0.5 * width, -0.5 * height, 0.5 * depth},
		["Bottom Southeast"] = {0.5 * width, -0.5 * height, -0.5 * depth},
		   ["Top Northwest"] = {-0.5 * width, 0.5 * height, 0.5 * depth},
		   ["Top Southwest"] = {-0.5 * width, 0.5 * height, -0.5 * depth},
		["Bottom Northwest"] = {-0.5 * width, -0.5 * height, 0.5 * depth},
		["Bottom Southwest"] = {-0.5 * width, -0.5 * height, -0.5 * depth}
	} -- These names are so I don't mess up the vertices when connecting them with lines. I could probably go without them.
	
	lines = {	
		-- East to West lines
		{vertices["Top Northeast"], vertices["Top Northwest"]},
		{vertices["Top Southeast"], vertices["Top Southwest"]},
		{vertices["Bottom Northeast"], vertices["Bottom Northwest"]},
		{vertices["Bottom Southeast"], vertices["Bottom Southwest"]},
		
		-- Top to Bottom lines
		{vertices["Top Northeast"], vertices["Bottom Northeast"]},
		{vertices["Top Northwest"], vertices["Bottom Northwest"]},
		{vertices["Top Southeast"], vertices["Bottom Southeast"]},
		{vertices["Top Southwest"], vertices["Bottom Southwest"]},
		
		-- North to South lines
		{vertices["Top Northeast"], vertices["Top Southeast"]},
		{vertices["Top Northwest"], vertices["Top Southwest"]},
		{vertices["Bottom Northeast"], vertices["Bottom Southeast"]},
		{vertices["Bottom Northwest"], vertices["Bottom Southwest"]}
	}
	
	-- Find closest
	local closestVertex
	local bestScore = math.huge
	for _, vertex in pairs(vertices) do
		local score = graphics.getRelativePoint(camera, vertex)[3]
		if score < bestScore then
			bestScore = score
			closestVertex = vertex
		end
	end
	
	for _, line in pairs(lines) do
		if line[1] == closestVertex or line[2] == closestVertex then
			graphics.draw3DLine(camera, line[1], line[2], color, -math.huge)
		else
			graphics.draw3DLine(camera, line[1], line[2], color, math.huge)
		end
	end
end

while true do
	local blockOrigin = {
		(gridWidth - 1) / -2,
		(gridHeight - 1) / -2,
		(gridDepth - 1) / -2
	}
	for _, block in pairs(world) do
		graphics.drawVoxel(camera, {blockOrigin[1] + block["Position"][1], blockOrigin[2] + block["Position"][2], blockOrigin[3] + block["Position"][3]}, blockTypes[block["Type"]]["Color"], colors.gray)
	end
	
	drawBorder(camera, gridWidth + 0.1, gridHeight + 0.1, gridDepth + 0.1, colors.white)
	graphics.render()
	
	key = inputs.waitForInput()
	if key == keys.w or key == keys.d or key == keys.s or key == keys.a or key == keys.q or key == keys.e then
		local speed = 1
		if key == keys.a or key == keys.q or key == keys.s then
			speed = -speed
		end
		
		if key == keys.w or key == keys.a or key == keys.s or key == keys.d then
			local axis
			if key == keys.w or key == keys.s then
				axis = "Z"
			else
				axis = "X"
			end
			
			speed, axis = inputs.normalizeMovement(camera, speed, axis)
			if axis == "X" then
				player[1] = player[1] + speed
			elseif axis == "Z" then
				player[3] = player[3] + speed
			end
		else
			player[2] = player[2] + speed
		end
	elseif key == keys.up or key == keys.right or key == keys.down or key == keys.left then
		local rotation = 360 / 2 ^ stepSize
		if key == keys.left or key == keys.down then
			rotation = -rotation
		end
		
		if key == keys.left or key == keys.right then
			camera[5] = camera[5] + rotation
		else
			camera[4] = camera[4] + rotation
			camera[4] = math.max(-90, math.min(90, camera[4]))
		end
		
		-- Orbit the camera around the origin
		camera[1] = math.cos(math.rad(camera[4])) * math.sin(math.rad(camera[5])) * radius
		camera[2] = math.sin(math.rad(camera[4])) * radius
		camera[3] = math.cos(math.rad(camera[4])) * -math.cos(math.rad(camera[5])) * radius
	end
	
--	print("Camera position: " .. camera[1] .. ", " .. camera[2] .. ", " .. camera[3])
--	print("Camera rotation: " .. camera[4] .. ", " .. camera[5])
	
	sleep(0.05)
end