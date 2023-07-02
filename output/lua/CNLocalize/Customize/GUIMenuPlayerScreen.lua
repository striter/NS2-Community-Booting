-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/menu2/PlayerScreen/GUIMenuPlayerScreen.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    The screen that contains player profile information, the friends list, and the customization
--    screen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/menu2/GUIMenuScreen.lua")

Script.Load("lua/GUI/GUIText.lua")

Script.Load("lua/menu2/PlayerScreen/CallingCards/GUIMenuCallingCardCustomizer.lua")
Script.Load("lua/menu2/PlayerScreen/FriendsList/GUIMenuFriendsList.lua")
Script.Load("lua/menu2/PlayerScreen/GUIMenuPlayerScreenPullout.lua")
Script.Load("lua/menu2/PlayerScreen/GUIMenuSkillTierIcon.lua")
Script.Load("lua/menu2/PlayerScreen/Badges/GUIMenuBadgesCustomizer.lua")
Script.Load("lua/menu2/PlayerScreen/GUIMenuPlayerProfilePicture.lua")
Script.Load("lua/menu2/PlayerScreen/Customize/GUIMenuCustomizeScreen.lua")

Script.Load("lua/menu2/MenuStyles.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")
Script.Load("lua/menu2/GUIMenuText.lua")
Script.Load("lua/menu2/GUIMenuCoolGlowBox.lua")

---@class GUIMenuPlayerScreen : GUIMenuScreen
local baseClass = GUIMenuScreen
class "GUIMenuPlayerScreen" (GUIMenuScreen)


-- Maximum width the pullout can be, determined by the screen size.
GUIMenuPlayerScreen:AddClassProperty("_MaxWidth", 100)


local kSteamProfileURL = "http://steamcommunity.com/profiles/"

local kPulloutWidth = 116
local kPulloutGap = 10

local kScreenEdgeXSpacing = kPulloutWidth * 2 + kPulloutGap * 2 -- so it doesn't overlap the other menu's pullout.
local kTopEdgeY = 456
local kBottomEdgeYSpacing = 100
local kInteriorPadding = 48
local kContentsSpacing = 48
local kSmallerContentsSpacing = 24

local kLeftWidth = 800

local kMinWidth = 1920

local kCustomizeLeftOffset = 0
local kCustomizeTopOffset = 0

local kAvatarSize = 200
local kAvatarTextSeparation = 32 -- spacing between name and avatar.

local kSkillTierIconScale = 2

local kPlayerNameFont = ReadOnly{family = "Microgramma", size = 40}

local kCustomizeTitleFont = ReadOnly{family = "MicrogrammaBold", size = 42}        --ReadOnly{family = "AgencyBold", size = 64}

local kBounceAnimationName = "heyLookAtMeAnimation"
local kViewCountOptionName = "playerScreenOpenCount"

local kCustomizeTitleTopPad = kContentsSpacing --15

-- Until the user has viewed this screen at least this many times, make it do a little bounce
-- animation so they notice it.
local kScreenViewReminderThreshold = 1

-- Awesome bouncing ball formula(s).
-- https://twitter.com/desmos/status/522182031368024064
local HeyLookAtMeAnimation = ReadOnly
{
    gravity = -1600.0,
    startingForce = 400,
    restitution = 0.5,
    cycleTime = 3.0,
    
    func = function(obj, time, params, currentValue, startValue, endValue, startTime)
        
        local r = params.restitution
        
        -- Time to use for animation (cycles).
        local currentTime = time % params.cycleTime
        
        -- Time of first bounce.
        local t1 = (-2.0 * params.startingForce) / params.gravity
        
        local tEnd = t1 / (1-r)
        if currentTime >= tEnd then
            return currentValue, false
        end
        
        -- Total number of bounces so far.
        local bounceCount = math.floor( math.log(1 - ((currentTime*(1-r)) / t1), r) )
        
        local energyLossFactor = math.pow(r, bounceCount)
        
        -- Time since the last bounce
        local timeSinceLastBounce = currentTime - (t1 * (1 - energyLossFactor)) / (1 - r)
        
        local height = params.startingForce * energyLossFactor * timeSinceLastBounce +
                0.5 * params.gravity * timeSinceLastBounce * timeSinceLastBounce
        
        -- Bounce along the x axis.  This is specifically made for the player screen.
        return currentValue + Vector(height, 0, 0), false
    
    end
}

