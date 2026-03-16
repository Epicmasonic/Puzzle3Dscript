--- @diagnostic disable: undefined-global, undefined-field, undefined-doc-name

-- Helper functions

-- Cool stuff

--- Gets an input by stopping the program until it has one
--- @return key key The key code of the key that was pressed
local function waitForInput()
	local _, key = os.pullEvent("key")
	return key
end

--- Gets an input by opening a window of time to get one
--- @return key key The key code of the key that was pressed
local function getInput(delay)
	-- Start a short timer (for non-blocking wait)
	local timer = os.startTimer(delay)
	
	while true do
		local event, param = os.pullEvent()
		if event == "key" then
			local key = param
		elseif event == "timer" and param == timer then
			break
		end
	end
	
	return key
end

--- Normalizes movement input based on the camera's rotation
--- @param camera {[1]: number, [2]: number, [3]: number, [4]: number, [5]: number} The X, Y, and Z coordinates of the camera in 3D space as well as the camera's pitch and yaw in degrees
--- @param speed number The speed of the movement (Should often be 1 or -1)
--- @param axis string The axis to move along, either "X", "Y", or "Z"
--- @return number speed The new speed of the movement (Should still often be 1 or -1)
--- @return string axis The new axis to move along, either "X", "Y", or "Z"
local function normalizeMovement(camera, speed, axis)
	if camera[5] % 360 > 45 and camera[5] % 360 <= 135 then -- Looking from the right
--	if camera[5] % 360 >= 90 and camera[5] % 360 < 180 then
		if axis == "X" then
			axis = "Z"
		elseif axis == "Z" then
			axis = "X"
			speed = -speed
		end
	elseif camera[5] % 360 > 135 and camera[5] % 360 <= 225 then -- Looking from the back
--	elseif camera[5] % 360 >= 180 and camera[5] % 360 < 270 then
		speed = -speed
	elseif camera[5] % 360 > 225 and camera[5] % 360 <= 315 then -- Looking from the left
--	elseif camera[5] % 360 >= 270 then
		if axis == "X" then
			axis = "Z"
			speed = -speed
		elseif axis == "Z" then
			axis = "X"
		end
	end
	
	return speed, axis
end

return {
	waitForInput = waitForInput,
	getInput = getInput,
	normalizeMovement = normalizeMovement
}