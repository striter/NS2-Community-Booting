-- ======= Copyright (c) 2003-2020, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/GUIGameEndStats.lua
--
-- Ported by: Darrell Gentry (darrell@naturalselection2.com)
--
-- Port of the NS2+ end of round stats. It displays an amalgam of stats at the end of a round.
-- Originally Created By: Juanjo Alfaro "Mendasp"
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIGameEndStats' (GUIScript)

Script.Load("lua/graphs/LineGraph.lua")
Script.Load("lua/graphs/ComparisonBarGraph.lua")
Script.Load("lua/NS2Utility.lua")

local kButtonClickSound = "sound/NS2.fev/common/button_click"
local kMouseHoverSound = "sound/NS2.fev/common/hovar"
local kSlideSound = "sound/NS2.fev/marine/commander/hover_ui"
Client.PrecacheLocalSound(kButtonClickSound)
Client.PrecacheLocalSound(kMouseHoverSound)
Client.PrecacheLocalSound(kSlideSound)

local screenWidth = Client.GetScreenWidth()
local screenHeight = Client.GetScreenHeight()
local aspectRatio = screenWidth/screenHeight

local kSteamProfileURL = "http://steamcommunity.com/profiles/"
local kObservatoryUserURL = "https://observatory.morrolan.ch/player?steam_id="

-- To avoid printing 200.00 or things like that
local function printNum(number)
	if number and IsNumber(number) then
		if number == math.floor(number) then
			return string.format("%d", number)
		else
			return string.format("%.2f", number)
		end
	else
		return "NaN"
	end
end

local function printNum2(number)
	if number and IsNumber(number) then
		return string.format("%.2f", number)
	else
		return "NaN"
	end
end

local kTitleFontName = Fonts.kAgencyFB_Medium
local kSubTitleFontName = Fonts.kAgencyFB_Small
local kRowFontName = Fonts.kArial_17
local widthPercentage
local kTitleSize
local kCardSize
local kTechLogTitleSize
local kCloseButtonSize
local scaledVector
local kTopOffset
local rtGraphPadding
local rtGraphSize
local comparisonSize

local kMarineStatsColor = Color(0, 0.75, 0.88, 0.65)
local kAlienStatsColor = Color(0.84, 0.48, 0.17, 0.65)
local kCommanderStatsColor = Color(0.75, 0.75, 0, 0.65)
local kStatusStatsColor = Color(1, 1, 1, 0.65)
local kPlayerStatsTextColor = Color(1, 1, 1, 1)
local kMarinePlayerStatsEvenColor = Color(0, 0, 0, 0.75)
local kMarinePlayerStatsOddColor = Color(0, 0, 0, 0.65)
local kAlienPlayerStatsEvenColor = Color(0, 0, 0, 0.75)
local kAlienPlayerStatsOddColor = Color(0, 0, 0, 0.65)
local kCurrentPlayerStatsColor = Color(1, 1, 1, 0.75)
local kCurrentPlayerStatsTextColor = Color(0, 0, 0, 1)
local kCommanderStatsEvenColor = kMarinePlayerStatsEvenColor
local kCommanderStatsOddColor = kMarinePlayerStatsOddColor
local kLostTechEvenColor = Color(0.55, 0, 0, 1)
local kLostTechOddColor = Color(0.65, 0, 0, 1)
local kHeaderRowColor = Color(0, 0, 0, 0)
local kMarineHeaderRowTextColor = Color(1, 1, 1, 1)
local kMarineHeaderRowTextHighlightColor = Color(0, 0, 0, 1)
local kAlienHeaderRowTextColor = Color(1, 1, 1, 1)
local kAlienHeaderRowTextHighlightColor = Color(0, 0, 0, 1)
local kAverageRowColor = Color(0.05, 0.05, 0.05, 0.25)
local kAverageRowTextColor = Color(1, 1, 1, 1)

local kHeaderTexture = PrecacheAsset("ui/statsheader.dds")
local kHeaderCoordsLeft = { 0, 0, 15, 64 }
local kHeaderCoordsMiddle = { 16, 0, 112, 64 }
local kHeaderCoordsRight = { 113, 0, 128, 64 }
local kMarineStatsLogo = PrecacheAsset("ui/logo_marine.dds")
local kAlienStatsLogo = PrecacheAsset("ui/logo_alien.dds")
local kLogoSize
local kLogoOffset
local kTeamNameOffset
local kTextShadowOffset
local kPlayerCountOffset
local kContentMaxYSize

local kRowSize
local kCardRowSize
local kTechLogRowSize
local kTableContainerOffset
local kRowBorderSize
local kRowPlayerNameOffset

local finalStatsTable = {}
local playerStatMap = {}
local avgAccTable = {}
local miscDataTable = {}
local cardsTable = {}
local hiveSkillGraphTable = {}
local rtGraphTable = {}
local commanderStats
local killGraphTable = {}
local buildingSummaryTable = {}
local statusSummaryTable = {}
local techLogTable = {}

local lastStatsMsg = -100
local lastGameEnd = 0
local kMaxAppendTime = 2.5
local loadedLastRound = false
local lastRoundFile = "config://NS2Plus/LastRoundStats.json"

local highlightedField
local highlightedFieldMarine
local lastSortedT1 = "kills"
local lastSortedT1WasInv = false
local lastSortedT2 = "kills"
local lastSortedT2WasInv = false

local function estimateHiveSkillGraph()
	if #hiveSkillGraphTable ~= 0 or #finalStatsTable == 0 then
		return
	end

	-- split and sort into teams
	local teams = {}
	for _, stat in ipairs(finalStatsTable) do
		if stat.score ~= 0 and stat.minutesPlaying > 0 and stat.teamNumber ~= 0 then
			if not teams[stat.teamNumber] then
				teams[stat.teamNumber] = {}
			end
			table.insert(teams[stat.teamNumber],stat)
		end
	end

	if #teams < 2 then return end

	table.sort(teams[1], function(a, b) return a.minutesPlaying > b.minutesPlaying end)
	table.sort(teams[2], function(a, b) return a.minutesPlaying > b.minutesPlaying end)

	-- greedy knapsack
	local gameLength = miscDataTable.gameLengthMinutes
	local left = gameLength
	for _, team in ipairs(teams) do
		repeat
			left = gameLength
			for i, player in ipairs(team) do
				if player and player.minutesPlaying then
					if left - player.minutesPlaying >= 0 then
						table.insert(hiveSkillGraphTable,{ gameMinute = gameLength - left, joined = true, teamNumber = player.teamNumber, steamId = player.steamId })
						left = left - player.minutesPlaying
						table.insert(hiveSkillGraphTable,{ gameMinute = gameLength - left, joined = false, teamNumber = player.teamNumber, steamId = player.steamId })
						-- allow some time for others to react and join instead
						left = left - 10/60
						team[i] = {}
					end
				end
			end
		until left == gameLength
	end
end

local function UpdateSizeOfUI()
	screenWidth = Client.GetScreenWidth()
	screenHeight = Client.GetScreenHeight()
	aspectRatio = screenWidth/screenHeight

	widthPercentage = ConditionalValue(aspectRatio < 1.5, 0.95, 0.75)
	kTitleSize = Vector(screenWidth*widthPercentage, GUILinearScale(74), 0)
	kCardSize = Vector(kTitleSize.x/3.5, GUILinearScale(74), 0)
	kTechLogTitleSize = Vector(kTitleSize.x/2-GUILinearScale(16), GUILinearScale(74), 0)
	kCloseButtonSize = Vector(GUILinearScale(24), GUILinearScale(24), 0)
	scaledVector = GUILinearScale(Vector(1,1,1))
	kTopOffset = GUILinearScale(32)

	kLogoSize = GUILinearScale(Vector(52, 52, 0))
	kLogoOffset = GUILinearScale(4)
	kTeamNameOffset = GUILinearScale(10)
	kTextShadowOffset = GUILinearScale(2)
	kPlayerCountOffset = -GUILinearScale(20)
	kContentMaxYSize = screenHeight - GUILinearScale(128) - kTopOffset

	kRowSize = Vector(kTitleSize.x-(kLogoSize.x+kTeamNameOffset)*2, GUILinearScale(24), 0)
	kCardRowSize = Vector(kCardSize.x*0.85, GUILinearScale(24), 0)
	kTechLogRowSize = Vector(kTechLogTitleSize.x*0.85, GUILinearScale(24), 0)
	kTableContainerOffset = GUILinearScale(5)
	kRowBorderSize = GUILinearScale(2)
	kRowPlayerNameOffset = GUILinearScale(10)

	rtGraphPadding = GUILinearScale(50)
	rtGraphSize = Vector(kTitleSize.x*0.85, GUILinearScale(370), 0)
	comparisonSize = GUILinearScale(Vector(400,30,0))
end

function GUIGameEndStats:CreateTeamBackground(teamNumber)

	local color = kMarineStatsColor
	local teamLogo = kMarineStatsLogo
	local teamName = "Frontiersmen"

	if teamNumber == 2 then
		color = kAlienStatsColor
		teamLogo = kAlienStatsLogo
		teamName = "Kharaa"
	end

	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(color)
	item.background:SetTexture(kHeaderTexture)
	item.background:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(Vector(kTitleSize.x-GUILinearScale(64), kTitleSize.y, 0))

	item.backgroundLeft = GUIManager:CreateGraphicItem()
	item.backgroundLeft:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundLeft:SetColor(color)
	item.backgroundLeft:SetTexture(kHeaderTexture)
	item.backgroundLeft:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsLeft))
	item.backgroundLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundLeft:SetInheritsParentAlpha(false)
	item.backgroundLeft:SetLayer(kGUILayerMainMenu)
	item.backgroundLeft:SetSize(Vector(GUILinearScale(16), kTitleSize.y, 0))
	item.backgroundLeft:SetPosition(Vector(-GUILinearScale(16), 0, 0))
	item.background:AddChild(item.backgroundLeft)

	item.backgroundRight = GUIManager:CreateGraphicItem()
	item.backgroundRight:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundRight:SetColor(color)
	item.backgroundRight:SetTexture(kHeaderTexture)
	item.backgroundRight:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsRight))
	item.backgroundRight:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundRight:SetInheritsParentAlpha(false)
	item.backgroundRight:SetLayer(kGUILayerMainMenu)
	item.backgroundRight:SetSize(Vector(GUILinearScale(16), kTitleSize.y, 0))
	item.backgroundRight:SetPosition(Vector(kTitleSize.x-GUILinearScale(64), 0, 0))
	item.background:AddChild(item.backgroundRight)

	item.tableBackground = GUIManager:CreateGraphicItem()
	item.tableBackground:SetStencilFunc(GUIItem.NotEqual)
	item.tableBackground:SetColor(color)
	item.tableBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	item.tableBackground:SetPosition(Vector(-(kRowSize.x+kRowBorderSize*2)/2, -kTableContainerOffset, 0))
	item.tableBackground:SetLayer(kGUILayerMainMenu)
	item.tableBackground:SetSize(Vector(kRowSize.x + kRowBorderSize*2, kRowBorderSize*2, 0))
	item.background:AddChild(item.tableBackground)

	item.logo = GUIManager:CreateGraphicItem()
	item.logo:SetStencilFunc(GUIItem.NotEqual)
	item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.logo:SetLayer(kGUILayerMainMenu)
	item.logo:SetIsVisible(true)
	item.logo:SetSize(kLogoSize)
	item.logo:SetPosition(Vector(kLogoOffset, -kLogoSize.y/2, 0))
	item.logo:SetTexture(teamLogo)
	item.background:AddChild(item.logo)

	item.teamNameTextShadow = GUIManager:CreateTextItem()
	item.teamNameTextShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameTextShadow:SetFontName(kTitleFontName)
	item.teamNameTextShadow:SetColor(Color(0,0,0,1))
	item.teamNameTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(item.teamNameTextShadow)
	item.teamNameTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameTextShadow:SetText(teamName)
	item.teamNameTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameTextShadow:SetPosition(Vector(kLogoSize.x + kTeamNameOffset + kTextShadowOffset, kTitleSize.y/2 + kTextShadowOffset, 0))
	item.teamNameTextShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameTextShadow)

	item.teamNameText = GUIManager:CreateTextItem()
	item.teamNameText:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameText:SetFontName(kTitleFontName)
	item.teamNameText:SetColor(Color(1,1,1,1))
	item.teamNameText:SetScale(scaledVector)
	GUIMakeFontScale(item.teamNameText)
	item.teamNameText:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameText:SetText(teamName)
	item.teamNameText:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameText:SetPosition(Vector(kLogoSize.x + kTeamNameOffset, kTitleSize.y/2, 0))
	item.teamNameText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameText)

	item.teamGameStatusShadow = GUIManager:CreateTextItem()
	item.teamGameStatusShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamGameStatusShadow:SetFontName(kTitleFontName)
	item.teamGameStatusShadow:SetColor(Color(0,0,0,1))
	item.teamGameStatusShadow:SetScale(scaledVector)
	GUIMakeFontScale(item.teamGameStatusShadow)
	item.teamGameStatusShadow:SetAnchor(GUIItem.Middle, GUIItem.Center)
	item.teamGameStatusShadow:SetText("")
	item.teamGameStatusShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamGameStatusShadow:SetTextAlignmentX(GUIItem.Align_Center)
	item.teamGameStatusShadow:SetPosition(Vector(kTextShadowOffset, kTextShadowOffset, 0))
	item.teamGameStatusShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamGameStatusShadow)

	item.teamGameStatus = GUIManager:CreateTextItem()
	item.teamGameStatus:SetStencilFunc(GUIItem.NotEqual)
	item.teamGameStatus:SetFontName(kTitleFontName)
	item.teamGameStatus:SetColor(Color(1,1,1,1))
	item.teamGameStatus:SetScale(scaledVector)
	GUIMakeFontScale(item.teamGameStatus)
	item.teamGameStatus:SetAnchor(GUIItem.Middle, GUIItem.Center)
	item.teamGameStatus:SetText("")
	item.teamGameStatus:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamGameStatus:SetTextAlignmentX(GUIItem.Align_Center)
	item.teamGameStatus:SetPosition(Vector(0, 0, 0))
	item.teamGameStatus:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamGameStatus)

	item.teamPlayerCountShadow = GUIManager:CreateTextItem()
	item.teamPlayerCountShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamPlayerCountShadow:SetFontName(kSubTitleFontName)
	item.teamPlayerCountShadow:SetColor(Color(0,0,0,1))
	item.teamPlayerCountShadow:SetScale(scaledVector)
	GUIMakeFontScale(item.teamPlayerCountShadow)
	item.teamPlayerCountShadow:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.teamPlayerCountShadow:SetText("")
	item.teamPlayerCountShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamPlayerCountShadow:SetTextAlignmentX(GUIItem.Align_Max)
	item.teamPlayerCountShadow:SetPosition(Vector(kPlayerCountOffset + kTextShadowOffset, kTextShadowOffset, 0))
	item.teamPlayerCountShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamPlayerCountShadow)

	item.teamPlayerCount = GUIManager:CreateTextItem()
	item.teamPlayerCount:SetStencilFunc(GUIItem.NotEqual)
	item.teamPlayerCount:SetFontName(kSubTitleFontName)
	item.teamPlayerCount:SetColor(Color(1,1,1,1))
	item.teamPlayerCount:SetScale(scaledVector)
	GUIMakeFontScale(item.teamPlayerCount)
	item.teamPlayerCount:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.teamPlayerCount:SetText("")
	item.teamPlayerCount:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamPlayerCount:SetTextAlignmentX(GUIItem.Align_Max)
	item.teamPlayerCount:SetPosition(Vector(kPlayerCountOffset, 0, 0))
	item.teamPlayerCount:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamPlayerCount)

	return item
end

