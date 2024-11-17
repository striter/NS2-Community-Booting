-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIInsight_PlayerFrames.lua
--
-- Created by: Jon 'Huze' Hughes (jon@jhuze.com)
--
-- Spectator: Displays player info
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_PlayerFrames' (GUIScript)

local isVisible

local kNameFontName = Fonts.kInsight
local kInfoFontName = Fonts.kInsight
local kMarineTexture = "ui/marine_sheet.dds"
local kAlienTexture = "ui/alien_sheet.dds"
local kBackgroundTexture = "ui/player.dds"
local kFrameTexture = "ui/players.dds"
local kHealthbarTexture = "ui/player_healthbar.dds"

-- Also change in OnResolutionChanged!
local scale = 0.55
local kHealthBarSize
local kFrameYOffset
local kFrameYSpacing
local kNameFontScale
local kInfoFontScale
local kPlayersPanelSize
local kTopFrameSize
local kBottomFrameSize
local kIconSize

-- Color constants.
local kInfoColor = Color(1, 1, 1, 1)
local kDeadColor = Color(1, 0, 0, 1)
local kCommanderColor = Color(1, 0.8, 0.1, 1)

-- Texture coordinates.
local leftBackgroundCoords = {0,0,256,92}
local leftFrameCoords = {0,92,256,184}
local leftGradientCoords = {0,184,256,276}
local leftTopCoords = {0,0,256,64}
local leftBottomCoords = {0,128,256,256}

local rightBackgroundCoords = {256,0,0,92}
local rightFrameCoords = {256,92,0,184}
local rightGradientCoords = {256,184,0,276}
local rightTopCoords = {256,0,512,64}
local rightBottomCoords = {256,128,512,256}

local keysDisableAutoFollow = { "Weapon1", "Weapon2", "Weapon3", "Jump", "MoveForward", "MoveLeft", "MoveBackward", "MoveRight"}

local iconSize = Vector(32,32,0)
local kIconCoords = {

    [Locale.ResolveString("STATUS_RIFLE")] =             {            0, 0,   iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_SHOTGUN")] =           {   iconSize.x, 0, 2*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_GRENADE_LAUNCHER")] =  { 2*iconSize.x, 0, 3*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_FLAMETHROWER")] =      { 3*iconSize.x, 0, 4*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_EXO")] =               { 0, iconSize.y,   iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_HMG")] =               { 0, 2*iconSize.y, iconSize.x, 3*iconSize.y },

    [Locale.ResolveString("STATUS_SKULK")] =             {            0, 0,   iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_GORGE")] =             {   iconSize.x, 0, 2*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_LERK")] =              { 2*iconSize.x, 0, 3*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_FADE")] =              { 3*iconSize.x, 0, 4*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_ONOS")] =              {            0, iconSize.y,   iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_EVOLVING")] =          {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_EMBRYO")] =            {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("SKULK_EGG")] =                {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("GORGE_EGG")] =                {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("LERK_EGG")] =                 {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("FADE_EGG")] =                 {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("ONOS_EGG")] =                 {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },

    [Locale.ResolveString("STATUS_COMMANDER")] =         { 2*iconSize.x, iconSize.y, 3*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_DEAD")] =              { 3*iconSize.x, iconSize.y, 4*iconSize.x, 2*iconSize.y }

}