local playerScreen
function GetPlayerScreen()
    return playerScreen
end

local mockupRes = Vector(3840, 2160, 0)
local function UpdateResolutionScaling(self, newX, newY)
    
    local res = Vector(newX, newY, 0)
    local scale = res / mockupRes
    scale = math.min(scale.x, scale.y)
    
    self:SetScale(scale, scale)
    
    -- Compute width of player screen.
    local screenWidth = res.x / scale -- in "mockup" pixels...
    local width = screenWidth - kScreenEdgeXSpacing * 2
    self:Set_MaxWidth(width)
    
    -- Compute height of player screen.
    local screenHeight = res.y / scale -- in "mockup" pixels...
    local screenBottomEdgeY = screenHeight - kBottomEdgeYSpacing
    self:SetHeight(screenBottomEdgeY - kTopEdgeY)
    
    -- Compute Y position of player screen (top edge Y coordinate in screen space, not mockup space).
    self:SetY(kTopEdgeY * scale)
    
end

local function UpdateHeyLookAtMeAnimation(self)
    
    local shouldBePlaying = not self:GetScreenDisplayed() and
            Client.GetOptionInteger(kViewCountOptionName, 0) < kScreenViewReminderThreshold
    
    local isPlaying = self:GetIsAnimationPlaying("Position", kBounceAnimationName)
    if shouldBePlaying and not isPlaying then
        self:AnimateProperty("Position", nil, HeyLookAtMeAnimation, kBounceAnimationName)
    elseif not shouldBePlaying and isPlaying then
        self:ClearPropertyAnimations("Position", kBounceAnimationName)
    end
    
end
GUIMenuPlayerScreen._UpdateHeyLookAtMeAnimation = UpdateHeyLookAtMeAnimation

local function OnPulloutPressed(self)
    
    if self:GetScreenDisplayed() then
        
        PlayMenuSound("CancelChoice")
        
        -- Clear the history by going back to the nav bar.
        GetScreenManager():DisplayScreen("NavBar")
        GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)
        
        -- Start the "look at me" animation, if necessary.
        UpdateHeyLookAtMeAnimation(self)
        
    else
        
        PlayMenuSound("ButtonClick")
        GetScreenManager():DisplayScreen("PlayerScreen")
        
        -- Make a note that the player actually clicked the button to view this screen.
        local viewCount = Client.GetOptionInteger(kViewCountOptionName, 0)
        if viewCount < kScreenViewReminderThreshold then
            viewCount = viewCount + 1
            Client.SetOptionInteger(kViewCountOptionName, viewCount)
        end
        
        -- Stop the "look at me" animation, if it's playing.
        UpdateHeyLookAtMeAnimation(self)
        
    end
    
end

local function UpdateRightSideWidth(self)
    local totalWidth = self:GetSize().x -- 150
    local leftWidth = self.leftSide:GetSize().x
    local scale = self:GetScale().x
    local rightWidth = math.max(totalWidth - leftWidth, kMinWidth)
    self.rightSide:SetWidth(rightWidth)
end

local function UpdateWidth(self)
    local maxWidth = self:Get_MaxWidth()
    local scale = self:GetScale().x
    local tMin = Client.GetScreenWidth() / scale
    local desiredWidth = self.leftSide:GetSize().x + self.rightSide:GetSize().x + kScreenEdgeXSpacing * 2
    local aspect = Client.GetScreenWidth() / Client.GetScreenHeight()
    local aspectHeight = desiredWidth / aspect

    if aspectHeight > self.rightSide:GetSize().y then
        local dH = aspectHeight - self.rightSide:GetSize().y
        local adjHeight = aspectHeight - dH
        local adjWidth = adjHeight * aspect + kScreenEdgeXSpacing * 2
        desiredWidth = adjWidth
    end

    local newWidth = math.max (math.min( maxWidth, desiredWidth ), kMinWidth ) 
    self:SetWidth( newWidth )    
