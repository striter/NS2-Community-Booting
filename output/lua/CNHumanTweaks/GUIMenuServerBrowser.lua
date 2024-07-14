-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/NavBar/Screens/ServerBrowser/GUIMenuServerBrowser.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Entire server browser screen: the settings at the top, the column names, and the list of
--    entries.
--
--  Events
--      OnRefreshFinished       Fires when the server browser finishes refreshing the server list.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

-- Load this script then immediately call the load function.  This function is called here rather
-- than inside the script file so that mods can have a chance to hook into
-- "LoadServerBrowserColumns" to load their own columns, if they wish.
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/ServerBrowserColumns.lua")
LoadServerBrowserColumns()

Script.Load("lua/menu2/NavBar/Screens/GUIMenuNavBarScreen.lua")
Script.Load("lua/menu2/GUIMenuTabbedBox.lua")
Script.Load("lua/menu2/popup/GUIMenuPopupSimpleMessage.lua")
Script.Load("lua/menu2/popup/GUIMenuPopupDoNotShowAgainMessage.lua")
Script.Load("lua/menu2/popup/GUIMenuPasswordDialog.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBGameModeFilters.lua")
Script.Load("lua/GUI/layouts/GUIFillLayout.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBListLayout.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBTopButtonGroupBackground.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBPlayerCountWidget.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBTextButton.lua")
Script.Load("lua/menu2/widgets/GUIMenuTabButtonsWidget.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/FilterWindow/GMSBFilterWindow.lua")
Script.Load("lua/IterableDict.lua")
Script.Load("lua/OrderedIterableDict.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/ServerBrowserUtils.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/ServerBrowserFunctions.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBEntry.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")
Script.Load("lua/GUI/GUIGlobalEventDispatcher.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBRefreshButton.lua")

Script.Load("lua/menu2/wrappers/Expandable.lua")

---@class GUIMenuServerBrowser : GUIMenuNavBarScreen
class "GUIMenuServerBrowser" (GUIMenuNavBarScreen)

-- DEBUG STUFF
-- Leaving it here for now... not really hurting anything by being here.
local spoofFull = false
local spoofSpecFull = false
local spoofReservedFull = false
Event.Hook("Console_spoof_full", function(value)
    if value == nil then
        spoofFull = not spoofFull
    else
        spoofFull = value == true
    end
    Log("spoofFull set to %s", spoofFull)
end)
Event.Hook("Console_spoof_spec_full", function(value)
    if value == nil then
        spoofSpecFull = not spoofSpecFull
    else
        spoofSpecFull = value == true
    end
    Log("spoofSpecFull set to %s", spoofSpecFull)
end)
Event.Hook("Console_spoof_reserved_full", function(value)
    if value == nil then
        spoofReservedFull = not spoofReservedFull
    else
        spoofReservedFull = value == true
    end
    Log("spoofReservedFull set to %s", spoofReservedFull)
end)

local kSortFunctionNameOptionName = "server-browser/sort-function-name"

GUIMenuServerBrowser.NoEntry = ReadOnly{"GUIMenuServerBrowser.NoEntry"}

-- Set of addresses that the user has blacklisted from themselves.
-- Mapping of address string --> true.
GUIMenuServerBrowser:AddClassProperty("Blocked", {}, true)

-- Set of addresses that the user has marked as their favorite servers.
-- Mapping of address string --> true.
GUIMenuServerBrowser:AddClassProperty("Favorites", {}, true)

-- Set of addresses of ranked servers.
-- Mapping of address string --> true.
GUIMenuServerBrowser:AddClassProperty("WhiteList", {}, true)

-- Mapping of server address --> server info table (not entry) of servers that once existed (and
-- quite possibly still do exist), that the user once visited.  The set is ordered from oldest to
-- newest.
GUIMenuServerBrowser:AddClassProperty("History", OrderedIterableDict(), true)
kHistoryMax = 10 -- max 10 entries in history.

-- The currently selected server entry, or GUIMenuServerBrowser.NoEntry if none selected.
GUIMenuServerBrowser:AddClassProperty("SelectedEntry", GUIMenuServerBrowser.NoEntry, true)

-- Mapping of server address -> server entry.
GUIMenuServerBrowser:AddClassProperty("ServerSet", IterableDict(), true)

-- Set of server addresses that were received by the latest Steam query.
GUIMenuServerBrowser:AddClassProperty("ActiveAddressesSet", {}, true)

-- The user's preferred sorting method.
GUIMenuServerBrowser:AddClassProperty("SortFunction", ServerBrowserSortFunctions.QuickPlayRank)

-- What set of server entries are being viewed (can be "default", "favorites", or "history")
GUIMenuServerBrowser:AddClassProperty("CurrentView", "default")

-- Singleton accessor.  Does not create server browser if it doesn't already exist, so keep in mind
-- that it can return nil.
local serverBrowser
function GetServerBrowser()
    return serverBrowser
end

local kRefreshButtonScale = 0.6

local kScreenBottomDistance = 250
local kScreenWidth = 2800
local kTabMinWidth = 900
local kTabHeight = 94
local kInnerBackgroundSideSpacing = 32 -- horizontal spacing between edge of outer background and inner background.
local kInnerBackgroundTopSpacing = 280 -- spacing between top edge of outer background and inner background.
local kInnerBackgroundBottomSpacing = 16

local kTopButtonsWidth = 847
local kTopButtonsHeight = 84
local kTopButtonsGlowTexture = PrecacheAsset("ui/newMenu/server_browser/view_mode_glow.dds")

local kSecondRowHeight = kInnerBackgroundTopSpacing - GUIMenuNavBar.kUnderlapYSize - kTopButtonsHeight
local kSecondRowRightSideStuffSpacing = 30

local kColumnHeadersHeight = 74
GUIMenuServerBrowser.kColumnHeadersSpacing = 10

local kJoinGlowTexture = PrecacheAsset("ui/newMenu/server_browser/join_glow.dds")
local kJoinGlowCornerXOffset = 110

local kRefreshingArrowsTexture = PrecacheAsset("ui/newMenu/refreshing_arrows.dds")
local kDimmerColor = Color(0, 0, 0, 0.5)
local kArrowSpinSpeed = -360 * (math.pi / 180.0) -- radians/sec
local kArrowAnimation = ReadOnly
{
    func = function(obj, time, params, currentValue, startValue, endValue, startTime)
        return time * kArrowSpinSpeed, false
    end
}

local kUpdateSelectedServerInterval = 1.0
local kUpdateSelectedServerDetailsInterval = 2.0
local kUpdateMiscStuffInterval = 1.0
local kRefreshRequestExpireTime = 5.0
local kEmptyPlayerScoresGracePeriod = 15 -- ignore 15 empty tables before accepting server is empty.
local kMaxNewServerEntriesPerUpdate = 1 -- amortize this cost over time.

local function UpdateInnerBackgroundSize(self, coolBackSize)
    self.innerBack:SetSize(coolBackSize - Vector(kInnerBackgroundSideSpacing * 2, kInnerBackgroundBottomSpacing + kInnerBackgroundTopSpacing + kTabHeight, 0))
end

local function OnServerBrowserSizeChanged(self, size, prevSize)
    
    -- Make the outer background the same size as this object.
    self.coolBack:SetSize(self:GetSize() + Vector(0, GUIMenuNavBar.kUnderlapYSize, 0))
    self.innerBack:SetSize(self:GetSize() + Vector(-kInnerBackgroundSideSpacing * 2, GUIMenuNavBar.kUnderlapYSize - kInnerBackgroundTopSpacing - kInnerBackgroundBottomSpacing - kTabHeight, 0))
    self.topButtonsHolder:SetSize(self:GetSize().x, self.topButtonsHolder:GetSize().y)
    self.secondRowHolder:SetSize(self.innerBack:GetSize().x, self.secondRowHolder:GetSize().y)
    self.columnHeadersLayout:SetSize(self.innerBack:GetSize().x, kColumnHeadersHeight)
    self.scrollPane:SetSize(self.innerBack:GetSize().x, self.innerBack:GetSize().y - kColumnHeadersHeight)
    --self.dimmer:SetSize(self.innerBack:GetSize())
    
    -- Update the widths of the server entries.
    local entryWidth = self.scrollPane:GetSize().x - self.scrollPane:GetScrollBarThickness()
    for i=1, #self.serverEntries do
        
        local entry = self.serverEntries[i]
        entry:SetSize(entryWidth, entry:GetSize().y)
        
    end
    
end

local function RecomputeServerBrowserHeight(self)
    
    -- Resize this object to leave a consistent spacing to the bottom of the screen.
    local aScale = self.absoluteScale
    local ssSpacing = kScreenBottomDistance * aScale.y
    local ssBottomY = Client.GetScreenHeight() - ssSpacing
    local ssTopY = self:GetParent():GetScreenPosition().y
    local ssSizeY = ssBottomY - ssTopY
    local localSizeY = ssSizeY / aScale.y
    self:SetSize(kScreenWidth, localSizeY)
    
end

local function OnAbsoluteScaleChanged(self, aScale)
    
    self.absoluteScale = aScale
    RecomputeServerBrowserHeight(self)
    
end

local function CreateColumnHeader(self, columnDef)
    
    local newHeader = CreateGUIObject("columnHeader"..columnDef.name, columnDef.headingClass, self.columnHeadersLayout,
    {
        weight = columnDef.weight,
    })
    newHeader:AlignLeft()
    
    -- Create a dark background behind the header item.
    local newBack = CreateGUIObject("columnHeader"..columnDef.name.."Background", GUIMenuBasicBox, newHeader)
    newBack:SetFillColor(MenuStyle.kServerBrowserHeaderColumnBoxFillColor)
    newBack:SetStrokeColor(MenuStyle.kServerBrowserHeaderColumnBoxStrokeColor)
    newBack:HookEvent(newHeader, "OnSizeChanged", newBack.SetSize)
    
    newHeader:SetSize(newHeader:GetSize().x, self.columnHeadersLayout:GetSize().y)
    