function GUIInsight_PlayerFrames:Initialize()

    kHealthBarSize = GUIScale(Vector(14, 30, 0))
    kFrameYOffset = GUIScale(180)
    kFrameYSpacing = GUIScale(20)
    kNameFontScale = GUIScale( Vector(1, 1, 1) ) * 0.8
    kInfoFontScale = GUIScale( Vector(1, 1, 1) ) * 0.7
    kPlayersPanelSize = GUIScale(Vector(95, 32, 0))
    kTopFrameSize = GUIScale(Vector(scale*256, scale*64, 0))
    kBottomFrameSize = GUIScale(Vector(scale*256, scale*128, 0))
    kIconSize = GUIScale(Vector(32, 32, 0))

    isVisible = true

    -- Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    self.teams = {
        -- Blue team.
        [kTeam1Index] = {
            Background    = self:CreateBackground( kTeam1Index ),
            Color         = kBlueColor,
            TechColors    = {},
            PlayerList    = {},
            GetScores     = ScoreboardUI_GetBlueScores,
            TeamNumber    = kTeam1Index
        },
        -- Red team.
        [kTeam2Index] = {
            Background    = self:CreateBackground( kTeam2Index ),
            Color         = kRedColor,
            TechColors    = {},
            PlayerList    = {},
            GetScores     = ScoreboardUI_GetRedScores,
            TeamNumber    = kTeam2Index
        }
    }

    self:ReloadGUIVoiceChat()
end

function GUIInsight_PlayerFrames:ReloadGUIVoiceChat()
    -- Reload GUIVoiceChat so it applies offset to not overlap with playerframes
    local guiVoiceChat = ClientUI.GetScript("GUIVoiceChat")
    if guiVoiceChat then
        guiVoiceChat:Reload()
    end
end

function GUIInsight_PlayerFrames:Uninitialize()

    for _, team in ipairs(self.teams) do
        GUI.DestroyItem(team.Background)
    end
    self.teams = {}

    self:ReloadGUIVoiceChat()
end

function GUIInsight_PlayerFrames:OnResolutionChanged()

    self:Uninitialize()
    kHealthBarSize = GUIScale(Vector(14, 30, 0))
    kFrameYOffset = GUIScale(180)
    kFrameYSpacing = GUIScale(20)
    kNameFontScale = GUIScale( Vector(1, 1, 1) ) * 0.8
    kInfoFontScale = GUIScale( Vector(1, 1, 1) ) * 0.7
    kPlayersPanelSize = GUIScale(Vector(95, 32, 0))
    kTopFrameSize = GUIScale(Vector(scale*256, scale*64, 0))
    kBottomFrameSize = GUIScale(Vector(scale*256, scale*128, 0))
    kIconSize = GUIScale(Vector(32, 32, 0))
    self:Initialize()

end


function GUIInsight_PlayerFrames:CreateBackground(teamNumber)

    -- Player
    local playersBackground = GUIManager:CreateGraphicItem()
    local top = GUIManager:CreateGraphicItem()
    local bottom = GUIManager:CreateGraphicItem()

    if teamNumber == kTeam1Index then
        playersBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
        playersBackground:SetPosition(Vector(0, kFrameYOffset, 0))
        playersBackground:SetColor(kBlueColor)

        top:SetTexturePixelCoordinates(GUIUnpackCoords(leftTopCoords))
        top:SetAnchor(GUIItem.Left, GUIItem.Top)
        top:SetPosition(-Vector(0, kTopFrameSize.y,0))

        bottom:SetTexturePixelCoordinates(GUIUnpackCoords(leftBottomCoords))
        bottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)

        playersBackground:SetTexturePixelCoordinates(GUIUnpackCoords(leftGradientCoords))
    elseif teamNumber == kTeam2Index then
        playersBackground:SetAnchor(GUIItem.Right, GUIItem.Top)
        playersBackground:SetPosition(Vector(-kPlayersPanelSize.x, kFrameYOffset, 0))
        playersBackground:SetColor(kRedColor)

        top:SetTexturePixelCoordinates(GUIUnpackCoords(rightTopCoords))
        top:SetAnchor(GUIItem.Right, GUIItem.Top)
        top:SetPosition(-Vector(kTopFrameSize.x, kTopFrameSize.y,0))

        bottom:SetTexturePixelCoordinates(GUIUnpackCoords(rightBottomCoords))
        bottom:SetAnchor(GUIItem.Right, GUIItem.Bottom)
        bottom:SetPosition(-Vector(kBottomFrameSize.x,0,0))

        playersBackground:SetTexturePixelCoordinates(GUIUnpackCoords(rightGradientCoords))
    end

    top:SetSize(kTopFrameSize)
    top:SetTexture(kFrameTexture)
    top:SetLayer(kGUILayerInsight+1)
    playersBackground:AddChild(top)

    bottom:SetSize(kBottomFrameSize)
    bottom:SetTexture(kFrameTexture)
    bottom:SetLayer(kGUILayerInsight+1)
    playersBackground:AddChild(bottom)

    playersBackground:SetTexture(kBackgroundTexture)
    playersBackground:SetColor(Color(0,0,0,1))
    playersBackground:SetLayer(kGUILayerInsight)

    return playersBackground
