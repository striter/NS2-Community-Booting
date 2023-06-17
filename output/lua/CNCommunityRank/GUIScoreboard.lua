-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIScoreboard.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages the player scoreboard (scores, pings, etc).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/SpecialSkillTierRecipients.lua")

class 'GUIScoreboard' (GUIScript)

-- Horizontal size for the game time background is irrelevant as it will be expanded to SB width
GUIScoreboard.kGameTimeBackgroundSize = Vector(640, GUIScale(32), 0)
GUIScoreboard.kClickForMouseBackgroundSize = Vector(GUIScale(200), GUIScale(32), 0)
GUIScoreboard.kClickForMouseText = Locale.ResolveString("SB_CLICK_FOR_MOUSE")

GUIScoreboard.kFavoriteIconSize = Vector(26, 26, 0)
GUIScoreboard.kFavoriteTexture = PrecacheAsset("ui/menu/favorite.dds")
GUIScoreboard.kNotFavoriteTexture = PrecacheAsset("ui/menu/nonfavorite.dds")

GUIScoreboard.kBlockedIconSize = Vector(26, 26, 0)
GUIScoreboard.kBlockedTexture = PrecacheAsset("ui/menu/blocked.dds")
GUIScoreboard.kNotBlockedTexture = PrecacheAsset("ui/menu/notblocked.dds")

GUIScoreboard.kSlidebarSize = Vector(7.5, 25, 0)
GUIScoreboard.kBgColor = Color(0, 0, 0, 0.5)
GUIScoreboard.kBgMaxYSpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)

local kIconSize = Vector(40, 40, 0)
local kIconOffset = Vector(-15, -10, 0)

-- Shared constants.
GUIScoreboard.kTeamInfoFontName      = Fonts.kArial_15
GUIScoreboard.kPlayerStatsFontName   = Fonts.kArial_15
GUIScoreboard.kTeamNameFontName      = Fonts.kArial_17
GUIScoreboard.kGameTimeFontName      = Fonts.kArial_17
GUIScoreboard.kClickForMouseFontName = Fonts.kArial_17

GUIScoreboard.kLowPingThreshold = 100
GUIScoreboard.kLowPingColor = Color(0, 1, 0, 1)
GUIScoreboard.kMedPingThreshold = 249
GUIScoreboard.kMedPingColor = Color(1, 1, 0, 1)
GUIScoreboard.kHighPingThreshold = 499
GUIScoreboard.kHighPingColor = Color(1, 0.5, 0, 1)
GUIScoreboard.kInsanePingColor = Color(1, 0, 0, 1)
GUIScoreboard.kVoiceMuteColor = Color(1, 1, 1, 1)
GUIScoreboard.kVoiceDefaultColor = Color(1, 1, 1, 0.5)
GUIScoreboard.kHighPresThreshold = 75
GUIScoreboard.kHighPresColor = Color(1, 1, 0, 1)
GUIScoreboard.kVeryHighPresThreshold = 90
GUIScoreboard.kVeryHighPresColor = Color(1, 0.5, 0, 1)

-- Team constants.
GUIScoreboard.kTeamBackgroundYOffset = 50
GUIScoreboard.kTeamNameFontSize = 26
GUIScoreboard.kTeamInfoFontSize = 16
GUIScoreboard.kTeamItemWidth = 600
GUIScoreboard.kTeamItemHeight = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 8
GUIScoreboard.kTeamSpacing = 32
GUIScoreboard.kTeamScoreColumnStartX = 200
GUIScoreboard.kTeamColumnSpacingX = ConditionalValue(Client.GetScreenWidth() < 1280, 30, 40)

-- Player constants.
GUIScoreboard.kPlayerStatsFontSize = 16
GUIScoreboard.kPlayerItemWidthBuffer = 10
GUIScoreboard.kPlayerItemWidth = 275
GUIScoreboard.kPlayerItemHeight = 32
GUIScoreboard.kPlayerSpacing = 4

local kPlayerItemLeftMargin = 10
local kPlayerNumberWidth = 20
local kPlayerVoiceChatIconSize = 20
local kPlayerBadgeIconSize = 20
local kPlayerBadgeRightPadding = 4

local kPlayerSkillIconSize = Vector(62, 20, 0)
local kPlayerSkillIconTexture = PrecacheAsset("ui/skill_tier_icons.dds")
local kPlayerSkillIconSizeOverride = Vector(58, 20, 0) -- slightly smaller so it doesn't overlap.

---------------
local kCommunityRankIconSize = Vector(20,20,0)
local kCommunityRankIconTexture = PrecacheAsset("ui/CommunityRankIcons.dds")

local kCommunityRankBGs = PrecacheAsset("ui/CommunityRankBGs.dds")

local kCommunityRankIndex =
{
    ["RANK_C1"] = 1,
    ["RANK_C2"] = 2,
    ["RANK_C3"] = 3,
    ["RANK_LIVER"] = 3,
    ["RANK_C4"] = 4,
    ["RANK_C5"] = 5,
    ["RANK_HOST"] = 6,
    ["RANK_ADMIN"] = 6,
}

local kDynamicTimer = 0
local kDynamicEmblems = {}

local temporaryEmblemFiles ={}
Shared.GetMatchingFileNames( "ui/dynamicEmblems/*.dds", false, temporaryEmblemFiles)
table.sort(temporaryEmblemFiles)
for _, dynamicEmblemFile in ipairs(temporaryEmblemFiles) do
    local indexStart = string.find(dynamicEmblemFile,'_') + 1
    local indexEnd = string.find(dynamicEmblemFile,".dds") - 1
    local frameCount = string.sub(dynamicEmblemFile,indexStart,indexEnd ) or "16"

    table.insert(kDynamicEmblems, {texture = PrecacheAsset(dynamicEmblemFile) , count = tonumber(frameCount)})
end
temporaryEmblemFiles = nil

---------------
local lastScoreboardVisState = false

local kSteamProfileURL = "http://steamcommunity.com/profiles/"
local kMinTruncatedNameLength = 8

-- Color constants.
GUIScoreboard.kBlueColor = ColorIntToColor(kMarineTeamColor)
GUIScoreboard.kBlueHighlightColor = Color(0.30, 0.69, 1, 1)
GUIScoreboard.kRedColor = kRedColor--ColorIntToColor(kAlienTeamColor)
GUIScoreboard.kRedHighlightColor = Color(1, 0.79, 0.23, 1)
GUIScoreboard.kSpectatorColor = ColorIntToColor(kNeutralTeamColor)
GUIScoreboard.kSpectatorHighlightColor = Color(0.8, 0.8, 0.8, 1)

GUIScoreboard.kCommanderFontColor = Color(1, 1, 0, 1)
GUIScoreboard.kWhiteColor = Color(1,1,1,1)
local kDeadColor = Color(1,0,0,1)
local kReserveColor = Color(0.92, 0.73, 0.6)

local kMutedTextTexture = PrecacheAsset("ui/sb-text-muted.dds")
local kMutedVoiceTexture = PrecacheAsset("ui/sb-voice-muted.dds")

function GUIScoreboard:OnResolutionChanged(_, _, newX, _)

    GUIScoreboard.screenWidth = newX

    GUIScoreboard.kTeamColumnSpacingX = ConditionalValue(GUIScoreboard.screenWidth < 1280, 30, 40)

    -- Horizontal size for the game time background is irrelevant as it will be expanded to SB width
    GUIScoreboard.kGameTimeBackgroundSize = Vector(640, GUIScale(32), 0)
    GUIScoreboard.kClickForMouseBackgroundSize = Vector(GUIScale(200), GUIScale(32), 0)

    GUIScoreboard.kBgMaxYSpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)

    self:Uninitialize()
    self:Initialize()

end

function GUIScoreboard:GetTeamItemWidth()
    if GUIScoreboard.screenWidth < 1280 then
        return 608 -- 640 * 0.95
    else
        return math.min(800, GUIScoreboard.screenWidth/2 * 0.95)
    end
end

