--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

-- Helper functions

--- Gets the size of the screen
--- @return integer x The width of the screen in pixels
--- @return integer y The height of the screen in pixels
local function pixelDimensions()
	return term.getSize(term.getGraphicsMode() or 1)
end

--- Linearly interpolates between two numbers
--- @param start number The starting number
--- @param finish number The ending number
--- @param percent number The percentage to interpolate between the two numbers, between 0 and 1
--- @return number output The interpolated number
local function lerp(start, finish, percent)
	return start + (finish - start) * percent
end

--- Linearly interpolates between two points
--- @param start {[1]: integer, [2]: integer} The starting point
--- @param finish {[1]: integer, [2]: integer} The ending point
--- @param percent number The percentage to interpolate between the two points, between 0 and 1
--- @return { [1]: number, [2]: number } output The interpolated point
local function lerpPoint(start, finish, percent)
	return {lerp(start[1], finish[1], percent), lerp(start[2], finish[2], percent)}
end

--- Calculates the diagonal distance between two points
--- @param pointA {[1]: integer, [2]: integer} The first point
--- @param pointB {[1]: integer, [2]: integer} The second point
--- @return integer distance The diagonal distance between the two points
local function diagonalDistance(pointA, pointB)
	local dx = pointB[1] - pointA[1]
	local dy = pointB[2] - pointA[2]
	return math.max(math.abs(dx), math.abs(dy))
end

--- Rounds the X and Y values of a point
--- @param point { [1]: number, [2]: number } The point to round
--- @return {[1]: integer, [2]: integer} rounded The rounded point
local function roundPoint(point)
	return {math.floor(point[1] + 0.5), math.floor(point[2] + 0.5)}
end

-- The cool stuff

--- Draws a single pixel onto the screen
--- @param point {[1]: integer, [2]: integer} The X and Y coordinates of the pixel to draw
--- @param color Color The color to draw the pixel in
local function drawPixel(point, color)
	term.setPixel(point[1], point[2], color)
end

--- Draws a line between two points using that algorithm I found from Red Blob Games
--- @param start {[1]: integer, [2]: integer} The starting point
--- @param finish {[1]: integer, [2]: integer} The ending point
--- @param color Color The color to draw the line in
local function drawLine(start, finish, color)
	local distance = diagonalDistance(start, finish)
	
	if distance == 0 then
		drawPixel(start, color)
		return
	end
	
	for i = 0, distance do
		--sleep(delay)
		drawPixel(roundPoint(lerpPoint(start, finish, i / distance)), color)
	end
end

--- Draws a hollow polygon onto the screen
--- @param points {[1]: integer, [2]: integer}[] The points that make up the polygon, in order
--- @param color Color The color to draw the line in
local function drawPolyline(points, color)
	for i = 1, #points do
		drawLine(points[i], points[i % #points + 1], color)
	end
end

--- Draws a filled polygon onto the screen (Claude made (most of) this function :/)
--- @param points {[1]: integer, [2]: integer}[] The points that make up the polygon, in order
--- @param color Color The color to fill the polygon with
--- @param outlineColor Color? The color to draw the outline in
local function drawPolygon(points, color, outlineColor)
	if not outlineColor then
		outlineColor = color
	end
	
	-- Find vertical bounds
	local minY, maxY = points[1][2], points[1][2]
	for i = 2, #points do
		minY = math.min(minY, points[i][2])
		maxY = math.max(maxY, points[i][2])
	end
	
	-- Scan each row
	for y = minY, maxY do
		local intersections = {}

		for i = 1, #points do
			local a = points[i]
			local b = points[i % #points + 1]

			-- Check if this edge crosses the current scanline
			if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
				-- X coordinate where the edge crosses y
				local t = (y - a[2]) / (b[2] - a[2])
				intersections[#intersections + 1] = a[1] + t * (b[1] - a[1])
			end
		end

		-- Sort intersections left to right, then fill between pairs
		table.sort(intersections)
		for i = 1, #intersections - 1, 2 do
			local x1 = math.floor(intersections[i] + 0.5)
			local x2 = math.floor(intersections[i + 1] + 0.5)
			for x = x1, x2 do
				--sleep(delay)
				drawPixel({x, y}, color)
			end
		end
	end

	drawPolyline(points, outlineColor) -- Draw the outline last so it's on top
end

-- Exports

return {
	pixelDimensions = pixelDimensions,
	drawPixel = drawPixel,
	drawLine = drawLine,
	drawPolyline = drawPolyline,
	drawPolygon = drawPolygon,
}