end

function GUIInsight_PlayerFrames:SetIsVisible(bool)

    isVisible = bool

    for _, team in ipairs(self.teams) do
        team.Background:SetIsVisible(bool)
    end

end

function GUIInsight_PlayerFrames:Update()

    PROFILE("GUIInsight_PlayerFrames:Update")

    if isVisible then

        --Update Teams and Tech Points
        for _, team in ipairs(self.teams) do
            self:UpdatePlayers(team)
        end

    end

end

-------------
-- PLAYERS --
-------------

--Sort by entity ID (clientIndex)
function GUIInsight_PlayerFrames:Players_Sort(team)

    local function sortById(player1, player2)
        return player1.ClientIndex > player2.ClientIndex
    end

    -- Sort it by entity id
    table.sort(team, sortById)

end

local kRed = Color(1, 0, 0, 1)
function GUIInsight_PlayerFrames:UpdateTechColors(team)
    local teamNumber = team.TeamNumber
    local teamColor = PlayerUI_GetTeamColor(teamNumber)
    team.TechColors = {
        [0] = teamColor,
        [kTechId.CragHive] = GetShellLevel(teamNumber) == 0 and kRed or teamColor ,
        [kTechId.ShiftHive] = GetSpurLevel(teamNumber) == 0 and kRed or teamColor,
        [kTechId.ShadeHive] = GetVeilLevel(teamNumber) == 0 and kRed or teamColor
    }
end

function GUIInsight_PlayerFrames:UpdatePlayers(updateTeam)

    local teamScores = updateTeam["GetScores"]()

    -- How many items per player.
    local numPlayers = #teamScores
    local playersGUIItem = updateTeam.Background

    -- Draw if there are players
    if numPlayers > 0 then
        local playerList = updateTeam["PlayerList"]
        playersGUIItem:SetIsVisible(true)

        -- Resize the player list if it doesn't match.
        if #playerList ~= numPlayers then

            while #playerList > numPlayers do
                local removeItem = playerList[1]
                playersGUIItem:RemoveChild(removeItem.Background)
                GUI.DestroyItem(removeItem.Background)
                table.remove(playerList,1)
            end

            while #playerList < numPlayers do
                local team = updateTeam.TeamNumber
                local newItem
                if team == kTeam1Index then
                    newItem = self:CreateMarineBackground()
                else
                    newItem = self:CreateAlienBackground()
                end
                playersGUIItem:AddChild(newItem.Background)
                table.insert(playerList, newItem)
            end
            -- Make sure there is enough room for all players on this GUI.
            playersGUIItem:SetSize(Vector(kPlayersPanelSize.x, (kPlayersPanelSize.y + kFrameYSpacing)* numPlayers, 0))
        end

        -- Sort by entity Id so players always remain in the same order
        self:Players_Sort(teamScores) -- kind of hacky, but gets the job done

        self:UpdateTechColors(updateTeam)

        local cursor = MouseTracker_GetCursorPos()
        local inside, _, posY = GUIItemContainsPoint( updateTeam.Background, cursor.x, cursor.y )
        updateTeam.mouseOverIndex = inside and math.floor( posY / (kPlayersPanelSize.y + kFrameYSpacing) ) + 1 or 0 -- is 0 when mouse is outside^^

        local currentY = kFrameYSpacing
        for i, player in ipairs(playerList) do
            local playerRecord = teamScores[i]

            self:UpdatePlayer(player, playerRecord, updateTeam, currentY, i == updateTeam.mouseOverIndex)

            currentY = currentY + kPlayersPanelSize.y + kFrameYSpacing
        end
    else
        updateTeam.mouseOverIndex = 0
        playersGUIItem:SetIsVisible(false)
    end

