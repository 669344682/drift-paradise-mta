SearchScreen = {}
local screenSize = Vector2(guiGetScreenSize())
local UI = exports.dpUI
local ui = {}

local panelWidth = 400
local panelHeight = 250

local BUTTON_HEIGHT = 50
local counterTimer
local secoundsCount = 0

local foundGame = false
local acceptedGame = false
local lastMapsList = {}

local function onGameFound()
	foundGame = true
	acceptedGame = false
	UI:setType(ui.acceptButton, "primary")
	UI:setText(ui.acceptButton, exports.dpLang:getString("race_search_accept"))	

	UI:setText(ui.mainLabel, exports.dpLang:getString("race_search_race_fount"))
	UI:setText(ui.infoLabel, exports.dpLang:getString("race_search_press_accept"))
end
addEvent("dpRaceLobby.raceFound", true)
addEventHandler("dpRaceLobby.raceFound", resourceRoot, onGameFound)

local function updateTime()
	secoundsCount = secoundsCount + 1
	if foundGame then
		return
	end
	local minutesCount = math.floor(secoundsCount / 60)
	local time = secoundsCount % 60
	if time < 10 then
		time = "0" .. tostring(time)
	end
	if minutesCount < 10 then
		minutesCount = "0" .. tostring(minutesCount)
	end
	time = tostring(minutesCount) .. ":" .. time

	UI:setText(ui.acceptButton, exports.dpLang:getString("race_search_searching") .. " " .. time)
	UI:setType(ui.acceptButton, "default_dark")
end

function SearchScreen.startSearch(mapsList)
	if not mapsList then
		exports.dpUI:showMessageBox("Maps", "No maps selected")
		return false
	end
	lastMapsList = mapsList
	SearchScreen.setVisible(true)
	triggerServerEvent("dpRaceLobby.startSearch", resourceRoot, mapsList)
end

function SearchScreen.setVisible(visible)
	local isVisible = UI:getVisible(ui.panel)
	if not not isVisible == not not visible then
		return false
	end 

	UI:setVisible(ui.panel, visible)
	showCursor(visible)

	exports.dpHUD:setVisible(not visible)
	exports.dpUI:fadeScreen(visible)	

	foundGame = false
	acceptedGame = false

	if isTimer(counterTimer) then
		killTimer(counterTimer)
		counterTimer = nil
	end
	if visible then
		counterTimer = setTimer(updateTime, 1000, 0)
		secoundsCount = -1
		updateTime()

		UI:setText(ui.mainLabel, exports.dpLang:getString("race_search_searching_label"))
		local playersCount = root:getData("MatchmakingSearchingPlayersCount") or 12
		UI:setText(ui.infoLabel, exports.dpLang:getString("race_search_players_in_search")  .. " " .. tostring(playersCount))				
	end
end

addEventHandler("onClientResourceStart", resourceRoot, function ()
	ui.panel = UI:createDpPanel {
		x = (screenSize.x - panelWidth) / 2,
		y = (screenSize.y - panelHeight) / 1.7,
		width = panelWidth,
		height = panelHeight,
		type = "transparent"
	}
	UI:addChild(ui.panel)

	-- Кнопка "Отмена"
	ui.cancelButton = UI:createDpButton({
		x = 0,
		y = panelHeight - BUTTON_HEIGHT,
		width = panelWidth / 2,
		height = BUTTON_HEIGHT,
		locale = "race_search_cancel",
		type = "default_dark"
	})
	UI:addChild(ui.panel, ui.cancelButton)

	-- Кнопка "Принять"
	ui.acceptButton = UI:createDpButton({
		x = panelWidth / 2,
		y = panelHeight - BUTTON_HEIGHT,
		width = panelWidth / 2,
		height = BUTTON_HEIGHT,
		text = "...",
		type = "default_dark"
	})
	UI:addChild(ui.panel, ui.acceptButton)

	local labelOffset = 0.45
	ui.mainLabel = UI:createDpLabel({
		x = 0 , y = 0,
		width = panelWidth, height = panelHeight * labelOffset,
		type = "dark",
		fontType = "defaultLarge",
		text = "...",
		alignX = "center",
		alignY = "bottom"
	})
	UI:addChild(ui.panel, ui.mainLabel)

	ui.infoLabel = UI:createDpLabel({
		x = 0 , y = panelHeight * labelOffset,
		width = panelWidth, height = panelHeight * labelOffset - BUTTON_HEIGHT,
		type = "light",
		fontType = "defaultSmall",
		text = "...",
		color = tocolor(0, 0, 0, 100),
		alignX = "center",
		alignY = "top"
	})
	UI:addChild(ui.panel, ui.infoLabel)	

	UI:setVisible(ui.panel, false)
end)

addEvent("dpUI.click", false)
addEventHandler("dpUI.click", resourceRoot, function (widget)
	if widget == ui.cancelButton then
		SearchScreen.setVisible(false)
		MapsScreen.setVisible(true)
		triggerServerEvent("dpRaceLobby.cancelSearch", resourceRoot)
		lastMapsList = {}
	elseif widget == ui.acceptButton then
		if foundGame and not acceptedGame then
			acceptedGame = true
			triggerServerEvent("dpRaceLobby.acceptRace", resourceRoot)

			UI:setType(ui.acceptButton, "default_dark")
			UI:setText(ui.acceptButton, exports.dpLang:getString("race_search_waiting_button"))	

			UI:setText(ui.mainLabel, exports.dpLang:getString("race_search_waiting_label"))
			UI:setText(ui.infoLabel, string.format(
				exports.dpLang:getString("race_search_players_ready_count")
				"0", "0"
			))			
		end
	end
end)

addEvent("dpRaceLobby.raceCancelled", true)
addEventHandler("dpRaceLobby.raceCancelled", resourceRoot, function (player)
	if foundGame then
		SearchScreen.setVisible(false)
		SearchScreen.startSearch(lastMapsList)
		if player ~= client then
			exports.dpUI:showMessageBox(
				exports.dpLang:getString("race_search_reject_error_title"),
				exports.dpLang:getString("race_search_reject_error_body")
			)
		end
	end
end)

addEvent("dpRaceLobby.updateReadyCount", true)
addEventHandler("dpRaceLobby.updateReadyCount", resourceRoot, function (count, total)
	if not count or not total then
		return
	end
	if not foundGame or not acceptedGame then
		return
	end
	UI:setText(ui.infoLabel, string.format(
		exports.dpLang:getString("race_search_players_ready_count"),
		tostring(count), tostring(total)
	))		
end)

addEvent("dpRaceLobby.raceStart", true)
addEventHandler("dpRaceLobby.raceStart", resourceRoot, function ()
	SearchScreen.setVisible(false)
	lastMapsList = {}
end)