--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

local graphics = require("functions.drawing3D")

local x, y = graphics.simple.pixelDimensions()

local diagonal = math.sqrt(Puzzl3D["World"]["Size"][1] ^ 2 + Puzzl3D["World"]["Size"][2] ^ 2 + Puzzl3D["World"]["Size"][3] ^ 2)
local radius = diagonal * 2

--local stepSize = 6
Puzzl3D["Camera"] = {
	0,       -- X
	0,       -- Y
	-radius, -- Z
	0,       -- Pitch
	0        -- Yaw
}

--- Draws a wireframe box with variable size (but it's a differnt so I can workaround painter's algorithm)
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param width number The width of the cube
--- @param height number The height of the cube
--- @param depth number The depth of the cube
--- @param color Color The color to draw the cube in
local function drawBorder(camera, width, height, depth, color)
	local vertices = {
		   ["Top Northeast"] = {0.5 * width, 0.5 * height, 0.5 * depth},
		   ["Top Southeast"] = {0.5 * width, 0.5 * height, -0.5 * depth},
		["Bottom Northeast"] = {0.5 * width, -0.5 * height, 0.5 * depth},
		["Bottom Southeast"] = {0.5 * width, -0.5 * height, -0.5 * depth},
		   ["Top Northwest"] = {-0.5 * width, 0.5 * height, 0.5 * depth},
		   ["Top Southwest"] = {-0.5 * width, 0.5 * height, -0.5 * depth},
		["Bottom Northwest"] = {-0.5 * width, -0.5 * height, 0.5 * depth},
		["Bottom Southwest"] = {-0.5 * width, -0.5 * height, -0.5 * depth}
	} -- These names are so I don't mess up the vertices when connecting them with lines. I could probably go without them.
	
	local lines = {	
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

local function buildWorld(world, blockTypes)
	local blockOrigin = {
		(world["Size"][1] - 1) / -2,
		(world["Size"][2] - 1) / -2,
		(world["Size"][3] - 1) / -2
	}
	for _, block in pairs(world["Blocks"]) do
		graphics.drawVoxel(Puzzl3D["Camera"], {blockOrigin[1] + block["Position"][1], blockOrigin[2] + block["Position"][2], blockOrigin[3] + block["Position"][3]}, blockTypes[block["Type"]]["Color"], colors.gray)
	end
	
	drawBorder(Puzzl3D["Camera"], Puzzl3D["World"]["Size"][1] + 0.1, Puzzl3D["World"]["Size"][2] + 0.1, Puzzl3D["World"]["Size"][3] + 0.1, colors.white)
	graphics.render()
end

local stepSize = 6
local function moveCamera(command)
	local rotation = 360 / 2 ^ stepSize
	if command == "Left" or command == "Down" then
		rotation = -rotation
	end
	
	if command == "Left" or command == "Right" then
		Puzzl3D["Camera"][5] = Puzzl3D["Camera"][5] + rotation
	else
		Puzzl3D["Camera"][4] = Puzzl3D["Camera"][4] + rotation
		Puzzl3D["Camera"][4] = math.max(-90, math.min(90, Puzzl3D["Camera"][4]))
	end
	
	-- Orbit the camera around the origin
	Puzzl3D["Camera"][1] = math.cos(math.rad(Puzzl3D["Camera"][4])) * math.sin(math.rad(Puzzl3D["Camera"][5])) * radius
	Puzzl3D["Camera"][2] = math.sin(math.rad(Puzzl3D["Camera"][4])) * radius
	Puzzl3D["Camera"][3] = math.cos(math.rad(Puzzl3D["Camera"][4])) * -math.cos(math.rad(Puzzl3D["Camera"][5])) * radius
end

return {
	buildWorld = buildWorld,
	moveCamera = moveCamera
}