end

function GUIInsight_PlayerFrames:UpdatePlayer(player, playerRecord, team, yPosition, isMouseOver)

    local playerName = playerRecord.Name
    local isCommander = playerRecord.IsCommander

    player.EntityId = playerRecord.EntityId

    if player.EntityId == Client.GetLocalPlayer().followId then
        player.Frame:SetColor(Color(1,1,0,1))
    else
        player.Frame:SetColor(Color(1,1,1,1))
    end

    local resourcesStr = string.format("%d Res", playerRecord.Resources)
    local KDRStr = string.format("%s / %s", playerRecord.Kills, playerRecord.Deaths)
    local currentPosition = Vector(player["Background"]:GetPosition())
    local newStatus = playerRecord.Status
    local teamNumber = team["TeamNumber"]
    local teamColor = team["Color"]

    currentPosition.y = yPosition
    player["Background"]:SetPosition(currentPosition)
    player["Detail"]:SetText(resourcesStr)
    player.KDR:SetText(KDRStr)
    player["Background"]:SetColor(teamColor)
    -- Name
    local name = player["Name"]
    name:SetText(playerName)
    name:SetColor(kWhite)

    -- Health bar
    local healthBar = player["HealthBar"]
    local barSize = 0
    if newStatus == Locale.ResolveString("STATUS_DEAD") then

        player["Background"]:SetColor(kDeadColor)
        healthBar:SetIsVisible(false)

    elseif isCommander then

        player["Background"]:SetColor(kCommanderColor)
        healthBar:SetIsVisible(false)

    else

        if playerRecord.Health then
            local health = playerRecord.Health + playerRecord.Armor * kHealthPointsPerArmor
            local maxHealth = playerRecord.MaxHealth + playerRecord.MaxArmor * kHealthPointsPerArmor
            local healthFraction = health/maxHealth

            barSize = math.max(healthFraction * kHealthBarSize.y, 0)
            local barColor
            if healthFraction > 0.6 then
                local redFraction = 1 - ((healthFraction - 0.6) / 0.4)
                barColor = Color(redFraction, 1, 0, 1)
            elseif healthFraction > 0.1 then
                local greenFraction = ((healthFraction - 0.1) / 0.5)
                barColor = Color(1, greenFraction, 0, 1)
            else
                barColor = Color(1, 0, 0, 1)
            end
            healthBar:SetColor(barColor)
            healthBar:SetSize(Vector(kHealthBarSize.x, -barSize, 0))
            healthBar:SetIsVisible(true)

            if isMouseOver and gBotDebugWindow == nil then
                local hpText = string.format("%s / %s", playerRecord.Health, playerRecord.Armor)
                player["Detail"]:SetText(hpText)
            end

        else
            healthBar:SetIsVisible(false)
        end

    end

    if playerRecord.Tech then
        local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)

        -- Parasite should be in the last position of the array if it exists
        -- If it does, make player name yellow and remove it from the table
        if currentTech[#currentTech] == kTechId.Parasite then
            name:SetColor(kCommanderColorFloat)
            table.remove(currentTech, #currentTech)
        end

        for i = 1, 3 do
            if #currentTech >= i then
                player["Upgrades"][i]:SetTexture("ui/buildmenu.dds")
                player["Upgrades"][i]:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(tonumber(currentTech[i]))))
                player["Upgrades"][i]:SetColor(team.TechColors[LookupTechData(tonumber(currentTech[i]), kTechDataCategory, 0)] or team.TechColors[0])
            else
                player["Upgrades"][i]:SetTexture("ui/transparent.dds")
            end
        end
    end

    if newStatus ~= player.status then

        local oldStatus = player.status
        -- Alerts for Lerk, Fade, Onos, Exo deaths
        if newStatus == Locale.ResolveString("STATUS_DEAD") then

            if player.Name:GetText() == playerName then

                local texture, textureCoordinates
                if oldStatus == Locale.ResolveString("STATUS_LERK") then
                    texture = "ui/Lerk.dds"
                    textureCoordinates = {0, 0, 284, 253}
                elseif oldStatus == Locale.ResolveString("LERK_EGG") then
                    texture = "ui/Lerk.dds"
                    textureCoordinates = {0, 0, 284, 253}
                elseif oldStatus == Locale.ResolveString("STATUS_FADE") then
                    texture = "ui/Fade.dds"
                    textureCoordinates = {0, 0, 188, 220}
                elseif oldStatus == Locale.ResolveString("FADE_EGG") then
                    texture = "ui/Fade.dds"
                    textureCoordinates = {0, 0, 188, 220}
                elseif oldStatus == Locale.ResolveString("STATUS_ONOS") then
                    texture = "ui/Onos.dds"
                    textureCoordinates = {0, 0, 304, 326}
                elseif oldStatus == Locale.ResolveString("ONOS_EGG") then
                    texture = "ui/Onos.dds"
                    textureCoordinates = {0, 0, 304, 326}
                elseif oldStatus == Locale.ResolveString("STATUS_EXO") then
                    texture = "ui/marine_buy_bigIcons.dds"
                    textureCoordinates = {47, 2093, 47+316, 2093+316}
                end

                if texture ~= nil then

                    local position = player["Background"]:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                    local text = string.format("%s %s %s", oldStatus, playerName,Locale.ResolveString("STATUS_DEAD"))
                    local icon = {Texture = texture, TextureCoordinates = textureCoordinates, Color = Color(1,1,1,0.25), Size = Vector(0,0,0)}
                    local info = {Text = text, Scale = Vector(1,1,1), Color = Color(0.5,0.5,0.5,0.5), ShadowColor = Color(0,0,0,0.5)}
                    local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, teamNumber)
                    GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), Color(1,1,1,1))

                end

            end

        end

        local coords = kIconCoords[newStatus]
        if coords then
            player["Type"]:SetIsVisible(true)
            player["Type"]:SetTexturePixelCoordinates(coords[1], coords[2], coords[3], coords[4])
        else
            player["Type"]:SetIsVisible(false)
        end
        player.status = newStatus

    end

