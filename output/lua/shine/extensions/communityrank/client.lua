local Plugin = ...

function Plugin:Initialise()
	Shine.Hook.SetupClassHook( "GUIScoreboard", "UpdateTeam", "OnGUIScoreboardUpdateTeam", "PassivePost" )
    Plugin._GUIScoreboardUpdateTeam = Shine.ReplaceClassMethod("GUIScoreboard", "UpdateTeam", self.GUIScoreboardUpdateTeam);
    Plugin.oldGUIScoreboardSendKeyEvent = Shine.ReplaceClassMethod("GUIScoreboard", "SendKeyEvent", Plugin.GUIScoreboardSendKeyEvent);
    return true
end

function Plugin:OnFirstThink()
    self.playerCommunityData = {
        Tier = 0,
        TimePlayed = 0,
        RoundWin = 0,
        TimePlayedCommander = 0,
        RoundWinCommander = 0,
    }
    self.playerCommunityGadgets = {}
end

Shine.HookNetworkMessage( "Shine_CommunityGadgets", function(Message)
    Shared.Message(string.format("[CNCT] Item Get %i",Message.ItemID))
    Plugin.playerCommunityGadgets[Message.ItemID] = true
end )

local baseOwnsItem = GetOwnsItem
function GetOwnsItem( _item ) 
    return true 
end

Shine.HookNetworkMessage( "Shine_CommunityTier", function( Message )
    Plugin.playerCommunityData = Message
    Shared.Message(string.format("[CNCT] Tier Set %i|%i|%i|%i|%i",Message.Tier,Message.TimePlayed,Message.RoundWin,Message.TimePlayedCommander,Message.RoundWinCommander ))

    Shine.Hook.SetupGlobalHook( "GetOwnsItem", "GetCommunityOwnsItem", "Replace" )
    
    GetGlobalEventDispatcher():FireEvent("OnUserStatsAndItemsRefreshed")
    SendPlayerCallingCardUpdate()
    SendPlayerVariantUpdate()
    GetCustomizeScene():RefreshOwnedItems()
    GetBadgeCustomizer():UpdateOwnedBadges()
end )

function Plugin:GetCommunityData()
    return self.playerCommunityData
end

local function CommunityRankUnlocks(_itemId, _tier)
    for index,unlocks in pairs(gCommunityUnlocks) do
        if _tier >= index then
            for k,v in pairs(unlocks) do
                if v == _itemId then
                    return true
                end
            end
        end
    end
end

local function GetTDItemId(tdItem,tdData)
    local ccId = GetThunderdomeRewardCallingCardId(tdItem)
    if ccId then
        return GetCallingCardItemId(ccId)
    end
    return tdData.itemId
end
local function CommunityTDUnlocks(_itemId,data)
    for tdItem,tdData in pairs(kThunderdomeTimeRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = math.floor( (GetIsThunderdomeRewardCommander(tdItem) and data.TimePlayedCommander or data.TimePlayed ) / 60)
            return comparer >= tdData.progressRequired
        end
    end

    for tdItem,tdData in pairs(kThunderdomeVictoryRewardsData) do
        if GetTDItemId(tdItem,tdData) == _itemId then
            local comparer = GetIsThunderdomeRewardCommander(tdItem) and data.RoundWinCommander or data.RoundWin
            return comparer >= tdData.progressRequired
        end
    end
    return false
end


function Plugin:GetCommunityOwnsItem(_itemId)
    if self.playerCommunityGadgets[_itemId] then
        return true
    end

    local data = self.playerCommunityData

    if CommunityTDUnlocks(_itemId,data) then
        return true
    end

    if CommunityRankUnlocks(_itemId,data.Tier) then
        return true
    end
    
    return baseOwnsItem(_itemId)
end

local kZeroStr = "0"
Plugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
    Plugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)
        local playerList = updateTeam["PlayerList"]
        local teamScores = updateTeam["GetScores"]()
        local currentPlayerIndex = 1
        
        for _, player in ipairs(playerList) do
            if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
                
                local pr = teamScores[currentPlayerIndex]
                if pr == nil
                    or pr.FakeBot == nil
                then return end
                
                local skillIcon = player.SkillIcon
                if pr.FakeBot then  --Fake BOT
                    skillIcon:SetTexturePixelCoordinates(0, 1 * 32, 100, 2 * 32 - 1)
                    player["Ping"]:SetText(kZeroStr)
                end

                if MouseTracker_GetIsVisible() then
                    local mouseX, mouseY = Client.GetCursorPosScreen()
                    if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
                        local description
                        if pr.FakeBot or pr.SteamId == 0 then
                            description = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString("SKILLTIER_BOT"),-1)
                        else
                            description = skillIcon.tooltipText
                            if pr.CommSkill > 0 then
                                description = description .. "\n" .. string.format(Locale.ResolveString("SKILL_TIER_COMM"), math.max(0,pr.CommSkill + pr.CommSkillOffset), math.max(0,pr.CommSkill - pr.CommSkillOffset) )
                            end
                            description = description .. "\n" .. string.format(Locale.ResolveString("SKILL_TIER"), math.max(0,pr.Skill + pr.SkillOffset) , math.max(0,pr.Skill - pr.SkillOffset))
                            if pr.ns2TimePlayed > 0 then
                                description = description .. "\n" .. string.format(Locale.ResolveString("NS2_TIME_PLAYED"),pr.ns2TimePlayed )
                            end
                            
                            if pr.lastSeenName ~= "" and pr.lastSeenName ~= pr.Name then
                                description = description .. "\n" .. string.format( Locale.ResolveString("LAST_SEEN_NAME")) .. pr.lastSeenName
                            end

                            description = description .. "\n\n" .. string.format(Locale.ResolveString("COMMUNITY_RANK"),Locale.ResolveString(pr.Group))
                            if pr.reputation ~= 0 then
                                description = description .. "\n" .. (pr.reputation > 0 and string.format(Locale.ResolveString("COMMUNITY_REPUTATION_POSITIVE"),pr.reputation > 256 and ">=256" or pr.reputation ) 
                                        or string.format(Locale.ResolveString("COMMUNITY_REPUTATION_NEGATIVE"),-pr.reputation ))
                            end
                            if pr.prewarmTime > 0 then
                                description = description .. "\n" .. string.format( Locale.ResolveString("COMMUNITY_PLAYTIME"), pr.prewarmTime)

                                if pr.prewarmScore > 0 then
                                    description = description .. "\n" .. string.format( Locale.ResolveString("COMMUNITY_PREWARM"), pr.prewarmScore)
                                end
                                
                                if pr.prewarmTier > 0 then
                                    description = description .. "\n" .. Locale.ResolveString(string.format("COMMUNITY_PREWARM_%i", pr.prewarmTier))
                                end
                            end
                            
                            
                        end
                        scoreboard.badgeNameTooltip:SetText(description)
                    end
                end
            end
            
            currentPlayerIndex = currentPlayerIndex + 1
        end