local function CreateScoreboardRow(container, bgColor, textColor, playerName, kills, assists, deaths, acc, score, pdmg, sdmg, timeBuilding, timePlayed, timeComm, steamId, isRookie, hiveSkill)
	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kRowSize.y, 0))

	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kRowSize)

	if steamId then
		item.steamId = steamId
	end

	if hiveSkill and GetPlayerSkillTier then
		local skillTier, skillTierName = GetPlayerSkillTier(hiveSkill, isRookie)
		item.hiveSkillTier = skillTier
		item.hiveSkillTierName = skillTierName
	end

	container:AddChild(item.background)

	item.playerName = GUIManager:CreateTextItem()
	item.playerName:SetStencilFunc(GUIItem.NotEqual)
	item.playerName:SetFontName(kRowFontName)
	item.playerName:SetColor(isRookie and Color(0, 0.8, 0.25, 1) or textColor)
	item.playerName:SetScale(scaledVector)
	GUIMakeFontScale(item.playerName)
	item.playerName:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.playerName:SetTextAlignmentY(GUIItem.Align_Center)
	item.playerName:SetPosition(Vector(kRowPlayerNameOffset, 0, 0))
	item.playerName:SetText(playerName or "")
	item.playerName:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.playerName)

	local playerNameLength = item.playerName:GetTextWidth(playerName or "") * item.playerName:GetScale().x + GUILinearScale(5)

	if timeComm then
		item.commIcon = GUIManager:CreateGraphicItem()
		item.commIcon:SetStencilFunc(GUIItem.NotEqual)
		item.commIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.commIcon:SetTexture("ui/badges/commander_grey_20.dds")
		item.commIcon:SetIsVisible(true)
		item.commIcon:SetSize(GUILinearScale(Vector(20, 20, 0)))
		item.commIcon:SetPosition(Vector(kRowPlayerNameOffset + playerNameLength, -GUILinearScale(10), 0))
		item.commIcon:SetLayer(kGUILayerMainMenu)
		item.commIcon.tooltip = "指挥时长: " .. timeComm
		item.background:AddChild(item.commIcon)
	end

	local kItemSize = GUILinearScale(50)
	local xOffset = kRowSize.x
	local kItemPaddingMediumLarge = GUILinearScale(50)
	local kItemPaddingMedium = GUILinearScale(40)
	local kItemPaddingSmallMedium = GUILinearScale(30)
	local kItemPaddingSmall = GUILinearScale(20)
	local kItemPaddingExtraSmall = GUILinearScale(10)

	xOffset = xOffset - kItemPaddingMedium + kItemPaddingExtraSmall

	item.timePlayed = GUIManager:CreateTextItem()
	item.timePlayed:SetStencilFunc(GUIItem.NotEqual)
	item.timePlayed:SetFontName(kRowFontName)
	item.timePlayed:SetColor(textColor)
	item.timePlayed:SetScale(scaledVector)
	GUIMakeFontScale(item.timePlayed)
	item.timePlayed:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.timePlayed:SetTextAlignmentY(GUIItem.Align_Center)
	item.timePlayed:SetTextAlignmentX(GUIItem.Align_Max)
	item.timePlayed:SetPosition(Vector(xOffset, 0, 0))
	item.timePlayed:SetText(timePlayed or "")
	item.timePlayed:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.timePlayed)

	xOffset = xOffset - kItemSize - kItemPaddingExtraSmall

	item.timeBuilding = GUIManager:CreateTextItem()
	item.timeBuilding:SetStencilFunc(GUIItem.NotEqual)
	item.timeBuilding:SetFontName(kRowFontName)
	item.timeBuilding:SetColor(textColor)
	item.timeBuilding:SetScale(scaledVector)
	GUIMakeFontScale(item.timeBuilding)
	item.timeBuilding:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.timeBuilding:SetTextAlignmentY(GUIItem.Align_Center)
	item.timeBuilding:SetTextAlignmentX(GUIItem.Align_Max)
	item.timeBuilding:SetPosition(Vector(xOffset, 0, 0))
	item.timeBuilding:SetText(timeBuilding or "")
	item.timeBuilding:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.timeBuilding)

	xOffset = xOffset - kItemSize - kItemPaddingSmallMedium

	item.sdmg = GUIManager:CreateTextItem()
	item.sdmg:SetStencilFunc(GUIItem.NotEqual)
	item.sdmg:SetFontName(kRowFontName)
	item.sdmg:SetColor(textColor)
	item.sdmg:SetScale(scaledVector)
	GUIMakeFontScale(item.sdmg)
	item.sdmg:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.sdmg:SetTextAlignmentY(GUIItem.Align_Center)
	item.sdmg:SetTextAlignmentX(GUIItem.Align_Max)
	item.sdmg:SetPosition(Vector(xOffset, 0, 0))
	item.sdmg:SetText(sdmg or "")
	item.sdmg:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.sdmg)

	xOffset = xOffset - kItemSize - kItemPaddingSmallMedium

	item.pdmg = GUIManager:CreateTextItem()
	item.pdmg:SetStencilFunc(GUIItem.NotEqual)
	item.pdmg:SetFontName(kRowFontName)
	item.pdmg:SetColor(textColor)
	item.pdmg:SetScale(scaledVector)
	GUIMakeFontScale(item.pdmg)
	item.pdmg:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.pdmg:SetTextAlignmentY(GUIItem.Align_Center)
	item.pdmg:SetTextAlignmentX(GUIItem.Align_Max)
	item.pdmg:SetPosition(Vector(xOffset, 0, 0))
	item.pdmg:SetText(pdmg or "")
	item.pdmg:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.pdmg)

	xOffset = xOffset - kItemSize - kItemSize

	item.score = GUIManager:CreateTextItem()
	item.score:SetStencilFunc(GUIItem.NotEqual)
	item.score:SetFontName(kRowFontName)
	item.score:SetColor(textColor)
	item.score:SetScale(scaledVector)
	GUIMakeFontScale(item.score)
	item.score:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.score:SetTextAlignmentY(GUIItem.Align_Center)
	item.score:SetTextAlignmentX(GUIItem.Align_Max)
	item.score:SetPosition(Vector(xOffset, 0, 0))
	item.score:SetText(score or "")
	item.score:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.score)

	xOffset = xOffset - kItemSize - kItemSize

	item.acc = GUIManager:CreateTextItem()
	item.acc:SetStencilFunc(GUIItem.NotEqual)
	item.acc:SetFontName(kRowFontName)
	item.acc:SetColor(textColor)
	item.acc:SetScale(scaledVector)
	GUIMakeFontScale(item.acc)
	item.acc:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.acc:SetTextAlignmentY(GUIItem.Align_Center)
	item.acc:SetTextAlignmentX(GUIItem.Align_Max)
	item.acc:SetPosition(Vector(xOffset, 0, 0))
	item.acc:SetText(acc or "")
	item.acc:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.acc)

	xOffset = xOffset - kItemSize - ConditionalValue(avgAccTable.marineOnosAcc == -1, kItemPaddingSmall, kItemPaddingMediumLarge)*2

	item.deaths = GUIManager:CreateTextItem()
	item.deaths:SetStencilFunc(GUIItem.NotEqual)
	item.deaths:SetFontName(kRowFontName)
	item.deaths:SetColor(textColor)
	item.deaths:SetScale(scaledVector)
	GUIMakeFontScale(item.deaths)
	item.deaths:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.deaths:SetTextAlignmentY(GUIItem.Align_Center)
	item.deaths:SetTextAlignmentX(GUIItem.Align_Max)
	item.deaths:SetPosition(Vector(xOffset, 0, 0))
	item.deaths:SetText(deaths or "")
	item.deaths:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.deaths)

	xOffset = xOffset - kItemSize

	item.assists = GUIManager:CreateTextItem()
	item.assists:SetStencilFunc(GUIItem.NotEqual)
	item.assists:SetFontName(kRowFontName)
	item.assists:SetColor(textColor)
	item.assists:SetScale(scaledVector)
	GUIMakeFontScale(item.assists)
	item.assists:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.assists:SetTextAlignmentY(GUIItem.Align_Center)
	item.assists:SetTextAlignmentX(GUIItem.Align_Max)
	item.assists:SetPosition(Vector(xOffset, 0, 0))
	item.assists:SetText(assists or "")
	item.assists:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.assists)

	xOffset = xOffset - kItemSize

	item.kills = GUIManager:CreateTextItem()
	item.kills:SetStencilFunc(GUIItem.NotEqual)
	item.kills:SetFontName(kRowFontName)
	item.kills:SetColor(textColor)
	item.kills:SetScale(scaledVector)
	GUIMakeFontScale(item.kills)
	item.kills:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.kills:SetTextAlignmentY(GUIItem.Align_Center)
	item.kills:SetTextAlignmentX(GUIItem.Align_Max)
	item.kills:SetPosition(Vector(xOffset, 0, 0))
	item.kills:SetText(kills or "")
	item.kills:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.kills)

	return item
end

function GUIGameEndStats:CreateGraphicHeader(text, color, logoTexture, logoCoords, logoSizeX, logoSizeY)
	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(color)
	item.background:SetTexture(kHeaderTexture)
	item.background:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(Vector(kCardSize.x-GUILinearScale(32), kCardSize.y, 0))
	self.background:AddChild(item.background)

	item.backgroundLeft = GUIManager:CreateGraphicItem()
	item.backgroundLeft:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundLeft:SetColor(color)
	item.backgroundLeft:SetTexture(kHeaderTexture)
	item.backgroundLeft:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsLeft))
	item.backgroundLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundLeft:SetInheritsParentAlpha(false)
	item.backgroundLeft:SetLayer(kGUILayerMainMenu)
	item.backgroundLeft:SetSize(Vector(GUILinearScale(16), kCardSize.y, 0))
	item.backgroundLeft:SetPosition(Vector(-GUILinearScale(16), 0, 0))
	item.background:AddChild(item.backgroundLeft)

	item.backgroundRight = GUIManager:CreateGraphicItem()
	item.backgroundRight:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundRight:SetColor(color)
	item.backgroundRight:SetTexture(kHeaderTexture)
	item.backgroundRight:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsRight))
	item.backgroundRight:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundRight:SetInheritsParentAlpha(false)
	item.backgroundRight:SetLayer(kGUILayerMainMenu)
	item.backgroundRight:SetSize(Vector(GUILinearScale(16), kCardSize.y, 0))
	item.backgroundRight:SetPosition(Vector(kCardSize.x-GUILinearScale(32), 0, 0))
	item.background:AddChild(item.backgroundRight)

	local xOffset = kLogoOffset

	if logoTexture then
		logoSizeX = GUILinearScale(logoSizeX)
		logoSizeY = GUILinearScale(logoSizeY)

		item.logo = GUIManager:CreateGraphicItem()
		item.logo:SetStencilFunc(GUIItem.NotEqual)
		item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.logo:SetLayer(kGUILayerMainMenu)
		item.logo:SetIsVisible(true)
		item.logo:SetSize(Vector(logoSizeX, logoSizeY, 0))
		item.logo:SetPosition(Vector(kLogoOffset, -logoSizeY/2, 0))
		item.logo:SetTexture(logoTexture)
		if logoCoords then
			item.logo:SetTexturePixelCoordinates(GUIUnpackCoords(logoCoords))
		end
		item.background:AddChild(item.logo)

		xOffset = xOffset + logoSizeX + kTeamNameOffset
	else
		xOffset = 0
	end

	item.textShadow = GUIManager:CreateTextItem()
	item.textShadow:SetStencilFunc(GUIItem.NotEqual)
	item.textShadow:SetFontName(kTitleFontName)
	item.textShadow:SetColor(Color(0,0,0,1))
	item.textShadow:SetScale(scaledVector)
	GUIMakeFontScale(item.textShadow)
	item.textShadow:SetAnchor(ConditionalValue(logoTexture, GUIItem.Left, GUIItem.Middle), GUIItem.Top)
	item.textShadow:SetText(text)
	item.textShadow:SetTextAlignmentX(ConditionalValue(logoTexture, GUIItem.Align_Min, GUIItem.Align_Center))
	item.textShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.textShadow:SetPosition(Vector(xOffset + kTextShadowOffset, kCardSize.y/2 + kTextShadowOffset, 0))
	item.textShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.textShadow)

	item.text = GUIManager:CreateTextItem()
	item.text:SetStencilFunc(GUIItem.NotEqual)
	item.text:SetFontName(kTitleFontName)
	item.text:SetColor(Color(1,1,1,1))
	item.text:SetScale(scaledVector)
	GUIMakeFontScale(item.text)
	item.text:SetAnchor(ConditionalValue(logoTexture, GUIItem.Left, GUIItem.Middle), GUIItem.Top)
	item.text:SetText(text)
	item.text:SetTextAlignmentX(ConditionalValue(logoTexture, GUIItem.Align_Min, GUIItem.Align_Center))
	item.text:SetTextAlignmentY(GUIItem.Align_Center)
	item.text:SetPosition(Vector(xOffset, kCardSize.y/2, 0))
	item.text:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.text)

	item.tableBackground = GUIManager:CreateGraphicItem()
	item.tableBackground:SetStencilFunc(GUIItem.NotEqual)
	item.tableBackground:SetColor(color)
	item.tableBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	item.tableBackground:SetPosition(Vector(-(kCardRowSize.x+kRowBorderSize*2)/2, -kTableContainerOffset, 0))
	item.tableBackground:SetLayer(kGUILayerMainMenu)
	item.tableBackground:SetSize(Vector(kCardRowSize.x + kRowBorderSize*2, kRowBorderSize*2, 0))
	item.background:AddChild(item.tableBackground)

	return item
end

local function CreateHeaderRow(container, bgColor, textColor, leftText, rightText)

	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kCardRowSize.y, 0))

	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kCardRowSize)

	container:AddChild(item.background)

	item.leftText = GUIManager:CreateTextItem()
	item.leftText:SetStencilFunc(GUIItem.NotEqual)
	item.leftText:SetFontName(kRowFontName)
	item.leftText:SetColor(textColor)
	item.leftText:SetScale(scaledVector)
	GUIMakeFontScale(item.leftText)
	item.leftText:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.leftText:SetTextAlignmentY(GUIItem.Align_Center)
	item.leftText:SetPosition(Vector(GUILinearScale(5), 0, 0))
	item.leftText:SetText(leftText or "")
	item.leftText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.leftText)

	item.rightText = GUIManager:CreateTextItem()
	item.rightText:SetStencilFunc(GUIItem.NotEqual)
	item.rightText:SetFontName(kRowFontName)
	item.rightText:SetColor(textColor)
	item.rightText:SetScale(scaledVector)
	GUIMakeFontScale(item.rightText)
	item.rightText:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.rightText:SetTextAlignmentX(GUIItem.Align_Max)
	item.rightText:SetTextAlignmentY(GUIItem.Align_Center)
	item.rightText:SetPosition(Vector(-GUILinearScale(5), 0, 0))
	item.rightText:SetText(rightText or "")
	item.rightText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.rightText)

	return item
end

function GUIGameEndStats:CreateTechLogHeader(teamNumber, teamName)
	local item = {}

	local color = kMarineStatsColor
	local teamLogo = kMarineStatsLogo

	if teamNumber == 2 then
		color = kAlienStatsColor
		teamLogo = kAlienStatsLogo
	end

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(color)
	item.background:SetTexture(kHeaderTexture)
	item.background:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsMiddle))
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetInheritsParentAlpha(false)
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(Vector(kTechLogTitleSize.x-GUILinearScale(32), kTechLogTitleSize.y, 0))
	self.background:AddChild(item.background)

	item.backgroundLeft = GUIManager:CreateGraphicItem()
	item.backgroundLeft:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundLeft:SetColor(color)
	item.backgroundLeft:SetTexture(kHeaderTexture)
	item.backgroundLeft:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsLeft))
	item.backgroundLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundLeft:SetInheritsParentAlpha(false)
	item.backgroundLeft:SetLayer(kGUILayerMainMenu)
	item.backgroundLeft:SetSize(Vector(GUILinearScale(16), kTechLogTitleSize.y, 0))
	item.backgroundLeft:SetPosition(Vector(-GUILinearScale(16), 0, 0))
	item.background:AddChild(item.backgroundLeft)

	item.backgroundRight = GUIManager:CreateGraphicItem()
	item.backgroundRight:SetStencilFunc(GUIItem.NotEqual)
	item.backgroundRight:SetColor(color)
	item.backgroundRight:SetTexture(kHeaderTexture)
	item.backgroundRight:SetTexturePixelCoordinates(GUIUnpackCoords(kHeaderCoordsRight))
	item.backgroundRight:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.backgroundRight:SetInheritsParentAlpha(false)
	item.backgroundRight:SetLayer(kGUILayerMainMenu)
	item.backgroundRight:SetSize(Vector(GUILinearScale(16), kTechLogTitleSize.y, 0))
	item.backgroundRight:SetPosition(Vector(kTechLogTitleSize.x-GUILinearScale(32), 0, 0))
	item.background:AddChild(item.backgroundRight)

	item.logo = GUIManager:CreateGraphicItem()
	item.logo:SetStencilFunc(GUIItem.NotEqual)
	item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.logo:SetLayer(kGUILayerMainMenu)
	item.logo:SetIsVisible(true)
	item.logo:SetSize(kLogoSize)
	item.logo:SetPosition(Vector(kLogoOffset, -kLogoSize.y/2, 0))
	item.logo:SetTexture(teamLogo)
	item.background:AddChild(item.logo)

	item.teamNameTextShadow = GUIManager:CreateTextItem()
	item.teamNameTextShadow:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameTextShadow:SetFontName(kTitleFontName)
	item.teamNameTextShadow:SetColor(Color(0,0,0,1))
	item.teamNameTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(item.teamNameTextShadow)
	item.teamNameTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameTextShadow:SetText(teamName)
	item.teamNameTextShadow:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameTextShadow:SetPosition(Vector(kLogoSize.x + kTeamNameOffset + kTextShadowOffset, kTechLogTitleSize.y/2 + kTextShadowOffset, 0))
	item.teamNameTextShadow:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameTextShadow)

	item.teamNameText = GUIManager:CreateTextItem()
	item.teamNameText:SetStencilFunc(GUIItem.NotEqual)
	item.teamNameText:SetFontName(kTitleFontName)
	item.teamNameText:SetColor(Color(1,1,1,1))
	item.teamNameText:SetScale(scaledVector)
	GUIMakeFontScale(item.teamNameText)
	item.teamNameText:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.teamNameText:SetText(teamName)
	item.teamNameText:SetTextAlignmentY(GUIItem.Align_Center)
	item.teamNameText:SetPosition(Vector(kLogoSize.x + kTeamNameOffset, kTechLogTitleSize.y/2, 0))
	item.teamNameText:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.teamNameText)

	item.tableBackground = GUIManager:CreateGraphicItem()
	item.tableBackground:SetStencilFunc(GUIItem.NotEqual)
	item.tableBackground:SetColor(color)
	item.tableBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
	item.tableBackground:SetPosition(Vector(-(kTechLogRowSize.x+kRowBorderSize*2)/2, -kTableContainerOffset, 0))
	item.tableBackground:SetLayer(kGUILayerMainMenu)
	item.tableBackground:SetSize(Vector(kTechLogRowSize.x + kRowBorderSize*2, kRowBorderSize*2, 0))
	item.background:AddChild(item.tableBackground)

	return item
