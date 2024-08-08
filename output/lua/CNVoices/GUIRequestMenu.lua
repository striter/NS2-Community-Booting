-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIRequestMenu.lua
--
-- Created by: Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/VoiceOver.lua")
Script.Load("lua/BindingsDialog.lua")

class 'GUIRequestMenu'(GUIScript)

local kOpenSound = "sound/NS2.fev/common/checkbox_on"
Client.PrecacheLocalSound(kOpenSound)
local function OnShow_RequestMenu()
    StartSoundEffect(kOpenSound)
end

local kCloseSound = "sound/NS2.fev/common/checkbox_on"
Client.PrecacheLocalSound(kCloseSound)
local function OnHide_RequestMenu()
    -- StartSoundEffect(kCloseSound)
end

local kClickSound = "sound/NS2.fev/common/button_enter"
Client.PrecacheLocalSound(kClickSound)
local function OnClick_RequestMenu()
    StartSoundEffect(kClickSound)
end

-- make this part of UI bindings
local function GetIsRequestMenuKey(key)
    return key == InputKey.X
end

local gIsConcedeButton = false

local gSendAvailableTime = 0
local kDefaultSendInterval = 2.0
local function GetCanSendRequest(id)

    local player = Client.GetLocalPlayer()
    local isAlive = player ~= nil and (not HasMixin(player, "Live") or player:GetIsAlive())
    local allowWhileDead = id == kVoiceId.VoteConcede or id == kVoiceId.VoteEject

    return (isAlive or allowWhileDead) and gSendAvailableTime < Shared.GetTime()

end

local kBackgroundSize
local kKeyBindXOffset

--Distance from center
local kConcedeButtonPadding
local kCommanderButtonPadding

local kPadding

local kFontName = Fonts.kAgencyFB_Small
local kFontScale

local scaleVector

local kMenuSize

-- moves button towards the center
local kButtonClipping

local kButtonMaxXOffset

local kMenuTexture = {
    [kMarineTeamType] = "ui/marine_request_menu.dds",
    [kAlienTeamType] = "ui/alien_request_menu.dds",
    [kNeutralTeamType] = "ui/marine_request_menu.dds",
}

local kBackgroundTexture = {
    [kMarineTeamType] = "ui/marine_request_button.dds",
    [kAlienTeamType] = "ui/alien_request_button.dds",
    [kNeutralTeamType] = "ui/marine_request_button.dds",
}

local kBackgroundTextureHighlight = {
    [kMarineTeamType] = "ui/marine_request_button_highlighted.dds",
    [kAlienTeamType] = "ui/alien_request_button_highlighted.dds",
    [kNeutralTeamType] = "ui/marine_request_button_highlighted.dds",
}

local function CreateEjectButton(self, teamType)

    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kBackgroundTexture[teamType]))
    background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    background:SetPosition(Vector(-kBackgroundSize.x * .5, -kBackgroundSize.y - kPadding, 0))
    background:SetIsVisible(false)

    local commanderName = GetGUIManager():CreateTextItem()
    commanderName:SetTextAlignmentX(GUIItem.Align_Center)
    commanderName:SetTextAlignmentY(GUIItem.Align_Center)
    commanderName:SetFontName(kFontName)
    commanderName:SetScale(scaleVector)
    GUIMakeFontScale(commanderName)
    commanderName:SetAnchor(GUIItem.Middle, GUIItem.Center)

    self.background:AddChild(background)
    background:AddChild(commanderName)

    return { Background = background, CommanderName = commanderName }

end

local function CreateBottomButton(self, teamType)

    local extraPadding = #self.menuButtons > 8 and kConcedeButtonPadding or 0
    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kBackgroundTexture[teamType]))
    background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    background:SetPosition(Vector(-kBackgroundSize.x * .5, kPadding + extraPadding, 0))
    background:SetIsVisible(false)

    local concedeText = GetGUIManager():CreateTextItem()
    concedeText:SetTextAlignmentX(GUIItem.Align_Center)
    concedeText:SetTextAlignmentY(GUIItem.Align_Center)
    concedeText:SetFontName(kFontName)
    concedeText:SetScale(scaleVector)
    GUIMakeFontScale(concedeText)
    concedeText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    concedeText:SetText(Locale.ResolveString("VOTE_CONCEDE"))
    self.background:AddChild(background)
    background:AddChild(concedeText)

    return { Background = background, ConcedeText = concedeText }

end