end

function OpenPlayerProfile(self)
    local steamId = Client.GetSteamId()
    steamId = Shared.ConvertSteamId32To64(steamId)
    Client.ShowWebpage(string.format("%s%s/", kSteamProfileURL, steamId))
end

local function OnAvatarPressed(self)
    PlayMenuSound("ButtonClick")
    OpenPlayerProfile(self)
end

local function UpdateFriendsListHeight(self)
    
    local desiredHeight = self.leftSide:GetSize().y
    local actualHeight = self.leftSideContents:GetSize().y
    local excessHeight = actualHeight - desiredHeight
    
    local currentFriendsListHeight = self.friendsList:GetSize().y
    self.friendsList:SetHeight(currentFriendsListHeight - excessHeight)
    
end

local function UpdateRightOfAvatarWidth(self)
    self.rightOfAvatar:SetWidth(math.max(self.leftSideContents:GetSize().x - kAvatarSize - kAvatarTextSeparation, 32))
end

local function UpdatePlayerNameTextScale(self)
    
    local space = self.rightOfAvatar:GetSize().x
    
    -- NOTE: textSize is unstable.  Given the same text, font, and fontSize, textSize can still be
    -- a different value due to the screen resolution/scaling.  This shouldn't be a problem here
    -- since all we need is an approximate size.  Eg. after we set the text scale, that _may_
    -- result in a different source font being picked, which means we'll end up maybe a few pixels
    -- off our target size.  This is acceptable, as long as it doesn't oscillate/flicker -- which it
    -- shouldn't since the only two events that kick this off are the text changing, or the size of
    -- the area changing -- not the size of the text.
    local textSize = self.playerName:GetSize().x
    
    -- Maximum scale is 1.0 -- ie we're only wanting to scale text _down_ to make it fit.
    local scale = 1.0
    if textSize ~= 0 then
        scale = math.min(scale, space / textSize)
    end
    
    self.playerName:SetScale(scale, scale)

end

local function OnRightOfAvatarWidthChanged(self, size, prevSize)
    if prevSize.x == size.x then return end -- don't care about height-only changes.
    UpdatePlayerNameTextScale(self)
end

local function OnPlayerLevelChanged(self, level)
    self.skillTierIcon:SetIsRookie(GetLocalPlayerProfileData():GetIsRookie())
end

local function UpdateTopStuffHeight(self)
    self.topStuff:SetHeight(math.max(self.rightOfAvatar:GetSize().y, kAvatarSize))
end

local function UpdateLeftSideContentsWidth(self)
    self.leftSideContents:SetWidth(self.leftSide:GetSize().x - kInteriorPadding*2)
end

local function UpdateBadgeCustomizerScale(self)
    
    local bcLayoutWidth = self.badgeCustomizer:GetSize().x
    local availableWidth = self.rightOfAvatar:GetSize().x - kSmallerContentsSpacing*2
    
    local scale = 1.0
    if bcLayoutWidth > 0.0 then
        scale = math.min(1.0, availableWidth / bcLayoutWidth)
    end
    
    self.badgeCustomizer:SetScale(scale, scale)
    
end


function GUIMenuPlayerScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    playerScreen = self
    
    PushParamChange(params, "screenName", "PlayerScreen")
    baseClass.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")
    
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", UpdateResolutionScaling)
    UpdateResolutionScaling(self, Client.GetScreenWidth(), Client.GetScreenHeight())
    
    self.back = CreateGUIObject("back", GUIMenuCoolGlowBox, self)
    self.back:SetLayer(-1)
    self.back:HookEvent(self, "OnSizeChanged", self.back.SetSize)
    self.back:SetSize(self:GetSize())
    
    self.pullout = CreateGUIObject("pullout", GUIMenuPlayerScreenPullout, self,
    {
        anchor = Vector(1, 0, 0),
        position = Vector(kPulloutGap, 0, 0),
        size = Vector(kPulloutWidth, 32, 0),
    })
    self.pullout:HookEvent(self, "OnSizeChanged", self.pullout.SetHeight)
    self.pullout:SetHeight(self:GetSize().y)
    self:HookEvent(self.pullout, "OnPressed", OnPulloutPressed)
    
    self.leftSide = CreateGUIObject("leftSide", GUIObject, self)
    self.leftSide:SetWidth(kLeftWidth)
    self.leftSide:SetHeight(self:GetSize().y)
    self.leftSide:HookEvent(self, "OnSizeChanged", self.leftSide.SetHeight)

    self.rightSide = CreateGUIObject("rightSide", GUIObject, self, 
    {
        position = Vector( -25, 0, 0 ),
        size = Vector(1920, 1080, 0)
    })
    self.rightSide:AlignTopRight()
    self:HookEvent(self, "OnSizeChanged", UpdateRightSideWidth)
    self:HookEvent(self.leftSide, "OnSizeChanged", UpdateRightSideWidth)
    UpdateRightSideWidth(self)
    self.rightSide:HookEvent(self, "OnSizeChanged", self.rightSide.SetHeight)
    self.rightSide:SetHeight( self:GetSize().y )

    self.leftSideContents = CreateGUIObject("leftSideContents", GUIListLayout, self.leftSide,
    {
        orientation = "vertical",
        fixedMinorSize = true,
        spacing = kContentsSpacing,
        frontPadding = kInteriorPadding,
        backPadding = kInteriorPadding,
    })
    self:HookEvent(self.leftSide, "OnSizeChanged", UpdateLeftSideContentsWidth)
    UpdateLeftSideContentsWidth(self)
    self.leftSideContents:AlignTop()
    
    self.topStuff = CreateGUIObject("topStuff", GUIObject, self.leftSideContents)
    self.topStuff:SetWidth(self.leftSideContents:GetSize())
    self.topStuff:HookEvent(self.leftSideContents, "OnSizeChanged", self.topStuff.SetWidth)
    
    self.avatarHolder = CreateGUIObject("avatarHolder", GUIMenuCoolGlowBox, self.topStuff,
    {
        position = Vector(-4, -4, 0),
        size = Vector(kAvatarSize + 8, kAvatarSize + 8, 0),
    })
    
    self.avatar = CreateGUIObject("avatar", GUIMenuPlayerProfilePicture, self.avatarHolder)
    self.avatar:SetSize(kAvatarSize, kAvatarSize)
    self.avatar:AlignCenter()
    self.avatar:SetTexture(GetLocalAvatarTextureName())
    self:HookEvent(self.avatar, "OnPressed", OnAvatarPressed)
    
    self.rightOfAvatar = CreateGUIObject("rightOfAvatar", GUIListLayout, self.topStuff,
    {
        orientation = "vertical",
        spacing = kSmallerContentsSpacing,
        fixedMinorSize = true,
    })
    self.rightOfAvatar:AlignTopRight()
    self.rightOfAvatar:SetHeight(kAvatarSize)
    self:HookEvent(self.topStuff, "OnSizeChanged", UpdateRightOfAvatarWidth)
    UpdateRightOfAvatarWidth(self)
    self:HookEvent(self.rightOfAvatar, "OnSizeChanged", UpdateTopStuffHeight)
    
    local playerNameClass = GUIMenuText
    playerNameClass = GetCursorInteractableWrappedClass(playerNameClass)
    self.playerName = CreateGUIObject("playerName", playerNameClass, self.rightOfAvatar,
    {
        font = kPlayerNameFont,
        text = GetLocalPlayerProfileData():GetPlayerName(),
        align = "top",
    })

    self.playerName:HookEvent(GetOptionsMenu():GetOptionWidget("nickname"), "OnValueChanged", self.playerName.SetText)

    self.playerName:HookEvent(GetLocalPlayerProfileData(), "OnPlayerNameChanged", self.playerName.SetText)
    self:HookEvent(self.playerName, "OnPressed", OpenPlayerProfile)
    self:HookEvent(self.rightOfAvatar, "OnSizeChanged", OnRightOfAvatarWidthChanged)
    self:HookEvent(self.playerName, "OnTextChanged", UpdatePlayerNameTextScale)

    UpdatePlayerNameTextScale(self)
    
    self.badgeCustomizer = CreateGUIObject("badgeCustomizer", GUIMenuBadgesCustomizer, self.rightOfAvatar)
    self.badgeCustomizer:AlignTop()
    self.badgeCustomizer:SetLayer(10) -- above skill tier badge for when it is closing.
    self:HookEvent(self.badgeCustomizer, "OnSizeChanged", UpdateBadgeCustomizerScale)
    self:HookEvent(self.rightOfAvatar, "OnSizeChanged", UpdateBadgeCustomizerScale)
    
    self.skillTierIcon = CreateGUIObject("skillTierIcon", GUIMenuSkillTierIcon, self.rightOfAvatar)
    self.skillTierIcon:SetScale(kSkillTierIconScale, kSkillTierIconScale)
    self.skillTierIcon:AlignBottom()
    self.skillTierIcon:SetSteamID64(Shared.ConvertSteamId32To64(Client.GetSteamId()))
    self.skillTierIcon:SetIsRookie(GetLocalPlayerProfileData():GetIsRookie())
    self.skillTierIcon:SetSkill(GetLocalPlayerProfileData():GetSkill())
    self.skillTierIcon:SetAdagradSum(GetLocalPlayerProfileData():GetAdagradSum())
    self.skillTierIcon:HookEvent(GetLocalPlayerProfileData(), "OnSkillChanged", self.skillTierIcon.SetSkill)
    self.skillTierIcon:HookEvent(GetLocalPlayerProfileData(), "OnAdagradSumChanged", self.skillTierIcon.SetAdagradSum)
    self:HookEvent(GetLocalPlayerProfileData(), "OnLevelChanged", OnPlayerLevelChanged)
    
    self.callingCardCustomizer = CreateGUIObject("callingCardCustomizer", GUIMenuCallingCardCustomizer, self.leftSideContents)
    self.callingCardCustomizer:SetWidth(self.leftSideContents:GetSize().x)
    
    self.friendsList = CreateGUIObject("friendsList", GUIMenuFriendsList, self.leftSideContents)
    self.friendsList:HookEvent(self.leftSideContents, "OnSizeChanged", self.friendsList.SetWidth)
    self.friendsList:SetWidth(self.leftSideContents:GetSize().x)
    self.friendsList:AlignBottomLeft()
    
    self:HookEvent(self.leftSideContents, "OnSizeChanged", UpdateFriendsListHeight)
    self:HookEvent(self.leftSide, "OnSizeChanged", UpdateFriendsListHeight)
    UpdateFriendsListHeight(self)

    local function UpdateCustomizeSize(self)
        local parent = self:GetParent()
        local title = parent:GetChild("customizeTitle")
        self:SetWidth(parent:GetSize().x)
        local aspect = Client.GetScreenWidth() / Client.GetScreenHeight()
        self:SetHeight( parent:GetSize().x / aspect - kContentsSpacing)
        local tOffset = self:GetSize().y * 0.5
        title:SetY( -tOffset )
        title:SetX( kContentsSpacing )
        self:SetY( kContentsSpacing )   --offset to give enough room for customize title
    end

    local csInitSize = Vector( self.rightSide:GetSize().x, self.rightSide:GetSize().y, 0 )
    self.customizeScreen = CreateGUIObject("customizeScreen", GUIMenuCustomizeScreen, self.rightSide,
    {
        --position = Vector(0, 0, 0),
        size = csInitSize,
    })
    self.customizeScreen:AlignLeft()
    self.customizeScreen:HookEvent(self.rightSide, "OnSizeChanged", UpdateCustomizeSize)
    self.customizeScreen:SetWidth(csInitSize.x)
    self.customizeScreen:SetHeight(csInitSize.y)

    self.customizeTitle = CreateGUIObject("customizeTitle", GUIText, self.rightSide, 
    {
        text = Locale.ResolveString("CUSTOMIZATION"),     --TODO localize
        font = kCustomizeTitleFont,
        color = MenuStyle.kOptionHeadingColor, 
    })
    self.customizeTitle:AlignLeft()

    self:HookEvent(self, "OnSizeChanged", UpdateWidth)
    self:HookEvent(self.leftSide, "OnSizeChanged", UpdateWidth)
    self:HookEvent(self, "On_MaxWidthChanged", UpdateWidth)
    UpdateWidth(self)
    UpdateCustomizeSize(self.customizeScreen)

    -- Initial state is closed.
    self.leftSide:BlockChildInteractions()
    self.rightSide:BlockChildInteractions()
    self:SetHotSpot(1, self:GetHotSpot().y)
    self:SetX(-kPulloutGap * self:GetScale().x)
    
    self.rightSide:SetOpacity(0)

    -- If the player hasn't used the player screen yet (like... ever, not just this launch), then
    -- make it do a little bounce animation when closed so that they notice it.
    UpdateHeyLookAtMeAnimation(self)
    
    -- Make shortcut "skins" link on nav bar glow when customize/player screen is open.
    if not kInGame then -- in-game link is a different button.
        local navBar = GetNavBar()
        assert(navBar)
        navBar:HookEvent(self, "OnScreenDisplay", function(self2) self2:SetGlowingButtonIndex(3) end)
        navBar:HookEvent(self, "OnScreenHide", function(self2) self2:SetGlowingButtonIndex(nil) end)
    end
    
    self:HookEvent(self, "OnScreenDisplay", function() DoPopupsForUnopenedBundles( GetCustomizeScreen().RefreshOwnedItems ) end)    