local function CreateTeamBackground(self, teamNumber)

    local color
    local teamItem = GUIManager:CreateGraphicItem()
    teamItem:SetStencilFunc(GUIItem.NotEqual)

    -- Background
    teamItem:SetSize(Vector(self:GetTeamItemWidth(), GUIScoreboard.kTeamItemHeight, 0) * GUIScoreboard.kScalingFactor)
    if teamNumber == kTeamReadyRoom then

        color = GUIScoreboard.kSpectatorColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)

    elseif teamNumber == kTeam1Index then

        color = GUIScoreboard.kBlueColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)

    elseif teamNumber == kTeam2Index then

        color = GUIScoreboard.kRedColor
        teamItem:SetAnchor(GUIItem.Middle, GUIItem.Top)

    end

    teamItem:SetColor(Color(0, 0, 0, 0.75))
    teamItem:SetIsVisible(false)
    teamItem:SetLayer(kGUILayerScoreboard)

    -- Team name text item.
    local teamNameItem = GUIManager:CreateTextItem()
    teamNameItem:SetFontName(GUIScoreboard.kTeamNameFontName)
    teamNameItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(teamNameItem)
    teamNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamNameItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamNameItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamNameItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
    teamNameItem:SetColor(color)
    teamNameItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(teamNameItem)


    local teamSkillItem = GUIManager:CreateGraphicItem()
    teamSkillItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamSkillItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
    teamSkillItem:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)
    teamSkillItem:SetStencilFunc(GUIItem.NotEqual)
    teamSkillItem:SetTexture(kPlayerSkillIconTexture)
    teamSkillItem:SetTexturePixelCoordinates(0, 0, 100, 31)
    teamSkillItem:SetIsVisible(false)
    teamItem:AddChild(teamSkillItem)

    local teamCommanderSkillItem = GUIManager:CreateGraphicItem()
    teamCommanderSkillItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamCommanderSkillItem:SetPosition(Vector(10, 5, 0) * GUIScoreboard.kScalingFactor)
    teamCommanderSkillItem:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)
    teamCommanderSkillItem:SetStencilFunc(GUIItem.NotEqual)
    teamCommanderSkillItem:SetTexture(kPlayerSkillIconTexture)
    teamCommanderSkillItem:SetTexturePixelCoordinates(0, 0, 100, 31)
    teamCommanderSkillItem:SetIsVisible(false)
    teamItem:AddChild(teamCommanderSkillItem)


    -- Add team info (team resources and number of players).
    local teamInfoItem = GUIManager:CreateTextItem()
    teamInfoItem:SetFontName(GUIScoreboard.kTeamInfoFontName)
    teamInfoItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(teamInfoItem)
    teamInfoItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamInfoItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamInfoItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamInfoItem:SetPosition(Vector(12, GUIScoreboard.kTeamNameFontSize + 7, 0) * GUIScoreboard.kScalingFactor)
    teamInfoItem:SetColor(color)
    teamInfoItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(teamInfoItem)

    local currentColumnX = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10)
    local playerDataRowY = 10

    -- Status text item.
    local statusItem = GUIManager:CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    statusItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(statusItem)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUIItem.Align_Min)
    statusItem:SetTextAlignmentY(GUIItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX + 60, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    statusItem:SetColor(color)
    statusItem:SetText("")
    statusItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(statusItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 2 + 33

    -- Score text item.
    local scoreItem = GUIManager:CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    scoreItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(scoreItem)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUIItem.Align_Center)
    scoreItem:SetTextAlignmentY(GUIItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX + 42.5, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    scoreItem:SetColor(color)
    scoreItem:SetText(Locale.ResolveString("SB_SCORE"))
    scoreItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(scoreItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX + 40

    -- Kill text item.
    local killsItem = GUIManager:CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    killsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(killsItem)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUIItem.Align_Center)
    killsItem:SetTextAlignmentY(GUIItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    killsItem:SetColor(color)
    killsItem:SetText(Locale.ResolveString("SB_KILLS"))
    killsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(killsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Assist text item.
    local assistsItem = GUIManager:CreateTextItem()
    assistsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    assistsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(assistsItem)
    assistsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    assistsItem:SetTextAlignmentX(GUIItem.Align_Center)
    assistsItem:SetTextAlignmentY(GUIItem.Align_Min)
    assistsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    assistsItem:SetColor(color)
    assistsItem:SetText(Locale.ResolveString("SB_ASSISTS"))
    assistsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(assistsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Deaths text item.
    local deathsItem = GUIManager:CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    deathsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(deathsItem)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUIItem.Align_Center)
    deathsItem:SetTextAlignmentY(GUIItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    deathsItem:SetColor(color)
    deathsItem:SetText(Locale.ResolveString("SB_DEATHS"))
    deathsItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(deathsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Resources text item.
    local resItem = GUIManager:CreateGraphicItem()
    resItem:SetPosition((Vector(currentColumnX, playerDataRowY, 0) + kIconOffset) * GUIScoreboard.kScalingFactor)
    resItem:SetTexture("ui/buildmenu.dds")
    resItem:SetTexturePixelCoordinates(GUIUnpackCoords(GetTextureCoordinatesForIcon(kTechId.CollectResources)))
    resItem:SetSize(kIconSize * GUIScoreboard.kScalingFactor)
    resItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(resItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Ping text item.
    local pingItem = GUIManager:CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    pingItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(pingItem)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUIItem.Align_Min)
    pingItem:SetTextAlignmentY(GUIItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, playerDataRowY, 0) * GUIScoreboard.kScalingFactor)
    pingItem:SetColor(color)
    pingItem:SetText(Locale.ResolveString("SB_PING"))
    pingItem:SetStencilFunc(GUIItem.NotEqual)
    teamItem:AddChild(pingItem)

    return { Background = teamItem, TeamName = teamNameItem, TeamInfo = teamInfoItem, TeamSkill = teamSkillItem ,TeamCommanderSkill = teamCommanderSkillItem }

end

local kFavoriteMouseOverColor = Color(1,1,0,1)
local kFavoriteColor = Color(1,1,1,0.9)

local kBlockedMouseOverColor = Color(1,1,0,1)
local kBlockedColor = Color(1,1,1,0.9)

function GUIScoreboard:Initialize()

    self.updateInterval = 0.2

    self.visible = false

    self.teams = { }
    self.reusePlayerItems = { }
    self.slidePercentage = -1
    GUIScoreboard.screenWidth = Client.GetScreenWidth()
    GUIScoreboard.screenHeight = Client.GetScreenHeight()
    GUIScoreboard.kScalingFactor = ConditionalValue(GUIScoreboard.screenHeight > 1280, GUIScale(1), 1)
    self.centerOnPlayer = true -- For modding

    self.scoreboardBackground = GUIManager:CreateGraphicItem()
    self.scoreboardBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.scoreboardBackground:SetLayer(kGUILayerScoreboard)
    self.scoreboardBackground:SetColor(GUIScoreboard.kBgColor)
    self.scoreboardBackground:SetIsVisible(false)

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetLayer(kGUILayerScoreboard)
    self.background:SetColor(GUIScoreboard.kBgColor)
    self.background:SetIsVisible(false)

    self.backgroundStencil = GUIManager:CreateGraphicItem()
    self.backgroundStencil:SetIsStencil(true)
    self.backgroundStencil:SetClearsStencilBuffer(true)
    self.scoreboardBackground:AddChild(self.backgroundStencil)

    self.slidebar = GUIManager:CreateGraphicItem()
    self.slidebar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.slidebar:SetSize(GUIScoreboard.kSlidebarSize * GUIScoreboard.kScalingFactor)
    self.slidebar:SetLayer(kGUILayerScoreboard)
    self.slidebar:SetColor(Color(1, 1, 1, 1))
    self.slidebar:SetIsVisible(true)

    self.slidebarBg = GUIManager:CreateGraphicItem()
    self.slidebarBg:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.slidebarBg:SetSize(Vector(GUIScoreboard.kSlidebarSize.x * GUIScoreboard.kScalingFactor, GUIScoreboard.kBgMaxYSpace-20, 0))
    self.slidebarBg:SetPosition(Vector(-12.5 * GUIScoreboard.kScalingFactor, 10, 0))
    self.slidebarBg:SetLayer(kGUILayerScoreboard)
    self.slidebarBg:SetColor(Color(0.25, 0.25, 0.25, 1))
    self.slidebarBg:SetIsVisible(false)
    self.slidebarBg:AddChild(self.slidebar)
    self.scoreboardBackground:AddChild(self.slidebarBg)

    self.gameTimeBackground = GUIManager:CreateGraphicItem()
    self.gameTimeBackground:SetSize(GUIScoreboard.kGameTimeBackgroundSize)
    self.gameTimeBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.gameTimeBackground:SetPosition( Vector(- GUIScoreboard.kGameTimeBackgroundSize.x / 2, 10, 0) )
    self.gameTimeBackground:SetIsVisible(false)
    self.gameTimeBackground:SetColor(Color(0,0,0,0.5))
    self.gameTimeBackground:SetLayer(kGUILayerScoreboard)

    self.gameTime = GUIManager:CreateTextItem()
    self.gameTime:SetFontName(GUIScoreboard.kGameTimeFontName)
    self.gameTime:SetScale(GetScaledVector())
    GUIMakeFontScale(self.gameTime)
    self.gameTime:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.gameTime:SetTextAlignmentX(GUIItem.Align_Center)
    self.gameTime:SetTextAlignmentY(GUIItem.Align_Center)
    self.gameTime:SetColor(Color(1, 1, 1, 1))
    self.gameTime:SetText("")
    self.gameTimeBackground:AddChild(self.gameTime)

    self.serverAddress = Client.GetConnectedServerAddress()

    self.favoriteButton = GUIManager:CreateGraphicItem()
    self.favoriteButton:SetSize(GUIScale(self.kFavoriteIconSize))
    self.favoriteButton.isServerFavorite = GetServerIsFavorite(self.serverAddress)
    self.favoriteButton:SetTexture(self.favoriteButton.isServerFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)
    self.favoriteButton:SetColor(kFavoriteColor)
    self.favoriteButton:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.gameTimeBackground:AddChild(self.favoriteButton)

    self.blockedButton = GUIManager:CreateGraphicItem()
    self.blockedButton:SetSize(GUIScale(self.kBlockedIconSize))
    self.blockedButton.isServerBlocked = GetServerIsBlocked(self.serverAddress)
    self.blockedButton:SetTexture(self.blockedButton.isServerBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
    self.blockedButton:SetColor(kFavoriteColor)
    self.blockedButton:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.gameTimeBackground:AddChild(self.blockedButton)

    -- Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    -- Spectator team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeamReadyRoom), TeamName = ScoreboardUI_GetSpectatorTeamName(),
                               Color = GUIScoreboard.kSpectatorColor, PlayerList = { }, HighlightColor = GUIScoreboard.kSpectatorHighlightColor,
                               GetScores = ScoreboardUI_GetSpectatorScores, TeamNumber = kTeamReadyRoom })

    -- Blue team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeam1Index), TeamName = ScoreboardUI_GetBlueTeamName(),
                               Color = GUIScoreboard.kBlueColor, PlayerList = { }, HighlightColor = GUIScoreboard.kBlueHighlightColor,
                               GetScores = ScoreboardUI_GetBlueScores, TeamNumber = kTeam1Index})

    -- Red team.
    table.insert(self.teams, { GUIs = CreateTeamBackground(self, kTeam2Index), TeamName = ScoreboardUI_GetRedTeamName(),
                               Color = GUIScoreboard.kRedColor, PlayerList = { }, HighlightColor = GUIScoreboard.kRedHighlightColor,
                               GetScores = ScoreboardUI_GetRedScores, TeamNumber = kTeam2Index })

    self.background:AddChild(self.teams[1].GUIs.Background)
    self.background:AddChild(self.teams[2].GUIs.Background)
    self.background:AddChild(self.teams[3].GUIs.Background)

    self.playerHighlightItem = GUIManager:CreateGraphicItem()
    self.playerHighlightItem:SetSize(Vector(self:GetTeamItemWidth() - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0) * GUIScoreboard.kScalingFactor)
    self.playerHighlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerHighlightItem:SetColor(Color(1, 1, 1, 1))
    self.playerHighlightItem:SetTexture("ui/hud_elements.dds")
    self.playerHighlightItem:SetTextureCoordinates(0, 0.16, 0.558, 0.32)
    self.playerHighlightItem:SetStencilFunc(GUIItem.NotEqual)
    self.playerHighlightItem:SetIsVisible(false)

    self.clickForMouseBackground = GUIManager:CreateGraphicItem()
    self.clickForMouseBackground:SetSize(GUIScoreboard.kClickForMouseBackgroundSize)
    self.clickForMouseBackground:SetPosition(Vector(-GUIScoreboard.kClickForMouseBackgroundSize.x / 2, -GUIScoreboard.kClickForMouseBackgroundSize.y - 5, 0))
    self.clickForMouseBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.clickForMouseBackground:SetIsVisible(false)

    self.clickForMouseIndicator = GUIManager:CreateTextItem()
    self.clickForMouseIndicator:SetFontName(GUIScoreboard.kClickForMouseFontName)
    self.clickForMouseIndicator:SetScale(GetScaledVector())
    GUIMakeFontScale(self.clickForMouseIndicator)
    self.clickForMouseIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.clickForMouseIndicator:SetTextAlignmentX(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetTextAlignmentY(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetColor(Color(0, 0, 0, 1))
    self.clickForMouseIndicator:SetText(GUIScoreboard.kClickForMouseText)
    self.clickForMouseBackground:AddChild(self.clickForMouseIndicator)

    self.mousePressed = { LMB = { Down = nil }, RMB = { Down = nil } }
    self.badgeNameTooltip = GetGUIManager():CreateGUIScriptSingle("menu/GUIHoverTooltip")

    self.hoverMenu = GetGUIManager():CreateGUIScriptSingle("GUIHoverMenu")
    self.hoverMenu:Hide()

    self.hoverPlayerClientIndex = 0

    self.mouseVisible = false

    self.hiddenOverride = HelpScreen_GetHelpScreen():GetIsBeingDisplayed() -- if true, forces scoreboard to be hidden

end

function GUIScoreboard:Uninitialize()

    for _, team in ipairs(self.teams) do
        GUI.DestroyItem(team["GUIs"]["Background"])
    end
    self.teams = { }

    for _, playerItem in ipairs(self.reusePlayerItems) do
        GUI.DestroyItem(playerItem["Background"])
    end
    self.reusePlayerItems = { }

    GUI.DestroyItem(self.clickForMouseIndicator)
    self.clickForMouseIndicator = nil
    GUI.DestroyItem(self.clickForMouseBackground)
    self.clickForMouseBackground = nil

    GUI.DestroyItem(self.gameTime)
    self.gameTime = nil
    GUI.DestroyItem(self.favoriteButton)
    self.favoriteButton = nil
    GUI.DestroyItem(self.blockedButton)
    self.blockedButton = nil
    GUI.DestroyItem(self.gameTimeBackground)
    self.gameTimeBackground = nil

    GUI.DestroyItem(self.scoreboardBackground)
    self.scoreboardBackground = nil

    GUI.DestroyItem(self.background)
    self.background = nil

    GUI.DestroyItem(self.playerHighlightItem)
    self.playerHighlightItem = nil

end

local function SetMouseVisible(self, setVisible)

    if self.mouseVisible ~= setVisible then

        self.mouseVisible = setVisible

        MouseTracker_SetIsVisible(self.mouseVisible, "ui/Cursor_MenuDefault.dds", true)
        if self.mouseVisible then
            self.clickForMouseBackground:SetIsVisible(false)
        end

    end

end


local function HandleSlidebarClicked(self, _, mouseY)

    if self.slidebarBg:GetIsVisible() and self.isDragging then
        local topPos = (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 19
        local bottomPos = Client.GetScreenHeight() - (GUIScoreboard.kClickForMouseBackgroundSize.y + 5) - 19
        mouseY = Clamp(mouseY, topPos, bottomPos)
        self.slidePercentage = (mouseY - topPos) / (bottomPos - topPos) * 100
    end

end

local function GetIsVisibleTeam(teamNumber)
    local isVisibleTeam = false
    local localPlayer = Client.GetLocalPlayer()
    if localPlayer then

        local localPlayerTeamNum = localPlayer:GetTeamNumber()
        -- Can see secret information if the player is on the team or is a spectator.
        if teamNumber == kTeamReadyRoom or localPlayerTeamNum == teamNumber or localPlayerTeamNum == kSpectatorIndex then
            isVisibleTeam = true
        end

    end

    if not isVisibleTeam then
        -- Allow seeing who is commander during pre-game
        local gInfo = GetGameInfoEntity()
        if gInfo and gInfo:GetState() <= kGameState.PreGame then
            return true
        end
    end

    return isVisibleTeam
end

function GUIScoreboard:Update(deltaTime)

    PROFILE("GUIScoreboard:Update")

    local vis = self.visible and not self.hiddenOverride
    ------------
    if vis then
        kDynamicTimer = kDynamicTimer + deltaTime
    else
        kDynamicTimer = 0
    end
    ----

    -- Show all the elements the frame after sorting them
    -- so it doesn't appear to shift when we open
    local displayScoreboard = self.slidePercentage > -1 and not self.hiddenOverride
    self.gameTimeBackground:SetIsVisible(displayScoreboard)
    self.gameTime:SetIsVisible(displayScoreboard)
    self.background:SetIsVisible(displayScoreboard)
    self.scoreboardBackground:SetIsVisible(displayScoreboard)
    if lastScoreboardVisState ~= displayScoreboard then
        lastScoreboardVisState = displayScoreboard
        if vis == false then
            self.updateInterval = 0.2
            self.badgeNameTooltip:Hide(0)
        end
    end

    if not vis then
        SetMouseVisible(self, false)
    end

    if self.hoverMenu.background:GetIsVisible() then
        if not vis then
            self.hoverMenu:Hide()
        end
    else
        self.hoverPlayerClientIndex = 0
    end

    if not self.mouseVisible then

        -- Click for mouse only visible when not a commander and when the scoreboard is visible.
        local clickForMouseBackgroundVisible = (not PlayerUI_IsACommander()) and vis
        self.clickForMouseBackground:SetIsVisible(clickForMouseBackgroundVisible)
        local backgroundColor = PlayerUI_GetTeamColor()
        backgroundColor.a = 0.8
        self.clickForMouseBackground:SetColor(backgroundColor)

    end

    --First, update teams.
    local teamGUISize = {}
    for index, team in ipairs(self.teams) do

        -- Don't draw if no players on team
        local numPlayers = table.icount(team["GetScores"]())
        if team.TeamNumber == 0 and numPlayers == 0 and PlayerUI_GetNumConnectingPlayers() > 0 then
            numPlayers = PlayerUI_GetNumConnectingPlayers()
        end
        team["GUIs"]["Background"]:SetIsVisible(vis and (numPlayers > 0))

        if vis then
            self:UpdateTeam(team)
            if numPlayers > 0 then
                if teamGUISize[team.TeamNumber] == nil then
                    teamGUISize[team.TeamNumber] = {}
                end
                teamGUISize[team.TeamNumber] = self.teams[index].GUIs.Background:GetSize().y
            end
        end

    end

    local topBar = nil
    --Yes, a bit janky but each "mode" needs different handling
    if PlayerUI_GetIsSpecating() then
        topBar = GetGUIManager():GetGUIScriptSingle("GUIInsight_TopBar")

        if topBar then
            topBar:SetIsVisible( not vis )
        end
    else
        topBar = ClientUI.GetScript( "Hud2/topBar/GUIHudTopBarForLocalTeam" )

        if topBar then
            topBar:SetIsHiddenOverride(vis)
        end
    end

    if vis then

        if self.hoverPlayerClientIndex == 0 and GUIItemContainsPoint(self.scoreboardBackground, Client.GetCursorPosScreen()) then
            self.badgeNameTooltip:Hide(0)
        end

        local gameTime = PlayerUI_GetGameLengthTime()
        local minutes = math.floor( gameTime / 60 )
        local seconds = math.floor( gameTime - minutes * 60 )

        local serverName = Client.GetServerIsHidden() and "Hidden" or Client.GetConnectedServerName()
        local gameTimeText = serverName .. " | " .. GetGamemode() .. "/" .. string.gsub( Shared.GetMapName(), "^ns[12]?_", "" ) .. string.format( " - %d:%02d", minutes, seconds)

        self.gameTime:SetText(gameTimeText)

        -- Update the favorite button when the coreboard opens (dt == 0)
        if deltaTime == 0 then
            self.favoriteButton.isServerFavorite = GetServerIsFavorite(self.serverAddress)
            self.favoriteButton:SetTexture(self.favoriteButton.isServerFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)

            self.blockedButton.isServerBlocked = GetServerIsFavorite(self.serverAddress)
            self.blockedButton:SetTexture(self.blockedButton.isServerBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
        end

        local width = - self.gameTime:GetTextWidth(gameTimeText) / 2 - GUIScale(2 * self.kFavoriteIconSize.x + 20)
        self.favoriteButton:SetPosition(Vector(width, GUIScale(4), 0))

        width = - self.gameTime:GetTextWidth(gameTimeText) / 2 - GUIScale(self.kBlockedIconSize.x + 10)
        self.blockedButton:SetPosition(Vector(width, GUIScale(4), 0))

        -- Get sizes for everything so we can reposition correctly
        local contentYSize = 0
        local teamItemWidth = self:GetTeamItemWidth() * GUIScoreboard.kScalingFactor
        local teamItemVerticalFormat = teamItemWidth*2 > GUIScoreboard.screenWidth
        local contentXOffset = (GUIScoreboard.screenWidth - teamItemWidth * 2) / 2
        local contentXExtraOffset = ConditionalValue(GUIScoreboard.screenWidth > 1900, contentXOffset * 0.33, 15 * GUIScoreboard.kScalingFactor)
        local contentXSize = teamItemWidth + contentXExtraOffset * 2
        local contentYSpacing = 20 * GUIScoreboard.kScalingFactor

        if teamGUISize[1] then
            -- If it doesn't fit horizontally or there is only one team put it below
            if teamItemVerticalFormat or not teamGUISize[2] then
                self.teams[2].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize, 0))
                contentYSize = contentYSize + teamGUISize[1] + contentYSpacing
            else
                self.teams[2].GUIs.Background:SetPosition(Vector(-teamItemWidth - contentXOffset / 2 + contentXExtraOffset, contentYSize, 0))
            end

        end
        if teamGUISize[2] then
            -- If it doesn't fit horizontally or there is only one team put it below
            if teamItemVerticalFormat or not teamGUISize[1] then
                self.teams[3].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize, 0))
                contentYSize = contentYSize + teamGUISize[2] + contentYSpacing
            else
                self.teams[3].GUIs.Background:SetPosition(Vector(contentXOffset / 2 - contentXExtraOffset, contentYSize, 0))
            end
        end
        -- If both teams fit horizontally then take only the biggest size
        if teamGUISize[1] and teamGUISize[2] and not teamItemVerticalFormat then
            contentYSize = math.max(teamGUISize[1], teamGUISize[2]) + contentYSpacing*2
            contentXSize = teamItemWidth*2 + contentXOffset
        end
        if teamGUISize[0] then
            self.teams[1].GUIs.Background:SetPosition(Vector(-teamItemWidth / 2, contentYSize, 0))
            contentYSize = contentYSize + teamGUISize[0] + contentYSpacing
        end

        local slideOffset = -(self.slidePercentage * contentYSize/100)+(self.slidePercentage * self.slidebarBg:GetSize().y/100)
        local displaySpace = Client.GetScreenHeight() - ((GUIScoreboard.kClickForMouseBackgroundSize.y + 5) + (GUIScoreboard.kGameTimeBackgroundSize.y + 6) + 20)
        local showSlidebar = contentYSize > displaySpace
        local ySize = math.min(displaySpace, contentYSize)

        if self.slidePercentage == -1 then
            self.slidePercentage = 0
            local teamNumber = Client.GetLocalPlayer():GetTeamNumber()
            if showSlidebar and teamNumber ~= 3 and self.centerOnPlayer then
                local player = self.playerHighlightItem:GetParent()
                local playerItem = player:GetPosition().y
                local teamItem = player:GetParent() and player:GetParent():GetPosition().y or 0
                local playerPos = playerItem + teamItem + GUIScoreboard.kPlayerItemHeight
                if playerPos > displaySpace then
                    self.slidePercentage = math.max(0, math.min((playerPos / contentYSize * 100), 100))
                end
            end
        end

        local sliderPos = (self.slidePercentage * self.slidebarBg:GetSize().y/100)
        if sliderPos < self.slidebar:GetSize().y/2 then
            sliderPos = 0
        end
        if sliderPos > self.slidebarBg:GetSize().y - self.slidebar:GetSize().y then
            sliderPos = self.slidebarBg:GetSize().y - self.slidebar:GetSize().y
        end

        self.background:SetPosition(Vector(0, 10+(-ySize/2+slideOffset), 0))
        self.scoreboardBackground:SetSize(Vector(contentXSize, ySize, 0))
        self.scoreboardBackground:SetPosition(Vector(-contentXSize/2, -ySize/2, 0))
        self.backgroundStencil:SetSize(Vector(contentXSize, ySize-20, 0))
        self.backgroundStencil:SetPosition(Vector(0, 10, 0))
        local gameTimeBgYSize = self.gameTimeBackground:GetSize().y
        local gameTimeBgYPos = self.gameTimeBackground:GetPosition().y

        self.gameTimeBackground:SetSize(Vector(contentXSize, gameTimeBgYSize, 0))
        self.gameTimeBackground:SetPosition(Vector(-contentXSize/2, gameTimeBgYPos, 0))

        self.slidebar:SetPosition(Vector(0, sliderPos, 0))
        self.slidebarBg:SetIsVisible(showSlidebar)
        self.scoreboardBackground:SetColor(ConditionalValue(showSlidebar, GUIScoreboard.kBgColor, Color(0, 0, 0, 0)))

        local mouseX, mouseY = Client.GetCursorPosScreen()
        if self.mousePressed["LMB"]["Down"] and self.isDragging then
            HandleSlidebarClicked(self, mouseX, mouseY)
        end
    else
        self.slidePercentage = -1
    end
