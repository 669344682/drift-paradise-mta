-- Выбор автомобиля
GarageCar = {}

addEvent("dpGarage.loaded", false)

local CAR_POSITION = Vector3 { x = 2915.438, y = -3186.282, z = 2535.244 }
local vehicle
local vehiclesList = {}
local currentVehicle = 1
local currentTuningTable = {}

-- Время, на которое размораживается машина при смене модели
local VEHICLE_UNFREEZE_TIME = 600
local unfreezeTimer

-- Дата, которая округляется при сохранении
local configurationData = {
	"WheelsOffsetF", 
	"WheelsOffsetR", 
	"WheelsWidthF", 
	"WheelsWidthR", 
	"WheelsAngleF", 
	"WheelsAngleR", 
	"WheelsSize"
}
-- Цвета, которые выставляются белыми по умолчанию
local colorsData = {
	"BodyColor", 
	"WheelsColorR", 
	"WheelsColorF", 
	"SpoilerColor"
}
-- Дата, которая копируется как есть
local copyData = {
	"Numberplate"
}

local function updateVehicle()
	if not vehiclesList[currentVehicle] then
		outputDebugString("Could not load vehicle: " .. tostring(currentVehicle))
		return
	end

	vehicle.model = vehiclesList[currentVehicle].model

	vehicle:setColor(255, 0, 0, 255, 255, 255)
	-- Разморозка машины на 1 сек
	vehicle.frozen = false
	vehicle.velocity = Vector3(0, 0, -0.01)
	vehicle.position = CAR_POSITION
	if isTimer(unfreezeTimer) then killTimer(unfreezeTimer) end
	unfreezeTimer = setTimer(function ()
		vehicle.frozen = true
	end, VEHICLE_UNFREEZE_TIME, 1)


	currentTuningTable = {}
	if type(vehiclesList[currentVehicle].tuning) == "string" then
		currentTuningTable = fromJSON(vehiclesList[currentVehicle].tuning)
	end


	-- Наклейки
	local stickersJSON = vehiclesList[currentVehicle].stickers
	if stickersJSON then
		local stickers = fromJSON(stickersJSON)
		if type(stickers) ~= "table" then
			stickers = {}
		end
		vehicle:setData("stickers", stickers)	
	else
		vehicle:setData("stickers", {})
	end
	GarageCar.resetTuning()
	CarTexture.reset()
end

function GarageCar.getId()
	return vehiclesList[currentVehicle]._id
end

function GarageCar.start(vehicles)
	vehiclesList = vehicles
	currentVehicle = 1
	vehicle = createVehicle(411, CAR_POSITION)
	unfreezeTimer = setTimer(function ()
		vehicle.frozen = true
	end, VEHICLE_UNFREEZE_TIME, 1)
	vehicle.rotation = Vector3(0, 0, -90)

	addEventHandler("dpGarage.loaded", resourceRoot, updateVehicle)

	vehicle:setData("LightsState", false, false)
end

function GarageCar.stop()
	if isElement(vehicle) then
		destroyElement(vehicle)
	end
	removeEventHandler("dpGarage.loaded", resourceRoot, updateVehicle)
end

function GarageCar.getVehicle()
	return vehicle
end

function GarageCar.showNextCar()
	currentVehicle = currentVehicle + 1
	if currentVehicle > #vehiclesList then
		currentVehicle = 1
	end
	updateVehicle()
end

function GarageCar.showPreviousCar()
	currentVehicle = currentVehicle - 1
	if currentVehicle < 1 then
		currentVehicle = #vehiclesList
	end
	updateVehicle()
end

function GarageCar.showCarById(id)
	for i, vehicle in ipairs(vehiclesList) do
		if vehicle._id == id then
			currentVehicle = i
			updateVehicle()
			return true
		end
	end
	return false
end

function GarageCar.previewTuning(name, value)
	vehicle:setData(name, value)
end

function GarageCar.applyTuning(name, value)
	vehicle:setData(name, value)
	currentTuningTable[name] = value
end

function GarageCar.applyTuningFromData(name)
	currentTuningTable[name] = vehicle:getData(name)
end

function GarageCar.resetTuning()
	-- Сброс компонентов
	local componentNames = exports.dpVehicles:getComponentsNames()

	for i, name in ipairs(componentNames) do
		vehicle:setData(name, currentTuningTable[name])
	end

	for i, name in ipairs(configurationData) do
		local value = currentTuningTable[name]
		if type(value) == "number" then
			vehicle:setData(name, value)
		else
			vehicle:setData(name, 0)
		end
	end

	-- Цвета
	for i, name in ipairs(colorsData) do
		if currentTuningTable[name] then
			vehicle:setData(name, currentTuningTable[name])
		else
			vehicle:setData(name, {255, 255, 255})
		end
	end

	for i, name in ipairs(copyData) do
		vehicle:setData(name, currentTuningTable[name])
	end

	-- Размер колёс по-умолчанию
	if not currentTuningTable["WheelsSize"] then
		local defaultWheelsSize = exports.dpVehicles:getModelDefaultWheelsSize(vehicle.model)
		if not defaultWheelsSize then
			defaultWheelsSize = 0.69
		end
		GarageCar.applyTuning("WheelsSize", defaultWheelsSize)
	end

	if not currentTuningTable["Numberplate"] then
		GarageCar.applyTuning("Numberplate", "DRIFT")
	end
end

function GarageCar.getTuningTable()
	local componentNames = exports.dpVehicles:getComponentsNames()
	local tuningTable = {}
	for i, name in ipairs(componentNames) do
		tuningTable[name] = vehicle:getData(name)
	end

	for i, name in ipairs(configurationData) do
		tuningTable[name] = vehicle:getData(name)
		if type(tuningTable[name]) == "number" then
			tuningTable[name] = math.floor(tuningTable[name] * 100) / 100
		end
	end	

	for i, name in ipairs(colorsData) do
		tuningTable[name] = vehicle:getData(name)
		if not tuningTable[name] then
			tuningTable[name] = {255, 255, 255}
		end
	end

	for i, name in ipairs(copyData) do
		tuningTable[name] = vehicle:getData(name)
	end

	-- TODO:
	-- BodyTexture 	= false
	-- NeonColor 		= false
	-- Nitro 			= 0
	-- Windows			= 0
	return tuningTable
end

function GarageCar.save()
	CarTexture.save()
	local tuningTable = GarageCar.getTuningTable()
	vehiclesList[currentVehicle].tuning = toJSON(tuningTable)
	vehiclesList[currentVehicle].stickers = toJSON(vehicle:getData("stickers"))
	triggerServerEvent("dpGarage.saveCar", resourceRoot,
		currentVehicle, 
		tuningTable,
		vehicle:getData("stickers")
	)
end

function GarageCar.getComponentsCount(name)
	if not name then
		return 0
	end
	if 	name == "Spoilers" or 
		name == "Numberplate" or
		name == "WheelsF" or
		name == "WheelsR"
	then
		return 1
	end	
	local count = 0
	for i = 1, 50 do
		if not vehicle:getComponentPosition(name .. tostring(i)) then
			return count
		end
		count = count + 1
	end
	return count
end