end

local function CreateTechLogRow(container, bgColor, textColor, timeBuilt, techName, activeRTs, numRes, logoTexture, logoCoords, logoSizeX, logoSizeY, logoColor)

	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kTechLogRowSize.y, 0))

	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kTechLogRowSize)

	container:AddChild(item.background)

	local xOffset = GUILinearScale(10)

	if timeBuilt ~= "" then
		item.timeBuilt = GUIManager:CreateTextItem()
		item.timeBuilt:SetStencilFunc(GUIItem.NotEqual)
		item.timeBuilt:SetFontName(kRowFontName)
		item.timeBuilt:SetColor(textColor)
		item.timeBuilt:SetScale(scaledVector)
		GUIMakeFontScale(item.timeBuilt)
		item.timeBuilt:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.timeBuilt:SetTextAlignmentX(GUIItem.Align_Center)
		item.timeBuilt:SetTextAlignmentY(GUIItem.Align_Center)
		item.timeBuilt:SetPosition(Vector(GUILinearScale(30), 0, 0))
		item.timeBuilt:SetText(timeBuilt or "")
		item.timeBuilt:SetLayer(kGUILayerMainMenu)
		item.background:AddChild(item.timeBuilt)

		xOffset = GUILinearScale(70)
	end

	if logoTexture then
		logoSizeX = GUILinearScale(logoSizeX)
		logoSizeY = GUILinearScale(logoSizeY)

		item.logo = GUIManager:CreateGraphicItem()
		item.logo:SetStencilFunc(GUIItem.NotEqual)
		item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.logo:SetLayer(kGUILayerMainMenu)
		item.logo:SetIsVisible(true)
		item.logo:SetSize(Vector(logoSizeX, logoSizeY, 0))
		item.logo:SetPosition(Vector(xOffset, -logoSizeY/2, 0))
		item.logo:SetColor(logoColor)
		item.logo:SetTexture(logoTexture)
		if logoCoords then
			item.logo:SetTexturePixelCoordinates(GUIUnpackCoords(logoCoords))
		end
		item.background:AddChild(item.logo)

		xOffset = xOffset + logoSizeX + GUILinearScale(5)
	end

	item.techName = GUIManager:CreateTextItem()
	item.techName:SetStencilFunc(GUIItem.NotEqual)
	item.techName:SetFontName(kRowFontName)
	item.techName:SetColor(textColor)
	item.techName:SetScale(scaledVector)
	GUIMakeFontScale(item.techName)
	item.techName:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.techName:SetTextAlignmentY(GUIItem.Align_Center)
	item.techName:SetPosition(Vector(xOffset, 0, 0))
	item.techName:SetText(techName or "")
	item.techName:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.techName)

	item.activeRTs = GUIManager:CreateTextItem()
	item.activeRTs:SetStencilFunc(GUIItem.NotEqual)
	item.activeRTs:SetFontName(kRowFontName)
	item.activeRTs:SetColor(textColor)
	item.activeRTs:SetScale(scaledVector)
	GUIMakeFontScale(item.activeRTs)
	item.activeRTs:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.activeRTs:SetTextAlignmentX(GUIItem.Align_Center)
	item.activeRTs:SetTextAlignmentY(GUIItem.Align_Center)
	item.activeRTs:SetPosition(Vector(GUILinearScale(-80), 0, 0))
	item.activeRTs:SetText(tostring(activeRTs) or "")
	item.activeRTs:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.activeRTs)

	item.numRes = GUIManager:CreateTextItem()
	item.numRes:SetStencilFunc(GUIItem.NotEqual)
	item.numRes:SetFontName(kRowFontName)
	item.numRes:SetColor(textColor)
	item.numRes:SetScale(scaledVector)
	GUIMakeFontScale(item.numRes)
	item.numRes:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.numRes:SetTextAlignmentX(GUIItem.Align_Center)
	item.numRes:SetTextAlignmentY(GUIItem.Align_Center)
	item.numRes:SetPosition(Vector(GUILinearScale(-30), 0, 0))
	item.numRes:SetText(tostring(numRes) or "")
	item.numRes:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.numRes)

	return item
end

local function CreateCommStatsRow(container, bgColor, textColor, techName, accuracy, efficiency, refill, used, wasted, logoTexture, logoCoords, logoSizeX, logoSizeY, logoColor)

	local containerSize = container:GetSize()
	container:SetSize(Vector(containerSize.x, containerSize.y + kTechLogRowSize.y, 0))

	local item = {}

	item.background = GUIManager:CreateGraphicItem()
	item.background:SetStencilFunc(GUIItem.NotEqual)
	item.background:SetColor(bgColor)
	item.background:SetAnchor(GUIItem.Left, GUIItem.Top)
	item.background:SetPosition(Vector(kRowBorderSize, containerSize.y - kRowBorderSize, 0))
	item.background:SetLayer(kGUILayerMainMenu)
	item.background:SetSize(kTechLogRowSize)

	container:AddChild(item.background)

	local xOffset = GUILinearScale(10)

	if logoTexture then
		logoSizeX = GUILinearScale(logoSizeX)
		logoSizeY = GUILinearScale(logoSizeY)

		item.logo = GUIManager:CreateGraphicItem()
		item.logo:SetStencilFunc(GUIItem.NotEqual)
		item.logo:SetAnchor(GUIItem.Left, GUIItem.Center)
		item.logo:SetLayer(kGUILayerMainMenu)
		item.logo:SetIsVisible(true)
		item.logo:SetSize(Vector(logoSizeX, logoSizeY, 0))
		item.logo:SetPosition(Vector(xOffset, -logoSizeY/2, 0))
		item.logo:SetColor(logoColor)
		item.logo:SetTexture(logoTexture)
		if logoCoords then
			item.logo:SetTexturePixelCoordinates(GUIUnpackCoords(logoCoords))
		end
		item.background:AddChild(item.logo)

		xOffset = xOffset + logoSizeX + GUILinearScale(5)
	end

	item.techName = GUIManager:CreateTextItem()
	item.techName:SetStencilFunc(GUIItem.NotEqual)
	item.techName:SetFontName(kRowFontName)
	item.techName:SetColor(textColor)
	item.techName:SetScale(scaledVector)
	GUIMakeFontScale(item.techName)
	item.techName:SetAnchor(GUIItem.Left, GUIItem.Center)
	item.techName:SetTextAlignmentY(GUIItem.Align_Center)
	item.techName:SetPosition(Vector(xOffset, 0, 0))
	item.techName:SetText(techName or "")
	item.techName:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.techName)

	item.accuracy = GUIManager:CreateTextItem()
	item.accuracy:SetStencilFunc(GUIItem.NotEqual)
	item.accuracy:SetFontName(kRowFontName)
	item.accuracy:SetColor(textColor)
	item.accuracy:SetScale(scaledVector)
	GUIMakeFontScale(item.accuracy)
	item.accuracy:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.accuracy:SetTextAlignmentX(GUIItem.Align_Center)
	item.accuracy:SetTextAlignmentY(GUIItem.Align_Center)
	item.accuracy:SetPosition(Vector(GUILinearScale(-250), 0, 0))
	item.accuracy:SetText(tostring(accuracy) or "")
	item.accuracy:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.accuracy)

	item.efficiency = GUIManager:CreateTextItem()
	item.efficiency:SetStencilFunc(GUIItem.NotEqual)
	item.efficiency:SetFontName(kRowFontName)
	item.efficiency:SetColor(textColor)
	item.efficiency:SetScale(scaledVector)
	GUIMakeFontScale(item.efficiency)
	item.efficiency:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.efficiency:SetTextAlignmentX(GUIItem.Align_Center)
	item.efficiency:SetTextAlignmentY(GUIItem.Align_Center)
	item.efficiency:SetPosition(Vector(GUILinearScale(-130), 0, 0))
	item.efficiency:SetText(tostring(efficiency) or "")
	item.efficiency:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.efficiency)

	item.refill = GUIManager:CreateTextItem()
	item.refill:SetStencilFunc(GUIItem.NotEqual)
	item.refill:SetFontName(kRowFontName)
	item.refill:SetColor(textColor)
	item.refill:SetScale(scaledVector)
	GUIMakeFontScale(item.refill)
	item.refill:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.refill:SetTextAlignmentX(GUIItem.Align_Center)
	item.refill:SetTextAlignmentY(GUIItem.Align_Center)
	item.refill:SetPosition(Vector(GUILinearScale(-190), 0, 0))
	item.refill:SetText(tostring(refill) or "")
	item.refill:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.refill)

	item.used = GUIManager:CreateTextItem()
	item.used:SetStencilFunc(GUIItem.NotEqual)
	item.used:SetFontName(kRowFontName)
	item.used:SetColor(textColor)
	item.used:SetScale(scaledVector)
	GUIMakeFontScale(item.used)
	item.used:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.used:SetTextAlignmentX(GUIItem.Align_Center)
	item.used:SetTextAlignmentY(GUIItem.Align_Center)
	item.used:SetPosition(Vector(GUILinearScale(-80), 0, 0))
	item.used:SetText(tostring(used) or "")
	item.used:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.used)

	item.wasted = GUIManager:CreateTextItem()
	item.wasted:SetStencilFunc(GUIItem.NotEqual)
	item.wasted:SetFontName(kRowFontName)
	item.wasted:SetColor(textColor)
	item.wasted:SetScale(scaledVector)
	GUIMakeFontScale(item.wasted)
	item.wasted:SetAnchor(GUIItem.Right, GUIItem.Center)
	item.wasted:SetTextAlignmentX(GUIItem.Align_Center)
	item.wasted:SetTextAlignmentY(GUIItem.Align_Center)
	item.wasted:SetPosition(Vector(GUILinearScale(-30), 0, 0))
	item.wasted:SetText(tostring(wasted) or "")
	item.wasted:SetLayer(kGUILayerMainMenu)
	item.background:AddChild(item.wasted)

	return item
end

function GUIGameEndStats:SetPlayerCount(teamItem, playerCount)
	if playerCount and IsNumber(playerCount) then
		local playerString = string.format("%d %s", playerCount, ConditionalValue(playerCount == 1, Locale.ResolveString("PLAYER"), Locale.ResolveString("PLAYERS")))
		teamItem.teamPlayerCountShadow:SetText(playerString)
		teamItem.teamPlayerCount:SetText(playerString)
	else
		teamItem.teamPlayerCountShadow:SetText("")
		teamItem.teamPlayerCount:SetText("")
	end
end

function GUIGameEndStats:SetGameResult(teamItem, result)
	teamItem.teamGameStatusShadow:SetText(result)
	teamItem.teamGameStatus:SetText(result)
end

function GUIGameEndStats:SetTeamName(teamItem, teamName)
	if teamName == nil then
		teamName = ""
	end
	teamItem.teamNameTextShadow:SetText(teamName)
	teamItem.teamNameText:SetText(teamName)
end

function GUIGameEndStats:LoadLastRoundStats()

	if not loadedLastRound and GetFileExists(lastRoundFile) then

		local openedFile = io.open(lastRoundFile, "r")
		if openedFile then

			local parsedFile = json.decode(openedFile:read("*all"))
			io.close(openedFile)

			if parsedFile then
				finalStatsTable = parsedFile.finalStatsTable or {}
				avgAccTable = parsedFile.avgAccTable or {}
				miscDataTable = parsedFile.miscDataTable or {}
				cardsTable = parsedFile.cardsTable or {}
				hiveSkillGraphTable = parsedFile.hiveSkillGraphTable or {}
				rtGraphTable = parsedFile.rtGraphTable or {}
				commanderStats = parsedFile.commanderStats or nil
				techLogTable = parsedFile.techLogTable or {}
				killGraphTable = parsedFile.killGraphTable or {}
				buildingSummaryTable = parsedFile.buildingSummaryTable or {}
				statusSummaryTable = parsedFile.statusSummaryTable or {}

				if #hiveSkillGraphTable == 0 then
					estimateHiveSkillGraph()
				end
			end

			self.saved = true
			loadedLastRound = true
		end
	end
end

function GUIGameEndStats:SaveLastRoundStats()
	if not self.saved then
		local savedStats = {}
		savedStats.finalStatsTable = finalStatsTable
		savedStats.avgAccTable = avgAccTable
		savedStats.miscDataTable = miscDataTable
		savedStats.cardsTable = cardsTable
		savedStats.hiveSkillGraphTable = hiveSkillGraphTable
		savedStats.rtGraphTable = rtGraphTable
		savedStats.commanderStats = commanderStats
		savedStats.killGraphTable = killGraphTable
		savedStats.buildingSummaryTable = buildingSummaryTable
		savedStats.statusSummaryTable = statusSummaryTable
		savedStats.techLogTable = techLogTable

		local savedFile = io.open(lastRoundFile, "w+")
		if savedFile then
			savedFile:write(json.encode(savedStats, { indent = true }))
			io.close(savedFile)
		end
		self.saved = true
	end
end