local function CreateMenuButton(self, teamType, voiceId, align, index, numEntries)

    voiceId = voiceId or kVoiceId.None
    index = index + (kMaxRequestsPerSide - numEntries) * .5
    local keyBind = GetVoiceKeyBind(voiceId)

    align = align or GUIItem.Left

    local background = GetGUIManager():CreateGraphicItem()
    background:SetSize(kBackgroundSize)
    background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kBackgroundTexture[teamType]))
    background:SetAnchor(align, GUIItem.Top)
    background:SetLayer(kGUILayerPlayerHUDForeground1)

    local position = Vector(0, 0, 0)
    local shiftDirection = -1
    if align == GUIItem.Left then
        position.x = -kBackgroundSize.x
        shiftDirection = 1
    end

    position.y = (index - 1) * (kBackgroundSize.y + kPadding)
    local xOffset = math.cos(Clamp((index - 1) / (kMaxRequestsPerSide - 1), 0, 1) * math.pi * 2) * kButtonMaxXOffset + kButtonClipping
    position.x = position.x + shiftDirection * xOffset

    background:SetPosition(position)

    local keyBindText = GetGUIManager():CreateTextItem()
    keyBindText:SetPosition(Vector(kKeyBindXOffset, 0, 0))
    keyBindText:SetAnchor(GUIItem.Left, GUIItem.Center)
    keyBindText:SetTextAlignmentY(GUIItem.Align_Center)
    keyBindText:SetFontName(kFontName)
    keyBindText:SetScale(scaleVector)
    GUIMakeFontScale(keyBindText)
    keyBindText:SetColor(Color(1, 1, 0, 1))

    local description = GetGUIManager():CreateTextItem()
    description:SetAnchor(GUIItem.Middle, GUIItem.Center)
    description:SetTextAlignmentX(GUIItem.Align_Center)
    description:SetTextAlignmentY(GUIItem.Align_Center)
    description:SetFontName(kFontName)
    description:SetScale(scaleVector)
    GUIMakeFontScale(description)
    description:SetText(GetVoiceDescriptionText(voiceId))

    self.background:AddChild(background)
    background:AddChild(description)
    background:AddChild(keyBindText)

    gSendAvailableTime = 0

    return { Background = background, Description = description, KeyBindText = keyBindText, KeyBind = keyBind, VoiceId = voiceId, Align = align }

end

local function OnEjectCommanderClicked()

    if GetCanSendRequest(kVoiceId.VoteEject) then

        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(kVoiceId.VoteEject), true)
        gSendAvailableTime = Shared.GetTime() + kDefaultSendInterval
        return true

    end

    return false

end

local function OnConcedeButtonClicked()
    if GetCanSendRequest(kVoiceId.VoteConcede) then

        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(kVoiceId.VoteConcede), true)
        gSendAvailableTime = Shared.GetTime() + kDefaultSendInterval
        return true

    end

    return false

end

local function SendRequest(voiceId,itemId)

    if itemId and not GetOwnsItem(itemId) then
        Shared.Message(string.format("[%s|%s]item unAccessible",EnumToString(kVoiceId,voiceId),itemId))
        return
    end
    
    if GetCanSendRequest(voiceId) and not MainMenu_GetIsOpened() then
        Client.SendNetworkMessage("VoiceMessage", BuildVoiceMessage(voiceId), true)
        local sendInterval = kDefaultSendInterval

        ---------
        local data = GetAdditionalVoiceSoundData(voiceId) or GetVoiceSoundData(voiceId)
        if data.Interval then
            sendInterval = data.Interval
        end
        gSendAvailableTime = Shared.GetTime() + sendInterval
        --------
        return true

    end

    return false

end

local function GetBindedVoiceId(playerClass, key)

    local requestMenuLeft = GetRequestMenu(LEFT_MENU, playerClass)
    for i = 1, #requestMenuLeft do

        local soundData = GetVoiceSoundData(requestMenuLeft[i])
        if soundData and soundData.KeyBind then

            if GetIsBinding(key, soundData.KeyBind) then
                return requestMenuLeft[i]
            end

        end

    end

    local requestMenuRight = GetRequestMenu(RIGHT_MENU, playerClass)
    for i = 1, #requestMenuRight do

        local soundData = GetVoiceSoundData(requestMenuRight[i])
        if soundData and soundData.KeyBind then

            if GetIsBinding(key, soundData.KeyBind) then
                return requestMenuRight[i]
            end

        end

    end

