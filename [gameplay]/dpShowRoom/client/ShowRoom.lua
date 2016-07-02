ShowRoom = {}

ShowRoom.room = {}
ShowRoom.podium = {}
ShowRoom.isActive = false
ShowRoom.currentCar = 1
ShowRoom.currentColor = 1

ShowRoom.freeLookEnabled = false

ShowRoom.Colors = {
	{ r = 0x24, g = 0x09, b = 0x35 },
	{ r = 0x47, g = 0x4a, b = 0x51 },
	{ r = 0x6a, g = 0x5f, b = 0x31 }
}

ShowRoom.Cars = {
	{
		model = 411, 
		price = 25000
	}, 
	{
		model = 562, 
		price = 28000
	},
	{
		model = 429, 
		price = 29000
	},
	{
		model = 600, 
		price = 30000
	}
}

ShowRoom.targetRotation = 0
ShowRoom.ROTATION_VELOCITY = -0.005

local mouseFrameDelay = 10
local prevMousePos = 0

local function update(dt)
	local podiumRotation = ShowRoom.podium.rotation
	if ShowRoom.freeLookEnabled then 
		local delta = podiumRotation.z - ShowRoom.targetRotation
		if delta > 180 then 
			delta = delta - 360 
		elseif delta < -180 then
			delta = delta + 360 
		end
		if math.abs(delta) > 5 then
			local direction = (delta) / math.abs(delta) 
			ShowRoom.podium.rotation = Vector3(podiumRotation.x, podiumRotation.y, 
				podiumRotation.z + direction * 10 * ShowRoom.ROTATION_VELOCITY * dt)
			ShowRoom.vehicle.rotation = ShowRoom.podium.rotation
		end
		return
	end

	ShowRoom.podium.rotation = Vector3(podiumRotation.x, podiumRotation.y, 
		podiumRotation.z + ShowRoom.ROTATION_VELOCITY * dt)
	ShowRoom.vehicle.rotation = ShowRoom.podium.rotation
end

local function onLeftArrowUp()
	ShowRoom.changeCar(-1)
end

local function onRightArrowUp()
	ShowRoom.changeCar(1)
end

local function onUpArrowUp()
	ShowRoom.changeColor(1)
end

local function onDownArrowUp()
	ShowRoom.changeColor(-1)
end

local function onClientCursorMove(cX, cY, aX, aY)
	if not ShowRoom.freeLookEnabled then 
		return 
	end
	if isMTAWindowActive() or isCursorShowing() then 
		mouseFrameDelay = 10
		return
	elseif mouseFrameDelay > 0 then 
		mouseFrameDelay = mouseFrameDelay - 1
		return
	end

	local width, height = guiGetScreenSize()

	-- Center offsets
	aX = aX - width / 2
	ShowRoom.targetRotation = ShowRoom.targetRotation + aX * 0.017
	ShowRoom.targetRotation = math.mod(ShowRoom.targetRotation, 360)
	if ShowRoom.targetRotation < 0 then
		ShowRoom.targetRotation = ShowRoom.targetRotation + 360
	end
	-- outputChatBox(tostring(offset))
	-- outputChatBox(tostring(ShowRoom.podium.rotation))
end

ShowRoom.changeCar = function(inc)
	ShowRoom.currentCar = (ShowRoom.currentCar + inc)
	if ShowRoom.currentCar > #ShowRoom.Cars then 
		ShowRoom.currentCar = 1
	elseif ShowRoom.currentCar < 1 then 
		ShowRoom.currentCar = #ShowRoom.Cars
	end
	ShowRoom.vehicle.model = ShowRoom.Cars[ShowRoom.currentCar].model
end

ShowRoom.changeColor = function(inc)
	ShowRoom.currentColor = (ShowRoom.currentColor + inc)
	if ShowRoom.currentColor > #ShowRoom.Colors then 
		ShowRoom.currentColor = 1
	elseif ShowRoom.currentColor < 1 then 
		ShowRoom.currentColor = #ShowRoom.Colors
	end
	local color = ShowRoom.Colors[ShowRoom.currentColor]
	setVehicleColor(ShowRoom.vehicle, color.r, color.g, color.b)
end

function ShowRoom.start()
	if ShowRoom.isActive then 
		return false
	end

	return true
end

local function toggleFreeLook()
	ShowRoom.targetRotation = ShowRoom.podium.rotation.z
	ShowRoom.freeLookEnabled = not ShowRoom.freeLookEnabled
end

function ShowRoom.start()
	if ShowRoom.isActive then 
		return false
	end
	ShowRoom.isActive = true
	ShowRoom.vehicle = createVehicle(ShowRoom.Cars[ShowRoom.currentCar].model, 1500, 1500, 1498)
	setTimer(function()
		local color = ShowRoom.Colors[ShowRoom.currentColor]
		setVehicleColor(ShowRoom.vehicle, color.r, color.g, color.b)
	end, 500, 1)
	-- Dimension машины и объектов
	ShowRoom.podium.dimension = localPlayer.dimension
	ShowRoom.room.dimension = localPlayer.dimension
	ShowRoom.vehicle.dimension = localPlayer.dimension

	CameraManager.start()

	bindKey("arrow_l", "up", onLeftArrowUp)
	bindKey("arrow_r", "up", onRightArrowUp)
	bindKey("arrow_u", "up", onUpArrowUp)
	bindKey("arrow_d", "up", onDownArrowUp)	
	bindKey("e", "up", toggleFreeLook)
	bindKey("backspace", "down", exitShowRoom)
	addEventHandler("onClientPreRender", root, update)
	addEventHandler("onClientCursorMove", root, onClientCursorMove)

	toggleAllControls(false)
	exports.dpHUD:setVisible(false)
	showChat(false)
	return true
end

function ShowRoom.stop()
	if not ShowRoom.isActive then 
		return false
	end
	ShowRoom.isActive = false

	CameraManager.stop()

	unbindKey("arrow_l", "up", onLeftArrowUp)
	unbindKey("arrow_r", "up", onRightArrowUp)
	unbindKey("arrow_u", "up", onUpArrowUp)
	unbindKey("arrow_d", "up", onDownArrowUp)
	unbindKey("e", "up", toggleFreeLook)
	removeEventHandler("onClientPreRender", root, update)
	removeEventHandler("onClientCursorMove", root, onClientCursorMove)

	showChat(true)
	exports.dpHUD:setVisible(true)
	toggleAllControls(true)

	destroyElement(ShowRoom.vehicle)
	return true
end

addEventHandler("onClientResourceStart", resourceRoot, function()
	ShowRoom.podium = createObject(3782, 1500, 1500, 1497)
	ShowRoom.room = createObject(3781, 1500, 1500, 1500)

	local txd = engineLoadTXD("assets/object.txd")
    engineImportTXD(txd, 3781)
    local dff = engineLoadDFF("assets/object.dff")
    engineReplaceModel(dff, 3781)
    local col = engineLoadCOL("assets/object2.col")
    engineReplaceCOL(col, 3782)
    dff = engineLoadDFF("assets/object2.dff")
    engineImportTXD(txd, 3782)
    engineReplaceModel(dff, 3782)
end)
 