end

function GUIMenuPlayerScreen:Display(immediate)
    
    if not GUIMenuScreen.Display(self, immediate) then
        return -- already being displayed!
    end
    
    self.leftSide:AllowChildInteractions()
    self.rightSide:AllowChildInteractions()
    self.pullout:PointLeft()
    
    if immediate then
        self:ClearPropertyAnimations("HotSpot")
        self:ClearPropertyAnimations("Position")
        self:SetHotSpot(0, self:GetHotSpot().y)
        self:SetPosition(0, self:GetPosition().y)
    else
        self:AnimateProperty("HotSpot", Vector(0, self:GetHotSpot().y, 0), MenuAnimations.FlyInFast)
        self:AnimateProperty("Position", Vector(0, self:GetPosition().y, 0), MenuAnimations.FlyInFast)
    end
    
    self.friendsList:Display(immediate)
    self.customizeScreen:Display(immediate)
end

function GUIMenuPlayerScreen:Hide(immediate)
    
    if not GUIMenuScreen.Hide(self, immediate) then
        return -- already hidden!
    end
    
    self.leftSide:BlockChildInteractions()
    self.rightSide:BlockChildInteractions()
    self.pullout:PointRight()
    
    if immediate then
        self:ClearPropertyAnimations("HotSpot")
        self:ClearPropertyAnimations("Position")
        self:SetHotSpot(1, self:GetHotSpot().y)
        self:SetPosition(-kPulloutGap * self:GetScale().x, self:GetPosition().y)
    else
        self:AnimateProperty("HotSpot", Vector(1, self:GetHotSpot().y, 0), MenuAnimations.FlyInFast)
        self:AnimateProperty("Position", Vector(-kPulloutGap * self:GetScale().x, self:GetPosition().y, 0), MenuAnimations.FlyInFast)
    end

    self.customizeScreen:Hide()
end

function GUIMenuPlayerScreen:SetUnread()
    Client.SetOptionInteger(kViewCountOptionName, 0)
    self:_UpdateHeyLookAtMeAnimation()
end

function GUIMenuPlayerScreen:OnBack()
    
    -- Clear the history by going back to the nav bar.
    GetScreenManager():DisplayScreen("NavBar")
    GetScreenManager():GetCurrentScreen():SetPreviousScreenName(nil)

end

Event.Hook("Console_reset_player_screen_view_count", function()
    Log("Reset the view count of the play screen to zero.  It should start to crave attention now.")
    Client.SetOptionInteger(kViewCountOptionName, 0)
    GetPlayerScreen():_UpdateHeyLookAtMeAnimation()
end)