end

local function UpdateItemsGUIScale(self)
    kBackgroundSize = GUIScale(Vector(225, 48, 0))
    kKeyBindXOffset = GUIScale(20)
    kPadding = GUIScale(9)
    kFontScale = GUIScale(1)
    scaleVector = Vector(1, 1, 1) * kFontScale
    kMenuSize = GUIScale(Vector(300, 300, 0))
    kButtonClipping = GUIScale(6)
    kButtonMaxXOffset = GUIScale(32)
    kConcedeButtonPadding = GUIScale(32)
    kCommanderButtonPadding = GUIScale(18)
end

function GUIRequestMenu:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

function GUIRequestMenu:Initialize()

    self.cachedHudDetail = Client.GetHudDetail()

    UpdateItemsGUIScale(self)

    self.teamType = PlayerUI_GetTeamType()
    self.playerClass = Client.GetIsControllingPlayer() and PlayerUI_GetPlayerClassName() or "Spectator"

    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:SetSize(kMenuSize)
    self.background:SetPosition(-kMenuSize * .5)
    self.background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kMenuTexture[self.teamType]))
    self.background:SetIsVisible(false)

    self.menuButtons = { }

    if self.teamType == kMarineTeamType then
        local player = Client.GetLocalPlayer()
        if player and player.variant and table.icontains(kRoboticMarineVariantIds, player.variant) then
            if table.icontains(kMilitaryMacVariantIds, player.variant) then
                self.playerClass = player:GetClassName() == "Exo" and "ExoMilitaryMac" or "MilitaryMac"
            else
                self.playerClass = player:GetClassName() == "Exo" and "ExoBigMac" or "BigMac"
            end
        end
    end

    -------------
    gIsConcedeButton = self.teamType ~= kNeutralTeamType

    local timer = GetGUIManager():CreateTextItem()
    timer:SetTextAlignmentX(GUIItem.Align_Center)
    timer:SetTextAlignmentY(GUIItem.Align_Center)
    timer:SetFontName(kFontName)
    timer:SetScale(scaleVector)
    GUIMakeFontScale(timer)
    timer:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.background:AddChild(timer)
    self.timerText = timer
    --------------

    self.ejectCommButton = CreateEjectButton(self, self.teamType)
    self.bottomButton = CreateBottomButton(self, self.teamType)
    ------------
    local leftMenu = GetRequestMenuTeam(LEFT_MENU, self.playerClass, self.teamType)
    local numLeftEntries = #leftMenu
    local rightMenu = GetRequestMenuTeam(RIGHT_MENU, self.playerClass, self.teamType)
    local numRightEntries = #rightMenu
    -----------

    for i = 1, numLeftEntries do

        if i > kMaxRequestsPerSide then
            break
        end

        local voiceId = leftMenu[i]
        table.insert(self.menuButtons, CreateMenuButton(self, self.teamType, voiceId, GUIItem.Left, i, numLeftEntries))

    end

    for i = 1, numRightEntries do

        if i > kMaxRequestsPerSide then
            break
        end

        local voideId = rightMenu[i]
        table.insert(self.menuButtons, CreateMenuButton(self, self.teamType, voideId, GUIItem.Right, i, numRightEntries))

    end

    HelpScreen_AddObserver(self)

end

function GUIRequestMenu:OnHelpScreenVisChange(hsVis)

    self.visible_hs = not hsVis -- visible due to help screen?
    if self.background then
        self:SetIsVisible(self.background:GetIsVisible())
    end

end

function GUIRequestMenu:Uninitialize()

    self:SetIsVisible(false)

    if self.background then
        GUI.DestroyItem(self.background)
    end

    self.background = nil
    self.ejectCommButton = nil
    self.bottomButton = nil
    self.timerText = nil
    self.menuButtons = {}

    HelpScreen_RemoveObserver(self)

end

local function GetCanOpenRequestMenu(self)
    return PlayerUI_GetCanDisplayRequestMenu()
end

function GUIRequestMenu:SetIsVisible(isVisible)

    isVisible = isVisible and self.visible_hs

    if self.background then

        local wasVisible = self.background:GetIsVisible()
        if wasVisible ~= isVisible then

            if isVisible and GetCanOpenRequestMenu(self) then

                OnShow_RequestMenu()
                MouseTracker_SetIsVisible(true)
                self.background:SetIsVisible(true)

            else

                OnHide_RequestMenu()
                MouseTracker_SetIsVisible(false)
                self.background:SetIsVisible(false)

            end

        end

    end

