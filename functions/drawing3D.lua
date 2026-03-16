--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

local graphics = require("functions.drawing2D")

local requestStack = {}

-- Helper functions

--- Rotates a point around a pivot point by a given angle around a specified axis
--- @param point {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the point to rotate
--- @param pivot {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the pivot point to rotate around
--- @param axis string The axis to rotate around, either "X", "Y", or "Z"
--- @param angle number The angle to rotate by in degrees
local function rotatePoint(point, pivot, axis, angle)
	-- Convert the angle from degrees (user-friendly) to radians for math.sin/cos
	local rad = math.rad(angle)
	
	-- Normalize the point's position to be relative to the pivot
	local x = point[1] - pivot[1]
	local y = point[2] - pivot[2]
	local z = point[3] - pivot[3]
	
	local rx, ry, rz
	if axis == "X" then
		rx = x
		ry = y * math.cos(rad) - z * math.sin(rad)
		rz = y * math.sin(rad) + z * math.cos(rad)
	elseif axis == "Y" then
		rx = x * math.cos(rad) + z * math.sin(rad)
		ry = y
		rz = -x * math.sin(rad) + z * math.cos(rad)
	elseif axis == "Z" then
		rx = x * math.cos(rad) - y * math.sin(rad)
		ry = x * math.sin(rad) + y * math.cos(rad)
		rz = z
	end
	
	-- Put the point back in world space
	return {rx + pivot[1], ry + pivot[2], rz + pivot[3]}
end

local function getRelativePoint(camera, point)
	-- Normalize the point's position to be relative to the camera
	local relativePoint = {
		point[1] - camera[1],
		point[2] - camera[2],
		point[3] - camera[3]
	}
	
	-- Rotate the point based on the camera's rotation
	relativePoint = rotatePoint(relativePoint, {0, 0, 0}, "Y", camera[5])
	relativePoint = rotatePoint(relativePoint, {0, 0, 0}, "X", -camera[4])
	
	return relativePoint
end

--- Converts world coordinates to screen space coordinates
--- @param point {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the point in 3D space
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @return {[1]: integer, [2]: integer} screenSpacePoint The X and Y coordinates of the projected point on the 2D screen, or nil if the point is behind the camera
local function project(camera, point)
	-- Normalize the point's position to be relative to the camera
	local relativePoint = getRelativePoint(camera, point)
	
	if relativePoint[3] <= 0 then
		return {-10, -10} -- The point is behind the camera, so we don't need to care about it
	end
	
	local sw, sh = graphics.pixelDimensions()
	local fov = sw  -- tweak this to adjust field of view

	-- The perspective divide -- things further away (larger z) get
	-- divided by a bigger number, making them appear smaller
	local screenX = (relativePoint[1] / relativePoint[3]) * fov
	local screenY = (relativePoint[2] / relativePoint[3]) * fov

	-- Offset from the center of the screen, and flip Y since screen Y goes downward but world Y typically goes upward
	return {
		math.floor(sw / 2 + screenX + 0.5),
		math.floor(sh / 2 - screenY + 0.5)
	}
end

-- Cool stuff

--- Draws a single line in 3D
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param start {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the line's start point in 3D space
--- @param finish {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the line's end point in 3D space
--- @param color Color The color to draw the line in
--- @param ZOverride number? An optional override for the Z-depth of the line, which is used for rendering order. By default, this is calculated as the average Z-depth of the start and end points.
local function request3DLine(camera, start, finish, color, ZOverride)
	local z
	if ZOverride then
		z = ZOverride
	else
		z = getRelativePoint(camera, start)[3] + getRelativePoint(camera, finish)[3] / 2
	end
	
	table.insert(requestStack, {
		["Z"] = z,
		["Type"] = "Line",
		["Data"] = {project(camera, start), project(camera, finish), color}
	})
end

--- Draws a hollow polygon in 3D
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param points {[1]: integer, [2]: integer, [3]: number}[] The points that make up the polygon, in order
--- @param color Color The color to draw the line in
local function request3DPolyline(camera, points, color)
	for i = 1, #points do
		request3DLine(camera, points[i], points[i % #points + 1], color)
	end
end

--- Draws a filled polygon in 3D
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param points {[1]: integer, [2]: integer, [3]: number}[] The points that make up the polygon, in order
--- @param color Color The color to fill the polygon with
--- @param outlineColor Color? The color to draw the outline in
local function request3DPolygon(camera, points, color, outlineColor)
	local points2D = {}
	local averageZ = 0
	for i = 1, #points do
		points2D[i] = project(camera, points[i])
		averageZ = averageZ + getRelativePoint(camera, points[i])[3]
	end
	
	table.insert(requestStack, {
		["Z"] = averageZ / #points,
		["Type"] = "Polygon",
		["Data"] = {points2D, color, outlineColor}
	})
end

--- Draws a wireframe box with variable size
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param position {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the cube's position in 3D space
--- @param width number The width of the cube
--- @param height number The height of the cube
--- @param depth number The depth of the cube
--- @param color Color The color to draw the cube in
local function requestBoxWireframe(camera, position, width, height, depth, color)
	local vertices = {
		   ["Top Northeast"] = {position[1] + 0.5 * width, position[2] + 0.5 * height, position[3] + 0.5 * depth},
		   ["Top Southeast"] = {position[1] + 0.5 * width, position[2] + 0.5 * height, position[3] - 0.5 * depth},
		["Bottom Northeast"] = {position[1] + 0.5 * width, position[2] - 0.5 * height, position[3] + 0.5 * depth},
		["Bottom Southeast"] = {position[1] + 0.5 * width, position[2] - 0.5 * height, position[3] - 0.5 * depth},
		   ["Top Northwest"] = {position[1] - 0.5 * width, position[2] + 0.5 * height, position[3] + 0.5 * depth},
		   ["Top Southwest"] = {position[1] - 0.5 * width, position[2] + 0.5 * height, position[3] - 0.5 * depth},
		["Bottom Northwest"] = {position[1] - 0.5 * width, position[2] - 0.5 * height, position[3] + 0.5 * depth},
		["Bottom Southwest"] = {position[1] - 0.5 * width, position[2] - 0.5 * height, position[3] - 0.5 * depth}
	} -- These names are so I don't mess up the vertices when connecting them with lines. I could probably go without them.
	
	-- East to West lines
	request3DLine(camera, vertices["Top Northeast"], vertices["Top Northwest"], color)
	request3DLine(camera, vertices["Top Southeast"], vertices["Top Southwest"], color)
	request3DLine(camera, vertices["Bottom Northeast"], vertices["Bottom Northwest"], color)
	request3DLine(camera, vertices["Bottom Southeast"], vertices["Bottom Southwest"], color)
	
	-- Top to Bottom lines
	request3DLine(camera, vertices["Top Northeast"], vertices["Bottom Northeast"], color)
	request3DLine(camera, vertices["Top Northwest"], vertices["Bottom Northwest"], color)
	request3DLine(camera, vertices["Top Southeast"], vertices["Bottom Southeast"], color)
	request3DLine(camera, vertices["Top Southwest"], vertices["Bottom Southwest"], color)
	
	-- North to South lines
	request3DLine(camera, vertices["Top Northeast"], vertices["Top Southeast"], color)
	request3DLine(camera, vertices["Top Northwest"], vertices["Top Southwest"], color)
	request3DLine(camera, vertices["Bottom Northeast"], vertices["Bottom Southeast"], color)
	request3DLine(camera, vertices["Bottom Northwest"], vertices["Bottom Southwest"], color)
end

--- Draws a wireframe unit cube
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param position {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the cube's position in 3D space
--- @param color Color The color to draw the cube in
local function requestVoxelWireframe(camera, position, color)
	requestBoxWireframe(camera, position, 1, 1, 1, color)
end

--- Draws a box with variable size
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param position {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the cube's position in 3D space
--- @param width number The width of the cube
--- @param height number The height of the cube
--- @param depth number The depth of the cube
--- @param color Color The color to draw the cube in
--- @param outlineColor Color? The color to draw the outline in
local function requestBox(camera, position, width, height, depth, color, outlineColor)
	local vertices = {
		   ["Top Northeast"] = {position[1] + 0.5 * width, position[2] + 0.5 * height, position[3] + 0.5 * depth},
		   ["Top Southeast"] = {position[1] + 0.5 * width, position[2] + 0.5 * height, position[3] - 0.5 * depth},
		["Bottom Northeast"] = {position[1] + 0.5 * width, position[2] - 0.5 * height, position[3] + 0.5 * depth},
		["Bottom Southeast"] = {position[1] + 0.5 * width, position[2] - 0.5 * height, position[3] - 0.5 * depth},
		   ["Top Northwest"] = {position[1] - 0.5 * width, position[2] + 0.5 * height, position[3] + 0.5 * depth},
		   ["Top Southwest"] = {position[1] - 0.5 * width, position[2] + 0.5 * height, position[3] - 0.5 * depth},
		["Bottom Northwest"] = {position[1] - 0.5 * width, position[2] - 0.5 * height, position[3] + 0.5 * depth},
		["Bottom Southwest"] = {position[1] - 0.5 * width, position[2] - 0.5 * height, position[3] - 0.5 * depth}
	} -- These names are so I don't mess up the vertices when connecting them with lines. I could probably go without them.
	
	-- Top face
	request3DPolygon(
		camera,
		{
			vertices["Top Northeast"],
			vertices["Top Northwest"],
			vertices["Top Southwest"],
			vertices["Top Southeast"]
		},
		color,
		outlineColor
	)
	
	-- North face
	request3DPolygon(
		camera,
		{
			vertices["Top Northeast"],
			vertices["Top Northwest"],
			vertices["Bottom Northwest"],
			vertices["Bottom Northeast"]
		},
		color,
		outlineColor
	)
	
	-- East face
	request3DPolygon(
		camera,
		{
			vertices["Top Northeast"],
			vertices["Top Southeast"],
			vertices["Bottom Southeast"],
			vertices["Bottom Northeast"]
		},
		color,
		outlineColor
	)
	
	-- South face
	request3DPolygon(
		camera,
		{
			vertices["Top Southeast"],
			vertices["Top Southwest"],
			vertices["Bottom Southwest"],
			vertices["Bottom Southeast"]
		},
		color,
		outlineColor
	)
	
	-- West face
	request3DPolygon(
		camera,
		{
			vertices["Top Northwest"],
			vertices["Top Southwest"],
			vertices["Bottom Southwest"],
			vertices["Bottom Northwest"]
		},
		color,
		outlineColor
	)
	
	-- Bottom face
	request3DPolygon(
		camera,
		{
			vertices["Bottom Northeast"],
			vertices["Bottom Northwest"],
			vertices["Bottom Southwest"],
			vertices["Bottom Southeast"]
		},
		color,
		outlineColor
	)
end

--- Draws a unit cube
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param position {[1]: number, [2]: number, [3]: number} The X, Y, and Z coordinates of the cube's position in 3D space
--- @param color Color The color to draw the cube in
--- @param outlineColor Color? The color to draw the outline in
local function requestVoxel(camera, position, color, outlineColor)
	requestBox(camera, position, 1, 1, 1, color, outlineColor)
end

local function render()
	term.setFrozen(true)
	term.clear()
	
	table.sort(requestStack, function(a, b) return a["Z"] > b["Z"] end)
	for _, request in pairs(requestStack) do
		if request["Type"] == "Line" then
			graphics.drawLine(request["Data"][1], request["Data"][2], request["Data"][3])
		elseif request["Type"] == "Polygon" then
			graphics.drawPolygon(request["Data"][1], request["Data"][2], request["Data"][3])
		end
	end
	
	requestStack = {}
	term.setFrozen(false)
end

return {
	simple = graphics,
	rotatePoint = rotatePoint,
	getRelativePoint = getRelativePoint,
	
	draw3DLine = request3DLine,
	draw3DPolyline = request3DPolyline,
	draw3DPolygon = request3DPolygon,
	
	drawVoxelWireframe = requestVoxelWireframe,
	drawBoxWireframe = requestBoxWireframe,
	drawVoxel = requestVoxel,
	drawBox = requestBox,
	
	render = render
}