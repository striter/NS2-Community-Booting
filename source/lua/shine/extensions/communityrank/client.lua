local Plugin = ...

function Plugin:Initialise()
	Shine.Hook.SetupClassHook( "GUIScoreboard", "UpdateTeam", "OnGUIScoreboardUpdateTeam", "PassivePost" )
    Plugin._GUIScoreboardUpdateTeam = Shine.ReplaceClassMethod("GUIScoreboard", "UpdateTeam", self.GUIScoreboardUpdateTeam);
    Plugin.oldGUIScoreboardSendKeyEvent = Shine.ReplaceClassMethod("GUIScoreboard", "SendKeyEvent", Plugin.GUIScoreboardSendKeyEvent);
    return true
end


function Plugin:OnFirstThink()
    self.playerCommunityTier = 0
end

function Plugin:OnCleanUp()
    return self.BaseClass.Cleanup( self )
end


Shine.HookNetworkMessage( "Shine_CommunityTier", function( Message )
    Plugin.playerCommunityTier = Message.Tier or 0

    Shine.Hook.SetupGlobalHook( "GetOwnsItem", "CheckCommunityGadgets", "Replace" )
    GetCustomizeScene():RefreshOwnedItems()
    GetGlobalEventDispatcher():FireEvent("OnUserStatsAndItemsRefreshed")
    SendPlayerVariantUpdate()
    Shared.Message(string.format("[CNCT] Tier Set %i",Plugin.playerCommunityTier ))
end )

function Plugin:CheckCommunityGadgets(_item)
    return CommunityGetOwnsItem(_item,self.playerCommunityTier)
end

local kZeroStr = "0"
Plugin.GUIScoreboardUpdateTeam = function(scoreboard, updateTeam)
    Plugin._GUIScoreboardUpdateTeam(scoreboard, updateTeam)
        local playerList = updateTeam["PlayerList"]
        local teamScores = updateTeam["GetScores"]()
        local currentPlayerIndex = 1
        
        local sumPlayerSkill = 0
        local sumPlayers = 0
        for _, player in ipairs(playerList) do
            if not scoreboard.hoverMenu.background:GetIsVisible() and not MainMenu_GetIsOpened() then
                
                local playerRecord = teamScores[currentPlayerIndex]
                if playerRecord == nil then return end
                local clientIndex = playerRecord.ClientIndex
                if GetSteamIdForClientIndex(clientIndex) ~= 0 then
                    sumPlayerSkill = sumPlayerSkill + playerRecord.Skill
                    sumPlayers = sumPlayers + 1
                end
                
                local skillIcon = player.SkillIcon
                if playerRecord.FakeBot then  --Fake BOT
                    skillIcon:SetTexturePixelCoordinates(0, 1 * 32, 100, 2 * 32 - 1)
                    player["Ping"]:SetText(kZeroStr)
                end

                if MouseTracker_GetIsVisible() then
                    local mouseX, mouseY = Client.GetCursorPosScreen()
                    if skillIcon:GetIsVisible() and GUIItemContainsPoint(skillIcon, mouseX, mouseY) then
                        local description
                        if playerRecord.FakeBot or playerRecord.SteamId == 0 then
                            description = string.format(Locale.ResolveString("SKILLTIER_TOOLTIP"), Locale.ResolveString("SKILLTIER_BOT"))
                        else
                            description = skillIcon.tooltipText
                            description = string.format("%s \n社区%s \n段位分: %i\nNS2ID: %i",description , Locale.ResolveString(playerRecord.Group), playerRecord.Skill,playerRecord.SteamId)
                        end
                        scoreboard.badgeNameTooltip:SetText(description)
                    end
                end
            end
            
            currentPlayerIndex = currentPlayerIndex + 1
        end

        local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
        local teamSkillGUIItem = updateTeam["GUIs"]["TeamSkill"]
        if updateTeam.TeamNumber >= 1 and updateTeam.TeamNumber <= 2 then --and numPlayers > 0 then -- Display for only aliens or marines

            local avgSkill = sumPlayerSkill / math.max(1,sumPlayers)
            
            local teamHeaderText = teamNameGUIItem:GetText()
            teamHeaderText = string.sub(teamHeaderText, 1, string.len(teamHeaderText) - 1) -- Original header
    
            teamHeaderText = teamHeaderText .. string.format(", %i 均分)", avgSkill) -- Skill Average
            --
    
            teamNameGUIItem:SetText( teamHeaderText )
            
            teamSkillGUIItem:SetPosition(Vector(teamNameGUIItem:GetTextWidth(teamNameGUIItem:GetText()) + 20, 5, 0) * GUIScoreboard.kScalingFactor)
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

local function openUrlObservatory(steam_id)
    openUrl(string.format('https://observatory.morrolan.ch/player?steam_id=%s', steam_id), 'INFO_OBS');
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
        self.hoverMenu:AddButton('Observatory信息', teamColorBg, teamColorHighlight, textColor, function()
          openUrlObservatory(steamId);
        end);
        
        self.hoverMenu:AddButton('NS2Panel信息', teamColorBg, teamColorHighlight, textColor, function()
          openUrlNs2Panel(steamId);
        end);
      end
    end

    return false;
  end
  