end

local function SetupColumnHeaders(self)
    
    local columnTypeDefs = GetSortedColumnTypeDefs()
    for i=1, #columnTypeDefs do
        CreateColumnHeader(self, columnTypeDefs[i])
    end
    
end

local function CreateTopLeftButtons(self)
    
    self.topLeftGroupBack = CreateGUIObject("topLeftGroupBack", GMSBTopButtonGroupBackground, self.topButtonsHolder)
    self.topLeftGroupBack:AlignLeft()
    self.topLeftGroupBack:SetPoints(
    {
        Vector(0, 0, 0),
        Vector(0, kTopButtonsHeight, 0),
        Vector(kTopButtonsWidth, kTopButtonsHeight, 0),
        Vector(kTopButtonsWidth + kTopButtonsHeight, 0, 0),
    })
    
    self.topLeftGroupLayout = CreateGUIObject("topLeftGroupLayout", GUIFlexLayout, self.topLeftGroupBack, {orientation="horizontal"})
    self.topLeftGroupLayout:SetFixedMinorSize(true)
    self.topLeftGroupLayout:SetSize(self.topLeftGroupBack:GetSize().x - self.topLeftGroupBack:GetSize().y, self.topLeftGroupBack:GetSize().y)
    
    self.quickPlayButton = CreateGUIObject("quickPlayButton", GUIMenuSimpleTextButton, self.topLeftGroupLayout,
    {
        defaultColor = MenuStyle.kOptionHeadingColor,
    })
    self.quickPlayButton:SetLabel(Locale.ResolveString("PLAY_MENU_QUICK_PLAY"))
    self.quickPlayButton:SetFont(MenuStyle.kHeadingFont)
    self.quickPlayButton:AlignLeft()
    self:HookEvent(self.quickPlayButton, "OnPressed", function()
        DoQuickJoin()
    end)
    
end

local function CreateTopRightButtons(self)
    
    self.topRightGroupBack = CreateGUIObject("topRightGroupBack", GMSBTopButtonGroupBackground, self.topButtonsHolder)
    self.topRightGroupBack:SetAnchor(1, 0.5)
    self.topRightGroupBack:SetHotSpot(0, 0.5)
    self.topRightGroupBack:SetPoints(
    {
        Vector(-kTopButtonsWidth - kTopButtonsHeight, 0, 0),
        Vector(-kTopButtonsWidth, kTopButtonsHeight, 0),
        Vector(0, kTopButtonsHeight, 0),
        Vector(0, 0, 0),
    })
    
    self.topRightGroupLayout = CreateGUIObject("topRightGroupLayout", GUIFlexLayout, self.topRightGroupBack, {orientation="horizontal"})
    self.topRightGroupLayout:SetFixedMinorSize(true)
    self.topRightGroupLayout:SetSize(self.topRightGroupBack:GetSize().x - self.topRightGroupBack:GetSize().y, self.topRightGroupBack:GetSize().y)
    self.topRightGroupLayout:AlignRight()
    
    self.favoritesButton = CreateGUIObject("favoritesButton", GUIMenuSimpleTextButton, self.topRightGroupLayout,
    {
        defaultColor = MenuStyle.kOptionHeadingColor,
    })
    self.favoritesButton:SetLabel(string.upper(Locale.ResolveString("FAVORITES")))
    self.favoritesButton:SetFont(MenuStyle.kHeadingFont)
    self.favoritesButton:AlignLeft()
    self:HookEvent(self.favoritesButton, "OnPressed",
        function(self)
            if self:GetCurrentView() == "favorites" then
                self:SetCurrentView("default")
            else
                self:SetCurrentView("favorites")
            end
        end)
    
    self.historyButton = CreateGUIObject("historyButton", GUIMenuSimpleTextButton, self.topRightGroupLayout,
    {
        defaultColor = MenuStyle.kOptionHeadingColor,
    })
    self.historyButton:SetLabel(string.upper(Locale.ResolveString("HISTORY")))
    self.historyButton:SetFont(MenuStyle.kHeadingFont)
    self.historyButton:AlignLeft()
    self:HookEvent(self.historyButton, "OnPressed",
        function(self)
            if self:GetCurrentView() == "history" then
                self:SetCurrentView("default")
            else
                self:SetCurrentView("history")
            end
        end)
    
    self.favoritesButtonGlow = CreateGUIObject("favoritesButtonGlow", GUIObject, self.favoritesButton)
    self.favoritesButtonGlow:SetTexture(kTopButtonsGlowTexture)
    self.favoritesButtonGlow:SetSize(self.favoritesButton:GetSize().x, self.topRightGroupLayout:GetSize().y)
    self.favoritesButtonGlow:AlignCenter()
    self.favoritesButtonGlow:SetLayer(-1)
    self.favoritesButtonGlow:SetScale(1.5, 1)
    self.favoritesButtonGlow:HookEvent(self, "OnCurrentViewChanged",
        function(btnGlow, currentView)
            local goalOpacity = currentView == "favorites" and 1 or 0
            btnGlow:AnimateProperty("Color", Color(1, 1, 1, goalOpacity), MenuAnimations.Fade)
        end)
    
    self.historyButtonGlow = CreateGUIObject("historyButtonGlow", GUIObject, self.historyButton)
    self.historyButtonGlow:SetTexture(kTopButtonsGlowTexture)
    self.historyButtonGlow:SetSize(self.historyButton:GetSize().x, self.topRightGroupLayout:GetSize().y)
    self.historyButtonGlow:AlignCenter()
    self.historyButtonGlow:SetLayer(-1)
    self.historyButtonGlow:SetScale(1.5, 1)
    self.historyButtonGlow:HookEvent(self, "OnCurrentViewChanged",
        function(btnGlow, currentView)
            local goalOpacity = currentView == "history" and 1 or 0
            btnGlow:AnimateProperty("Color", Color(1, 1, 1, goalOpacity), MenuAnimations.Fade)
        end)
    
end

function GUIMenuServerBrowser:CloseFilterWindow()
    
    if not self.filtersWindow then
        return -- already closed.
    end
    
    self.filtersWindow:Close()
    
end

local function OnFilterWindowClosed(self)
    
    self.filtersWindow = nil
    self.filtersButton:SetEnabled(true)
    
end

local function OnFiltersButtonPressed(self)
    
    if self.filtersWindow then
        return -- filters window already open.
    end
    
    self.filtersButton:SetEnabled(false)
    
    self.filtersWindow = CreateGUIObject("filtersWindow", GMSBFilterWindow, GetMainMenu())
    self:HookEvent(self.filtersWindow, "OnClosed", OnFilterWindowClosed)
    
end

local function OnServerEntryDestroyed(self, entry)
    self.serverEntries:RemoveElement(entry)
    self.entriesAwaitingModNames:RemoveElement(entry)
end

local function OnServerEntryFavoritedChanged(entry, favorited)
    local self = GetServerBrowser()
    local address = entry:GetAddress()
    local favoritesSet = self:GetFavorites()
    
    if favorited then
        favoritesSet[address] = true
    else
        favoritesSet[address] = nil
    end
    
    self:SetFavorites(favoritesSet)
end

local function OnServerEntryBlockedChanged(entry, blocked)
    local self = GetServerBrowser()
    local address = entry:GetAddress()
    local blockedSet = self:GetBlocked()
    
    if blocked then
        blockedSet[address] = true
    else
        blockedSet[address] = nil
    end
    
    self:SetBlocked(blockedSet)
end

local function OnEntryFilteredOutChanged(entry, filteredOut)
    entry:SetExpanded(not filteredOut)
end

local function SortByRanking(a, b)
    return a:GetRanking() > b:GetRanking()
end

local function UpdateQuickPlayRankIndexes(self)
    
    local entriesToSort = {}
    for i=1, #self.serverEntries do
        table.insert(entriesToSort, self.serverEntries[i])
    end
    
    table.sort(entriesToSort, SortByRanking)
    
    for i=1, #entriesToSort do
        entriesToSort[i]:SetQuickPlayRankIndex(i)
    end
    
end

local function OnEntryRankingChanged(self)
    -- Defer this callback, since it's expensive (sorting involved) and a LOT of things can trigger
    -- it.  This means the layout sorting update might then be 1 frame off, but that's fine.
    self:EnqueueDeferredUniqueCallback(UpdateQuickPlayRankIndexes)
end

-- Creates a new, blank server entry.
local function CreateNewServerEntry(self, address)
    
    assert(address)
    
    local entry = CreateGUIObject("serverEntry", GetExpandableWrappedClass(GMSBEntry), self.listLayout,
    {
        address = address,
        expansionMargin = 2.0,
    })
    
    -- Start un-expanded.
    entry:SetExpanded(false)
    entry:ClearPropertyAnimations("Expansion")
    
    -- Make entry hide itself when filtered out.
    entry:HookEvent(entry, "OnFilteredOutChanged", OnEntryFilteredOutChanged)
    entry:SetSize(self.scrollPane:GetSize().x - self.scrollPane:GetScrollBarThickness(), entry:GetSize().y)
    
    -- When entry's Ranking property changes (quick play rating), the list needs to be re-sorted to
    -- compute all entries' QuickPlayRankIndex value.
    self:HookEvent(entry, "OnRankingChanged", OnEntryRankingChanged)
    
    -- Add to server set.  This set is all server entries that are _not_ being destroyed.
    local serverSet = self:GetServerSet()
    assert(serverSet[address] == nil)
    serverSet[address] = entry
    self:SetServerSet(serverSet)
    
    -- Add to a different server set.  This set is _ALL_ server entries, including those that are
    -- being destroyed.  This ensures we can still sort them properly while they are animating
    -- away.
    self.serverEntries:Add(entry)
    self:HookEvent(entry, "OnDestroy", OnServerEntryDestroyed)
    
    -- Hook into some events sent by this entry to update the server browser state.
    entry:HookEvent(entry, "OnFavoritedChanged", OnServerEntryFavoritedChanged)
    entry:HookEvent(entry, "OnBlockedChanged", OnServerEntryBlockedChanged)
    
    return entry
    