end

local function openUrl(url, title)
    if (not Shine.Config.DisableWebWindows) then
      Shine:OpenWebpage(url, title);
    else
      Client.ShowWebpage(url);
    end
end
local function openUrlNs2Panel(steam_id)
    openUrl(string.format('https://ns2panel.ocservers.com/%s/%s', 'player', steam_id), 'INFO_NS2PANEL');
end

function Plugin.GUIScoreboardSendKeyEvent(self, key, down)
    Plugin._GUIScoreboard = self

    if self.visible and key == InputKey.MouseButton0 then
        if Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "FakeBot") then
            return false
        end
    end

    local _backgroundGetIsVisible = self.hoverMenu.background:GetIsVisible()
    local result = Plugin.oldGUIScoreboardSendKeyEvent(self, key, down)

    if ChatUI_EnteringChatMessage() then
        return false
    end
    
    if not self.visible then
        return false
    end
    
    if key == InputKey.MouseButton0 then -- and self.mousePressed["LMB"]["Down"] ~= down and down and not MainMenu_GetIsOpened() 
      if _backgroundGetIsVisible then
          return false
      elseif true then --steamId ~= 0 or self.hoverPlayerClientIndex ~= 0 and Shared.GetDevMode()

        local teamColorBg
        local teamColorHighlight
        local playerName = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "Name")
        local teamNumber = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "EntityTeamNumber")
        local isCommander = Scoreboard_GetPlayerData(self.hoverPlayerClientIndex, "IsCommander")-- and GetIsVisibleTeam(teamNumber)
        
        local textColor = Color(1, 1, 1, 1)
        
        if isCommander then
            teamColorBg = GUIScoreboard.kCommanderFontColor
        elseif teamNumber == 1 then
            teamColorBg = GUIScoreboard.kBlueColor
        elseif teamNumber == 2 then
            teamColorBg = GUIScoreboard.kRedColor
        else
            teamColorBg = GUIScoreboard.kSpectatorColor
        end
        
        teamColorHighlight = teamColorBg * 0.75
        teamColorBg = teamColorBg * 0.5
        
        local steamId = GetSteamIdForClientIndex(self.hoverPlayerClientIndex)
        --self.hoverMenu:AddButton('Obs 信息', teamColorBg, teamColorHighlight, textColor, function()
        --  openUrlObservatory(steamId);
        --end);
        
        self.hoverMenu:AddButton('NS2Panel 信息', teamColorBg, teamColorHighlight, textColor, function()
          openUrlNs2Panel(steamId);
        end);
          
        self.hoverMenu:AddButton('复制NS2ID', teamColorBg, teamColorHighlight, textColor, function()
          Shine.GUI.SetClipboardText(tostring(steamId))
        end);
      end
    end

    return false;
  end
  