end

function VotingConcedeVoteAllowed()
    return PlayerUI_GetGameStartTime() > 0 and Shared.GetTime() - PlayerUI_GetGameStartTime() > kMinTimeBeforeConcede
end

function GUIRequestMenu:Update(deltaTime)
    --TODO Add Taunt throttle

    PROFILE("GUIRequestMenu:Update")
    if self.playerClass == "ReadyRoomPlayer" and Shared.GetTime() > 0.75 then
        --Lame delayed update needed in order for variant networked data to propagate to client (from server message)
        local player = Client.GetLocalPlayer()
        if player and player.variant and table.icontains(kRoboticMarineVariantIds, player.variant) then
            if table.icontains(kMilitaryMacVariantIds, player.variant) then
                self.playerClass = "MilitaryMac"
            else
                self.playerClass = "BigMac"
            end
        end
    end

    if self.background:GetIsVisible() then

        local commanderName = PlayerUI_GetCommanderName()
        self.ejectCommButton.Background:SetIsVisible(commanderName ~= nil)
        -------
        if gIsConcedeButton then
            self.bottomButton.Background:SetIsVisible(VotingConcedeVoteAllowed())
        end

        local timeNow = Shared.GetTime()
        local timeText = ""
        if timeNow < gSendAvailableTime then
            timeText = string.format("%.1f", gSendAvailableTime - timeNow)
        end
        self.timerText:SetText(timeText)

        ----------
        if commanderName then
            local text = string.format("%s %s", Locale.ResolveString("EJECT"), string.UTF8Upper(commanderName))
            local textWidth = GUIScale(Vector(190, 48, 0))
            local extraPadding = #self.menuButtons > 8 and kCommanderButtonPadding or 0
            textWidth.x = self.ejectCommButton.CommanderName:GetTextWidth(text) + 90

            self.ejectCommButton.CommanderName:SetText(text)

            if textWidth.x > 250 then
                textWidth.y = textWidth.x * 0.2
                self.ejectCommButton.Background:SetSize(textWidth)

                self.ejectCommButton.Background:SetPosition(Vector(-textWidth.x * .5, -textWidth.y / 1.5 - kPadding - extraPadding, 0))
            else
                self.ejectCommButton.Background:SetSize(kBackgroundSize)
                self.ejectCommButton.Background:SetPosition(Vector(-kBackgroundSize.x * .5, -kBackgroundSize.y / 2 - kPadding - extraPadding, 0))
            end

        end

        local mouseX, mouseY = Client.GetCursorPosScreen()

        self.selectedButton = nil

        if self.ejectCommButton.Background:GetIsVisible() and GUIItemContainsPoint(self.ejectCommButton.Background, mouseX, mouseY) then
            self.selectedButton = self.ejectCommButton
        end

        if self.bottomButton.Background:GetIsVisible() and GUIItemContainsPoint(self.bottomButton.Background, mouseX, mouseY) then
            self.selectedButton = self.bottomButton
        end

        for _, button in ipairs(self.menuButtons) do
            if GUIItemContainsPoint(button.Background, mouseX, mouseY) then
                self.selectedButton = button
                break
            end
        end

        if not self.selectedButton then
            -- See if there is a "best fit" option
            local screenCenter = Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) / 2
            local mouseVector = Vector(mouseX, mouseY, 0) - screenCenter
            local mouseVectorLengthSquared = mouseVector:GetLengthSquared()

            mouseVector:Normalize()

            local bestAngle = math.pi / 8.0
            local bestButton

            local itemSize, itemCenter, itemVector, dot
            for _, button in ipairs(self.menuButtons) do

                itemSize = button.Background:GetSize()
                itemCenter = GUIItemCalculateScreenPosition(button.Background) + itemSize / 2

                -- If mouse is not beyond the center of any button, not far enough to be doing this test
                itemVector = itemCenter - screenCenter
                if itemVector:GetLengthSquared() > mouseVectorLengthSquared then
                    bestButton = nil
                    break
                end

                local itemOutsideEdge = Vector(itemCenter.x, itemCenter.y, 0)
                if button.Align == GUIItem.Right then
                    itemOutsideEdge.x = itemOutsideEdge.x + itemSize.x
                else
                    itemOutsideEdge.x = itemOutsideEdge.x - itemSize.x
                end
                itemVector = itemOutsideEdge - screenCenter
                itemVector:Normalize()

                dot = Math.DotProduct(mouseVector, itemVector)
                if 0 < dot and math.acos(dot) < bestAngle then
                    bestAngle = math.acos(dot)
                    bestButton = button
                end
            end

            self.selectedButton = bestButton
        end

        local newHudDetail = Client.GetHudDetail()
        local minimal = newHudDetail == kHUDMode.Minimal

        -- Deselect all buttons
        local unselectedButtonTexture = ConditionalValue(minimal, "ui/transparent.dds", kBackgroundTexture[self.teamType])
        self.ejectCommButton.Background:SetTexture(unselectedButtonTexture)
        self.bottomButton.Background:SetTexture(unselectedButtonTexture)

        for _, button in ipairs(self.menuButtons) do

            button.Background:SetTexture(unselectedButtonTexture)

            -- Update KeyBind Strings
            local keyBindString = (button.KeyBind and BindingsUI_GetInputValue(button.KeyBind)) or ""
            if keyBindString ~= nil and keyBindString ~= "" and keyBindString ~= "None" then
                keyBindString = "[" .. string.sub(keyBindString, 1, 1) .. "]"
            else
                keyBindString = ""
            end

            button.KeyBindText:SetText(keyBindString)
        end

        -- Select single
        if self.selectedButton then
            self.selectedButton.Background:SetTexture(ConditionalValue(minimal, "ui/transparent.dds", kBackgroundTextureHighlight[self.teamType]))
        end

        local defaultColor = Color(1, 1, 1, 1)
        local highlightColor = ConditionalValue(minimal, Color(1, 1, 0, 1), defaultColor)

        if self.selectedButton == self.ejectCommButton then
            self.ejectCommButton.CommanderName:SetColor(highlightColor)
        else
            self.ejectCommButton.CommanderName:SetColor(defaultColor)
        end

        if self.selectedButton == self.bottomButton then
            self.bottomButton.ConcedeText:SetColor(highlightColor)
        else
            self.bottomButton.ConcedeText:SetColor(defaultColor)
        end

        for _, button in ipairs(self.menuButtons) do
            if self.selectedButton == button then
                button.Description:SetColor(highlightColor)
            else
                button.Description:SetColor(defaultColor)
            end
        end

        if self.cachedHudDetail ~= newHudDetail then
            self.cachedHudDetail = newHudDetail
            self.background:SetTexture(ConditionalValue(minimal, "ui/transparent.dds", kMenuTexture[self.teamType]))
            self.ejectCommButton.Background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kBackgroundTexture[self.teamType]))
            self.bottomButton.Background:SetTexture(ConditionalValue(self.cachedHudDetail == kHUDMode.Minimal, "ui/transparent.dds", kBackgroundTexture[self.teamType]))
        end

        if not PlayerUI_GetCanDisplayRequestMenu() then
            self:SetIsVisible(false)
        end

    end