end


local function SetPlayerItemBadges( item ,numberSize , teamItemWidth, badgeTextures , badgeNames , badgeColumns)

    assert( #badgeTextures <= #item.BadgeItems )

    local icon = false

    for i = 1, #item.BadgeItems do

        if badgeTextures[i] ~= nil then
            item.BadgeItems[i]:SetTexture( badgeTextures[i] )
            item.BadgeItems[i]:SetIsVisible( true )

            if badgeColumns[i] == 10 then
                icon = true
                item.BadgeItems[i]:SetPosition(Vector(ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, teamItemWidth - GUIScoreboard.kTeamColumnSpacingX * 10-kPlayerBadgeIconSize / 2), -kPlayerBadgeIconSize/2, 0) * GUIScoreboard.kScalingFactor)
            else
                item.BadgeItems[i]:SetPosition(Vector(numberSize + kPlayerItemLeftMargin + (i-1) * kPlayerVoiceChatIconSize + (i-1) * kPlayerBadgeRightPadding, -kPlayerVoiceChatIconSize/2, 0) * GUIScoreboard.kScalingFactor)
            end

        else
            item.BadgeItems[i]:SetIsVisible( false )
        end

    end

    return icon

end

function GUIScoreboard:UpdateTeam(updateTeam)

    local teamGUIItem = updateTeam["GUIs"]["Background"]
    local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
    local teamSkillGUIItem = updateTeam["GUIs"]["TeamSkill"]
    local teamCommanderSkillGUIItem = updateTeam["GUIs"]["TeamCommanderSkill"]
    local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
    local teamNameText = Locale.ResolveString( string.format("NAME_TEAM_%s", updateTeam["TeamNumber"]))
    local teamColor = updateTeam["Color"]
    local localPlayerHighlightColor = updateTeam["HighlightColor"]
    local playerList = updateTeam["PlayerList"]
    local teamScores = updateTeam["GetScores"]()
    local teamNumber = updateTeam["TeamNumber"]

    -- Determines if the local player can see secret information
    -- for this team.
    local isVisibleTeam = GetIsVisibleTeam(teamNumber)

    -- How many items per player.
    local numPlayers = table.icount(teamScores)


    -- Update team resource display
    if teamNumber ~= kTeamReadyRoom then
        local teamResourcesString = ConditionalValue(isVisibleTeam, string.format(Locale.ResolveString("SB_TEAM_RES"), ScoreboardUI_GetTeamResources(teamNumber)), "")
        teamInfoGUIItem:SetText(string.format("%s", teamResourcesString))
    end

    local teamItemWidth = self:GetTeamItemWidth()
    -- Make sure there is enough room for all players on this team GUI.
    teamGUIItem:SetSize(Vector(teamItemWidth, (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0) * GUIScoreboard.kScalingFactor)

    -- Resize the player list if it doesn't match.
    if table.icount(playerList) ~= numPlayers then
        self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    end

    local currentY = (GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 10) * GUIScoreboard.kScalingFactor
    local currentPlayerIndex = 1
    local deadString = Locale.ResolveString("STATUS_DEAD")

    local sumPlayerSkill = 0
    local numPlayerSkill = 0
    local commanderSkill = -1
    local numRookies = 0
    local numBots = 0

    for index, player in ipairs(playerList) do

        local playerRecord = teamScores[currentPlayerIndex]
        
        local fakeBot = playerRecord.FakeBot
        local hideRank = playerRecord.HideRank
        local playerName = playerRecord.Name
        local clientIndex = playerRecord.ClientIndex
        local steamId = GetSteamIdForClientIndex(clientIndex)
        local score = playerRecord.Score
        local kills = playerRecord.Kills
        local assists = playerRecord.Assists
        local deaths = playerRecord.Deaths
        local isCommander = playerRecord.IsCommander
        local isVisibleCommander = isCommander and isVisibleTeam == true
        local isRookie = playerRecord.IsRookie
        local isBot = steamId == 0
        local resourcesStr = ConditionalValue(isVisibleTeam, tostring(math.floor(playerRecord.Resources * 10) / 10), "-")
        local currentPosition = Vector(player["Background"]:GetPosition())
        local playerStatus = isVisibleTeam and playerRecord.Status or "-"
        local isDead = isVisibleTeam and playerRecord.Status == deadString
        local ping = playerRecord.Ping
        local isSteamFriend = playerRecord.IsSteamFriend 
        local playerSkill = playerRecord.IsCommander and playerRecord.CommSkill or playerRecord.Skill
        local adagradSum = playerRecord.AdagradSum
        local commanderColor = GUIScoreboard.kCommanderFontColor

        if isVisibleTeam and teamNumber == kTeam1Index then
            local currentTech = GetTechIdsFromBitMask(playerRecord.Tech)
            if table.icontains(currentTech, kTechId.Jetpack) then
                if playerStatus ~= "" and playerStatus ~= " " then
                    playerStatus = string.format("%s/%s", playerStatus, Locale.ResolveString("STATUS_JETPACK") )
                else
                    playerStatus = Locale.ResolveString("STATUS_JETPACK")
                end
            end
        end

        if isVisibleCommander then
            score = "*"
        end

        if hideRank then
            ping = ping + 140
            isSteamFriend = false
        end

        local communityRankIndex = kCommunityRankIndex[playerRecord.Group] or 0

        local emblemIndex = communityRankIndex
        if playerRecord.Emblem and playerRecord.Emblem ~= 0  then       --Override by emblem setting
            emblemIndex = playerRecord.Emblem
        end

        local showEmblem = not fakeBot
        showEmblem = showEmblem and (teamNumber == kTeamReadyRoom or teamNumber == kSpectatorIndex)
        if not showEmblem then
            emblemIndex = 0
        end

        currentPosition.y = currentY
        local background = player["Background"]
        background:SetPosition(currentPosition)
        background:SetColor(ConditionalValue(isVisibleCommander, commanderColor, teamColor))
        if emblemIndex < 0 then
            local dynamicEmblemIndex = - emblemIndex
            if dynamicEmblemIndex <= #kDynamicEmblems then
                local dynamicEmblemData = kDynamicEmblems[dynamicEmblemIndex]
                background:SetTexture(dynamicEmblemData.texture)
                local frameCount = dynamicEmblemData.count
                local framePerSecond = 12
                local currentFrame = (kDynamicTimer * framePerSecond) % frameCount
                local dynamicIndex = math.floor(currentFrame)
                background:SetTexturePixelCoordinates(0, dynamicIndex *32,512,(dynamicIndex +1)*32)
            else
                emblemIndex = 0
            end
        end

        if emblemIndex >= 0 then
            background:SetTexture(kCommunityRankBGs)
            background:SetTexturePixelCoordinates(0, emblemIndex *41,571,(emblemIndex +1)*41)
        end
        -- Handle local player highlight
        if ScoreboardUI_IsPlayerLocal(playerName) then
            if self.playerHighlightItem:GetParent() ~= player["Background"] then
                if self.playerHighlightItem:GetParent() ~= nil then
                    self.playerHighlightItem:GetParent():RemoveChild(self.playerHighlightItem)
                end
                player["Background"]:AddChild(self.playerHighlightItem)
                self.playerHighlightItem:SetIsVisible(true)
                self.playerHighlightItem:SetColor(localPlayerHighlightColor)
            end
        end

        player["Number"]:SetText(index..".")

        if fakeBot then
            playerName = "[BOT] " .. playerName
        end
        player["Name"]:SetText(playerName)

        -- Needed to determine who to (un)mute when voice icon is clicked.
        player["ClientIndex"] = clientIndex

        -- Voice icon.
        local playerVoiceColor = GUIScoreboard.kVoiceDefaultColor
        local voiceChannel = clientIndex and ChatUI_GetVoiceChannelForClient(clientIndex) or VoiceChannel.Invalid
        if ChatUI_GetClientMuted(clientIndex) then
            playerVoiceColor = GUIScoreboard.kVoiceMuteColor
        elseif voiceChannel ~= VoiceChannel.Invalid then
            playerVoiceColor = teamColor
        end

        -- Set player skill icon
        local skillIconOverrideSettings = CheckForSpecialBadgeRecipient(steamId)
        if skillIconOverrideSettings then

            -- User has a special skill-tier icon tied to their steam Id.

            -- Reset the skill icon's texture coordinates to the default normalized coordinates (0, 0), (1, 1).
            -- The shader depends on them being this way.
            player.SkillIcon:SetTextureCoordinates(0, 0, 1, 1)

            -- Change the skill icon's shader to the one that will animate.
            player.SkillIcon:SetShader(skillIconOverrideSettings.shader)
            player.SkillIcon:SetTexture(skillIconOverrideSettings.tex)
            player.SkillIcon:SetFloatParameter("frameCount", skillIconOverrideSettings.frameCount)

            -- Change the size so it doesn't touch the weapon name text.
            player.SkillIcon:SetSize(kPlayerSkillIconSizeOverride * GUIScoreboard.kScalingFactor)

            -- Change the tooltip of the skill icon.
            player.SkillIcon.tooltipText = skillIconOverrideSettings.tooltip

        else

            -- User has no special skill-tier icon.

            -- Reset the shader and texture back to the default one.
            player.SkillIcon:SetShader("shaders/GUIBasic.surface_shader")
            player.SkillIcon:SetTexture(kPlayerSkillIconTexture)
            player.SkillIcon:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)

            local skillTier, tierName, cappedSkill = GetPlayerSkillTier(playerSkill, isRookie, adagradSum, isBot)
            player.SkillIcon.tooltipText = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString(tierName), skillTier)

            local iconIndex = skillTier + 2
            if not isBot and isCommander then
                iconIndex = iconIndex + 8
                commanderSkill = playerSkill
            end
            player.SkillIcon:SetTexturePixelCoordinates(0, iconIndex * 32, 100, (iconIndex + 1) * 32 - 1)

            if cappedSkill then
                sumPlayerSkill = sumPlayerSkill + cappedSkill
                numPlayerSkill = numPlayerSkill + 1
            end
        end


        numRookies = numRookies + (isRookie and 1 or 0)
        numBots = numBots + (isBot and 1 or 0)

        player["Score"]:SetText(tostring(score))
        player["Kills"]:SetText(tostring(kills))
        player["Assists"]:SetText(tostring(assists))
        player["Deaths"]:SetText(tostring(deaths))
        player["Status"]:SetText(playerStatus)
        player["Resources"]:SetText(resourcesStr)
        player["Ping"]:SetText(tostring(ping))

        local white = GUIScoreboard.kWhiteColor
        local baseColor, nameColor, statusColor = white, white, white

        if isDead and isVisibleTeam then

            nameColor, statusColor = kDeadColor, kDeadColor

        end

        player["Score"]:SetColor(baseColor)
        player["Kills"]:SetColor(baseColor)
        player["Assists"]:SetColor(baseColor)
        player["Deaths"]:SetColor(baseColor)
        player["Status"]:SetColor(statusColor)

        player["Name"]:SetColor(nameColor)

        -- resource color
        if resourcesStr then
            local resourcesNumber = tonumber(resourcesStr)
            if resourcesNumber == nil then 	-- necessary at gamestart with bots
                resourcesNumber = 0
            end
            if resourcesNumber < GUIScoreboard.kHighPresThreshold then
                player["Resources"]:SetColor(baseColor)
            elseif resourcesNumber >= GUIScoreboard.kVeryHighPresThreshold then
                player["Resources"]:SetColor(GUIScoreboard.kVeryHighPresColor)
            else
                player["Resources"]:SetColor(GUIScoreboard.kHighPresColor)
            end
        else
            player["Resources"]:SetColor(baseColor)
        end

        if ping < GUIScoreboard.kLowPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kLowPingColor)
        elseif ping < GUIScoreboard.kMedPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kMedPingColor)
        elseif ping < GUIScoreboard.kHighPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kHighPingColor)
        else
            player["Ping"]:SetColor(GUIScoreboard.kInsanePingColor)
        end
        currentY = currentY + (GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * GUIScoreboard.kScalingFactor
        currentPlayerIndex = currentPlayerIndex + 1

        -- New scoreboard positioning

        local numberSize = 0
        if player["Number"]:GetIsVisible() then
            numberSize = kPlayerNumberWidth
        end

        local statusPos = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth + 30, (teamItemWidth - GUIScoreboard.kTeamColumnSpacingX * 10) + 60)
        playerStatus = player["Status"]:GetText()
        ----
        if playerStatus == Locale.ResolveString("STATUS_SPECTATOR") and playerRecord.QueueIndex then
            local reserved = playerRecord.ReservedQueueIndex > 0
            local queueIndex = reserved and playerRecord.ReservedQueueIndex or playerRecord.QueueIndex

            if queueIndex > 0 then
                local title = reserved and Locale.ResolveString("STATUS_QUEUE_RESERVED") or Locale.ResolveString("STATUS_QUEUE")
                player["Status"]:SetColor(reserved and kReserveColor or GUIScoreboard.kWhiteColor)
                player["Status"]:SetText(string.format(title,queueIndex))
            end
        end
        ---
        if playerStatus == "-" or (playerStatus ~= Locale.ResolveString("STATUS_SPECTATOR") and teamNumber ~= 1 and teamNumber ~= 2) then
            playerStatus = ""
            player["Status"]:SetText("")
            statusPos = statusPos + GUIScoreboard.kTeamColumnSpacingX * ConditionalValue(GUIScoreboard.screenWidth < 1280, 2.75, 1.75)
        end

        local icon = SetPlayerItemBadges( player, numberSize , teamItemWidth, Badges_GetBadgeTextures(clientIndex, "scoreboard") )

        local numBadges = math.min(#Badges_GetBadgeTextures(clientIndex, "scoreboard"), #player["BadgeItems"])
        if icon then
            numBadges = numBadges - 1
        end
        local pos = (numberSize + kPlayerItemLeftMargin + numBadges * kPlayerVoiceChatIconSize + numBadges * kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor

        player["Name"]:SetPosition(Vector(pos, 0, 0))

        -- Icons on the right side of the player name
        player["SteamFriend"]:SetIsVisible(isSteamFriend)
        player["Voice"]:SetIsVisible(ChatUI_GetClientMuted(clientIndex))
        player["Text"]:SetIsVisible(ChatUI_GetSteamIdTextMuted(steamId))

        local rankIconIndex = communityRankIndex
        player["CommunityRankIcon"]:SetTexturePixelCoordinates(0, rankIconIndex *80,80,(rankIconIndex +1)*80)
        player["CommunityRankIcon"]:SetIsVisible(not fakeBot and rankIconIndex > 0)
        
        local prewarmIconIndex = (playerRecord.prewarmTier and playerRecord.prewarmTier > 0) and (playerRecord.prewarmTier + 6) or 0
        player["CommunityPrewarmIcon"]:SetTexturePixelCoordinates(0, prewarmIconIndex * 80, 80 ,(prewarmIconIndex +1) * 80)
        player["CommunityPrewarmIcon"]:SetIsVisible(not fakeBot and prewarmIconIndex > 0)

        local nameRightPos = pos + (kPlayerBadgeRightPadding * GUIScoreboard.kScalingFactor)

        pos = (statusPos - kPlayerBadgeRightPadding) * GUIScoreboard.kScalingFactor
        if playerStatus ~= "" then
            pos = (statusPos - kPlayerSkillIconSize.x + kPlayerItemLeftMargin) * GUIScoreboard.kScalingFactor
            if icon then
                pos =  pos - kPlayerBadgeIconSize * GUIScoreboard.kScalingFactor
            end
        end

        for _, icon in ipairs(player["IconTable"]) do
            if icon:GetIsVisible() then
                local iconSize = icon:GetSize()
                pos = pos - iconSize.x
                icon:SetPosition(Vector(pos, (-iconSize.y/2), 0))
            end
        end

        local finalName = player["Name"]:GetText()
        local finalNameWidth = player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor
        local dotsWidth = player["Name"]:GetTextWidth("...") * GUIScoreboard.kScalingFactor
        -- The minimum truncated length for the name also includes the "..."
        while nameRightPos + finalNameWidth > pos and string.UTF8Length(finalName) > kMinTruncatedNameLength do
            finalName = string.UTF8Sub(finalName, 1, string.UTF8Length(finalName)-1)
            finalNameWidth = (player["Name"]:GetTextWidth(finalName) * GUIScoreboard.kScalingFactor) + dotsWidth
            player["Name"]:SetText(finalName .. "...")
        end

        local color = Color(0.5, 0.5, 0.5, 1)
        if isVisibleCommander then
            color = GUIScoreboard.kCommanderFontColor * 0.8
        else
            color = teamColor * 0.8
        end

        if not self.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
            if MouseTracker_GetIsVisible() then
                local mouseX, mouseY = Client.GetCursorPosScreen()
                if GUIItemContainsPoint(player["Background"], mouseX, mouseY) then
                    local canHighlight = true
                    local hoverBadge = false
                    for _, icon in ipairs(player["IconTable"]) do
                        if icon:GetIsVisible() and GUIItemContainsPoint(icon, mouseX, mouseY) and not icon.allowHighlight then
                            canHighlight = false
                            break
                        end
                    end

                    for i = 1, #player.BadgeItems do
                        local badgeItem = player.BadgeItems[i]
                        if GUIItemContainsPoint(badgeItem, mouseX, mouseY) and badgeItem:GetIsVisible() then
                            local _, badgeNames = Badges_GetBadgeTextures(clientIndex, "scoreboard")
                            local badge = ToString(badgeNames[i])
                            self.badgeNameTooltip:SetText(GetBadgeFormalName(badge))
                            hoverBadge = true
                            break
                        end
                    end

                    local skillIcon = player.SkillIcon
                    if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
                        self.badgeNameTooltip:SetText(skillIcon.tooltipText)
                        hoverBadge = true
                    end

                    if canHighlight then
                        self.hoverPlayerClientIndex = clientIndex
                        player["Background"]:SetColor(color)
                    else
                        self.hoverPlayerClientIndex = 0
                    end

                    if hoverBadge then
                        self.badgeNameTooltip:Show()
                    else
                        self.badgeNameTooltip:Hide()
                    end
                else
                    local overFavorite = GUIItemContainsPoint(self.favoriteButton, mouseX, mouseY)
                    local overBlocked = GUIItemContainsPoint(self.blockedButton, mouseX, mouseY)

                    if overFavorite then
                        self.favoriteButton:SetColor(kFavoriteMouseOverColor)
                        -- Todo: Tooltip?
                    else
                        self.favoriteButton:SetColor(kFavoriteColor)
                    end

                    if overBlocked then
                        self.blockedButton:SetColor(kBlockedMouseOverColor)
                        -- Todo: Tooltip?
                    else
                        self.blockedButton:SetColor(kBlockedColor)
                    end
                end
            end
        elseif steamId == GetSteamIdForClientIndex(self.hoverPlayerClientIndex) then
            player["Background"]:SetColor(color)
        end

    end

    -- Update the team name text.
    local playersOnTeamText = string.format("%d %s", numPlayers, numPlayers == 1 and Locale.ResolveString("SB_PLAYER") or Locale.ResolveString("SB_PLAYERS") )
    local teamHeaderText

    if teamNumber == kTeamReadyRoom then
        -- Add number of players connecting
        local numPlayersConnecting = PlayerUI_GetNumConnectingPlayers()
        if numPlayersConnecting > 0 then
            -- It will show RR team if players are connecting even if no players are in the RR
            if numPlayers > 0 then
                teamHeaderText = string.format("%s (%s, %d %s)", teamNameText, playersOnTeamText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING") )
            else
                teamHeaderText = string.format("%s (%d %s)", teamNameText, numPlayersConnecting, Locale.ResolveString("SB_CONNECTING") )
            end
        end
    end

    local avgSkill = sumPlayerSkill / math.max(1,numPlayerSkill)
    if teamNumber == kTeam1Index or teamNumber == kTeam2Index then
        local avgSkillText = string.format(Locale.ResolveString("SB_AVGSKILL"),avgSkill)
        if commanderSkill > 0 then
            local cmdSkillText = string.format(Locale.ResolveString("SB_COMMSKILL"),commanderSkill)
            teamHeaderText = string.format("%s - %s | %s | %s", teamNameText, playersOnTeamText,cmdSkillText,avgSkillText)
        else
            teamHeaderText = string.format("%s - %s | %s", teamNameText, playersOnTeamText,avgSkillText)
        end
    end

    if not teamHeaderText then
        teamHeaderText = string.format("%s (%s)", teamNameText, playersOnTeamText)
    end

    teamNameGUIItem:SetText( teamHeaderText )

    numPlayers = #playerList
    if teamNumber ~= kTeamReadyRoom then
        local offset = (teamNameGUIItem:GetTextWidth(teamHeaderText) + 10)* GUIScoreboard.kScalingFactor

        if commanderSkill >= 0 then

            local skillTier = GetPlayerSkillTier(commanderSkill)
            local textureIndex = skillTier + 2 + 8
            teamCommanderSkillGUIItem:SetTexturePixelCoordinates(0, textureIndex * 32, 100, (textureIndex + 1) * 32 - 1)
            teamCommanderSkillGUIItem:SetPosition(Vector( offset, 5, 0) * GUIScoreboard.kScalingFactor)
            teamCommanderSkillGUIItem:SetIsVisible(true)

            offset = offset + 50 * GUIScoreboard.kScalingFactor
        else
            teamCommanderSkillGUIItem:SetIsVisible(false)
        end

        if numPlayers > 0 then
            local skillTier = GetPlayerSkillTier(avgSkill, false, nil, false)
            local textureIndex = skillTier + 2
            teamSkillGUIItem:SetTexturePixelCoordinates(0, textureIndex * 32, 100, (textureIndex + 1) * 32 - 1)
            teamSkillGUIItem:SetPosition(Vector(offset, 5, 0) * GUIScoreboard.kScalingFactor)
            teamSkillGUIItem:SetIsVisible(true)

            offset = offset + 50 * GUIScoreboard.kScalingFactor
        else
            teamSkillGUIItem:SetIsVisible(false)
        end
    end
end

function GUIScoreboard:ResizePlayerList(playerList, numPlayers, teamGUIItem)

    while table.icount(playerList) > numPlayers do
        teamGUIItem:RemoveChild(playerList[1]["Background"])
        playerList[1]["Background"]:SetIsVisible(false)
        table.insert(self.reusePlayerItems, playerList[1])
        table.remove(playerList, 1)
    end

    while table.icount(playerList) < numPlayers do
        local newPlayerItem = self:CreatePlayerItem()
        table.insert(playerList, newPlayerItem)
        teamGUIItem:AddChild(newPlayerItem["Background"])
        newPlayerItem["Background"]:SetIsVisible(true)
    end

end

function GUIScoreboard:CreatePlayerItem()

    -- Reuse an existing player item if there is one.
    if table.icount(self.reusePlayerItems) > 0 then
        local returnPlayerItem = self.reusePlayerItems[1]
        table.remove(self.reusePlayerItems, 1)
        return returnPlayerItem
    end

    -- Create background.
    local playerItem = GUIManager:CreateGraphicItem()
    playerItem:SetSize(Vector(self:GetTeamItemWidth() - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0) * GUIScoreboard.kScalingFactor)
    playerItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerItem:SetPosition(Vector(GUIScoreboard.kPlayerItemWidthBuffer, GUIScoreboard.kPlayerItemHeight / 2, 0) * GUIScoreboard.kScalingFactor)
    playerItem:SetColor(Color(1, 1, 1, 1))
    playerItem:SetTexture(kCommunityRankBGs)
    playerItem:SetTextureCoordinates(0, 0, 0.558, 0.16)  --571 41
    playerItem:SetStencilFunc(GUIItem.NotEqual)

    local playerItemChildX = kPlayerItemLeftMargin

    -- Player number item
    local playerNumber = GUIManager:CreateTextItem()
    playerNumber:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    playerNumber:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(playerNumber)
    playerNumber:SetAnchor(GUIItem.Left, GUIItem.Center)
    playerNumber:SetTextAlignmentX(GUIItem.Align_Min)
    playerNumber:SetTextAlignmentY(GUIItem.Align_Center)
    playerNumber:SetPosition(Vector(playerItemChildX, 0, 0))
    playerItemChildX = playerItemChildX + kPlayerNumberWidth
    playerNumber:SetColor(Color(0.5, 0.5, 0.5, 1))
    playerNumber:SetStencilFunc(GUIItem.NotEqual)
    playerNumber:SetIsVisible(false)
    playerItem:AddChild(playerNumber)

    -- Player voice icon item.
    local playerVoiceIcon = GUIManager:CreateGraphicItem()
    playerVoiceIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
    playerVoiceIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    playerVoiceIcon:SetPosition(Vector(
            playerItemChildX,
            -kPlayerVoiceChatIconSize/2,
            0) * GUIScoreboard.kScalingFactor)
    playerItemChildX = playerItemChildX + kPlayerVoiceChatIconSize
    playerVoiceIcon:SetTexture(kMutedVoiceTexture)
    playerVoiceIcon:SetStencilFunc(GUIItem.NotEqual)
    playerVoiceIcon:SetIsVisible(false)
    playerVoiceIcon:SetColor(GUIScoreboard.kVoiceMuteColor)
    playerItem:AddChild(playerVoiceIcon)

    ------------------------------------------
    --  Badge icons
    ------------------------------------------
    local maxBadges = Badges_GetMaxBadges()
    local badgeItems = {}

    -- Player badges
    for _ = 1,maxBadges do

        local playerBadge = GUIManager:CreateGraphicItem()
        playerBadge:SetSize(Vector(kPlayerBadgeIconSize, kPlayerBadgeIconSize, 0) * GUIScoreboard.kScalingFactor)
        playerBadge:SetAnchor(GUIItem.Left, GUIItem.Center)
        playerBadge:SetPosition(Vector(playerItemChildX, -kPlayerBadgeIconSize/2, 0) * GUIScoreboard.kScalingFactor)
        playerItemChildX = playerItemChildX + kPlayerBadgeIconSize + kPlayerBadgeRightPadding
        playerBadge:SetIsVisible(false)
        playerBadge:SetStencilFunc(GUIItem.NotEqual)
        playerItem:AddChild(playerBadge)
        table.insert( badgeItems, playerBadge )

    end

    -- Player name text item.
    local playerNameItem = GUIManager:CreateTextItem()
    playerNameItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    playerNameItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(playerNameItem)
    playerNameItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    playerNameItem:SetTextAlignmentX(GUIItem.Align_Min)
    playerNameItem:SetTextAlignmentY(GUIItem.Align_Center)
    playerNameItem:SetPosition(Vector(
            playerItemChildX,
            0, 0) * GUIScoreboard.kScalingFactor)
    playerNameItem:SetColor(Color(1, 1, 1, 1))
    playerNameItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(playerNameItem)

    local currentColumnX = ConditionalValue(GUIScoreboard.screenWidth < 1280, GUIScoreboard.kPlayerItemWidth, self:GetTeamItemWidth() - GUIScoreboard.kTeamColumnSpacingX * 10)

    local playerSkillIcon = GUIManager:CreateGraphicItem()
    playerSkillIcon:SetSize(kPlayerSkillIconSize * GUIScoreboard.kScalingFactor)
    playerSkillIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    playerSkillIcon:SetPosition(Vector(currentColumnX, -kPlayerBadgeIconSize/2, 0) * GUIScoreboard.kScalingFactor)
    playerSkillIcon:SetStencilFunc(GUIItem.NotEqual)
    playerSkillIcon:SetTexture(kPlayerSkillIconTexture)
    playerSkillIcon:SetTexturePixelCoordinates(0, 0, 100, 31)
    playerItem:AddChild(playerSkillIcon)

    -- Status text item.
    local statusItem = GUIManager:CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    statusItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(statusItem)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    statusItem:SetTextAlignmentX(GUIItem.Align_Min)
    statusItem:SetTextAlignmentY(GUIItem.Align_Center)
    statusItem:SetPosition(Vector(currentColumnX + ConditionalValue(GUIScoreboard.screenWidth < 1280, 30, 60), 0, 0) * GUIScoreboard.kScalingFactor)
    statusItem:SetColor(Color(1, 1, 1, 1))
    statusItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(statusItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 2 + 35

    -- Score text item.
    local scoreItem = GUIManager:CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    scoreItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(scoreItem)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    scoreItem:SetTextAlignmentX(GUIItem.Align_Center)
    scoreItem:SetTextAlignmentY(GUIItem.Align_Center)
    scoreItem:SetPosition(Vector(currentColumnX + 30, 0, 0) * GUIScoreboard.kScalingFactor)
    scoreItem:SetColor(Color(1, 1, 1, 1))
    scoreItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(scoreItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX + 30

    -- Kill text item.
    local killsItem = GUIManager:CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    killsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(killsItem)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    killsItem:SetTextAlignmentX(GUIItem.Align_Center)
    killsItem:SetTextAlignmentY(GUIItem.Align_Center)
    killsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
    killsItem:SetColor(Color(1, 1, 1, 1))
    killsItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(killsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- assists text item.
    local assistsItem = GUIManager:CreateTextItem()
    assistsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    assistsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(assistsItem)
    assistsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    assistsItem:SetTextAlignmentX(GUIItem.Align_Center)
    assistsItem:SetTextAlignmentY(GUIItem.Align_Center)
    assistsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
    assistsItem:SetColor(Color(1, 1, 1, 1))
    assistsItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(assistsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Deaths text item.
    local deathsItem = GUIManager:CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    deathsItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(deathsItem)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    deathsItem:SetTextAlignmentX(GUIItem.Align_Center)
    deathsItem:SetTextAlignmentY(GUIItem.Align_Center)
    deathsItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
    deathsItem:SetColor(Color(1, 1, 1, 1))
    deathsItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(deathsItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Resources text item.
    local resItem = GUIManager:CreateTextItem()
    resItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    resItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(resItem)
    resItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    resItem:SetTextAlignmentX(GUIItem.Align_Center)
    resItem:SetTextAlignmentY(GUIItem.Align_Center)
    resItem:SetPosition(Vector(currentColumnX, 0, 0) * GUIScoreboard.kScalingFactor)
    resItem:SetColor(Color(1, 1, 1, 1))
    resItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(resItem)

    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX

    -- Ping text item.
    local pingItem = GUIManager:CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kPlayerStatsFontName)
    pingItem:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
    GUIMakeFontScale(pingItem)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    pingItem:SetTextAlignmentX(GUIItem.Align_Min)
    pingItem:SetTextAlignmentY(GUIItem.Align_Center)
    pingItem:SetPosition(Vector(currentColumnX - 2, 0, 0) * GUIScoreboard.kScalingFactor)
    pingItem:SetColor(Color(1, 1, 1, 1))
    pingItem:SetStencilFunc(GUIItem.NotEqual)
    playerItem:AddChild(pingItem)

    local playerTextIcon = GUIManager:CreateGraphicItem()
    playerTextIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
    playerTextIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    playerTextIcon:SetTexture(kMutedTextTexture)
    playerTextIcon:SetStencilFunc(GUIItem.NotEqual)
    playerTextIcon:SetIsVisible(false)
    playerTextIcon:SetColor(GUIScoreboard.kVoiceMuteColor)
    playerItem:AddChild(playerTextIcon)

    local steamFriendIcon = GUIManager:CreateGraphicItem()
    steamFriendIcon:SetSize(Vector(kPlayerVoiceChatIconSize, kPlayerVoiceChatIconSize, 0) * GUIScoreboard.kScalingFactor)
    steamFriendIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    steamFriendIcon:SetTexture("ui/steamfriend.dds")
    steamFriendIcon:SetStencilFunc(GUIItem.NotEqual)
    steamFriendIcon:SetIsVisible(false)
    steamFriendIcon.allowHighlight = true
    playerItem:AddChild(steamFriendIcon)

    local communityRankIcon = GUIManager:CreateGraphicItem()
    communityRankIcon:SetSize(kCommunityRankIconSize * GUIScoreboard.kScalingFactor)
    communityRankIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    communityRankIcon:SetStencilFunc(GUIItem.NotEqual)
    communityRankIcon:SetTexture(kCommunityRankIconTexture)
    communityRankIcon:SetTexturePixelCoordinates(0, 80, 80, 160)
    playerItem:AddChild(communityRankIcon)
    
    local communityPrewarmIcon = GUIManager:CreateGraphicItem()
    communityPrewarmIcon:SetSize(kCommunityRankIconSize * GUIScoreboard.kScalingFactor)
    communityPrewarmIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    communityPrewarmIcon:SetStencilFunc(GUIItem.NotEqual)
    communityPrewarmIcon:SetTexture(kCommunityRankIconTexture)
    communityPrewarmIcon:SetTexturePixelCoordinates(0, 80, 80, 160)
    playerItem:AddChild(communityPrewarmIcon)
    
    -- Let's do a table here to easily handle the highlighting/clicking of icons
    -- It also makes it easy for other mods to add icons afterwards
    local iconTable = {}
    table.insert(iconTable, communityPrewarmIcon)
    table.insert(iconTable, communityRankIcon)
    table.insert(iconTable, steamFriendIcon)
    table.insert(iconTable, playerVoiceIcon)
    table.insert(iconTable, playerTextIcon)

    return { Background = playerItem, Number = playerNumber, Name = playerNameItem,
             Voice = playerVoiceIcon, Status = statusItem, SkillIcon = playerSkillIcon, Score = scoreItem, Kills = killsItem,
             Assists = assistsItem, Deaths = deathsItem, Resources = resItem, Ping = pingItem,
             BadgeItems = badgeItems, Text = playerTextIcon,
             SteamFriend = steamFriendIcon, IconTable = iconTable , CommunityRankIcon = communityRankIcon , CommunityPrewarmIcon = communityPrewarmIcon,
    }

end

local function HandlePlayerVoiceClicked(self)
    if MouseTracker_GetIsVisible() then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        for t = 1, #self.teams do

            local playerList = self.teams[t]["PlayerList"]
            for p = 1, #playerList do

                local playerItem = playerList[p]
                if GUIItemContainsPoint(playerItem["Voice"], mouseX, mouseY) and playerItem["Voice"]:GetIsVisible() then

                    local clientIndex = playerItem["ClientIndex"]
                    ChatUI_SetClientMuted(clientIndex, not ChatUI_GetClientMuted(clientIndex))

                end

            end

        end
    end
end

local function HandlePlayerTextClicked(self)
    if MouseTracker_GetIsVisible() then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        for t = 1, #self.teams do

            local playerList = self.teams[t]["PlayerList"]
            for p = 1, #playerList do

                local playerItem = playerList[p]
                if GUIItemContainsPoint(playerItem["Text"], mouseX, mouseY) and playerItem["Text"]:GetIsVisible() then

                    local clientIndex = playerItem["ClientIndex"]
                    local steamId = GetSteamIdForClientIndex(clientIndex)
                    ChatUI_SetSteamIdTextMuted(steamId, not ChatUI_GetSteamIdTextMuted(steamId))

                end

            end

        end

        if self.favoriteButton and GUIItemContainsPoint(self.favoriteButton, mouseX, mouseY) then
            local serverIsFavorite = not self.favoriteButton.isServerFavorite
            self.favoriteButton:SetTexture(serverIsFavorite and self.kFavoriteTexture or self.kNotFavoriteTexture)
            self.favoriteButton.isServerFavorite = serverIsFavorite
            SetServerIsFavorite({address = self.serverAddress}, serverIsFavorite)

            if serverIsFavorite then
                self.blockedButton.isServerBlocked = false
                self.blockedButton:SetTexture(self.kNotBlockedTexture)
            end

        elseif self.blockedButton and GUIItemContainsPoint(self.blockedButton, mouseX, mouseY) then
            local serverIsBlocked = not self.blockedButton.isServerBlocked
            self.blockedButton:SetTexture(serverIsBlocked and self.kBlockedTexture or self.kNotBlockedTexture)
            self.blockedButton.isServerBlocked = serverIsBlocked
            SetServerIsBlocked({address = self.serverAddress}, serverIsBlocked)

            if serverIsBlocked then
                self.favoriteButton.isServerFavorite = false
                self.favoriteButton:SetTexture(self.kNotFavoriteTexture)
            end
        end

    end
end

function GUIScoreboard:SetIsVisible(state)

    self.hiddenOverride = not state

    -- Don't remove the deltatime parameter we use it to detect if the scoreboard get opened
    self:Update(0)

end

function GUIScoreboard:GetIsVisible()

    return not self.hiddenOverride

end

function GUIScoreboard:SendKeyEvent(key, down)

    if ChatUI_EnteringChatMessage() then
        return false
    end

    if GetIsBinding(key, "Scoreboard") then
        self.visible = down and not self.hiddenOverride
        if not self.visible then
            self.hoverMenu:Hide()
        else
            self.updateInterval = 0
        end
    end

    if not self.visible then
        return false
    end

    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down and down and not MainMenu_GetIsOpened() then
        HandlePlayerTextClicked(self)

        local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex) or 0
        if self.hoverMenu.background:GetIsVisible() then
            return false
            -- Display the menu for bots if dev mode is on (steamId is 0 but they have a proper clientIndex)
        elseif steamId ~= 0 or self.hoverPlayerClientIndex ~= 0 and Shared.GetDevMode() then
            local isTextMuted = ChatUI_GetSteamIdTextMuted(steamId)
            local isVoiceMuted = ChatUI_GetClientMuted(self.hoverPlayerClientIndex)
            local function openSteamProf()
                Client.ShowWebpage(string.format("%s[U:1:%s]", kSteamProfileURL, steamId))
            end
            local function muteText()
                ChatUI_SetSteamIdTextMuted(steamId, not isTextMuted)
            end
            local function muteVoice()
                ChatUI_SetClientMuted(self.hoverPlayerClientIndex, not isVoiceMuted)
            end

            self.hoverMenu:ResetButtons()

            local teamColorBg
            local teamColorHighlight
            local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
            local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
            local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander") and GetIsVisibleTeam(teamNumber)

            local textColor = Color(1, 1, 1, 1)
            local nameBgColor = Color(0, 0, 0, 0)

            if isCommander then
                teamColorBg = GUIScoreboard.kCommanderFontColor
            elseif teamNumber == 1 then
                teamColorBg = GUIScoreboard.kBlueColor
            elseif teamNumber == 2 then
                teamColorBg = GUIScoreboard.kRedColor
            else
                teamColorBg = GUIScoreboard.kSpectatorColor
            end

            local bgColor = teamColorBg * 0.1
            bgColor.a = 0.9

            teamColorHighlight = teamColorBg * 0.75
            teamColorBg = teamColorBg * 0.5

            self.hoverMenu:SetBackgroundColor(bgColor)
            self.hoverMenu:AddButton(playerName, nameBgColor, nameBgColor, textColor)
            self.hoverMenu:AddButton(Locale.ResolveString("SB_MENU_STEAM_PROFILE"), teamColorBg, teamColorHighlight, textColor, openSteamProf)

            if Client.GetSteamId() ~= steamId then
                self.hoverMenu:AddSeparator("muteOptions")
                self.hoverMenu:AddButton(ConditionalValue(isVoiceMuted, Locale.ResolveString("SB_MENU_UNMUTE_VOICE"), Locale.ResolveString("SB_MENU_MUTE_VOICE")), teamColorBg, teamColorHighlight, textColor, muteVoice)
                self.hoverMenu:AddButton(ConditionalValue(isTextMuted, Locale.ResolveString("SB_MENU_UNMUTE_TEXT"), Locale.ResolveString("SB_MENU_MUTE_TEXT")), teamColorBg, teamColorHighlight, textColor, muteText)
            end

            self.hoverMenu:Show()
            self.badgeNameTooltip:Hide(0)
        end
    end

    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then

        self.mousePressed["LMB"]["Down"] = down
        if down then
            local mouseX, mouseY = Client.GetCursorPosScreen()
            self.isDragging = GUIItemContainsPoint(self.slidebarBg, mouseX, mouseY)

            if not MouseTracker_GetIsVisible() then
                SetMouseVisible(self, true)
            else
                HandlePlayerVoiceClicked(self)
            end

            return true
        end
    end

    if self.slidebarBg:GetIsVisible() then
        if key == InputKey.MouseWheelDown then
            self.slidePercentage = math.min(self.slidePercentage + 5, 100)
            return true
        elseif key == InputKey.MouseWheelUp then
            self.slidePercentage = math.max(self.slidePercentage - 5, 0)
            return true
        elseif key == InputKey.PageDown and down then
            self.slidePercentage = math.min(self.slidePercentage + 10, 100)
            return true
        elseif key == InputKey.PageUp and down then
            self.slidePercentage = math.max(self.slidePercentage - 10, 0)
            return true
        elseif key == InputKey.Home then
            self.slidePercentage = 0
            return true
        elseif key == InputKey.End then
            self.slidePercentage = 100
            return true
        end
    end

end