function GUIGameEndStats:Initialize()
	UpdateSizeOfUI(self)

	self.header = GUIManager:CreateGraphicItem()
	self.header:SetColor(Color(0, 0, 0, 0.5))
	self.header:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.header:SetSize(kTitleSize)
	self.header:SetPosition(Vector(-kTitleSize.x/2, kTopOffset, 0))
	self.header:SetLayer(kGUILayerMainMenu)

	self.closeButton = GUIManager:CreateGraphicItem()
	self.closeButton:SetAnchor(GUIItem.Right, GUIItem.Top)
	self.closeButton:SetSize(kCloseButtonSize)
	self.closeButton:SetPosition(Vector(GUILinearScale(8), 0, 0))
	self.closeButton:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.closeButton)

	self.closeText = GUIManager:CreateTextItem()
	self.closeText:SetColor(Color(1, 1, 1, 1))
	self.closeText:SetAnchor(GUIItem.Middle, GUIItem.Center)
	self.closeText:SetText("X")
	self.closeText:SetScale(scaledVector)
	self.closeText:SetFontName(kSubTitleFontName)
	GUIMakeFontScale(self.closeText)
	self.closeText:SetTextAlignmentX(GUIItem.Align_Center)
	self.closeText:SetTextAlignmentY(GUIItem.Align_Center)
	self.closeText:SetPosition(Vector(0, GUILinearScale(2), 0))
	self.closeText:SetLayer(kGUILayerMainMenu)
	self.closeButton:AddChild(self.closeText)

	self.roundDate = GUIManager:CreateTextItem()
	self.roundDate:SetFontName(kSubTitleFontName)
	self.roundDate:SetColor(Color(1,1,1,1))
	self.roundDate:SetScale(scaledVector)
	GUIMakeFontScale(self.roundDate)
	self.roundDate:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.roundDate:SetPosition(Vector(GUILinearScale(10), GUILinearScale(4), 0))
	self.roundDate:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.roundDate)

	self.serverName = GUIManager:CreateTextItem()
	self.serverName:SetFontName(kSubTitleFontName)
	self.serverName:SetColor(Color(1,1,1,1))
	self.serverName:SetScale(scaledVector)
	GUIMakeFontScale(self.serverName)
	self.serverName:SetAnchor(GUIItem.Left, GUIItem.Bottom)
	self.serverName:SetPosition(Vector(GUILinearScale(10), GUILinearScale(-4), 0))
	self.serverName:SetTextAlignmentY(GUIItem.Align_Max)
	self.serverName:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.serverName)

	self.gameLength = GUIManager:CreateTextItem()
	self.gameLength:SetFontName(kSubTitleFontName)
	self.gameLength:SetColor(Color(1,1,1,1))
	self.gameLength:SetScale(scaledVector)
	GUIMakeFontScale(self.gameLength)
	self.gameLength:SetAnchor(GUIItem.Right, GUIItem.Top)
	self.gameLength:SetPosition(Vector(GUILinearScale(-10), GUILinearScale(4), 0))
	self.gameLength:SetTextAlignmentX(GUIItem.Align_Max)
	self.gameLength:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.gameLength)

	self.mapName = GUIManager:CreateTextItem()
	self.mapName:SetFontName(kSubTitleFontName)
	self.mapName:SetColor(Color(1,1,1,1))
	self.mapName:SetScale(scaledVector)
	GUIMakeFontScale(self.mapName)
	self.mapName:SetAnchor(GUIItem.Right, GUIItem.Bottom)
	self.mapName:SetPosition(Vector(GUILinearScale(-10), GUILinearScale(-4), 0))
	self.mapName:SetTextAlignmentX(GUIItem.Align_Max)
	self.mapName:SetTextAlignmentY(GUIItem.Align_Max)
	self.mapName:SetLayer(kGUILayerMainMenu)
	self.header:AddChild(self.mapName)

	self.team1UI = self:CreateTeamBackground(1)
	self.team1UI.playerRows = {}
	table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "玩家名称", "击杀", "助攻", "阵亡", ConditionalValue(avgAccTable.marineOnosAcc == -1, "精准度","精准度(无Onos)"), "分数", "玩家伤害", "建筑伤害", "建造时间", "时长"))
	self.team2UI = self:CreateTeamBackground(2)
	self.team2UI.playerRows = {}
	table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor,"玩家名称", "击杀", "助攻", "阵亡", "精准度", "分数", "玩家伤害", "建筑伤害", "建造时间", "时长"))

	self.sliderBarBg = GUIManager:CreateGraphicItem()
	self.sliderBarBg:SetColor(Color(0,0,0,0.5))
	self.sliderBarBg:SetSize(Vector(GUILinearScale(8), kContentMaxYSize, 0))
	self.sliderBarBg:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.sliderBarBg:SetPosition(Vector((kTitleSize.x+GUILinearScale(32))/2, GUILinearScale(128), 0))
	self.sliderBarBg:SetLayer(kGUILayerMainMenu)

	self.slider = GUIManager:CreateGraphicItem()
	self.slider:SetColor(Color(1,1,1,1))
	self.slider:SetSize(Vector(GUILinearScale(16), GUILinearScale(8), 0))
	self.slider:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.slider:SetLayer(kGUILayerMainMenu)
	self.sliderBarBg:AddChild(self.slider)

	self.contentBackground = GUIManager:CreateGraphicItem()
	self.contentBackground:SetColor(Color(0,0,0,0.5))
	self.contentBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.contentBackground:SetPosition(Vector(-kTitleSize.x/2, GUILinearScale(128), 0))
	self.contentBackground:SetSize(Vector(kTitleSize.x, kContentMaxYSize, 0))
	self.contentBackground:SetLayer(kGUILayerMainMenu)

	self.contentStencil = GUIManager:CreateGraphicItem()
	self.contentStencil:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.contentStencil:SetPosition(Vector(-kTitleSize.x/2, GUILinearScale(128), 0))
	self.contentStencil:SetSize(Vector(kTitleSize.x, kContentMaxYSize, 0))
	self.contentStencil:SetIsStencil(true)
	self.contentStencil:SetClearsStencilBuffer(true)
	self.contentStencil:SetLayer(kGUILayerMainMenu)

	self.background = GUIManager:CreateGraphicItem()
	self.background:SetColor(Color(0,0,0,0))
	self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.background:SetPosition(Vector(-(kTitleSize.x-GUILinearScale(32))/2, GUILinearScale(128), 0))
	self.background:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.team1UI.background)
	self.background:AddChild(self.team2UI.background)

	self.teamStatsTextShadow = GUIManager:CreateTextItem()
	self.teamStatsTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.teamStatsTextShadow:SetFontName(kTitleFontName)
	self.teamStatsTextShadow:SetColor(Color(0,0,0,1))
	self.teamStatsTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.teamStatsTextShadow)
	self.teamStatsTextShadow:SetText("队伍数据")
	self.teamStatsTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.teamStatsTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.teamStatsTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.teamStatsTextShadow)

	self.teamStatsText = GUIManager:CreateTextItem()
	self.teamStatsText:SetStencilFunc(GUIItem.NotEqual)
	self.teamStatsText:SetFontName(kTitleFontName)
	self.teamStatsText:SetColor(Color(1,1,1,1))
	self.teamStatsText:SetScale(scaledVector)
	GUIMakeFontScale(self.teamStatsText)
	self.teamStatsText:SetText("队伍数据")
	self.teamStatsText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.teamStatsText:SetTextAlignmentX(GUIItem.Align_Center)
	self.teamStatsText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.teamStatsText:SetLayer(kGUILayerMainMenu)
	self.teamStatsTextShadow:AddChild(self.teamStatsText)

	self.yourStatsTextShadow = GUIManager:CreateTextItem()
	self.yourStatsTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.yourStatsTextShadow:SetFontName(kTitleFontName)
	self.yourStatsTextShadow:SetColor(Color(0,0,0,1))
	self.yourStatsTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.yourStatsTextShadow)
	self.yourStatsTextShadow:SetIsVisible(false)
	self.yourStatsTextShadow:SetText("玩家数据")
	self.yourStatsTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.yourStatsTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.yourStatsTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.yourStatsTextShadow)

	self.yourStatsText = GUIManager:CreateTextItem()
	self.yourStatsText:SetStencilFunc(GUIItem.NotEqual)
	self.yourStatsText:SetFontName(kTitleFontName)
	self.yourStatsText:SetColor(Color(1,1,1,1))
	self.yourStatsText:SetScale(scaledVector)
	GUIMakeFontScale(self.yourStatsText)
	self.yourStatsText:SetText("玩家数据")
	self.yourStatsText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.yourStatsText:SetTextAlignmentX(GUIItem.Align_Center)
	self.yourStatsText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.yourStatsText:SetLayer(kGUILayerMainMenu)
	self.yourStatsTextShadow:AddChild(self.yourStatsText)

	self.techLogTextShadow = GUIManager:CreateTextItem()
	self.techLogTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.techLogTextShadow:SetFontName(kTitleFontName)
	self.techLogTextShadow:SetColor(Color(0,0,0,1))
	self.techLogTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.techLogTextShadow)
	self.techLogTextShadow:SetIsVisible(false)
	self.techLogTextShadow:SetText("科技树数据")
	self.techLogTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.techLogTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.techLogTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.techLogTextShadow)

	self.techLogText = GUIManager:CreateTextItem()
	self.techLogText:SetStencilFunc(GUIItem.NotEqual)
	self.techLogText:SetFontName(kTitleFontName)
	self.techLogText:SetColor(Color(1,1,1,1))
	self.techLogText:SetScale(scaledVector)
	GUIMakeFontScale(self.techLogText)
	self.techLogText:SetText("科技树数据")
	self.techLogText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.techLogText:SetTextAlignmentX(GUIItem.Align_Center)
	self.techLogText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.techLogText:SetLayer(kGUILayerMainMenu)
	self.techLogTextShadow:AddChild(self.techLogText)

	self.hiveSkillGraphTextShadow = GUIManager:CreateTextItem()
	self.hiveSkillGraphTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.hiveSkillGraphTextShadow:SetFontName(kTitleFontName)
	self.hiveSkillGraphTextShadow:SetColor(Color(0,0,0,1))
	self.hiveSkillGraphTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.hiveSkillGraphTextShadow)
	self.hiveSkillGraphTextShadow:SetIsVisible(false)
	self.hiveSkillGraphTextShadow:SetText("段位分图表")
	self.hiveSkillGraphTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.hiveSkillGraphTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.hiveSkillGraphTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.hiveSkillGraphTextShadow)

	self.hiveSkillGraphText = GUIManager:CreateTextItem()
	self.hiveSkillGraphText:SetStencilFunc(GUIItem.NotEqual)
	self.hiveSkillGraphText:SetFontName(kTitleFontName)
	self.hiveSkillGraphText:SetColor(Color(1,1,1,1))
	self.hiveSkillGraphText:SetScale(scaledVector)
	GUIMakeFontScale(self.hiveSkillGraphText)
	self.hiveSkillGraphText:SetText("段位分图表")
	self.hiveSkillGraphText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.hiveSkillGraphText:SetTextAlignmentX(GUIItem.Align_Center)
	self.hiveSkillGraphText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.hiveSkillGraphText:SetLayer(kGUILayerMainMenu)
	self.hiveSkillGraphTextShadow:AddChild(self.hiveSkillGraphText)

	self.rtGraphTextShadow = GUIManager:CreateTextItem()
	self.rtGraphTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.rtGraphTextShadow:SetFontName(kTitleFontName)
	self.rtGraphTextShadow:SetColor(Color(0,0,0,1))
	self.rtGraphTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.rtGraphTextShadow)
	self.rtGraphTextShadow:SetIsVisible(false)
	self.rtGraphTextShadow:SetText("资源塔图表")
	self.rtGraphTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.rtGraphTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.rtGraphTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.rtGraphTextShadow)

	self.rtGraphText = GUIManager:CreateTextItem()
	self.rtGraphText:SetStencilFunc(GUIItem.NotEqual)
	self.rtGraphText:SetFontName(kTitleFontName)
	self.rtGraphText:SetColor(Color(1,1,1,1))
	self.rtGraphText:SetScale(scaledVector)
	GUIMakeFontScale(self.rtGraphText)
	self.rtGraphText:SetText("资源塔图表")
	self.rtGraphText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.rtGraphText:SetTextAlignmentX(GUIItem.Align_Center)
	self.rtGraphText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.rtGraphText:SetLayer(kGUILayerMainMenu)
	self.rtGraphTextShadow:AddChild(self.rtGraphText)

	self.killGraphTextShadow = GUIManager:CreateTextItem()
	self.killGraphTextShadow:SetStencilFunc(GUIItem.NotEqual)
	self.killGraphTextShadow:SetFontName(kTitleFontName)
	self.killGraphTextShadow:SetColor(Color(0,0,0,1))
	self.killGraphTextShadow:SetScale(scaledVector)
	GUIMakeFontScale(self.killGraphTextShadow)
	self.killGraphTextShadow:SetIsVisible(false)
	self.killGraphTextShadow:SetText("击杀图表")
	self.killGraphTextShadow:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.killGraphTextShadow:SetTextAlignmentX(GUIItem.Align_Center)
	self.killGraphTextShadow:SetLayer(kGUILayerMainMenu)
	self.background:AddChild(self.killGraphTextShadow)

	self.killGraphText = GUIManager:CreateTextItem()
	self.killGraphText:SetStencilFunc(GUIItem.NotEqual)
	self.killGraphText:SetFontName(kTitleFontName)
	self.killGraphText:SetColor(Color(1,1,1,1))
	self.killGraphText:SetScale(scaledVector)
	GUIMakeFontScale(self.killGraphText)
	self.killGraphText:SetText("击杀图表")
	self.killGraphText:SetAnchor(GUIItem.Left, GUIItem.Top)
	self.killGraphText:SetTextAlignmentX(GUIItem.Align_Center)
	self.killGraphText:SetPosition(Vector(-kTextShadowOffset, -kTextShadowOffset, 0))
	self.killGraphText:SetLayer(kGUILayerMainMenu)
	self.killGraphTextShadow:AddChild(self.killGraphText)

	self.teamStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, GUILinearScale(16), 0))
	local yPos = GUILinearScale(48)
	self.team1UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
	yPos = yPos + self.team1UI.tableBackground:GetSize().y + self.team1UI.background:GetSize().y
	self.team2UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
	yPos = yPos + self.team2UI.tableBackground:GetSize().y + self.team2UI.background:GetSize().y + GUILinearScale(32)
	self.yourStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))

	self.contentSize = yPos

	self.statsCards = {}
	self.techLogs = {}
	self.hiveSkillGraphs = {}
	self.rtGraphs = {}
	self.killGraphs = {}

	self.hiveSkillGraph = LineGraph()
	self.hiveSkillGraph:Initialize()
	self.hiveSkillGraph:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.hiveSkillGraph:SetSize(rtGraphSize)
	self.hiveSkillGraph:SetYGridSpacing(1)
	self.hiveSkillGraph:SetIsVisible(false)
	self.hiveSkillGraph:SetXAxisIsTime(true)
	self.hiveSkillGraph:ExtendXAxisToBounds(true)
	self.hiveSkillGraph:GiveParent(self.background)
	self.hiveSkillGraph:SetStencilFunc(GUIItem.NotEqual)

	self.hiveSkillGraph:StartLine(kTeam1Index, kBlueColor)
	self.hiveSkillGraph:StartLine(kTeam2Index, kRedColor)
	self.rtGraph = LineGraph()
	self.rtGraph:Initialize()
	self.rtGraph:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.rtGraph:SetSize(rtGraphSize)
	self.rtGraph:SetYGridSpacing(1)
	self.rtGraph:SetIsVisible(false)
	self.rtGraph:SetXAxisIsTime(true)
	self.rtGraph:ExtendXAxisToBounds(true)
	self.rtGraph:GiveParent(self.background)
	self.rtGraph:SetStencilFunc(GUIItem.NotEqual)

	self.rtGraph:StartLine(kTeam1Index, kBlueColor)
	self.rtGraph:StartLine(kTeam2Index, kRedColor)

	self.killGraph = LineGraph()
	self.killGraph:Initialize()
	self.killGraph:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.killGraph:SetSize(rtGraphSize)
	self.killGraph:SetYGridSpacing(1)
	self.killGraph:SetIsVisible(false)
	self.killGraph:SetXAxisIsTime(true)
	self.killGraph:ExtendXAxisToBounds(true)
	self.killGraph:GiveParent(self.background)
	self.killGraph:SetStencilFunc(GUIItem.NotEqual)

	self.killGraph:StartLine(kTeam1Index, kBlueColor)
	self.killGraph:StartLine(kTeam2Index, kRedColor)

	self.builtRTsComp =  ComparisonBarGraph()
	self.builtRTsComp:Initialize()
	self.builtRTsComp:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.builtRTsComp:SetSize(comparisonSize)
	self.builtRTsComp:SetValues(0,0)
	self.builtRTsComp:SetStencilFunc(GUIItem.NotEqual)
	self.builtRTsComp:SetTitle("资源塔建造")
	self.builtRTsComp:GiveParent(self.background)

	self.lostRTsComp =  ComparisonBarGraph()
	self.lostRTsComp:Initialize()
	self.lostRTsComp:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.lostRTsComp:SetSize(comparisonSize)
	self.lostRTsComp:SetValues(0,0)
	self.lostRTsComp:SetStencilFunc(GUIItem.NotEqual)
	self.lostRTsComp:SetTitle("资源塔流失")
	self.lostRTsComp:GiveParent(self.background)

	self.killComparison =  ComparisonBarGraph()
	self.killComparison:Initialize()
	self.killComparison:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.killComparison:SetSize(comparisonSize)
	self.killComparison:SetValues(0,0)
	self.killComparison:SetStencilFunc(GUIItem.NotEqual)
	self.killComparison:SetTitle("击杀总计")
	self.killComparison:GiveParent(self.background)

	self.saved = false
	self.prevRequestKey = false
	self.prevScoreKey = false
	self.isDragging = false
	self.slideOffset = 0
	self.displayed = false

	lastSortedT1 = "kills"
	lastSortedT1WasInv = false
	lastSortedT2 = "kills"
	lastSortedT2WasInv = false

	pcall(self.LoadLastRoundStats, self)

	self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
	self.actionIconGUI:SetColor(kWhite)
	self.actionIconGUI.pickupIcon:SetLayer(kGUILayerPlayerHUD)
	self.actionIconGUI:Hide()

	self.tooltip = GetGUIManager():CreateGUIScriptSingle("menu/GUIHoverTooltip")
	self.hoverMenu = GetGUIManager():CreateGUIScript("GUIHoverMenu")
	self.hoverMenu:Hide()

	self.lastRow = nil

	self.background:SetIsVisible(false)
	self.header:SetIsVisible(false)
	self.sliderBarBg:SetIsVisible(false)
	self.contentBackground:SetIsVisible(false)
	self.contentStencil:SetIsVisible(false)

	EndStatsVisible = false