end

function GUIRequestMenu:SendKeyEvent(key, down)

    local hitButton = false

    if ChatUI_EnteringChatMessage() then

        self:SetIsVisible(false)
        return false

    end

    if down or key == InputKey.MouseWheelDown or key == InputKey.MouseWheelUp then

        local bindedVoiceId = GetBindedVoiceId(self.playerClass, key)
        if bindedVoiceId then
            SendRequest(bindedVoiceId)
            self:SetIsVisible(false)
            return true
        end

    end

    local mouseX, mouseY = Client.GetCursorPosScreen()

    if self.background:GetIsVisible() then

        if key == InputKey.MouseButton0 or (not down and GetIsBinding(key, "RequestMenu")) then

            if self.selectedButton == self.ejectCommButton and self.ejectCommButton.Background:GetIsVisible() then

                if OnEjectCommanderClicked() then
                    OnClick_RequestMenu()
                end
                hitButton = true

            elseif self.selectedButton == self.bottomButton and self.bottomButton.Background:GetIsVisible() then

                if OnConcedeButtonClicked() then
                    OnClick_RequestMenu()
                end
                hitButton = true

            elseif self.selectedButton then

                if SendRequest(self.selectedButton.VoiceId) then
                    OnClick_RequestMenu()
                end
                hitButton = true

            end

        end

        -- make sure that the menu is not conflicting when the player wants to attack
        if (not hitButton and key == InputKey.MouseButton0) or key == InputKey.MouseButton1 then

            self:SetIsVisible(false)
            return false

        end

    end

    local success = false

    if GetIsBinding(key, "RequestMenu") and PlayerUI_GetCanDisplayRequestMenu() then

        if self.requestMenuKeyDown ~= down then
            self:SetIsVisible(down)
        end
        self.requestMenuKeyDown = down

        return true

    end

    -- Return true only when the player clicked on a button, so you wont start attacking accidentally.
    if hitButton then

        if down then
            if not self.background:GetIsVisible() and PlayerUI_GetCanDisplayRequestMenu() then
                self:SetIsVisible(true)
            else

                self:SetIsVisible(false)
                PlayerUI_OnRequestSelected()

            end

        end

        success = true

    end

    return success