end

function GUIInsight_PlayerFrames:SendKeyEvent( key, down )

    if gBotDebugWindow ~= nil then return false end

    -- Clear the autofollow entity id when we switch modes
    local player = Client.GetLocalPlayer()

    for _, curKey in ipairs(keysDisableAutoFollow) do
        if GetIsBinding(key, curKey) and down then
            player.followId = Entity.invalidId
            return false
        end
    end

    if isVisible and key == InputKey.MouseButton0 and down then

        for _, team in ipairs(self.teams) do

            if team.mouseOverIndex > 0 then
                local entityId = team.PlayerList[team.mouseOverIndex].EntityId

                -- When clicking the same player, deselect so it stops following
                if player.followId == entityId then
                    entityId = Entity.invalidId
                end

                player.followId = entityId
                Client.SendNetworkMessage("SpectatePlayer", {entityId = player.followId}, true)

                return true
            end
        end

    end

    return false

end

------------------
-- GUI CREATION --
------------------

function GUIInsight_PlayerFrames:CreateMarineBackground()

    -- Create background.
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kPlayersPanelSize)
    background:SetAnchor(GUIItem.Left, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(GUIUnpackCoords(leftBackgroundCoords))

    -- Type icon item (Weapon/Class/CommandStructure)
    local typeIcon = GUIManager:CreateGraphicItem()
    typeIcon:SetSize(kIconSize)
    typeIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    typeIcon:SetPosition(Vector(kHealthBarSize.x, 0, 0))
    typeIcon:SetTexture(kMarineTexture)
    typeIcon:SetColor(Color(1, 1, 1, .8))
    background:AddChild(typeIcon)

    -- Name text item. (Player Name / Structure Location)
    local nameItem = GUIManager:CreateTextItem()
    nameItem:SetFontName(kNameFontName)
    nameItem:SetScale(kNameFontScale)
    nameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    nameItem:SetTextAlignmentX(GUIItem.Align_Min)
    nameItem:SetTextAlignmentY(GUIItem.Align_Max)
    nameItem:SetColor(kInfoColor)
    GUIMakeFontScale(nameItem)
    background:AddChild(nameItem)

    -- KDR text item.
    local KDRitem = GUIManager:CreateTextItem()
    KDRitem:SetFontName(kInfoFontName)
    KDRitem:SetScale(kInfoFontScale)
    KDRitem:SetAnchor(GUIItem.Left, GUIItem.Top)
    KDRitem:SetTextAlignmentX(GUIItem.Align_Max)
    KDRitem:SetTextAlignmentY(GUIItem.Align_Min)
    KDRitem:SetPosition(Vector(kPlayersPanelSize.x, 0, 0))
    KDRitem:SetColor(kInfoColor)
    GUIMakeFontScale(KDRitem)
    background:AddChild(KDRitem)

    -- Res text item.
    local detailItem = GUIManager:CreateTextItem()
    detailItem:SetFontName(kInfoFontName)
    detailItem:SetScale(kInfoFontScale)
    detailItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    detailItem:SetTextAlignmentX(GUIItem.Align_Max)
    detailItem:SetTextAlignmentY(GUIItem.Align_Min)
    detailItem:SetPosition(Vector(kPlayersPanelSize.x, 0, 0))
    detailItem:SetColor(kInfoColor)
    GUIMakeFontScale(detailItem)
    background:AddChild(detailItem)

    -- Health bar item.
    local healthBar = GUIManager:CreateGraphicItem()
    healthBar:SetSize(kHealthBarSize)
    healthBar:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    healthBar:SetColor(Color(1,1,1,1))
    healthBar:SetTexture(kHealthbarTexture)
    healthBar:SetTexturePixelCoordinates(GUIUnpackCoords({0,64,32,0}))
    background:AddChild(healthBar)

    -- 3 Upgrade slots
    local upgrades = { }
    local pos = 0

    for i = 1, 3 do
        upgrades[i] = GUIManager:CreateGraphicItem()
        upgrades[i]:SetSize(GUIScale(Vector(48, 48, 0)))
        upgrades[i]:SetAnchor(GUIItem.Right, GUIItem.Top)
        upgrades[i]:SetTexture("ui/transparent.dds")
        upgrades[i]:SetTexturePixelCoordinates(GUIUnpackCoords({0,0,256,92}))
        upgrades[i]:SetPosition(GUIScale(Vector(pos, -8, 0)))
        pos = pos + 40
        background:AddChild(upgrades[i])
    end

    local frame = GUIManager:CreateGraphicItem()
    frame:SetSize(kPlayersPanelSize)
    frame:SetAnchor(GUIItem.Left, GUIItem.Top)
    frame:SetTexture(kBackgroundTexture)
    frame:SetTexturePixelCoordinates(GUIUnpackCoords(leftFrameCoords))
    background:AddChild(frame)

    return { Background = background, Frame = frame, Name = nameItem, Type = typeIcon, Detail = detailItem, KDR = KDRitem, HealthBar = healthBar, Upgrades = upgrades }

end

function GUIInsight_PlayerFrames:CreateAlienBackground()

    -- Create background.
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kPlayersPanelSize)
    background:SetAnchor(GUIItem.Left, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(GUIUnpackCoords(rightBackgroundCoords))

    -- Type icon item (Weapon/Class/CommandStructure)
    local typeIcon = GUIManager:CreateGraphicItem()
    typeIcon:SetSize(kIconSize)
    typeIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    typeIcon:SetPosition(Vector(-kHealthBarSize.x - kIconSize.x, 0, 0))
    typeIcon:SetTexture(kAlienTexture)
    typeIcon:SetColor(Color(1, 1, 1, .8))
    background:AddChild(typeIcon)

    -- Name text item. (Player Name / Structure Location)
    local nameItem = GUIManager:CreateTextItem()
    nameItem:SetFontName(kNameFontName)
    nameItem:SetScale(kNameFontScale)
    nameItem:SetAnchor(GUIItem.Right, GUIItem.Top)
    nameItem:SetTextAlignmentX(GUIItem.Align_Max)
    nameItem:SetTextAlignmentY(GUIItem.Align_Max)
    nameItem:SetColor(kInfoColor)
    GUIMakeFontScale(nameItem)
    background:AddChild(nameItem)

    -- KDR text item.
    local KDRitem = GUIManager:CreateTextItem()
    KDRitem:SetFontName(kInfoFontName)
    KDRitem:SetScale(kInfoFontScale)
    KDRitem:SetAnchor(GUIItem.Left, GUIItem.Top)
    KDRitem:SetPosition(Vector(GUIScale(2), 0, 0))
    KDRitem:SetTextAlignmentX(GUIItem.Align_Min)
    KDRitem:SetTextAlignmentY(GUIItem.Align_Min)
    KDRitem:SetColor(kInfoColor)
    GUIMakeFontScale(KDRitem)
    background:AddChild(KDRitem)

    -- Res text item.
    local detailItem = GUIManager:CreateTextItem()
    detailItem:SetFontName(kInfoFontName)
    detailItem:SetScale(kInfoFontScale)
    detailItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    detailItem:SetPosition(Vector(GUIScale(2), 0, 0))
    detailItem:SetTextAlignmentX(GUIItem.Align_Min)
    detailItem:SetTextAlignmentY(GUIItem.Align_Min)
    detailItem:SetColor(kInfoColor)
    GUIMakeFontScale(detailItem)
    background:AddChild(detailItem)

    -- Health bar item.
    local healthBar = GUIManager:CreateGraphicItem()
    healthBar:SetSize(kHealthBarSize)
    healthBar:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    healthBar:SetPosition(Vector(-kHealthBarSize.x, 0, 0))
    healthBar:SetColor(Color(1,1,1,1))
    healthBar:SetTexture(kHealthbarTexture)
    healthBar:SetTexturePixelCoordinates(GUIUnpackCoords({32,64,0,0}))
    background:AddChild(healthBar)

    -- 3 Upgrade slots
    local upgrades = { }
    local pos = -144

    for i = 1, 3 do
        upgrades[i] = GUIManager:CreateGraphicItem()
        upgrades[i]:SetSize(GUIScale(Vector(48, 48, 0)))
        upgrades[i]:SetAnchor(GUIItem.Right, GUIItem.Top)
        upgrades[i]:SetTexture("ui/transparent.dds")
        upgrades[i]:SetTexturePixelCoordinates(GUIUnpackCoords({0,0,256,92}))
        upgrades[i]:SetPosition(GUIScale(Vector(pos, -8, 0)))
        pos = pos - 40
        background:AddChild(upgrades[i])
    end

    local frame = GUIManager:CreateGraphicItem()
    frame:SetSize(kPlayersPanelSize)
    frame:SetAnchor(GUIItem.Left, GUIItem.Top)
    frame:SetTexture(kBackgroundTexture)
    frame:SetTexturePixelCoordinates(GUIUnpackCoords(rightFrameCoords))
    background:AddChild(frame)

    return { Background = background, Frame = frame, Name = nameItem, Type = typeIcon, Detail = detailItem, KDR = KDRitem, HealthBar = healthBar, Upgrades = upgrades }

end