end

function GUIGameEndStats:Uninitialize()
	if self:GetIsVisible() then
		MouseTracker_SetIsVisible(false)
	end

	GUI.DestroyItem(self.background)
	GUI.DestroyItem(self.header)
	GUI.DestroyItem(self.sliderBarBg)
	GUI.DestroyItem(self.contentBackground)
	GUI.DestroyItem(self.contentStencil)

	GetGUIManager():DestroyGUIScript(self.actionIconGUI)
	self.actionIconGUI = nil
end

function GUIGameEndStats:SetIsVisible(visible)
	-- Don't try to display it if there is no content visible
	local gameInfo = GetGameInfoEntity()
	local teamStatsVisible = gameInfo and gameInfo.showEndStatsTeamBreakdown
	local visibleStats = teamStatsVisible and self.teamStatsTextShadow:GetIsVisible() or #self.statsCards > 0 or #self.rtGraphs > 0
	if visible ~= self:GetIsVisible() and ((visible and visibleStats) or not visible) then
		self.background:SetIsVisible(visible)
		self.header:SetIsVisible(visible)
		self.sliderBarBg:SetIsVisible(visible)
		self.contentBackground:SetIsVisible(visible)
		self.contentStencil:SetIsVisible(visible)

		EndStatsVisible = visible
		self.slideOffset = 0

		if not visible then
			self.hoverMenu:Hide()
			self.tooltip:Hide(0)
		else
			self:RepositionStats()
		end

		MouseTracker_SetIsVisible(visible)
	end
end

function GUIGameEndStats:GetIsVisible()
	return self.background:GetIsVisible()
end