end

function GUIRequestMenu:OnLocalPlayerChanged(newPlayer)

    self:Uninitialize()
    self:Initialize()

end

local function OnCommandChuckle()
    local player = Client.GetLocalPlayer()
    if player:isa("Alien") and player:GetTeamNumber() ~= kTeamReadyRoom then
        SendRequest(21)
    end
end

Event.Hook("Console_chuckle", OnCommandChuckle)

local function OnCommandRequestWeld()
    local player = Client.GetLocalPlayer()
    if player:isa("Marine") or player:isa("Exo") and player:GetTeamNumber() ~= kTeamReadyRoom then
        SendRequest(5)
    end
end

Event.Hook("Console_requestweld", OnCommandRequestWeld)

Event.Hook("Console_disease", function()
    SendRequest(kVoiceId.Disease)
end)
Event.Hook("Console_ohoo", function()
    SendRequest(kVoiceId.XuanOhoo)
end)
Event.Hook("Console_rea", function()
    SendRequest(kVoiceId.XuanRea)
end)
Event.Hook("Console_aha", function()
    SendRequest(kVoiceId.XuanAha)
end)
Event.Hook("Console_kthulu", function()
    SendRequest(kVoiceId.OttoKTHULU)
end)
Event.Hook("Console_oxg", function()
    SendRequest(kVoiceId.OttoOXG)
end)
Event.Hook("Console_onds", function()
    SendRequest(kVoiceId.OttoONDS)
end)
Event.Hook("Console_jchz", function()
    SendRequest(kVoiceId.OttoJCHZ)
end)
Event.Hook("Console_woof", function()
    SendRequest(kVoiceId.XuanWoof)
end)
Event.Hook("Console_hitme", function()
    SendRequest(kVoiceId.Hitme)
end)
Event.Hook("Console_wu", function()
    SendRequest(kVoiceId.Wu)
end)
Event.Hook("Console_ah", function()
    SendRequest(kVoiceId.Ah)
end)
Event.Hook("Console_slap", function()
    SendRequest(kVoiceId.Slap)
end)
Event.Hook("Console_aniki", function()
    SendRequest(kVoiceId.AnikiSpeak)
end)
Event.Hook("Console_scream", function()
    SendRequest(kVoiceId.Scream)
end)

--?
Event.Hook("Console_pyro", function()
    SendRequest(kVoiceId.Pyro)
end)

Event.Hook("Console_pyro2", function()
    SendRequest(kVoiceId.PyroLaugh)
end)

Event.Hook("Console_screamlong", function()
    SendRequest(kVoiceId.ScreamLong,kScreamLongItemId)
end)
Event.Hook("Console_jester", function()
    SendRequest(kVoiceId.Jester,kJesterItemId)
end)

Event.Hook("Console_aatrox", function()
    SendRequest(kVoiceId.Aatrox,kAatroxItemId)
end)

Event.Hook("Console_aatrox2", function()
    SendRequest(kVoiceId.AatroxLaugh,kAatroxLaughItemId)
end)
Event.Hook("Console_randomdisease", function()
    SendRequest(math.random(kVoiceId.Disease, kVoiceId.AnikiSpeak))
end)

-- local function OnS6Legend()
--     SendRequest(kVoiceId.XuanStory)
-- end
-- Event.Hook("Console_s6legend",OnS6Legend)

-- local function OnLiberity()
--     SendRequest(kVoiceId.Liberity)
-- end
-- Event.Hook("Console_liberity",OnLiberity)

-- local function OnDuiDuiDui()
--     SendRequest(kVoiceId.DuiDuiDui)
-- end
-- Event.Hook("Console_duiduidui",OnDuiDuiDui)