end

local function SplitModsString(str)
    
    if #str == 0 then
        return {}
    end
    
    local result = {}
    local index = 1
    while index < #str do
        
        local foundIndex = string.find(str, " ", index, true)
        if not foundIndex then
            table.insert(result, string.sub(str, index, #str)) -- add last mod id, which won't have a space after it.
            break
        end
        
        table.insert(result, string.sub(str, index, foundIndex - 1))
        index = foundIndex + 1
        
    end
    
    return result
    
end

local function ModDetailsCallback(results)

    local self = GetServerBrowser()
    local pendingModNames = self.pendingModNames

    for i, mod in ipairs(results) do
        local modIdStr = string.format("%x", mod.id)
        assert(pendingModNames[modIdStr] ~= nil)
        pendingModNames[modIdStr] = nil

        local modNameLookup = self.modNameLookup
        assert(modNameLookup[modIdStr] == nil)
        modNameLookup[modIdStr] = mod.title
    end

    self:_OnModsNameLookupUpdated()
    
end

-- Attempts to convert the string of mod ids (listed in a single space-delimited string) to a table
-- of mod names.  This will fail if the server browser doesn't know the mapping from mod id to mod
-- name -- it will need to be requested.  The server entry is then added to a set of entries
-- awaiting an updated list of mod names.  In the mean time, the mod id is used in place of the
-- name.


local function SetEntryModsListFromModsString(self, entry, modsString)
    
    local modIds = SplitModsString(modsString)
    
    local modNames = {}
    local requestedModNames = {}
    for i=1, #modIds do

        local currentModIdStr = modIds[i]

        local modName = self.modNameLookup[currentModIdStr]
        if modName == nil then
            
            -- As a temporary measure, use the mod id as the mod name until we get a better name.
            modName = currentModIdStr
            
            self.entriesAwaitingModNames:Add(entry)
            entry.tempModsString = modsString

            if self.pendingModNames[currentModIdStr] == nil then
                self.pendingModNames[currentModIdStr] = true
                table.insert(requestedModNames, currentModIdStr)
            end
        end
        
        table.insert(modNames, modName)
        
    end


    if #requestedModNames > 0 then
        Client.GetModDetails(requestedModNames, ModDetailsCallback)
    end
    
    return modNames,modIds
end

function GUIMenuServerBrowser:_OnModsNameLookupUpdated()
    
    -- Make a copy of the current entry list, so we can iterate over it without worrying about it
    -- changing.
    local entryList = {}
    for i=1, #self.entriesAwaitingModNames do
        table.insert(entryList, self.entriesAwaitingModNames[i])
    end
    
    for i=1, #entryList do
        local entry = entryList[i]
        self.entriesAwaitingModNames:RemoveElement(entry)
        if entry.tempModsString then
            SetEntryModsListFromModsString(self, entry, entry.tempModsString)
        end
    end
    
end

local function FormatGameMode(gameMode , maxPlayers)

    PROFILE("GUIMenuServerBrowser:FormatGameMode")

    gameMode = gameMode:sub(0, 20)
    if gameMode == "ns2" and maxPlayers > 24 then gameMode = "ns2Large" end
    return gameMode

end

local function UpdateServerInfoFromClientData(self, serverEntry, serverIndex)
    
    local maxPlayers = Client.GetServerMaxPlayers(serverIndex)
    local ranked = Client.GetServerIsRanked(serverIndex)
    local name = serverEntry:GetServerName()
    local gameMode = FormatGameMode(Client.GetServerGameMode(serverIndex),maxPlayers)
    serverEntry:SetCustomNetworkSettings(GetServerHasCustomNetVars(serverIndex))
    serverEntry:SetExists(true)
    serverEntry:SetFriendsOnServer(Client.GetServerContainsFriends(serverIndex))
    serverEntry:SetIndex(serverIndex)
    serverEntry:SetMapName(GetTrimmedMapName(Client.GetServerMapName(serverIndex)))
    serverEntry:SetModded(Client.GetServerIsModded(serverIndex))
    
    if string.find(name,"CN#") then
        ranked = true
        if (gameMode == "ns2Large" or gameMode == "ns2")  then
            if string.find(name,"<PvP") or string.find(name,"<PvE") then
                gameMode = "ns2.0"
            end
        end
    end
    
    local modNames,modIds = SetEntryModsListFromModsString(self, serverEntry, Client.GetServerKeyValue(serverIndex, "mods"))
    serverEntry:SetModsList(modNames)
    serverEntry:SetGameMode(gameMode)
    serverEntry:SetPassworded(Client.GetServerRequiresPassword(serverIndex))
    serverEntry:SetPerformanceQuality(Client.GetServerPerformanceQuality(serverIndex))
    serverEntry:SetPerformanceScore(Client.GetServerPerformanceScore(serverIndex))
    serverEntry:SetPing(Client.GetServerPing(serverIndex))
    serverEntry:SetPlayerCount(Client.GetServerNumPlayers(serverIndex))
    serverEntry:SetPlayerMax(maxPlayers)
    serverEntry:SetQuickPlayReady(Client.GetServerIsQuickPlayReady(serverIndex))
    serverEntry:SetReservedSlotCount(Client.GetServerNumReservedSlots(serverIndex))
    serverEntry:SetRookieOnly(Client.GetServerHasTag(serverIndex, "rookie_only"))
    serverEntry:SetServerName(Client.GetServerName(serverIndex))
    serverEntry:SetSkill(Client.GetServerAvgPlayerSkill(serverIndex))
    serverEntry:SetSpectatorCount(Client.GetServerNumSpectators(serverIndex))
    serverEntry:SetSpectatorMax(Client.GetServerMaxSpectators(serverIndex))
    serverEntry:SetRanked(ranked)

    local playersInfo = {}
    Client.GetServerPlayerDetails(serverIndex, playersInfo)
    
    -- Occasionally, we'll receive an empty table even though the server is full.  Ignore X number
    -- of empty tables before accepting that it might actually be empty.
    if #playersInfo == 0 then
        if serverEntry.playerScoresGracePeriod == nil then
            serverEntry.playerScoresGracePeriod = kEmptyPlayerScoresGracePeriod
        else
            serverEntry.playerScoresGracePeriod = serverEntry.playerScoresGracePeriod - 1
        end
    end
    
    if #playersInfo ~= 0 or serverEntry.playerScoresGracePeriod <= 0 then
        serverEntry:SetPlayerScores(playersInfo)
        serverEntry.playerScoresGracePeriod = nil
    end
    
end

local function UpdateServerInfoFromHistoryData(self, serverEntry, historyEntry)
    
    serverEntry:SetHistorical(true)
    serverEntry:SetLastConnect(historyEntry.lastConnect or 0)
    serverEntry:SetPassworded(historyEntry.requiresPassword == true)
    serverEntry:SetPlayerMax(historyEntry.maxPlayers or -1)
    serverEntry:SetRanked(historyEntry.ranked == true)
    serverEntry:SetRookieOnly(historyEntry.rookieOnly == true)
    serverEntry:SetServerName(historyEntry.name or "Unknown")
    serverEntry:SetSkill(historyEntry.playerSkill or 0)
    serverEntry:SetSpectatorMax(historyEntry.maxSpectators or 0)
    
end

local function LoadAddressSet(fileName)
    
    local loaded = LoadConfigFile(fileName)
    if not loaded then
        return {}
    end
    
    -- Build a set of addresses, keeping in mind the old format was a list of server entries, while
    -- the new format is just a set of address strings.
    local set
    
    if #loaded > 0 then -- old format detected!  Convert it.
        set = {}
        for i=1, #loaded do
            if loaded[i].address then
                set[loaded[i].address] = true
            end
        end
    else
        set = loaded
    end
    
    return set
    
end

local function SaveHistory(self)
    
    -- Convert from ordered iterable dict to something more json friendly.
    local historyDict = self:GetHistory()
    local historyList = {}
    for key, value in pairs(historyDict) do -- jit-safe pairs.
        table.insert(historyList, value)
    end
    
    SaveConfigFile(kHistoryFileName, historyList)
    
end

local function IsHistoryDataValid(historyData)
    
    if not historyData.lastConnect then
        return false
    end
    
    return true
    
end

-- Remove invalid entries from the history set.
local function CleanHistory(historyDict)
    
    local invalid = {}
    for address, hist in pairs(historyDict) do
        if not IsHistoryDataValid(hist) then
            table.insert(invalid, address)
        end
    end
    
    for i=1, #invalid do
        local address = invalid[i]
        historyDict[address] = nil
    end
    
end

local function LoadHistory(self)
    
    -- Convert from plain old table array to an ordered iterable dict, with server address as the
    -- keys.
    local history = LoadConfigFile(kHistoryFileName)
    
    if not history or #history == 0 then
        return
    end
    
    local historyDict = OrderedIterableDict()
    for i=1, #history do
        local entry = history[i]
        if entry.address then
            historyDict[entry.address] = entry
        end
    end
    
    CleanHistory(historyDict)
    self:SetHistory(historyDict)
    
    -- Create server entries for historical servers that do not already exist.
    local serverSet = self:GetServerSet()
    for address, historyEntry in pairs(historyDict) do -- JIT-safe pairs usage.
        
        local serverEntry = serverSet[address]
        if not serverEntry then
            serverEntry = CreateNewServerEntry(self, address)
        end
        
        UpdateServerInfoFromHistoryData(self, serverEntry, historyEntry)
    end
    
end

local function SaveFavorites(self)
    SaveConfigFile(kFavoritesFileName, self:GetFavorites())
end

local function LoadFavorites(self)
    local favoritesSet = LoadAddressSet(kFavoritesFileName)
    self:SetFavorites(favoritesSet)
end

local function SaveWhiteList(self)
    SaveConfigFile(kRankedFileName, self:GetWhiteList())
end

local function LoadWhiteList(self)
    
    -- Load a cached version from disk.
    local cachedWhiteList = LoadAddressSet(kRankedFileName)
    self:SetWhiteList(cachedWhiteList)
    
    -- Request up-to-date whitelist from hive.
    Shared.SendHTTPRequest(kHiveWhitelistRequestUrl, "GET", {},
        function(data)
            
            local obj, pos, err = json.decode(data)
            if obj then
                local whiteList = {}
                for _, entry in ipairs(obj) do
                    local address = string.format("%s:%s", entry.ip, entry.port)
                    whiteList[address] = true
                end
                
                self:SetWhiteList(whiteList)
                SaveWhiteList(self)
                
            end
            
        end)
        
end

local function SaveBlackList(self)
    SaveConfigFile(kBlockedFileName, self:GetBlocked())
end

local function LoadBlackList(self)
    local blockedSet = LoadAddressSet(kBlockedFileName)
    self:SetBlocked(blockedSet)
end

local function GetShouldEntryBeFilteredOut(self, entry)
    
    PROFILE("GUIMenuServerBrowser GetShouldEntryBeFilteredOut()")
    
    local currentView = self:GetCurrentView()
    
    -- Show only historical servers when history view is active -- ignoring all other filters.
    if currentView == "history" then
        return not entry:GetHistorical()
    
    -- Never show non-existent servers when history view is not active.
    elseif not entry:GetExists() then
        return true
    
    -- Show only favorited servers when favorites view is active -- ignoring all other filters.
    elseif currentView == "favorites" then
        return not entry:GetFavorited()
    
    -- Show only blocked servers when blocked view is active -- ignoring all other filters.
    elseif currentView == "blocked" then
        return not entry:GetBlocked()
    
    end
    
    -- Run against the filter-window filters first.
    for filterName, filter in pairs(self.filterData) do -- JIT-safe pairs.
        
        local filterFunc = filter.func
        local filterValue = filter.value
        
        if not filterFunc(entry, filterValue) then
            return true
        end
        
    end
    
    -- Run against the game-mode filters.
    if not self.filterWidget:GetSelectedModes():Contains(entry:GetGameMode()) then
        return true
    end
    
    return false
    
end

local function RunEntryAgainstFilters(self, entry)
    
    PROFILE("GUIMenuServerBrowser RunEntryAgainstFilters()")
    
    local filteredOut = GetShouldEntryBeFilteredOut(self, entry)
    entry:SetFilteredOut(filteredOut)
    
    -- Deselect this entry if it is filtered out and selected.
    if entry:GetFilteredOut() and entry:GetSelected() then
        self:SetSelectedEntry(nil)
    end
    
end

local function FilterAndSortServers(self)
    
    PROFILE("GUIMenuServerBrowser FilterAndSortServers()")
    
    local serverSet = self:GetServerSet()
    
    -- Pause layout updates for the moment...
    self.listLayout:SetAutoArrange(false)
    
    -- Test all servers against the current list of filters.
    for __, entry in pairs(serverSet) do -- JIT-safe pairs!
        RunEntryAgainstFilters(self, entry)
    end
    
    -- Build an array of server entries, including entries being destroyed.
    local serverList = {}
    for i=1, #self.serverEntries do
        local entry = self.serverEntries[i]
        table.insert(serverList, entry)
    end
    
    -- Sort the array.
    table.sort(serverList, self:GetSortFunction())
    
    -- Assign layer numbers to dictate the ordering to the layout.
    for i=1, #serverList do
        serverList[i]:SetLayer(i)
    end
    
    -- Resume layout updates for the moment...
    self.listLayout:SetAutoArrange(true)
    
end

local function OnFavoritesChanged(self)
    
    SaveFavorites(self)
    
    FilterAndSortServers(self)
    
end

local function OnHistoryChanged(self)
    
    SaveHistory(self)
    
    FilterAndSortServers(self)
    
end

local function OnBlockedChanged(self)
    
    SaveBlackList(self)
    
    FilterAndSortServers(self)
    
end

local function OnSortFunctionChanged(self)
    
    local name = self:GetSortFunctionName()
    if name then
        Client.SetOptionString(kSortFunctionNameOptionName, name)
    end
    
    FilterAndSortServers(self)
    
end

local function OnCurrentViewChanged(self)
    
    FilterAndSortServers(self)
    
end

local function SetupFilters(self)
    
    self.filterData = IterableDict()
    
    local filterConfig = GetServerBrowserFilterConfiguration()
    for i=1, #filterConfig do
        
        local filter = filterConfig[i]
        local filterOptionKey = filter.params.optionPath
        local filterOptionType = filter.params.optionType
        local optionGetterFunc = GetOptionValueGetterFunctionForType(filterOptionType)
        local defaultValue = filter.params.default
        local value = optionGetterFunc(filterOptionKey, defaultValue)
        
        self.filterData[filter.name] =
        {
            value = value,
            func = filter.func,
        }
        
    end
    
end

function GUIMenuServerBrowser:SetFilterValue(filterName, value)
    
    if self.filterData[filterName] == nil then
        error(string.format("Filter named '%s' not found!", filterName), 2)
    end
    
    local prevValue = self.filterData[filterName].value
    self.filterData[filterName].value = value
    
    if prevValue ~= value then
        self:FireEvent(string.format("OnFilterValue%sChanged", filterName), value, prevValue)
        FilterAndSortServers(self)
    end
    
end

function GUIMenuServerBrowser:GetFilterValue(filterName)
    
    if self.filterData[filterName] == nil then
        error(string.format("Filter named '%s' not found!", filterName), 2)
    end
    
    return self.filterData[filterName].value
    
end

local function OnSelectedModesChanged(self)
    
    FilterAndSortServers(self)
    
end

--[=[
local function OnDimmerFadeOutFinished(self, animationName)
    
    if animationName ~= "dimmerFadeOut" then
        return
    end
    
    self.refreshArrows:ClearPropertyAnimations("Angle", "arrowRotation")
    self.dimmer:SetVisible(false)
    
end
--]=]

local function UpdateJoinGlow(self)
    
    local selectedEntry = self:GetSelectedEntry()
    local glow = selectedEntry ~= GUIMenuServerBrowser.NoEntry
    local prevGlow = self.joinGlow == true
    
    self.bottomButtons:SetRightEnabled(glow)
    
    if glow then
        self.joinGlow:SetColor(1, 1, 1, 1)
        DoColorFlashEffect(self.joinGlow)
        PlayMenuSound("BeginChoice")
    else
        self.joinGlow:AnimateProperty("Color", Color(1, 1, 1, 0), MenuAnimations.Fade)
    end
    
end

local function OnSelectedEntryChanged(self, selectedEntry, prevSelectedEntry)
    
    if prevSelectedEntry ~= GUIMenuServerBrowser.NoEntry then
        prevSelectedEntry:SetSelected(false)
    end
    
    if selectedEntry ~= GUIMenuServerBrowser.NoEntry then
        selectedEntry:SetSelected(true)
    end
    
    UpdateJoinGlow(self)
    
end

local function SortGameModes(a, b)
    return a.count > b.count
end

local function UpdateGameModeList(self)
    
    PROFILE("GUIMenuServerBrowser UpdateGameModList")
    
    local serverSet = self:GetServerSet()
    
    -- Build a mapping of gameMode --> count
    -- In addition to a list of unique game modes.
    local gameModeSet = {}
    for __, entry in pairs(serverSet) do -- JIT-safe pairs
        
        local gameMode = entry:GetGameMode()
        if gameModeSet[gameMode] == nil then
            gameModeSet[#gameModeSet+1] = gameMode
            gameModeSet[gameMode] = 0
        end
        
        gameModeSet[gameMode] = gameModeSet[gameMode] + 1
        
    end
    
    -- Now build a list of game modes paired with their counts.  Exclude "ns2" because this one
    -- always comes first.
    local gameModeCounts = {}
    for i=1, #gameModeSet do
        local gameMode = gameModeSet[i]
        if gameMode ~= "ns2" then
            table.insert(gameModeCounts, { gameMode = gameMode, count = gameModeSet[gameMode] })
        end
    end
    
    -- Sort this list of game modes by their count.
    table.sort(gameModeCounts, SortGameModes)
    
    -- Convert to a sorted list of game modes.
    local sortedList = {"ns2"}
    for i=1, #gameModeCounts do
        table.insert(sortedList, gameModeCounts[i].gameMode)
    end
    
    self.filterWidget:SetModeList(sortedList)
    self.filterWidget:SelectAllInList()
end

local function UpdateSelectedServerDetails(self)
    
    local entry = self:GetSelectedEntry()
    if entry == GUIMenuServerBrowser.NoEntry then
        return -- no server was selected.
    end
    
    if not entry:GetExists() then
        return -- server doesn't actually exist (is only in history).
    end
    
    local index = entry:GetIndex()
    assert(index >= 0)
    
    Client.RequestServerDetails(index)
    
    -- We've requested the details.  We don't care when the details arrive, we just use them when
    -- we update the server.
    
end

local function OnServerRefreshed(index)
    self = GetServerBrowser()
    
    local address = Client.GetServerAddress(index)
    local serverSet = self:GetServerSet()
    local entry = serverSet[address]
    if not entry then
        -- We somehow managed to receive server refresh notification about a server we didn't
        -- request...
        return 
    end
    
    entry.refreshRequestExpire = nil -- request received
    
    UpdateServerInfoFromClientData(self, entry, index)
    
end

local function UpdateSelectedServer(self)
    
    PROFILE("GUIMenuServerBrowser UpdateSelectedServer")
    
    local entry = self:GetSelectedEntry()
    if entry == GUIMenuServerBrowser.NoEntry then
        return -- no server was selected.
    end
    
    if not entry:GetExists() then
        return -- server doesn't actually exist (is only in history).
    end
    
    local index = entry:GetIndex()
    assert(index >= 0)
    
    -- Request new data if we haven't requested it in a while, or if the request hasn't yet expired.
    local now = Shared.GetTime()
    if not entry.refreshRequestExpire or now >= entry.refreshRequestExpire then
        
        entry.refreshRequestExpire = now + kRefreshRequestExpireTime
        
        -- New server info will be updated when the request is received.
        Client.RefreshServer(index, OnServerRefreshed)
        
    end
    
    -- Update regardless of refresh request, as the server details will be coming also.
    UpdateServerInfoFromClientData(self, entry, index)
    
    UpdateGameModeList(self)
    
end

local function UpdateMiscStuff(self)
    
    PROFILE("GUIMenuServerBrowser UpdateMiscStuff")
    
    local totalPlayerCount = 0
    local serverSet = self:GetServerSet()
    for __, entry in pairs(serverSet) do -- JIT-safe pairs!
        
        totalPlayerCount = totalPlayerCount + math.max(0, entry:GetPlayerCount()) + math.max(0, entry:GetSpectatorCount())
        
    end
    
    self.populationDisplay:SetTotalPlayers(totalPlayerCount)
    --self.populationDisplay:SetSearchingCount(Matchmaking_GetNumInGlobalLobby() or 0)
    
end

local function OnScreenDisplay(self)
    
    -- Begin periodic loop that updates server details for selected server (if any).
    assert(self.updateSelectedDetailsCallback == nil)
    self.updateSelectedDetailsCallback = self:AddTimedCallback(UpdateSelectedServerDetails, kUpdateSelectedServerDetailsInterval, true)
    assert(self.updateSelectedDetailsCallback ~= nil)
    
    -- Begin periodic loop that requests updated information about the selected server.  This
    -- doesn't include the server details (mod list, player count), which is handled in a different
    -- loop, throttled separately.
    assert(self.updateSelectedCallback == nil)
    self.updateSelectedCallback = self:AddTimedCallback(UpdateSelectedServer, kUpdateSelectedServerInterval, true)
    assert(self.updateSelectedCallback ~= nil)
    
    -- Begin periodic loop to update miscellaneous server browser stuff.
    assert(self.updateMiscCallback == nil)
    self.updateMiscCallback = self:AddTimedCallback(UpdateMiscStuff, kUpdateMiscStuffInterval, true)
    assert(self.updateMiscCallback ~= nil)
    
    -- So the player shows up in the "players searching for servers" count.
    --Matchmaking_JoinGlobalLobby()
    
    -- If the server list hasn't been refreshed yet (eg player is in-game and hasn't seen server
    -- browser yet), do it now.
    if not self.initialRefreshDoing then
        self:RefreshServerList()
        self.initialRefreshDoing = true
    end
    
end

local function OnScreenHide(self)
    
    -- End the periodic loop that updates server details for selected server.
    assert(self.updateSelectedDetailsCallback ~= nil)
    self:RemoveTimedCallback(self.updateSelectedDetailsCallback)
    self.updateSelectedDetailsCallback = nil
    
    -- End the periodic loop that updates regular server information.
    assert(self.updateSelectedCallback ~= nil)
    self:RemoveTimedCallback(self.updateSelectedCallback)
    self.updateSelectedCallback = nil
    
    -- End the periodic loop to update miscellaneous stuff.
    assert(self.updateMiscCallback ~= nil)
    self:RemoveTimedCallback(self.updateMiscCallback)
    self.updateMiscCallback = nil
    
    -- Close the filters window if necessary.
    self:CloseFilterWindow()
    
    -- Player not looking at server browser anymore -- shouldn't appear in the "searching for servers" list.
    --Matchmaking_LeaveGlobalLobby()
    
end

local function UpdateListLayoutViewerParameters(self)
    
    local panePosition = self.scrollPane:GetPanePosition()
    local viewAreaSize = self.scrollPane:GetSize()
    
    local minY = -panePosition.y
    local maxY = minY + viewAreaSize.y
    
    self.listLayout:SetViewRegionMin(minY)
    self.listLayout:SetViewRegionMax(maxY)
    
end

function GUIMenuServerBrowser:GetIsPopulated()
    return self.initialRefreshDone == true
end

local function UpdateHintTextAnimationState(hintText, animationName)
    
    -- only care about the "opacityAnimation".  Update regardless if no animation name is given (eg
    -- manual update call).
    if animationName ~= "opacityAnimation" and animationName ~= nil then
        return
    end
    
    local opacity = hintText:GetOpacity()
    local staticOpacity = hintText:GetOpacity(true)
    local animationShouldPlay = opacity ~= 0.0 or staticOpacity ~= 0.0
    
    if hintText.animationPlaying == animationShouldPlay then
        return -- animation is doing as it should.
    end
    hintText.animationPlaying = animationShouldPlay
    
    if animationShouldPlay then
        
        -- Animation isn't playing, but it should be.  Play it now.
        hintText:AnimateProperty("Position", nil,
        {
            amplitude = Vector(50, 0, 0),
            frequency = 1.0,
            func = function(obj, time, params, currentValue, startValue, endValue, startTime)
                local offset = math.sin(time * math.pi * 2 * params.frequency) * params.amplitude
                return currentValue + offset, false
            end,
        }, "waveAnimation")
        
    else
        
        -- Animation is playing, but it shouldn't be.  Stop it.
        hintText:ClearPropertyAnimations("Position", "waveAnimation")
        
    end
    
end

local function UpdateEmptyGameModeSelectionHintText(self)

    local selectionEmpty = #self.filterWidget:GetSelectedModes() == 0
    
    -- Hint text should fade in/out.
    local goalOpacity = selectionEmpty and 1 or 0
    local currentOpacity = self.filterWidgetEmptyHintText:GetOpacity(true)
    if goalOpacity ~= currentOpacity then
        self.filterWidgetEmptyHintText:AnimateProperty("Opacity", goalOpacity, MenuAnimations.Fade, "opacityAnimation")
    end
    
    UpdateHintTextAnimationState(self.filterWidgetEmptyHintText)

end

function GUIMenuServerBrowser:Initialize(params, errorDepth)
    
    errorDepth = (errorDepth or 1) + 1
    
    serverBrowser = self
    
    PushParamChange(params, "screenName", "ServerBrowser")
    GUIMenuNavBarScreen.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")
    
    self:GetRootItem():SetDebugName("serverBrowser")
    self:ListenForCursorInteractions() -- prevent click-through
    
    -- Set of all server entries, regardless of visibility, and including those being destroyed.
    self.serverEntries = UnorderedSet()
    
    -- Mapping of mod id (number) --> mod name string.
    self.modNameLookup = {}
    
    -- Set of mod id (number) that were requested and awaiting a response.
    self.pendingModNames = {}
    
    -- Set of server entries whose mod lists are incomplete because we didn't know the mod names at the time.
    self.entriesAwaitingModNames = UnorderedSet()
    
    -- Background (two layers, the "cool" layer, and a basic layer on top of that).
    self.coolBack = CreateGUIObject("coolBack", GUIMenuTabbedBox, self)
    self.coolBack:SetLayer(-2)
    self.coolBack:SetPosition(0, -GUIMenuNavBar.kUnderlapYSize)
    
    self.innerBack = CreateGUIObject("innerBack", GUIMenuBasicBox, self)
    self.innerBack:SetLayer(1)
    self.innerBack:SetPosition(kInnerBackgroundSideSpacing, kInnerBackgroundTopSpacing - GUIMenuNavBar.kUnderlapYSize)
    self:HookEvent(self.coolBack, "OnSizeChanged", UpdateInnerBackgroundSize)
    
    -- Holder for the 4 buttons along the top.
    self.topButtonsHolder = CreateGUIObject("topButtonsHolder", GUIObject, self)
    self.topButtonsHolder:SetSize(1, kTopButtonsHeight)
    
    CreateTopLeftButtons(self)
    CreateTopRightButtons(self)
    
    -- Holder for the stuff just under the buttons (game mode filters, player count, etc.)
    self.secondRowHolder = CreateGUIObject("secondRowHolder", GUIObject, self)
    self.secondRowHolder:SetSize(1, kSecondRowHeight)
    self.secondRowHolder:AlignTop()
    self.secondRowHolder:SetPosition(0, kTopButtonsHeight)
    
    self.filterWidget = CreateGUIObject("filterWidget", GMSBGameModeFilters, self.secondRowHolder)
    self.filterWidget:AlignLeft()
    self.filterWidget:SetModeList({"ns2"})
    
    self.filterWidgetEmptyHintText = CreateGUIObject("filterWidgetEmptyHintText", GUIText, self.secondRowHolder)
    self.filterWidgetEmptyHintText:SetText(Locale.ResolveString("SERVERBROWSER_GAMEMODE_ALL_HIDDEN_TT").." -->")
    self.filterWidgetEmptyHintText:SetColor(MenuStyle.kWarningColor)
    self.filterWidgetEmptyHintText:SetFont(MenuStyle.kOptionHeadingFont)
    self.filterWidgetEmptyHintText:SetHotSpot(1, 0.5)
    self.filterWidgetEmptyHintText:SetAnchor(0, 0.5)
    self.filterWidgetEmptyHintText:SetDropShadowEnabled(true)
    self.filterWidgetEmptyHintText:SetX(-50)
    self:HookEvent(self.filterWidget, "OnSelectedModesChanged", UpdateEmptyGameModeSelectionHintText)
    UpdateEmptyGameModeSelectionHintText(self)
    self.filterWidgetEmptyHintText:HookEvent(self.filterWidgetEmptyHintText, "OnAnimationFinished", UpdateHintTextAnimationState)
    
    self.rightSideSecondRowStuff = CreateGUIObject("rightSideSecondRowStuff", GUIListLayout, self.secondRowHolder, {orientation="horizontal"})
    self.rightSideSecondRowStuff:SetSpacing(kSecondRowRightSideStuffSpacing)
    self.rightSideSecondRowStuff:AlignRight()
    
    self.populationDisplay = CreateGUIObject("populationDisplay", GMSBPlayerCountWidget, self.rightSideSecondRowStuff)
    
    self.filtersButton = CreateGUIObject("filtersButton", GMSBTextButton, self.rightSideSecondRowStuff)
    self.filtersButton:AlignLeft()
    self.filtersButton:SetLabel(Locale.ResolveString("SERVERBROWSER_FILTERS"))
    self.filtersButton:SetGlowing(false)
    self:HookEvent(self.filtersButton, "OnPressed", OnFiltersButtonPressed)
    
    self.refreshButton = CreateGUIObject("refreshButton", GMSBRefreshButton, self)
    self.refreshButton:AlignTop()
    self.refreshButton:SetScale(kRefreshButtonScale, kRefreshButtonScale)
    self:HookEvent(self.refreshButton, "OnPressed",
    function(self2)
        PlayMenuSound("ButtonClick")
        self2:RefreshServerList()
    end)
    
    -- Create server list heading.
    self.columnHeadersLayout = CreateGUIObject("columnHeadersLayout", GUIFillLayout, self.innerBack,
    {
        orientation = "horizontal",
        fixedMinorSize = true,
    })
    self.columnHeadersLayout:SetSize(1, kColumnHeadersHeight - self.kColumnHeadersSpacing)
    
    SetupColumnHeaders(self)
    
    self.scrollPane = CreateGUIObject("scrollPane", GUIMenuScrollPane, self.innerBack,
    {
        horizontalScrollBarEnabled = false,
    })
    self.scrollPane:AlignBottomLeft()
    
    self.columnHeadersLayout:SetSpacing(self.kColumnHeadersSpacing)
    self.columnHeadersLayout:SetFrontPadding(self.kColumnHeadersSpacing * 0.5)
    self.columnHeadersLayout:SetBackPadding(self.kColumnHeadersSpacing * 0.5 + self.scrollPane:GetScrollBarThickness())
    
    self.listLayout = CreateGUIObject("listLayout", GMSBListLayout, self.scrollPane,
    {
        frontPadding = 4, -- TODO how well does this scale with resolution?
    })
    self.scrollPane:HookEvent(self.listLayout, "OnSizeChanged", self.scrollPane.SetPaneSize)
    self:HookEvent(self.scrollPane, "OnPanePositionChanged", UpdateListLayoutViewerParameters)
    self:HookEvent(self.scrollPane, "OnSizeChanged", UpdateListLayoutViewerParameters)
    
    -- Create buttons at the bottom.
    self.bottomButtons = CreateGUIObject("bottomButtons", GUIMenuTabButtonsWidget, self)
    self.bottomButtons:SetLayer(2)
    self.bottomButtons:AlignBottom()
    self.bottomButtons:SetLeftLabel(Locale.ResolveString("BACK"))
    self.bottomButtons:SetRightLabel(Locale.ResolveString("JOIN"))
    self.bottomButtons:SetRightEnabled(false)
    self.bottomButtons:SetTabMinWidth(kTabMinWidth)
    self.bottomButtons:SetTabHeight(kTabHeight)
    self.bottomButtons:SetFont(MenuStyle.kButtonFont)
    self.coolBack:HookEvent(self.bottomButtons, "OnTabSizeChanged", self.coolBack.SetTabSize)
    self.coolBack:SetTabSize(self.bottomButtons:GetTabSize())
    
    -- Create extra glowy effect for join button when it is enabled.
    self.joinGlow = CreateGUIObject("joinGlow", GUIObject, self.bottomButtons.rightButton)
    self.joinGlow:SetLayer(2)
    self.joinGlow:SetTexture(kJoinGlowTexture)
    self.joinGlow:SetSizeFromTexture()
    self.joinGlow:AlignBottomRight()
    self.joinGlow:SetBlendTechnique(GUIItem.Add)
    UpdateJoinGlow(self)
    
    local function UpdateJoinGlowPosition(joinGlow, tabSize)
        joinGlow:SetPosition(kJoinGlowCornerXOffset - tabSize.y, 0)
    end
    self.joinGlow:HookEvent(self.bottomButtons, "OnTabSizeChanged", UpdateJoinGlowPosition)
    UpdateJoinGlowPosition(self.joinGlow, self.bottomButtons:GetTabSize())
    
    self:HookEvent(self.bottomButtons, "OnLeftPressed", self.OnBack)
    self:HookEvent(self.bottomButtons, "OnRightPressed", self.JoinSelectedServer)
    
    self.absoluteScale = Vector(1, 1, 1)
    EnableOnAbsoluteScaleChangedEvent(self)
    self:HookEvent(self, "OnAbsoluteScaleChanged", OnAbsoluteScaleChanged)
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", RecomputeServerBrowserHeight)
    self:HookEvent(self, "OnSizeChanged", OnServerBrowserSizeChanged)
    
    -- Load a set of favorite addresses for the user from disk.
    LoadFavorites(self)
    self:HookEvent(self, "OnFavoritesChanged", OnFavoritesChanged)

    -- Load a set of recently visited servers from disk.  These may or may not correspond to actual
    -- servers that are still operating.
    LoadHistory(self)
    self:HookEvent(self, "OnHistoryChanged", OnHistoryChanged)
    
    -- Load a set of servers that the player does not wish to see.
    LoadBlackList(self)
    self:HookEvent(self, "OnBlockedChanged", OnBlockedChanged)
    
    -- Build the initial server list if in main menu, otherwise wait until server browser is
    -- initially shown.
    if not Client.GetIsConnected() then
        self:RefreshServerList()
        self.initialRefreshDoing = true
    end
    
    -- Callbacks for when the screen is displayed/hidden, so we turn on/off certain updates.
    self:HookEvent(self, "OnScreenDisplay", OnScreenDisplay)
    self:HookEvent(self, "OnScreenHide", OnScreenHide)
    
    -- Re-filter all servers when the server set changes, the sorting function changes, or the
    -- current view changes (eg viewing favorites instead of all).
    self:HookEvent(self, "OnServerSetChanged", FilterAndSortServers)
    self:HookEvent(self, "OnSortFunctionChanged", OnSortFunctionChanged)
    self:HookEvent(self, "OnCurrentViewChanged", OnCurrentViewChanged)
    self:HookEvent(self.filterWidget, "OnSelectedModesChanged", OnSelectedModesChanged)
    
    self:SetSortFunctionName(Client.GetOptionString(kSortFunctionNameOptionName, "PlayerCount"))
    
    -- Load the filter setup, and create a combined filter function.
    SetupFilters(self)
    
    self:HookEvent(self, "OnSelectedEntryChanged", OnSelectedEntryChanged)
    
end

function GUIMenuServerBrowser:SetSortFunctionName(name)
    
    local sortFunction = ServerBrowserSortFunctions[name] or ServerBrowserSortFunctions.PlayerCount
    self:SetSortFunction(sortFunction)
    
end

-- Returns the GMSBEntry associated with the given address, or nil if it cannot yet be found.
function GUIMenuServerBrowser:GetServerEntryFromAddress(address)
    return self:GetServerSet()[address]
end

function GUIMenuServerBrowser:GetSortFunctionName()
    
    local sortFunc = self:GetSortFunction()
    
    -- not jit safe, but this won't be called very often.
    for key, value in pairs(ServerBrowserSortFunctions) do
        if value == sortFunc then
            return key
        end
    end
    
    return nil -- couldn't find it amongst the known functions.
    
end

local function UpdateRefreshingGraphics(self)
    
    local refreshing = self:GetRefreshing()
    self.refreshButton:SetSpinning(refreshing)
    
end

local function DestroyServerEntryWhenHidden(serverEntry, expansion)
    if expansion == 0.0 then
        serverEntry:Destroy()
    end
end

local function DeleteServerEntry(self, serverEntry)
    
    if serverEntry:GetExpansion() == 0.0 then
        -- Server was already hidden, can delete immediately.
        serverEntry:Destroy()
    else
        serverEntry:SetExpanded(false)
        serverEntry:HookEvent(serverEntry, "OnExpansionChanged", DestroyServerEntryWhenHidden)
    end
    
end

local function UpdateServerList(self)
    
    -- Certain things we can only do once we're done refreshing.  Eg, we're not given a list of
    -- servers that no longer exist, so we can only infer which servers no longer exist if they do
    -- not exist in the set of servers that we receive.  Therefore, we have to wait until
    -- refreshing is complete before we can know which servers can be removed from the set.
    local doneRefreshing = Client.GetServerListRefreshed()
    
    local newServerEntries = 0
    local numServers = Client.GetNumServers()
    local serverSet = self:GetServerSet()
    
    local activeAddresses -- excludes history
    if doneRefreshing then
        -- Start active address set from scratch if we're finished updating.  This way, we exclude
        -- servers we didn't receive an update from.
        activeAddresses = {}
    else
        -- Add to the existing active addresses set while we update.
        activeAddresses = self:GetActiveAddressesSet()
    end
    local inUseAddresses = {} -- includes history
    
    for i=1, numServers do
        
        local serverIndex = i-1
        local serverAddress = Client.GetServerAddress(serverIndex)
        
        -- Build a set of all the addresses we're JUST now getting that we know are up-to-date.
        activeAddresses[serverAddress] = true
        
        -- Also keep track of addresses that are in-use (same as above, but includes history)
        if doneRefreshing then
            inUseAddresses[serverAddress] = true
        end
        
        -- Update existing server entry if it exists, otherwise create a new one.
        local serverEntry = serverSet[serverAddress]
        if serverEntry == nil and newServerEntries < kMaxNewServerEntriesPerUpdate then
            -- This server hasn't been seen before, need to create a new entry for it.
            serverEntry = CreateNewServerEntry(self, serverAddress)
            newServerEntries = newServerEntries + 1
        end
        
        -- If the server entry exists, update it (might not exist since we're throttling the creation).
        if serverEntry ~= nil then
            UpdateServerInfoFromClientData(self, serverEntry, serverIndex)
        end
        
    end
    
    if newServerEntries >= kMaxNewServerEntriesPerUpdate then
        doneRefreshing = false -- we hit the limit, needs another cycle.
    end
    
    -- Add historical server addresses to the in-use set.
    local history = self:GetHistory()
    for address, __ in pairs(history) do -- JIT-safe pairs!
        inUseAddresses[address] = true
    end
    
    -- Delete all server entries that don't have in-use addresses.  Only do this if the server list
    -- is done refreshing, otherwise we can't distinguish between servers that no longer exist, and
    -- servers that we just haven't heard back from yet.
    local someRemoved = false
    if doneRefreshing then
        local serverSet = self:GetServerSet()
        local deletePending = {}
        for address, __ in pairs(serverSet) do -- JIT-safe pairs!
            if not inUseAddresses[address] then
                table.insert(deletePending, address)
            end
        end
        for i=1, #deletePending do
            local address = deletePending[i]
            local serverEntry = serverSet[address]
            DeleteServerEntry(self, serverEntry)
            
            -- Ensure we un-select this entry
            if self:GetSelectedEntry() == serverEntry then
                self:SetSelectedEntry(nil)
            end
            
            -- If the server was waiting for the mod name mapping to be updated, remove it from that set.
            self.entriesAwaitingModNames:RemoveElement(serverEntry)
            
            -- Server entry is "destroyed" (or at least will be soon enough).  We don't consider it
            -- part of the set anymore.  It IS, however, still a child of self.listLayout, so keep
            -- that in mind...
            serverSet[address] = nil
            
            someRemoved = true
            
        end
        
    end
    
    -- Update the server set if any were removed.
    if someRemoved then
        self:SetServerSet(serverSet)
    end
    
    -- Update the list of available game modes.
    UpdateGameModeList(self)
    
    -- Keep track of which server addresses actually exist.
    self:SetActiveAddressesSet(activeAddresses)
    
    -- Stop the callback if we're done refreshing.
    if doneRefreshing then
    
        if self.initialRefreshDoing then
            self.initialRefreshDoing = nil
            self.initialRefreshDone = true
        end
        
        self:RemoveTimedCallback(self.updateServerListCallback)
        self.updateServerListCallback = nil
        UpdateRefreshingGraphics(self)
        
        -- Fire an event when we finish refreshing.
        self:FireEvent("OnRefreshFinished")
        FilterAndSortServers(self)
    end
    
end

function GUIMenuServerBrowser:GetRefreshing()
    return self.updateServerListCallback ~= nil
end

function GUIMenuServerBrowser:RefreshServerList()
    
    if self:GetRefreshing() then
        return -- Already refreshing.
    end
    
    self:SetSelectedEntry(nil)
    
    Client.RebuildServerList()
    
    self.updateServerListCallback = self:AddTimedCallback(UpdateServerList, -1, true)
    UpdateRefreshingGraphics(self)
    
end

-- Add some validation.
local old_SetSelectedEntry = GUIMenuServerBrowser.SetSelectedEntry
function GUIMenuServerBrowser:SetSelectedEntry(entry)
    
    -- Allow nil for convenience
    if entry == nil then
        entry = GUIMenuServerBrowser.NoEntry
    end
    
    if entry ~= GUIMenuServerBrowser.NoEntry then
        RequireIsa("GMSBEntry", entry, "entry")
    end
    
    local result = old_SetSelectedEntry(self, entry)
    return result
    
end

local function JoinPrompt_CommonWarning(self, promptState, message, neverAgainOptionName, promptStatePassName)
    
    local popup = CreateGUIObject("popup", GUIMenuPopupDoNotShowAgainMessage, nil,
    {
        title = Locale.ResolveString("ALERT"),
        message = message,
        neverAgainOptionName = neverAgainOptionName,
        buttonConfig =
        {
            {
                name = "join",
                params =
                {
                    label = Locale.ResolveString("JOIN"),
                },
                callback = function(popup2)
                    promptState[promptStatePassName] = true
                    popup2:Close()
                    self:_AttemptToJoinServer(promptState)
                end,
            },
            
            GUIMenuPopupDialog.CancelButton,
        },
    })
    
end

local function JoinCheck_Unranked(self, entry, promptState)
    
    if promptState.passedUnrankedCheck or
       promptState.onlyPassword or
       entry:GetFavorited() or
       entry:GetRanked() then
        
        return true
    end
    
    local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
    {
        title = Locale.ResolveString("ALERT"),
        message = Locale.ResolveString("SERVERBROWSER_UNRANKED_TOOLTIP"),
        buttonConfig =
        {
            {
                name = "join",
                params =
                {
                    label = Locale.ResolveString("JOIN"),
                },
                callback = function(popup2)
                    promptState.passedUnrankedCheck = true
                    popup2:Close()
                    self:_AttemptToJoinServer(promptState)
                end,
            },
            GUIMenuPopupDialog.CancelButton,
        },
    })
    
    return false
    
end

-- If the server is running custom network settings, warn the user they may have a suboptimal
-- experience.
local function JoinCheck_ModifiedNetworkSettings(self, entry, promptState)
    
    if promptState.passedNetCheck or
       promptState.onlyPassword or
       entry:GetFavorited() or
       Client.GetOptionBoolean("never_show_snma", false) or
       entry:GetPlayerMax() <= 24 or not entry:GetCustomNetworkSettings() then
        
        return true
    end
    
    JoinPrompt_CommonWarning(self, promptState,
        Locale.ResolveString("SERVER_MODDED_WARNING"),  -- Message
        "never_show_snma",                              -- Option boolean name to modify if checkbox is changed.
        "passedNetCheck")                               -- promptState field name to set true if "join" clicked.
    
    return false
    
end

-- If the server is rookie only, and the player is not a rookie, inform them they can join, but
-- can only spec.
local function JoinCheck_Bootcamp(self, entry, promptState)
    
    if promptState.passedBootcampCheck or
       promptState.onlyPassword or
       entry:GetFavorited() or
       GetLocalPlayerProfileData():GetIsRookie() or
       not entry:GetRookieOnly() or 
       Client.GetOptionBoolean("never_show_roa", false) then
        
        return true
    end
    
    JoinPrompt_CommonWarning(self, promptState,
        Locale.ResolveString("ROOKIEONLYNAG_MSG"),  -- Message
        "never_show_roa",                           -- Option boolean name to modify if checkbox is changed.
        "passedBootcampCheck")                      -- promptState field name to set true if "join" clicked.
    
    return false
    
end

-- If the server requires a password, prompt the user for it now.
local function JoinCheck_Passworded(self, entry, promptState)
    
    -- Never skip if this is a password retry attempt.
    if not promptState.prevPassword and
       (promptState.passedPasswordCheck or
        promptState.password or
        not entry:GetPassworded()) then
        
        return true
    end
    
    local joinCallback = function(popup2)
        promptState.passedPasswordCheck = true
        popup2:Close()
        self:_AttemptToJoinServer(promptState)
    end
    
    local popup = CreateGUIObject("popup", GUIMenuPasswordDialog, nil,
    {
        title = Locale.ResolveString("ALERT"),
        password = promptState.prevPassword,
        buttonConfig =
        {
            {
                name = "join",
                params =
                {
                    label = Locale.ResolveString("JOIN"),
                },
                callback = joinCallback,
            },
            
            GUIMenuPopupDialog.CancelButton,
        },
    })
    
    local pwEntry = popup:GetPasswordWidget()
    assert(pwEntry)
    
    if promptState.prevPassword then
        
        local message
        if promptState.prevPassword == "" then
            -- No password was attempted, word the tooltip assuming they didn't enter one
            message = Locale.ResolveString("SERVERBROWSER_PASSWORD_MISSING_TOOLTIP")
        else
            -- Password wasn't blank, tell them it was wrong.
            message = Locale.ResolveString("SERVERBROWSER_PASSWORD_INCORRECT_TOOLTIP")
        end
        
        popup:SetMessage(message)
        promptState.password = promptState.prevPassword
        promptState.prevPassword = nil -- clear it out so we can join the server.
    else
        popup:SetMessage(Locale.ResolveString("SERVERBROWSER_PASSWORD_TOOLTIP"))
    end
    
    pwEntry:SetMaxCharacterCount(kMaxServerPasswordLength)
    popup:HookEvent(pwEntry, "OnKey", function(popup2, key, down)
        if (key == InputKey.Return or key == InputKey.NumPadEnter) and down then
            joinCallback(popup2)
        end
    end)
    
    popup:HookEvent(pwEntry, "OnValueChanged",
        function(popup2, value)
            promptState.password = value
        end)
    
    return false
    
end

local function JoinPrompt_PlayerSlots(self, entry, promptState)
    
    -- There aren't enough player slots left to immediately join the server.  Sit and wait for a
    -- slot, and let the player choose to try to join anyways (reserved slot or spectate), or give
    -- up to try a different server.  If a free player slot opens up, join immediately.
    local popup = CreateGUIObject("popup", GUIMenuPopupSimpleMessage, nil,
    {
        title = Locale.ResolveString("AUTOJOIN_TITLE"),
        message = "",
        buttonConfig =
        {
            {
                name = "join",
                params =
                {
                    label = Locale.ResolveString("JOIN"),
                },
                callback = function(popup2)
                    promptState.passedPlayerSlotCheck = true
                    popup2:Close()
                    self:_AttemptToJoinServer(promptState)
                end,
            },
            
            GUIMenuPopupDialog.CancelButton,
        },
    })
    
    -- If server entry is destroyed, ensure popup is destroyed also.
    popup:HookEvent(entry, "OnDestroy", popup.Destroy)
    
    -- We are actively waiting for a player slot to open up.  Ensure this is reflected in the
    -- message by animating the dots.
    popup:AddInstanceProperty("MessageMainBody", "") -- reason why we can't join right this second...
    popup:AddInstanceProperty("Dots", "") -- animated string of dots.
    popup.dotCount = 0
    
    local function PopupUpdateMessage(popup2)
        popup2:SetMessage(string.format("%s\n    %s%s", popup2:GetMessageMainBody(), Locale.ResolveString("AUTOJOIN_JOIN_STATUS"), popup2:GetDots()))
    end
    
    popup:HookEvent(popup, "OnMessageMainBodyChanged", PopupUpdateMessage)
    popup:HookEvent(popup, "OnDotsChanged", PopupUpdateMessage)
    PopupUpdateMessage(popup)
    
    -- Animate dots
    popup:AddTimedCallback(
        function(popup2)
            popup2.dotCount = (popup2.dotCount + 1) % 4
            popup2:SetDots(string.rep(".", popup2.dotCount))
        end, 0.5, true)
    
    -- Check for a free player slot, and update the popup's message and button text.
    popup:AddTimedCallback(
        function(popup2)
            
            local playerCount = entry:GetPlayerCount()
            local playerMax = entry:GetPlayerMax()
            local reservedSlotCount = entry:GetReservedSlotCount()
            
            local playerSlotsAvailable = (playerMax - reservedSlotCount) - playerCount
            if spoofFull then
                playerSlotsAvailable = 0
            end
            
            -- If a slot becomes available, join the server immediately.
            if playerSlotsAvailable > 0 then
                promptState.passedPlayerSlotCheck = true
                popup:Close()
                self:_AttemptToJoinServer(promptState)
                return
            end
            
            -- Otherwise, update the message of the popup.
            local reservedSlotsAvailable = playerMax - playerCount
            if spoofReservedFull then
                reservedSlotsAvailable = 0
            end
            
            local specCount = entry:GetSpectatorCount()
            local specMax = entry:GetSpectatorMax()
            local specSlotsAvailable = specMax - specCount
            if spoofSpecFull then
                specSlotsAvailable = 0
            end
            
            local button = popup2:GetButton("join")
            assert(button)
            
            if reservedSlotsAvailable > 0 then
                if specSlotsAvailable > 0 then
                    -- Spectator slots and reserved slots are available.
                    popup2:SetMessageMainBody(Locale.ResolveString("AUTOJOIN_JOIN_TOOLTIP_SPEC_AND_RS"))
                    button:SetLabel(Locale.ResolveString("AUTOJOIN_SPEC_AND_RS"))
                    button:SetEnabled(true)
                else
                    -- Reserved slots available, but no spec slots.
                    popup2:SetMessageMainBody(Locale.ResolveString("AUTOJOIN_JOIN_TOOLTIP"))
                    button:SetLabel(Locale.ResolveString("AUTOJOIN_SPEC_AND_RS"))
                    button:SetEnabled(true)
                end
            else -- no RS
                if specSlotsAvailable > 0 then
                    -- Spec, no RS
                    popup2:SetMessageMainBody(Locale.ResolveString("AUTOJOIN_JOIN_TOOLTIP_SPEC"))
                    button:SetLabel(Locale.ResolveString("AUTOJOIN_SPEC"))
                    button:SetEnabled(true)
                else
                    -- No spec, no rs.
                    popup2:SetMessageMainBody(Locale.ResolveString("AUTOJOIN_JOIN_TOOLTIP_FULL"))
                    button:SetLabel(Locale.ResolveString("AUTOJOIN_SPEC_AND_RS"))
                    button:SetEnabled(false)
                end
            end
            
        end, 0, true)
    
end

-- Ensure the server has available player slots, otherwise prompt user with their options.
local function JoinCheck_PlayerSlots(self, entry, promptState)
    
    local playerCount = entry:GetPlayerCount()
    local playerMax = entry:GetPlayerMax()
    local reservedSlotCount = entry:GetReservedSlotCount()
    
    local playerSlotsAvailable = (playerMax - reservedSlotCount) - playerCount
    if spoofFull then
        playerSlotsAvailable = 0
    end
    
    if promptState.passedPlayerSlotCheck or
       playerSlotsAvailable > 0 then
        
        return true
    end
    
    JoinPrompt_PlayerSlots(self, entry, promptState)
    
    return false
    
end

local kJoinChecks =
{
    JoinCheck_Unranked,
    JoinCheck_ModifiedNetworkSettings,
    JoinCheck_Bootcamp,
    JoinCheck_Passworded,
    JoinCheck_PlayerSlots,
}

local function PerformJoinChecks(self, entry, promptState)
    
    for i=1, #kJoinChecks do
        if kJoinChecks[i](self, entry, promptState) ~= true then
            return false
        end
    end
    
    return true
    
end

local function UpdateHistoryDataFromEntry(entry, data)
    
    data.address = entry:GetAddress()
    data.lastConnect = entry:GetLastConnect()
    data.passworded = entry:GetPassworded()
    data.maxPlayers = entry:GetPlayerMax()
    data.ranked = entry:GetRanked()
    data.rookieOnly = entry:GetRookieOnly()
    data.name = entry:GetServerName()
    data.playerSkill = entry:GetSkill()
    data.maxSpectators = entry:GetSpectatorMax()
    
end

local function RemoveOldestHistoryFromDict(historyDict)
    
    local oldestTime
    local oldestAddress
    
    for address, hist in pairs(historyDict) do
        
        if not oldestTime or hist.lastConnect < oldestTime then
            oldestTime = hist.lastConnect
            oldestAddress = address
        end
        
    end
    
    historyDict[oldestAddress] = nil
    
end

function GUIMenuServerBrowser:NotifyJoiningServer(address)
    
    RequireType("string", address, "address")
    
    local serverSet = self:GetServerSet()
    local entry = serverSet[address]
    
    if not entry then
        -- Unable to find a server entry for this address, just skip it.
        return
    end
    
    -- Update the entry's last connected value.
    local sysTime = Shared.GetSystemTime()
    entry:SetLastConnect(sysTime)
    
    -- Find the entry in the history data, and bring it up-to-date.
    local historySet = self:GetHistory()
    historySet[address] = {}
    local historyEntry = historySet[address]
    
    UpdateHistoryDataFromEntry(entry, historyEntry)
    
    -- Remove invalid entries
    CleanHistory(historySet)
    
    -- If we have too many history entries, remove the one we connected to longest ago.
    while #historySet > kHistoryMax do
        RemoveOldestHistoryFromDict(historySet)
    end
    
    self:SetHistory(historySet)
    
end

-- Attempt to join a server based on the promptState (or failing that, the selected server).
-- Returns false if the joining procedure completely fails.  Returns true if the joining procedure
-- is still in progress or was successful (eg starting to join a server, or waiting for the user to
-- answer a popup).
local function AttemptToJoinServer(self, promptState)
    
    -- We may need to call this function again after getting some required user input.  Previous
    -- state is optionally passed in in the form of a table.
    promptState = promptState or {}
    
    -- Get a valid entry.  Either get it from the promptState's address, or if that hasn't been set
    -- yet, get it from the selected server.
    local entry
    if promptState.address then
        
        -- The prompt state has an address already, use that one instead, as the selection might
        -- have been invalidated between now and when they originally attempted to join the server.
        -- Selection can become invalidated for many reasons the user might not be concerned about,
        -- becoming filtered out, for example.
        local serverSet = self:GetServerSet()
        entry = serverSet[promptState.address]
        if not entry then
            Log("Server entry for address '%s' no longer found.", promptState.address)
            return false
        end
        
    else
        
        -- This is the initial call to AttemptToJoinSelectedServer, eg not called by the popup.
        entry = self:GetSelectedEntry()
        if entry == GUIMenuServerBrowser.NoEntry then
            Log("No server was selected.")
            return false
        end
        promptState.address = entry:GetAddress()
        
    end
    
    local readyToJoin = PerformJoinChecks(self, entry, promptState)
    if not readyToJoin then
        -- Something popped up.  Return for now, we'll probably be back here later.
        return true
    end
    
    JoinServer(promptState.address, promptState.password)
    return true
    
end
GUIMenuServerBrowser._AttemptToJoinServer = AttemptToJoinServer

function GUIMenuServerBrowser:JoinSelectedServer()
    
    local entry = self:GetSelectedEntry()
    if entry == GUIMenuServerBrowser.NoEntry then
        return
    end
    
    AttemptToJoinServer(self)
    
end

Event.Hook("Console_reset_nag_messages", function()
    Log("Resetting 'never show again' status for:")
    Log("    server network parameters warning")
    Log("    rookie only server warning")
    Client.SetOptionBoolean("never_show_snma", false)
    Client.SetOptionBoolean("never_show_roa", false)
end)