local function repositionStatsCards(self)
	-- Every row will have 3 items
	local numItemsPerRow = 3
	local cardSize = (kCardSize.x-GUILinearScale(32))
	local yPos = 0
	local xPos = 0
	local ySize = 0

	if #self.statsCards > 0 then
		yPos = self.yourStatsTextShadow:GetPosition().y + GUILinearScale(32)
		ySize = self.yourStatsTextShadow:GetPosition().y
		local lastTeam
		local tmp = {}
		for _, teamCard in ipairs(self.statsCards) do
			if lastTeam ~= teamCard.teamNumber then
				lastTeam = teamCard.teamNumber
				table.insert(tmp, {})
			end
			table.insert(tmp[#tmp], teamCard)
		end
		for _, team in ipairs(tmp) do
			local row = 0
			local tallestElem = 0
			local remainingElems = 0
			for index, card in ipairs(team) do
				local numRows = math.ceil(#team/numItemsPerRow)
				-- Determine the last row with 3 elements
				local last3Row = numItemsPerRow*(numRows-1)
				local curRow = math.ceil(index/numItemsPerRow)
				local relativeIndex = index-((curRow-1)*numItemsPerRow)
				local currentYPos = card.tableBackground:GetSize().y + card.background:GetSize().y + GUILinearScale(16)
				if row == curRow and currentYPos > tallestElem then
					tallestElem = currentYPos
				elseif row ~= curRow then
					row = curRow
					yPos = yPos + tallestElem
					tallestElem = currentYPos
					remainingElems = #team - index + 1
				end
				if index <= last3Row or remainingElems == 3 then
					xPos = (relativeIndex-2)*GUILinearScale(32)-cardSize*1.5+(relativeIndex-1)*cardSize
				elseif remainingElems == 2 then
					xPos = -cardSize+(2-relativeIndex)*cardSize+ConditionalValue(relativeIndex == 1, 1, -1)*GUILinearScale(32)
				else
					xPos = -cardSize/2
				end
				card.background:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2 + xPos, yPos, 0))
			end
			yPos = yPos + tallestElem
		end
	end

	return yPos - ySize
end

function GUIGameEndStats:RepositionStats()
	local yPos = GUILinearScale(16)

	self.yourStatsTextShadow:SetIsVisible(#self.statsCards > 0)

	if self.team1UI.background:GetIsVisible() then
		self.teamStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
		yPos = yPos + GUILinearScale(32)
		self.team1UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
		yPos = yPos + self.team1UI.tableBackground:GetSize().y + self.team1UI.background:GetSize().y
		self.team2UI.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
		yPos = yPos + self.team2UI.tableBackground:GetSize().y + self.team2UI.background:GetSize().y + GUILinearScale(32)
	end

	self.yourStatsTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
	yPos = yPos + repositionStatsCards(self)

	local showTechLog = #self.techLogs > 0
	self.techLogTextShadow:SetIsVisible(showTechLog)
	if showTechLog then
		self.techLogTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
		yPos = yPos + GUILinearScale(32)

		self.techLogs[1].header.background:SetPosition(Vector(GUILinearScale(16), yPos, 0))
		self.techLogs[2].header.background:SetPosition(Vector(kTechLogTitleSize.x + GUILinearScale(16), yPos, 0))

		local team1YSize = self.techLogs[1].header.background:GetSize().y + self.techLogs[1].header.tableBackground:GetSize().y
		local team2YSize = self.techLogs[2].header.background:GetSize().y + self.techLogs[2].header.tableBackground:GetSize().y

		yPos = yPos + GUILinearScale(32) + math.max(team1YSize, team2YSize)
	end

	local showRTGraph = #self.rtGraphs > 0
	self.rtGraphTextShadow:SetIsVisible(showRTGraph)
	self.rtGraph:SetIsVisible(showRTGraph)
	self.builtRTsComp:SetIsVisible(showRTGraph)
	self.lostRTsComp:SetIsVisible(showRTGraph)
	if showRTGraph then
		self.rtGraphTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
		yPos = yPos + GUILinearScale(32)

		self.rtGraph:SetPosition(Vector((kTitleSize.x-rtGraphSize.x)/2, yPos, 0))
		yPos = yPos + rtGraphSize.y + GUILinearScale(72)

		self.builtRTsComp:SetPosition(Vector((kTitleSize.x-comparisonSize.x-rtGraphPadding)/2, yPos, 0))
		yPos = yPos + comparisonSize.y + GUILinearScale(48)

		self.lostRTsComp:SetPosition(Vector((kTitleSize.x-comparisonSize.x-rtGraphPadding)/2, yPos, 0))
		yPos = yPos + comparisonSize.y + GUILinearScale(48)
	end

	local showKillGraph = #self.killGraphs > 0
	self.killGraphTextShadow:SetIsVisible(showKillGraph)
	self.killGraph:SetIsVisible(showKillGraph)
	self.killComparison:SetIsVisible(showKillGraph)
	if showKillGraph then
		self.killGraphTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
		yPos = yPos + GUILinearScale(32)

		self.killGraph:SetPosition(Vector((kTitleSize.x-rtGraphSize.x)/2, yPos, 0))
		yPos = yPos + rtGraphSize.y + GUILinearScale(72)

		self.killComparison:SetPosition(Vector((kTitleSize.x-comparisonSize.x-rtGraphPadding)/2, yPos, 0))
		yPos = yPos + comparisonSize.y + GUILinearScale(48)
	end

	local showHiveSkillGraph = #self.hiveSkillGraphs > 0
	self.hiveSkillGraphTextShadow:SetIsVisible(showHiveSkillGraph)
	self.hiveSkillGraph:SetIsVisible(showHiveSkillGraph)
	if showHiveSkillGraph then
		self.hiveSkillGraphTextShadow:SetPosition(Vector((kTitleSize.x-GUILinearScale(32))/2, yPos, 0))
		yPos = yPos + GUILinearScale(32)

		self.hiveSkillGraph:SetPosition(Vector((kTitleSize.x-rtGraphSize.x)/2, yPos, 0))
		yPos = yPos + rtGraphSize.y + GUILinearScale(72)
	end

	self.contentSize = math.max(self.contentSize, yPos)
end

local function HandleSlidebarClicked(self)
	local _, mouseY = Client.GetCursorPosScreen()
	if self.sliderBarBg:GetIsVisible() and self.isDragging then
		local topPos = self.sliderBarBg:GetScreenPosition(screenWidth, screenHeight).y
		local bottomPos = topPos + kContentMaxYSize
		mouseY = Clamp(mouseY, topPos, bottomPos)
		local slidePercentage = (mouseY - topPos) / (bottomPos - topPos)
		self.slideOffset = slidePercentage * (self.contentSize - kContentMaxYSize)
	end
end

local function CheckRowHighlight(self, row, mouseX, mouseY)
	if GUIItemContainsPoint(row.background, mouseX, mouseY) and row.steamId then
		if not row.originalColor then
			row.originalColor = row.background:GetColor()
		end
		local color = row.originalColor * 0.75
		row.background:SetColor(color)

		if row.commIcon and row.commIcon.tooltip and GUIItemContainsPoint(row.commIcon, mouseX, mouseY) then
			self.tooltip:SetText(row.commIcon.tooltip)
			self.tooltip:Show()
		else
			self.tooltip:Hide()
		end

		self.lastRow = row
	elseif row.originalColor then
		row.background:SetColor(row.originalColor)
		row.originalColor = nil
	end
end

local function SortByColumn(self, isMarine, sortField, inv)
	local playerRows = isMarine and self.team1UI.playerRows or self.team2UI.playerRows
	local sortTable = {}
	for _, row in ipairs(playerRows) do
		if row.originalOrder and row.message then
			table.insert(sortTable, row)
		end
	end

	table.sort(sortTable, function(a, b)
		if a.message[sortField] == b.message[sortField] then
			return a.originalOrder < b.originalOrder
		elseif sortField == "lowerCaseName" and not inv or sortField ~= "lowerCaseName" and inv then
			return a.message[sortField] < b.message[sortField]
		else
			return a.message[sortField] > b.message[sortField]
		end
	end)

	for index, row in ipairs(sortTable) do
		local bgColor = isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
		if index % 2 == 0 then
			bgColor = isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
		end

		row.background:SetPosition(Vector(kRowBorderSize, kRowBorderSize + index*kRowSize.y, 0))
		-- Our own row is colored correctly already
		if row.message.steamId ~= Client.GetSteamId() then
			row.background:SetColor(bgColor)
		end
	end
end

local function GetXSpacing(gameLength)
	local xSpacing = 60

	if gameLength < 60 then
		xSpacing = 10
	elseif gameLength < 5*60 then
		xSpacing = 30
	elseif gameLength < 15*60 then
		xSpacing = 60
	elseif gameLength < 60*60 then
		xSpacing = 300
	else
		xSpacing = 600
	end

	return xSpacing
end

local function GetYSpacing(value)
	local ySpacing = 25

	if value < 10 then
		return 1
	elseif value < 20 then
		return 2
	elseif value < 100 then
		return 10
	else
		return 25
	end

	return ySpacing
end

function GUIGameEndStats:UpdateRowHighlight()
	local mouseX, mouseY = Client.GetCursorPosScreen()

	if not self.hoverMenu.background:GetIsVisible() then
		self.lastRow = nil
		highlightedField = nil
		for index, row in ipairs(self.team1UI.playerRows) do
			if index == 1 then
				local highlightColor = kMarineHeaderRowTextHighlightColor
				local textColor = kMarineHeaderRowTextColor
				for fieldName, item in pairs(row) do
					if item.GetText and item:GetText() ~= "" then
						if GUIItemContainsPoint(item, mouseX, mouseY) then
							highlightedField = fieldName
							highlightedFieldMarine = true
							item:SetColor(highlightColor)
						else
							item:SetColor(textColor)
						end
					end
				end
			else
				CheckRowHighlight(self, row, mouseX, mouseY)
			end
		end
		for index, row in ipairs(self.team2UI.playerRows) do
			if index == 1 then
				local highlightColor = kAlienHeaderRowTextHighlightColor
				local textColor = kAlienHeaderRowTextColor
				for fieldName, item in pairs(row) do
					if item.GetText and item:GetText() ~= "" then
						if GUIItemContainsPoint(item, mouseX, mouseY) then
							highlightedField = fieldName
							highlightedFieldMarine = false
							item:SetColor(highlightColor)
						else
							item:SetColor(textColor)
						end
					end
				end
			else
				CheckRowHighlight(self, row, mouseX, mouseY)
			end
		end

		if self.lastRow == nil then
			self.tooltip:Hide()
		end

		-- Change it to the field name on the message table for proper sorting
		if highlightedField == "acc" then
			highlightedField = "realAccuracy"
		elseif highlightedField == "timeBuilding" then
			highlightedField = "minutesBuilding"
		elseif highlightedField == "timePlayed" then
			highlightedField = "minutesPlaying"
		elseif highlightedField == "playerName" then
			highlightedField = "lowerCaseName"
		end
	end

end

function GUIGameEndStats:UpdateSlidebar()
	-- Handle sliderbar position and display
	if self.sliderBarBg:GetIsVisible() and self.mousePressed and self.isDragging then
		HandleSlidebarClicked(self)
	end

	-- Check if it's visible again since we hide the menu if the game starts
	local showSlidebar = self.contentSize > kContentMaxYSize and self:GetIsVisible()
	local sliderPos = (self.slideOffset / (self.contentSize - kContentMaxYSize) * kContentMaxYSize) - self.slider:GetSize().y/2
	self.background:SetPosition(Vector(-(kTitleSize.x-GUILinearScale(32))/2, -self.slideOffset + GUILinearScale(128), 0))

	if math.abs(self.slider:GetPosition().y - sliderPos) > 2.5 then
		StartSoundEffect(kSlideSound)
	end

	self.slider:SetPosition(Vector(-GUILinearScale(8), sliderPos, 0))
	self.sliderBarBg:SetIsVisible(showSlidebar)
end

function GUIGameEndStats:CheckGameState()
	local gameInfo = GetGameInfoEntity()
	local warmupActive = gameInfo.GetWarmUpActive and gameInfo:GetWarmUpActive()

	-- Hide the stats when the game starts if we're on a team
	if PlayerUI_GetHasGameStarted() and not warmupActive and (Client.GetLocalPlayer():GetTeamNumber() ~= kTeamReadyRoom and Client.GetLocalPlayer():GetTeamNumber() ~= kSpectatorIndex) then
		self:SetIsVisible(false)
		self.actionIconGUI:Hide()
	end
end

function GUIGameEndStats:UpdateCloseButton()
	local mouseX, mouseY = Client.GetCursorPosScreen()

	-- Close button
	local kCloseButtonColor = Color(1, 0, 0, 0.5)
	local kCloseButtonHighlightColor = Color(1, 0, 0, 0.75)

	if GUIItemContainsPoint(self.closeButton, mouseX, mouseY) then
		if self.closeButton:GetColor() ~= kCloseButtonHighlightColor then
			self.closeButton:SetColor(kCloseButtonHighlightColor)
			StartSoundEffect(kMouseHoverSound)
		end
	elseif self.closeButton:GetColor() ~= kCloseButtonColor then
		self.closeButton:SetColor(kCloseButtonColor)
		StartSoundEffect(kMouseHoverSound)
	end
end

function GUIGameEndStats:UpdateVisibleUI()
	-- When going back to the RR sometimes we'll lose the cursor
	if not MouseTracker_GetIsVisible() then
		MouseTracker_SetIsVisible(true)
	end

	self:CheckGameState()

	if not self:GetIsVisible() then return end

	self:UpdateRowHighlight()

	self:UpdateSlidebar()

	self:UpdateCloseButton()
end

-- Todo: Split this monster into submethods
function GUIGameEndStats:ProcessStats()
	table.sort(finalStatsTable, function(a, b)
		a.teamNumber = a.isMarine and 1 or 2
		b.teamNumber = b.isMarine and 1 or 2
		a.realAccuracy = a.accuracyOnos == -1 and a.accuracy or a.accuracyOnos
		b.realAccuracy = b.accuracyOnos == -1 and b.accuracy or b.accuracyOnos
		a.lowerCaseName = string.UTF8Lower(a.playerName)
		b.lowerCaseName = string.UTF8Lower(b.playerName)
		if a.teamNumber == b.teamNumber then
			if a.kills == b.kills then
				if a.assists == b.assists then
					if a.deaths == b.deaths then
						if a.realAccuracy == b.realAccuracy then
							if a.pdmg == b.pdmg then
								if a.sdmg == b.sdmg then
									if a.minutesBuilding == b.minutesBuilding then
										return a.lowerCaseName < b.lowerCaseName
									else
										return a.minutesBuilding > b.minutesBuilding
									end
								else
									return a.sdmg > b.sdmg
								end
							else
								return a.pdmg > b.pdmg
							end
						else
							return a.accuracy > b.accuracy
						end
					else
						return a.deaths < b.deaths
					end
				else
					return a.assists > b.assists
				end
			else
				return a.kills > b.kills
			end
		else
			return a.teamNumber < b.teamNumber
		end
	end)

	table.sort(cardsTable, function(a, b)
		if a.order and b.order then
			return a.order < b.order
		elseif a.teamNumber == b.teamNumber then
			if a.message.kills and b.message.kills then
				a.message.realAccuracy = a.message.accuracyOnos == -1 and a.message.accuracy or a.message.accuracyOnos
				b.message.realAccuracy = b.message.accuracyOnos == -1 and b.message.accuracy or b.message.accuracyOnos
				if a.message.kills == b.message.kills then
					return a.message.realAccuracy > b.message.realAccuracy
				else
					return a.message.kills > b.message.kills
				end
			end
		else
			return a.teamNumber < b.teamNumber
		end
	end)

	local totalKills1 = 0
	local totalKills2 = 0
	local totalAssists1 = 0
	local totalAssists2 = 0
	local totalDeaths1 = 0
	local totalDeaths2 = 0
	local totalPdmg1 = 0
	local totalPdmg2 = 0
	local totalSdmg1 = 0
	local totalSdmg2 = 0
	local totalTimeBuilding1 = 0
	local totalTimeBuilding2 = 0
	local totalTimePlaying1 = 0
	local totalTimePlaying2 = 0
	local avgAccuracy1 = 0
	local avgAccuracy1Onos = 0
	local avgAccuracy2 = 0
	local team1Score = 0
	local team2Score = 0
	local team1Comm = 0
	local team2Comm = 0
	local team1CommTime = 0
	local team2CommTime = 0

	self:Uninitialize()
	self:Initialize()

	for _, message in ipairs(finalStatsTable) do
		-- Initialize the values in case there's something missing
		message.isMarine = message.isMarine or false
		message.playerName = message.playerName or "NSPlayer"
		message.kills = message.kills or 0
		message.assists = message.assists or 0
		message.deaths = message.deaths or 0
		message.accuracy = message.accuracy or 0
		message.accuracyOnos = message.accuracyOnos or -1
		message.score = message.score or 0
		message.pdmg = message.pdmg or 0
		message.sdmg = message.sdmg or 0
		message.minutesBuilding = message.minutesBuilding or 0
		message.minutesPlaying = message.minutesPlaying or 0
		message.minutesComm = message.minutesComm or 0
		message.killstreak = message.killstreak or 0
		message.steamId = message.steamId or 1
		message.isRookie = message.isRookie or false
		message.hiveSkill = message.hiveSkill or -1

		local isMarine = message.isMarine

		-- save player stats into a map for later usage (e.g. hive skill graph)
		local teamNumber = isMarine and 1 or 2
		if not playerStatMap[teamNumber] then playerStatMap[teamNumber] = {} end
		playerStatMap[teamNumber][message.steamId] = message

		local minutes = math.floor(message.minutesBuilding)
		local seconds = (message.minutesBuilding % 1)*60

		local pMinutes = math.floor(message.minutesPlaying)
		local pSeconds = (message.minutesPlaying % 1)*60

		local cMinutes = math.floor(message.minutesComm)
		local cSeconds = (message.minutesComm % 1)*60

		local teamObj

		if isMarine then
			teamObj = self.team1UI
			totalKills1 = totalKills1 + message.kills
			totalAssists1 = totalAssists1 + message.assists
			totalDeaths1 = totalDeaths1 + message.deaths
			totalPdmg1 = totalPdmg1 + message.pdmg
			totalSdmg1 = totalSdmg1 + message.sdmg
			totalTimeBuilding1 = totalTimeBuilding1 + message.minutesBuilding
			totalTimePlaying1 = totalTimePlaying1 + message.minutesPlaying
			avgAccuracy1 = avgAccTable.marineAcc
			avgAccuracy1Onos = avgAccTable.marineOnosAcc
			team1Score = team1Score + message.score
		else
			teamObj = self.team2UI
			totalKills2 = totalKills2 + message.kills
			totalAssists2 = totalAssists2 + message.assists
			totalDeaths2 = totalDeaths2 + message.deaths
			totalPdmg2 = totalPdmg2 + message.pdmg
			totalSdmg2 = totalSdmg2 + message.sdmg
			totalTimeBuilding2 = totalTimeBuilding2 + message.minutesBuilding
			totalTimePlaying2 = totalTimePlaying2 + message.minutesPlaying
			avgAccuracy2 = avgAccTable.alienAcc
			team2Score = team2Score + message.score
		end

		local playerCount = #teamObj.playerRows
		local bgColor = isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
		local playerTextColor = kPlayerStatsTextColor
		if playerCount % 2 == 0 then
			bgColor = isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
		end

		-- Color our own row in a different color
		if message.steamId == Client.GetSteamId() then
			bgColor = kCurrentPlayerStatsColor
			playerTextColor = kCurrentPlayerStatsTextColor
		end

		table.insert(teamObj.playerRows, CreateScoreboardRow(teamObj.tableBackground, bgColor, playerTextColor, message.playerName, printNum(message.kills), printNum(message.assists), printNum(message.deaths), message.accuracyOnos == -1 and string.format("%s%%", printNum(message.accuracy)) or string.format("%s%% (%s%%)", printNum(message.accuracy), printNum(message.accuracyOnos)), printNum2(message.score), printNum2(message.pdmg), printNum2(message.sdmg), string.format("%d:%02d", minutes, seconds), string.format("%d:%02d", pMinutes, pSeconds), message.minutesComm > 0 and string.format("%d:%02d", cMinutes, cSeconds) or nil, message.steamId, message.isRookie, message.hiveSkill))
		-- Store some of the original info so we can sort afterwards
		teamObj.playerRows[#teamObj.playerRows].originalOrder = playerCount
		teamObj.playerRows[#teamObj.playerRows].message = message

		if isMarine and message.minutesComm > team1CommTime then
			team1Comm = playerCount+1
			team1CommTime = message.minutesComm
		elseif not isMarine and message.minutesComm > team2CommTime then
			team2Comm = playerCount+1
			team2CommTime = message.minutesComm
		end
	end

	if team1Comm > 0 then
		if self.team1UI.playerRows[team1Comm].message then
			self.team1UI.playerRows[team1Comm].commIcon:SetTexture("ui/badges/commander_20.dds")
		end
	end

	if team2Comm > 0 then
		if self.team2UI.playerRows[team2Comm] then
			self.team2UI.playerRows[team2Comm].commIcon:SetTexture("ui/badges/commander_20.dds")
		end
	end

	local numPlayers1 = #self.team1UI.playerRows-1
	local numPlayers2 = #self.team2UI.playerRows-1
	self:SetPlayerCount(self.team1UI, numPlayers1)
	self:SetPlayerCount(self.team2UI, numPlayers2)
	miscDataTable.team1PlayerCount = numPlayers1
	miscDataTable.team2PlayerCount = numPlayers2
	self:SetTeamName(self.team1UI, miscDataTable.team1Name or "TSF陆战队")
	self:SetTeamName(self.team2UI, miscDataTable.team2Name or "卡拉异形")
	local team1Result, team2Result = "不分胜负", "不分胜负"
	if miscDataTable.winningTeam > 0 then
		team1Result = miscDataTable.winningTeam == kMarineTeamType and "已压制污染指标" or "指挥所失联"
		team2Result = miscDataTable.winningTeam == kAlienTeamType and "已侵占该区域" or "母巢体征消失"
	end
	self:SetGameResult(self.team1UI, team1Result)
	self:SetGameResult(self.team2UI, team2Result)

	local minutes1 = math.floor(totalTimeBuilding1)
	local seconds1 = (totalTimeBuilding1 % 1)*60
	totalTimeBuilding1 = totalTimeBuilding1/numPlayers1
	local minutes1Avg = math.floor(totalTimeBuilding1)
	local seconds1Avg = (totalTimeBuilding1 % 1)*60

	totalTimePlaying1 = totalTimePlaying1/numPlayers1
	local minutes1PAvg = math.floor(totalTimePlaying1)
	local seconds1PAvg = (totalTimePlaying1 % 1)*60

	local minutes2 = math.floor(totalTimeBuilding2)
	local seconds2 = (totalTimeBuilding2 % 1)*60
	totalTimeBuilding2 = totalTimeBuilding2/numPlayers2
	local minutes2Avg = math.floor(totalTimeBuilding2)
	local seconds2Avg = (totalTimeBuilding2 % 1)*60

	totalTimePlaying2 = totalTimePlaying2/numPlayers2
	local minutes2PAvg = math.floor(totalTimePlaying2)
	local seconds2PAvg = (totalTimePlaying2 % 1)*60

	-- When there's only one player in a team, the total and the average will be the same
	-- Don't even bother displaying this, it looks odd
	if numPlayers1 > 1 then
		table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "总计", printNum(totalKills1), printNum(totalAssists1), printNum(totalDeaths1), " ", printNum(team1Score), printNum2(totalPdmg1), printNum2(totalSdmg1), string.format("%d:%02d", minutes1, seconds1)))
		table.insert(self.team1UI.playerRows, CreateScoreboardRow(self.team1UI.tableBackground, kAverageRowColor, kAverageRowTextColor, "平均", printNum(totalKills1/numPlayers1), printNum(totalAssists1/numPlayers1), printNum(totalDeaths1/numPlayers1), avgAccuracy1Onos == -1 and string.format("%s%%", printNum(avgAccuracy1)) or string.format("%s%% (%s%%)", printNum(avgAccuracy1), printNum(avgAccuracy1Onos)), printNum(team1Score/numPlayers1), printNum2(totalPdmg1/numPlayers1), printNum2(totalSdmg1/numPlayers1), string.format("%d:%02d", minutes1Avg, seconds1Avg), string.format("%d:%02d", minutes1PAvg, seconds1PAvg)))
	end
	if numPlayers2 > 1 then
		table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor, "总计", printNum(totalKills2), printNum(totalAssists2), printNum(totalDeaths2), " ", printNum2(team2Score), printNum2(totalPdmg2), printNum2(totalSdmg2), string.format("%d:%02d", minutes2, seconds2)))
		table.insert(self.team2UI.playerRows, CreateScoreboardRow(self.team2UI.tableBackground, kAverageRowColor, kAverageRowTextColor, "平均", printNum(totalKills2/numPlayers2), printNum(totalAssists2/numPlayers2), printNum(totalDeaths2/numPlayers2), string.format("%s%%", printNum(avgAccuracy2)), printNum2(team2Score/numPlayers2), printNum2(totalPdmg2/numPlayers2), printNum2(totalSdmg2/numPlayers2), string.format("%d:%02d", minutes2Avg, seconds2Avg), string.format("%d:%02d", minutes2PAvg, seconds2PAvg)))
	end

	local gameInfo = GetGameInfoEntity()
	local teamStatsVisible = gameInfo.showEndStatsTeamBreakdown

	self.team1UI.background:SetIsVisible(teamStatsVisible)
	self.team2UI.background:SetIsVisible(teamStatsVisible)
	self.teamStatsTextShadow:SetIsVisible(teamStatsVisible)

	self.roundDate:SetText(string.format("日期: %s", miscDataTable.roundDateString))
	self.gameLength:SetText(string.format("对局时长: %s", miscDataTable.gameLength))
	self.serverName:SetText(string.format("服务器: %s", miscDataTable.serverName))
	self.mapName:SetText(string.format("地图: %s", miscDataTable.mapName))

	if #statusSummaryTable > 0 then
		table.sort(statusSummaryTable, function(a, b)
			if a.timeMinutes == b.timeMinutes then
				return a.className < b.className
			else
				return a.timeMinutes > b.timeMinutes
			end
		end)

		local bgColor = kStatusStatsColor
		local statCard = self:CreateGraphicHeader("单位时间占比", bgColor)
		statCard.rows = {}
		statCard.teamNumber = -2

		local totalTime = 0
		for _, row in ipairs(statusSummaryTable) do
			totalTime = totalTime + row.timeMinutes
		end

		for index, row in ipairs(statusSummaryTable) do
			bgColor = ConditionalValue(index % 2 == 0, kMarinePlayerStatsEvenColor, kMarinePlayerStatsOddColor)
			local minutes = math.floor(row.timeMinutes)
			local seconds = (row.timeMinutes % 1)*60
			local percentage = row.timeMinutes / totalTime * 100
			table.insert(statCard.rows, CreateHeaderRow(statCard.tableBackground, bgColor, Color(1,1,1,1), row.className, string.format("%d:%02d (%s%%)", minutes, seconds, printNum(percentage))))
		end
		table.insert(self.statsCards, statCard)
	end

	for _, card in ipairs(cardsTable) do
		local bgColor
		if card.teamNumber == 1 then
			bgColor = kMarineStatsColor
		elseif card.teamNumber == 2 then
			bgColor = kAlienStatsColor
		else
			bgColor = kCommanderStatsColor
		end
		local statCard = self:CreateGraphicHeader(card.text, bgColor, card.logoTexture, card.logoCoords, card.logoSizeX, card.logoSizeY)
		statCard.rows = {}
		statCard.teamNumber = card.teamNumber

		for index, row in ipairs(card.rows) do
			if card.teamNumber == 1 then
				bgColor = ConditionalValue(index % 2 == 0, kMarinePlayerStatsEvenColor, kMarinePlayerStatsOddColor)
			elseif card.teamNumber == 2 then
				bgColor = ConditionalValue(index % 2 == 0, kAlienPlayerStatsEvenColor, kAlienPlayerStatsOddColor)
			else
				bgColor = ConditionalValue(index % 2 == 0, kCommanderStatsEvenColor, kCommanderStatsOddColor)
			end

			table.insert(statCard.rows, CreateHeaderRow(statCard.tableBackground, bgColor, Color(1,1,1,1), row.title, row.value))
		end
		table.insert(self.statsCards, statCard)
	end

	if #techLogTable > 0 or #buildingSummaryTable > 0 then
		table.sort(techLogTable, function(a, b)
			if a.teamNumber == b.teamNumber then
				if a.finishedMinute == b.finishedMinute then
					return a.name > b.name
				else
					return a.finishedMinute < b.finishedMinute
				end
			else
				return a.teamNumber < b.teamNumber
			end
		end)

		table.sort(buildingSummaryTable, function(a, b)
			if a.teamNumber == b.teamNumber then
				if a.built == b. built then
					if a.lost == b.lost then
						return a.techId < b.techId
					else
						return a.lost > b.lost
					end
				else
					return a.built > b.built
				end
			else
				return a.teamNumber < b.teamNumber
			end
		end)

		local team1Name = miscDataTable.team1Name or "TSF陆战队"
		local team2Name = miscDataTable.team2Name or "卡拉异形"

		self.techLogs[1] = {}
		self.techLogs[1].header = self:CreateTechLogHeader(1, team1Name)
		self.techLogs[1].rows = {}

		self.techLogs[2] = {}
		self.techLogs[2].header = self:CreateTechLogHeader(2, team2Name)
		self.techLogs[2].rows = {}

		-- Right now we only have marine comm stats so...
		if commanderStats then
			table.insert(self.techLogs[1].rows, CreateCommStatsRow(self.techLogs[1].header.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "指挥数据", "精准度", "效率", "回复量", "被拾取", "流失"))

			local row = 1

			if commanderStats.medpackResUsed > 0 or commanderStats.medpackResExpired > 0 then
				table.insert(self.techLogs[1].rows, CreateCommStatsRow(self.techLogs[1].header.tableBackground, row % 2 == 0 and kMarinePlayerStatsEvenColor or kMarinePlayerStatsOddColor, kMarineHeaderRowTextColor, "治疗包", printNum(commanderStats.medpackAccuracy) .. "%", printNum(commanderStats.medpackEfficiency) .. "%", commanderStats.medpackRefill, commanderStats.medpackResUsed, commanderStats.medpackResExpired, "ui/buildmenu.dds", GetTextureCoordinatesForIcon(kTechId.MedPack), 24, 24, kIconColors[1]))
				row = row + 1
			end

			if commanderStats.ammopackResUsed > 0 or commanderStats.ammopackResExpired > 0 then
				table.insert(self.techLogs[1].rows, CreateCommStatsRow(self.techLogs[1].header.tableBackground, row % 2 == 0 and kMarinePlayerStatsEvenColor or kMarinePlayerStatsOddColor, kMarineHeaderRowTextColor, "弹药包", "-", printNum(commanderStats.ammopackEfficiency) .. "%", commanderStats.ammopackRefill, commanderStats.ammopackResUsed, commanderStats.ammopackResExpired, "ui/buildmenu.dds", GetTextureCoordinatesForIcon(kTechId.AmmoPack), 24, 24, kIconColors[1]))
				row = row + 1
			end

			if commanderStats.catpackResUsed > 0 or commanderStats.catpackResExpired > 0 then
				table.insert(self.techLogs[1].rows, CreateCommStatsRow(self.techLogs[1].header.tableBackground, row % 2 == 0 and kMarinePlayerStatsEvenColor or kMarinePlayerStatsOddColor, kMarineHeaderRowTextColor, "兴奋剂", "-", printNum(commanderStats.catpackEfficiency) .. "%", "-", commanderStats.catpackResUsed, commanderStats.catpackResExpired, "ui/buildmenu.dds", GetTextureCoordinatesForIcon(kTechId.CatPack), 24, 24, kIconColors[1]))
			end
		end

		if #buildingSummaryTable > 0 then
			if buildingSummaryTable[1].teamNumber == 1 then
				table.insert(self.techLogs[1].rows, CreateTechLogRow(self.techLogs[1].header.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "", "建筑", "建造", "被摧毁"))
			end

			if buildingSummaryTable[#buildingSummaryTable].teamNumber == 2 then
				table.insert(self.techLogs[2].rows, CreateTechLogRow(self.techLogs[2].header.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor, "", "建筑", "建造", "被摧毁"))
			end

			for index, buildingEntry in ipairs(buildingSummaryTable) do
				local isMarine = buildingEntry.teamNumber == 1
				local rowTextColor = isMarine and kMarineHeaderRowTextColor or kAlienHeaderRowTextColor
				local logoColor = kIconColors[buildingEntry.teamNumber]
				local bgColor = isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
				if index % 2 == 0 then
					bgColor = isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
				end

				table.insert(self.techLogs[buildingEntry.teamNumber].rows, CreateTechLogRow(self.techLogs[buildingEntry.teamNumber].header.tableBackground, bgColor, rowTextColor, "", buildingEntry.name, buildingEntry.built, buildingEntry.lost, buildingEntry.iconTexture, buildingEntry.iconCoords, buildingEntry.iconSizeX, buildingEntry.iconSizeY, logoColor))
			end

		end

		if #techLogTable > 0 then
			if techLogTable[1].teamNumber == 1 then
				table.insert(self.techLogs[1].rows, CreateTechLogRow(self.techLogs[1].header.tableBackground, kHeaderRowColor, kMarineHeaderRowTextColor, "时间点", "研发", "资源塔", "资源"))
			end

			if techLogTable[#techLogTable].teamNumber == 2 then
				table.insert(self.techLogs[2].rows, CreateTechLogRow(self.techLogs[2].header.tableBackground, kHeaderRowColor, kAlienHeaderRowTextColor, "时间点", "研发", "资源塔", "资源"))
			end

			for index, techLogEntry in ipairs(techLogTable) do
				local isMarine = techLogEntry.teamNumber == 1
				local isLost = techLogEntry.destroyed == true
				local rowTextColor = isMarine and kMarineHeaderRowTextColor or kAlienHeaderRowTextColor
				local logoColor = kIconColors[techLogEntry.teamNumber]
				local bgColor = isLost and kLostTechOddColor or isMarine and kMarinePlayerStatsOddColor or kAlienPlayerStatsOddColor
				if index % 2 == 0 then
					bgColor = isLost and kLostTechEvenColor or isMarine and kMarinePlayerStatsEvenColor or kAlienPlayerStatsEvenColor
				end

				table.insert(self.techLogs[techLogEntry.teamNumber].rows, CreateTechLogRow(self.techLogs[techLogEntry.teamNumber].header.tableBackground, bgColor, rowTextColor, techLogEntry.finishedTime, techLogEntry.name, techLogEntry.activeRTs, techLogEntry.teamRes, techLogEntry.iconTexture, techLogEntry.iconCoords, techLogEntry.iconSizeX, techLogEntry.iconSizeY, logoColor))
			end
		end
	end

	self.hiveSkillGraphs = {}
	if #hiveSkillGraphTable > 0 then
		table.sort(hiveSkillGraphTable, function(a, b)
			return a.gameMinute < b.gameMinute
		end)

		self.hiveSkillGraphs[1] = {}
		self.hiveSkillGraphs[2] = {}
		local hiveSkill = {0, 0}
		local lineOffset = {0, 0.5}
		local maxHiveSkill = 0
		local minHiveSkill = 0
		local avgTeam1Skill = 0
		local avgTeam2Skill = 0

		-- Keep track of players in each team to filter out duplicate hiveSkillGraphTable join/leave entries
		local players = {{}, {}}
		-- Counting set size is not easy so keep separate track
		local playerCount = {0, 0}

		-- Iterate over the graph data table but only add a new data point after advancing in time
		-- It's not uncommon for more than 1 player to change their team at any given point in time
		-- Specially at the very begining of a round
		-- The iteration limit is #hiveSkillGraphTable + 1 to add the last data point at the very end
		local graphTime = 0
		local roundEndTime = miscDataTable.gameLengthMinutes
		for i = 1, #hiveSkillGraphTable + 1 do
			local entry = hiveSkillGraphTable[i]
			local entryTime = entry and entry.gameMinute

			-- Add data point after advancing in time or reaching the end of the data table (entry == nil) / round
			local atEnd = entry == nil or entryTime >= roundEndTime
			if atEnd or graphTime ~= entry.gameMinute then
				local gameSeconds = graphTime * 60

				if gameSeconds == 0 then
					-- Dont show graph going from 0 to start average hive skill
					-- The total hive skill is larger than the min average hive skill.
					minHiveSkill = math.min(hiveSkill[1], hiveSkill[2])
				else
					table.insert(self.hiveSkillGraphs[1], Vector(gameSeconds, avgTeam1Skill + lineOffset[1], 0))
					table.insert(self.hiveSkillGraphs[2], Vector(gameSeconds, avgTeam2Skill + lineOffset[2], 0))
				end

				avgTeam1Skill, avgTeam2Skill = hiveSkill[1] / math.max(playerCount[1], 1) , hiveSkill[2] / math.max(playerCount[2], 1)
				maxHiveSkill = math.max(maxHiveSkill, avgTeam1Skill, avgTeam2Skill)
				minHiveSkill = math.min(minHiveSkill, avgTeam1Skill, avgTeam2Skill)

				table.insert(self.hiveSkillGraphs[1], Vector(gameSeconds, avgTeam1Skill + lineOffset[1], 0))
				table.insert(self.hiveSkillGraphs[2], Vector(gameSeconds, avgTeam2Skill + lineOffset[2], 0))

				-- Reached the end, exit here
				if atEnd then
					break
				end

				graphTime = entryTime
			end

            local id = entry.steamId
			local teamNumber = entry.teamNumber
			local isHuman = id > 0 -- don't track bots
			local playerEntry = isHuman and playerStatMap[teamNumber] and playerStatMap[teamNumber][id]
			local isPlaying = isHuman and players[teamNumber] and players[teamNumber][id]

			-- Filter out invalid data table entries
			if playerEntry and entry.joined ~= isPlaying then
				local playerSkill = math.max(playerEntry.hiveSkill, 0)
				players[teamNumber][id] = entry.joined
				playerCount[teamNumber] = playerCount[teamNumber] + ConditionalValue(entry.joined, 1, -1)
				hiveSkill[teamNumber] = hiveSkill[teamNumber] + ConditionalValue(entry.joined, playerSkill, -playerSkill)
			end
		end

		self.hiveSkillGraph:SetPoints(1, self.hiveSkillGraphs[1])
		self.hiveSkillGraph:SetPoints(2, self.hiveSkillGraphs[2])

		minHiveSkill = Round(math.max(minHiveSkill - 100, 0), -2)
		maxHiveSkill = Round(maxHiveSkill + 100, -2)
		self.hiveSkillGraph:SetYBounds(minHiveSkill, maxHiveSkill, true)

		local gameLength = miscDataTable.gameLengthMinutes * 60
		local xSpacing = GetXSpacing(gameLength)

		self.hiveSkillGraph:SetXBounds(0, gameLength)
		self.hiveSkillGraph:SetXGridSpacing(xSpacing)

		local diff = maxHiveSkill - minHiveSkill
		local yGridSpacing = diff <= 200 and 25 or diff <= 400 and 50 or diff <= 800 and 100 or Round(diff/8,-2)
		self.hiveSkillGraph:SetYGridSpacing(yGridSpacing)
	end

	self.rtGraphs = {}
	if #rtGraphTable > 0 then
		table.sort(rtGraphTable, function(a, b)
			return a.gameMinute < b.gameMinute
		end)

		self.rtGraphs[1] = {}
		self.rtGraphs[2] = {}
		local rtCount = {0, 0}
		local lineOffset = {0, 0.05}
		local maxRTs = 0

		for _, entry in ipairs(rtGraphTable) do
			local teamNumber = entry.teamNumber
			table.insert(self.rtGraphs[teamNumber], Vector(entry.gameMinute*60, rtCount[teamNumber]+lineOffset[teamNumber], 0))
			rtCount[teamNumber] = rtCount[teamNumber] + ConditionalValue(entry.destroyed, -1, 1)
			table.insert(self.rtGraphs[teamNumber], Vector(entry.gameMinute*60, rtCount[teamNumber]+lineOffset[teamNumber], 0))
			maxRTs = math.max(maxRTs,rtCount[teamNumber])
		end

		self.rtGraph:SetPoints(1, self.rtGraphs[1])
		self.rtGraph:SetPoints(2, self.rtGraphs[2])
		self.rtGraph:SetYBounds(0, maxRTs+1, true)
		local gameLength = miscDataTable.gameLengthMinutes*60
		local xSpacing = GetXSpacing(gameLength)

		self.rtGraph:SetXBounds(0, gameLength)
		self.rtGraph:SetXGridSpacing(xSpacing)

		self.builtRTsComp:SetValues(miscDataTable.marineRTsBuilt, miscDataTable.alienRTsBuilt)
		self.lostRTsComp:SetValues(miscDataTable.marineRTsLost, miscDataTable.alienRTsLost)

		if miscDataTable.marineRTsBuilt > 0 then
			self.builtRTsComp:SetLeftText("(" .. printNum(miscDataTable.marineRTsBuilt/miscDataTable.gameLengthMinutes) .. "/分钟)  " .. tostring(miscDataTable.marineRTsBuilt))
		end
		if miscDataTable.alienRTsBuilt > 0 then
			self.builtRTsComp:SetRightText(tostring(miscDataTable.alienRTsBuilt) .. "  (" .. printNum(miscDataTable.alienRTsBuilt/miscDataTable.gameLengthMinutes) .. "/分钟)")
		end
		if miscDataTable.marineRTsLost > 0 then
			self.lostRTsComp:SetLeftText("(" .. printNum(miscDataTable.marineRTsLost/miscDataTable.gameLengthMinutes) .. "/分钟)  " .. tostring(miscDataTable.marineRTsLost))
		end
		if miscDataTable.alienRTsLost > 0 then
			self.lostRTsComp:SetRightText(tostring(miscDataTable.alienRTsLost) .. "  (" .. printNum(miscDataTable.alienRTsLost/miscDataTable.gameLengthMinutes) .. "/分钟)")
		end
	end

	self.killGraphs = {}
	if #killGraphTable > 0 then
		table.sort(killGraphTable, function(a, b)
			return a.gameMinute < b.gameMinute
		end)

		self.killGraphs[1] = {}
		self.killGraphs[2] = {}
		local teamKills = {0, 0}
		local lineOffsets = {0, 0.05}

		for _, entry in ipairs(killGraphTable) do
			local teamNumber = entry.teamNumber
			table.insert(self.killGraphs[teamNumber], Vector(entry.gameMinute*60, teamKills[teamNumber]+lineOffsets[teamNumber], 0))
			teamKills[teamNumber] = teamKills[teamNumber] + 1
			table.insert(self.killGraphs[teamNumber], Vector(entry.gameMinute*60, teamKills[teamNumber]+lineOffsets[teamNumber], 0))
		end

		self.killGraph:SetPoints(1, self.killGraphs[1])
		self.killGraph:SetPoints(2, self.killGraphs[2])
		local yElems = math.max(teamKills[1], teamKills[2])+1
		self.killGraph:SetYBounds(0, yElems, true)
		local gameLength = miscDataTable.gameLengthMinutes*60
		local xSpacing = GetXSpacing(gameLength)
		local ySpacing = GetYSpacing(yElems)

		self.killGraph:SetXBounds(0, gameLength)
		self.killGraph:SetXGridSpacing(xSpacing)
		self.killGraph:SetYGridSpacing(ySpacing)

		self.killComparison:SetValues(teamKills[1], teamKills[2])

		if teamKills[1] > 0 then
			self.killComparison:SetLeftText("(" .. printNum(teamKills[1]/miscDataTable.gameLengthMinutes) .. "/分钟)  " .. tostring(teamKills[1]))
		end
		if teamKills[2] > 0 then
			self.killComparison:SetRightText(tostring(teamKills[2]) .. "  (" .. printNum(teamKills[2]/miscDataTable.gameLengthMinutes) .. "/分钟)")
		end
	end

	self:RepositionStats()

	pcall(self.SaveLastRoundStats, self)

	finalStatsTable = {}
	playerStatMap = {}
	avgAccTable = {}
	miscDataTable = {}
	cardsTable = {}
	hiveSkillGraphTable = {}
	rtGraphTable = {}
	commanderStats = nil
	killGraphTable = {}
	buildingSummaryTable = {}
	statusSummaryTable = {}
	techLogTable = {}
end

function GUIGameEndStats:Update()
	local timeSinceRoundEnd = lastStatsMsg > 0 and Shared.GetTime() - lastGameEnd or 0
	local gameInfo = GetGameInfoEntity()

	if self:GetIsVisible() then
		self:UpdateVisibleUI()
	else
		self.lastRow = nil
	end

	-- Enough time has passed, so let's process the stats we received
	if Shared.GetTime() > lastStatsMsg + kMaxAppendTime and (#finalStatsTable > 0 or #cardsTable > 0 or #miscDataTable > 0) and gameInfo then
		self:ProcessStats()
	end

	-- Automatic data display on round end
	if timeSinceRoundEnd > 2.5 and Shared.GetTime() > lastStatsMsg + kMaxAppendTime then

		if GetAdvancedOption("deathstats") > 0 and timeSinceRoundEnd < 7.5 and not self.displayed then
			self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("RequestMenu"), nil, "上局数据统计", nil)
		else
			self.actionIconGUI:Hide()
		end

		local gameEndSummary = Client.shouldShowEndSummary or ClientUI.GetScript("GUIGameEndPage") and ClientUI.GetScript("GUIGameEndPage"):GetIsVisible()
		local gameFeedback = Client.shouldShowFeedback or ClientUI.GetScript("GUIGameFeedback") and ClientUI.GetScript("GUIGameFeedback"):GetIsVisible()

		if not gameEndSummary and not gameFeedback and timeSinceRoundEnd > 7.5 and lastGameEnd > 0 and not self.displayed then

			self:SetIsVisible(gameInfo and gameInfo.showEndStatsAuto and GetAdvancedOption("deathstats") > 1)
			self.displayed = true
		end
	end
end

function GUIGameEndStats:GetShouldUpdate()
	return true
end

function EndStats_SetEndStatsHeaderInfo(self, playerWon, playerDraw, playerTeamType)

	local playerIsMarine = playerTeamType == kMarineTeamType
	miscDataTable.team1Name = InsightUI_GetTeam1Name()
	miscDataTable.team2Name = InsightUI_GetTeam2Name()
	miscDataTable.winningTeam = 0

	if playerWon then
		miscDataTable.winningTeam = playerIsMarine and kMarineTeamType or kAlienTeamType
	elseif not playerDraw then
		miscDataTable.winningTeam = playerIsMarine and kAlienTeamType or kMarineTeamType
	end

	miscDataTable.roundDateString = FormatDateTimeString(Shared.GetSystemTime())
	miscDataTable.serverName = Client.GetServerIsHidden() and "Hidden" or Client.GetConnectedServerName()
	miscDataTable.mapName = Shared.GetMapName()

	lastGameEnd = Shared.GetTime()
end

local function CHUDSetPlayerStats(message)
	if message and message.playerName then
		table.insert(finalStatsTable, message)
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetGameData(message)
	if message and message.marineAcc then
		avgAccTable = {marineAcc = message.marineAcc, marineOnosAcc = message.marineOnosAcc, alienAcc = message.alienAcc}

		local minutes = math.floor(message.gameLengthMinutes)
		local seconds = (message.gameLengthMinutes % 1)*60

		miscDataTable.gameLengthMinutes = message.gameLengthMinutes
		miscDataTable.gameLength = string.format("%d:%.2d", minutes, seconds)
		miscDataTable.marineRTsBuilt = message.marineRTsBuilt
		miscDataTable.marineRTsLost = message.marineRTsLost
		miscDataTable.alienRTsBuilt = message.alienRTsBuilt
		miscDataTable.alienRTsLost = message.alienRTsLost
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetWeaponStats(message)
	local weaponName

	local wTechId = message.wTechId

	if wTechId > 1 and wTechId ~= kTechId.None then
		local techdataName = LookupTechData(wTechId, kTechDataMapName) or Locale.ResolveString(LookupTechData(wTechId, kTechDataDisplayName, ""))
		weaponName = Locale.ResolveString(string.upper(techdataName)) --techdataName:gsub("^%l", string.upper)
	else
		weaponName = "其他"
	end

	local cardEntry = {}
	cardEntry.text = weaponName
	cardEntry.teamNumber = message.teamNumber
	cardEntry.logoTexture = kInventoryIconsTexture
	cardEntry.logoCoords = { GetTexCoordsForTechId(wTechId) }
	cardEntry.logoSizeX = 64
	cardEntry.logoSizeY = 32
	cardEntry.message = message

	cardEntry.rows = {}

	local row = {}
	row.title = "击杀"
	row.value = printNum(message.kills)
	table.insert(cardEntry.rows, row)

	if message.accuracy > 0 then
		row = {}
		row.title = "精准度"
		row.value = printNum(message.accuracy) .. "%"
		table.insert(cardEntry.rows, row)

		if message.accuracyOnos > -1 then
			row = {}
			row.title = "精准度(不包括Onos)"
			row.value = printNum(message.accuracyOnos) .. "%"
			table.insert(cardEntry.rows, row)
		end
	end

	if message.pdmg > 0 then
		row = {}
		row.title = "玩家伤害"
		row.value = printNum(message.pdmg)
		table.insert(cardEntry.rows, row)
	end

	if message.sdmg > 0 then
		row = {}
		row.title = "建筑伤害"
		row.value = printNum(message.sdmg)
		table.insert(cardEntry.rows, row)
	end

	table.insert(cardsTable, cardEntry)

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetStatusStats(message)
	local kStatusString = {
		[kPlayerStatus.Dead]="阵亡",
		[kPlayerStatus.Commander]="指挥官",
		[kPlayerStatus.Exo]="机甲",
		[kPlayerStatus.GrenadeLauncher]="榴弹枪",
		[kPlayerStatus.Rifle]= "步枪",
		[kPlayerStatus.Shotgun]="霰弹枪",
		[kPlayerStatus.Flamethrower]="喷火器",
		[kPlayerStatus.Void]="其他",
		[kPlayerStatus.Spectator]="观察者",
		[kPlayerStatus.Embryo]="蛹",
		[kPlayerStatus.Skulk]="Skulk",
		[kPlayerStatus.Gorge]="Gorge",
		[kPlayerStatus.Lerk]="Lerk",
		[kPlayerStatus.Fade]="Fade",
		[kPlayerStatus.Onos]="Onos",
	}

	local entry = {}
	entry.className = kStatusString[message.statusId] or "未知"
	entry.timeMinutes = message.timeMinutes
	table.insert(statusSummaryTable, entry)

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetCommStats(message)
	if message.medpackAccuracy then
		if message.medpackResUsed + message.medpackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "治疗包"
			cardEntry.teamNumber = -1
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.MedPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 1

			cardEntry.rows = {}

			local row = {}
			row.title = "精准度"
			row.value = printNum(message.medpackAccuracy) .. "%"
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "治疗量"
			row.value = printNum(message.medpackRefill)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "治疗包耗费资源(被使用)"
			row.value = printNum(message.medpackResUsed)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "治疗包耗费资源(流失)"
			row.value = printNum(message.medpackResExpired)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "效率 (使用 / 流失)"
			row.value = printNum(message.medpackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)

			table.insert(cardsTable, cardEntry)
		end

		if message.ammopackResUsed + message.ammopackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "弹药包"
			cardEntry.teamNumber = -1
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.AmmoPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 2

			cardEntry.rows = {}

			local row = {}
			row.title = "弹药回复"
			row.value = printNum(message.ammopackRefill)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "治疗包耗费资源(被使用)"
			row.value = printNum(message.ammopackResUsed)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "治疗包耗费资源(流失)"
			row.value = printNum(message.ammopackResExpired)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "效率 (使用 / 流失)"
			row.value = printNum(message.ammopackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)

			table.insert(cardsTable, cardEntry)
		end

		if message.catpackResUsed + message.catpackResExpired > 0 then
			local cardEntry = {}
			cardEntry.text = "兴奋剂"
			cardEntry.teamNumber = -1
			cardEntry.logoTexture = "ui/buildmenu.dds"
			cardEntry.logoCoords = GetTextureCoordinatesForIcon(kTechId.CatPack)
			cardEntry.logoSizeX = 32
			cardEntry.logoSizeY = 32
			cardEntry.message = message
			cardEntry.order = 3

			cardEntry.rows = {}

			local row = {}
			row.title = "兴奋剂耗费资源(被使用)"
			row.value = printNum(message.catpackResUsed)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "兴奋剂耗费资源(流失)"
			row.value = printNum(message.catpackResExpired)
			table.insert(cardEntry.rows, row)

			row = {}
			row.title = "效率 (使用 / 流失)"
			row.value = printNum(message.catpackEfficiency) .. "%"
			table.insert(cardEntry.rows, row)

			table.insert(cardsTable, cardEntry)
		end
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetGlobalCommStats(message)
	if message and message.medpackAccuracy then
		commanderStats = message
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetHiveSkillGraph(message)
	if message and message.gameMinute then
		table.insert(hiveSkillGraphTable, message)
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetRTGraph(message)
	if message and message.gameMinute then
		table.insert(rtGraphTable, message)
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetKillGraph(message)
	if message and message.gameMinute then
		local entry = {}
		entry.teamNumber = message.killerTeamNumber
		entry.gameMinute = message.gameMinute
		table.insert(killGraphTable, entry)
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetBuildingSummary(message)
	if message and message.techId then
		local entry = {}
		entry.iconTexture = "ui/buildmenu.dds"
		entry.iconCoords = GetTextureCoordinatesForIcon(message.techId)
		entry.iconSizeX = 24
		entry.iconSizeY = 24
		entry.teamNumber = message.teamNumber
		entry.name = GetDisplayNameForTechId(message.techId)

		entry.techId = message.techId
		entry.lost = message.lost
		entry.built = message.built

		table.insert(buildingSummaryTable, entry)
	end

	lastStatsMsg = Shared.GetTime()
end

local function CHUDSetTechLog(message)
	if message and message.finishedMinute then
		local entry = {}
		entry.iconTexture = "ui/buildmenu.dds"
		entry.iconCoords = GetTextureCoordinatesForIcon(message.techId)
		entry.iconSizeX = 24
		entry.iconSizeY = 24
		entry.teamNumber = message.teamNumber
		entry.name = GetDisplayNameForTechId(message.techId)
		if message.built == false then
			entry.name = string.format(Locale.ResolveString("UNBUILT_STRUCTURE"), entry.name)
		end
		if message.recycled == true then
			local format_string = message.teamNumber == 2 and Locale.ResolveString("CONSUMED_STRUCTURE") or Locale.ResolveString("RECYCLED_STRUCTURE")
			entry.name = string.format(format_string, entry.name)
		end

		local minutes = math.floor(message.finishedMinute)
		local seconds = (message.finishedMinute % 1)*60

		entry.finishedMinute = message.finishedMinute
		entry.finishedTime = string.format("%d:%.2d", minutes, seconds)
		entry.activeRTs = message.activeRTs
		entry.teamRes = message.teamRes
		entry.destroyed = message.destroyed
		entry.built = message.built
		entry.recycled = message.recycled

		table.insert(techLogTable, entry)
	end

	lastStatsMsg = Shared.GetTime()
end

local function GetIsOnNeutralTeam()
	local player = Client.GetLocalPlayer()
	local teamNumber = player and player:GetTeamNumber()
	return teamNumber == kTeamReadyRoom or
			teamNumber == kSpectatorIndex
end

local function GetGameStarted()
	local gameInfo = GetGameInfoEntity()
	return gameInfo and gameInfo:GetGameStarted()
end

local lastDisplayStatus = false
local lastDown = 0
local kKeyTapTiming = 0.2
function GUIGameEndStats:SendKeyEvent(key, down)

	if GetIsBinding(key, "RequestMenu") and GetAdvancedOption("deathstats") > 0
			and (not GetGameStarted() or GetIsOnNeutralTeam())
			and not ChatUI_EnteringChatMessage() and not MainMenu_GetIsOpened()
			and self.prevRequestKey ~= down then

		self.prevRequestKey = down

		if down then
			lastDown = Shared.GetTime()

		-- Only show stats when the player hasn't selected something from the request menu first
		elseif not down then
			local isVisible = self:GetIsVisible()
			if isVisible then
				self:SetIsVisible(false)
			elseif lastDown + kKeyTapTiming > Shared.GetTime() then
				self:SetIsVisible(true)
			end
		end
	end

	if self:GetIsVisible() then
		if key == InputKey.Escape and down then
			self:SetIsVisible(false)
			return true
		elseif key == InputKey.MouseButton0 and down then
			local mouseX, mouseY = Client.GetCursorPosScreen()

			if GUIItemContainsPoint(self.closeButton, mouseX, mouseY) then
				StartSoundEffect(kButtonClickSound)
				self:SetIsVisible(false)
				return true
			end

			if self.lastRow and not self.hoverMenu.background:GetIsVisible() then
				local function openSteamProf()
					Client.ShowWebpage(string.format("%s[U:1:%s]", kSteamProfileURL, self.lastRow.steamId))
				end

				local function openObservatoryProf()
					Client.ShowWebpage(string.format("%s%s", kObservatoryUserURL, self.lastRow.steamId))
				end

				self.hoverMenu:ResetButtons()

				local textColor = Color(1, 1, 1, 1)
				local nameBgColor = Color(0, 0, 0, 0)
				local teamColorHighlight = self.lastRow.background:GetParent():GetColor() * 0.25
				teamColorHighlight.a = 1
				local teamColorBg = self.lastRow.background:GetParent():GetColor() * 0.5
				teamColorBg.a = 1
				local bgColor = self.lastRow.background:GetParent():GetColor() * 0.75
				bgColor.a = 0.9

				self.hoverMenu:SetBackgroundColor(bgColor)
				local name = self.lastRow.playerName:GetText()

				-- Todo: Add skill tier icon
				if self.lastRow.hiveSkillTier then
					name = string.format("[%s] %s", self.lastRow.hiveSkillTier, name)
				end

				self.hoverMenu:AddButton(name, nameBgColor, nameBgColor, textColor)
				self.hoverMenu:AddButton(Locale.ResolveString("SB_MENU_STEAM_PROFILE"), teamColorBg, teamColorHighlight, textColor, openSteamProf)
				self.hoverMenu:AddButton("Observatory profile", teamColorBg, teamColorHighlight, textColor, openObservatoryProf)

				StartSoundEffect(kButtonClickSound)
				self.hoverMenu:Show()

				return true
			elseif self.lastRow and self.hoverMenu.background:GetIsVisible() and not GUIItemContainsPoint(self.hoverMenu.background, mouseX, mouseY) then
				self.hoverMenu:Hide()
			end

			if highlightedField ~= nil then
				if highlightedFieldMarine then
					if lastSortedT1 == highlightedField then
						lastSortedT1WasInv = not lastSortedT1WasInv
					else
						lastSortedT1WasInv = false
						lastSortedT1 = highlightedField
					end
				else
					if lastSortedT2 == highlightedField then
						lastSortedT2WasInv = not lastSortedT2WasInv
					else
						lastSortedT2WasInv = false
						lastSortedT2 = highlightedField
					end
				end

				StartSoundEffect(kButtonClickSound)
				SortByColumn(self, highlightedFieldMarine, highlightedField, highlightedFieldMarine and lastSortedT1WasInv or lastSortedT2WasInv)
				return true
			end
		end
	end

	if GetIsBinding(key, "Scoreboard") and self.prevScoreKey ~= down then
		self.prevScoreKey = down
		if down then
			lastDisplayStatus = self:GetIsVisible()
			if lastDisplayStatus then
				self:SetIsVisible(false)
			end
		elseif lastDisplayStatus and not self:GetIsVisible() then
			self:SetIsVisible(lastDisplayStatus)
		end
	end

	if self.sliderBarBg:GetIsVisible() and not self.hoverMenu.background:GetIsVisible() then
		local maxPos = self.contentSize - kContentMaxYSize
		if key == InputKey.MouseButton0 and self.mousePressed ~= down then
			self.mousePressed = down
			if down then
				local mouseX, mouseY = Client.GetCursorPosScreen()
				self.isDragging = GUIItemContainsPoint(self.sliderBarBg, mouseX, mouseY) or GUIItemContainsPoint(self.slider, mouseX, mouseY)
				return true
			end
		elseif key == InputKey.MouseWheelDown then
			self.slideOffset = math.min(self.slideOffset + GUILinearScale(75), maxPos)
			return true
		elseif key == InputKey.MouseWheelUp then
			self.slideOffset = math.max(self.slideOffset - GUILinearScale(75), 0)
			return true
		elseif key == InputKey.PageDown and down then
			self.slideOffset = math.min(self.slideOffset + kContentMaxYSize/2, maxPos)
			return true
		elseif key == InputKey.PageUp and down then
			self.slideOffset = math.max(self.slideOffset - kContentMaxYSize/2, 0)
			return true
		elseif key == InputKey.Home then
			self.slideOffset = 0
			return true
		elseif key == InputKey.End then
			self.slideOffset = maxPos
			return true
		end
	end

	return false
end

function GUIGameEndStats:OnResolutionChanged(oldX, oldY, newX, newY)
	-- Mark the last round as not loaded so it loads it back when we destroy the current UI
	loadedLastRound = false

	-- We need to trigger this manually to update font sizes
	self.hiveSkillGraph:OnResolutionChanged(oldX, oldY, newX, newY)
	self.rtGraph:OnResolutionChanged(oldX, oldY, newX, newY)
	self.builtRTsComp:OnResolutionChanged(oldX, oldY, newX, newY)
	self.lostRTsComp:OnResolutionChanged(oldX, oldY, newX, newY)

	self:Uninitialize()
	self:Initialize()
end

local oldGetCanDisplayReqMenu = PlayerUI_GetCanDisplayRequestMenu
function PlayerUI_GetCanDisplayRequestMenu()
	return oldGetCanDisplayReqMenu() and not EndStatsVisible and lastDown+kKeyTapTiming < Shared.GetTime()
end

-- Add the missing icons so they display correctly
-- We have to call the function first so it creates the array
GetTexCoordsForTechId(kTechId.None)

gTechIdPosition[kTechId.Sentry] = kDeathMessageIcon.Sentry
gTechIdPosition[kTechId.ARC] = kDeathMessageIcon.ARC
gTechIdPosition[kTechId.Whip] = kDeathMessageIcon.Whip
gTechIdPosition[kTechId.Babbler] = kDeathMessageIcon.Babbler
gTechIdPosition[kTechId.Hydra] = kDeathMessageIcon.HydraSpike
gTechIdPosition[kTechId.Minigun] = kDeathMessageIcon.Minigun
gTechIdPosition[kTechId.Claw] = kDeathMessageIcon.Claw
gTechIdPosition[kTechId.Railgun] = kDeathMessageIcon.Railgun

Client.HookNetworkMessage("PlayerStats", CHUDSetPlayerStats)
Client.HookNetworkMessage("GameData", CHUDSetGameData)
Client.HookNetworkMessage("EndStatsWeapon", CHUDSetWeaponStats)
Client.HookNetworkMessage("EndStatsStatus", CHUDSetStatusStats)
Client.HookNetworkMessage("MarineCommStats", CHUDSetCommStats)
Client.HookNetworkMessage("GlobalCommStats", CHUDSetGlobalCommStats)
Client.HookNetworkMessage("HiveSkillGraph", CHUDSetHiveSkillGraph)
Client.HookNetworkMessage("RTGraph", CHUDSetRTGraph)
Client.HookNetworkMessage("KillGraph", CHUDSetKillGraph)
Client.HookNetworkMessage("TechLog", CHUDSetTechLog)
Client.HookNetworkMessage("BuildingSummary", CHUDSetBuildingSummary)
