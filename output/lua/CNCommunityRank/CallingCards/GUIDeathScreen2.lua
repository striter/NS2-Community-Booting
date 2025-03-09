local kBackgroundDesiredShowTime = 2 -- Desired seconds to show the black background
local kContentsDesiredShowTime = 5 -- How long to show the calling card, name, etc
local kBackgroundFadeInDelay = 0.45 -- When the black background starts fading in, compared to the contents

local baseInitialize = GUIDeathScreen2.Initialize
local kFontName = "Agency"
local kSmallFontSize = 18
function GUIDeathScreen2:Initialize(params, errorDepth)
    baseInitialize(self,params,errorDepth)

    self.killerSign = CreateGUIObject("killerSign", GUIText, self.background)
    self.killerSign:AlignTop()
    self.killerSign:SetFont(kFontName, kSmallFontSize)
    self.killerSign:SetColor(1,1,1)
    self.killerSign:SetPosition(0, self.callingCard:GetSize().y + 135)
    table.insert(self.contentsObjs, self.killerSign)
end

function GUIDeathScreen2:ShowBackground(show, instant)

     local opacityTarget = show and 1 or 0
     local currentOpacity = self:GetOpacity()
     self:ClearPropertyAnimations("Opacity")
     self:SetOpacity(currentOpacity) -- When clearing animations, it'll set it to animation's baseValue.

     if instant then
         self:SetOpacity(opacityTarget)
     else
         self:AnimateProperty("Opacity", opacityTarget, MenuAnimations.DeathScreenFade)
     end

end

local kShowingCardID = -1
local callingCardStartTime = 0
function GUIDeathScreen2:UpdateContentsFromKillerInfo()

    local killerInfo = GetAndClearKillerInfo()

    if not killerInfo.Name then -- Killer name not set yet (sent via network message)
        return false
    end

    kShowingCardID = killerInfo.CallingCard or kNaturalCausesCallingCard
    callingCardStartTime = Shared.GetTime()
    
    self:ShowDeathCinematic(true)
    self:CleanupTimedCallbacks()

    self.backgroundFadeInCallback = self:AddTimedCallback(self.FadeInBackground, kBackgroundFadeInDelay, false) -- show black background

    -- lifetime callbacks
    self.contentsMaxShowtimeReachedCallback = self:AddTimedCallback(self.OnContentsMaxShowtimeReached, kContentsDesiredShowTime, false)
    self.backgroundMaxShowtimeReachedCallback = self:AddTimedCallback(self.OnBackgroundMaxShowtimeReached, kBackgroundDesiredShowTime, false)

    -- Now we have the info ready, we can finally start updating the UI
    self.killerName:SetText(killerInfo.Name) -- Always available
    local cardTextureDetails = GetCallingCardTextureDetails(kShowingCardID)
    self.callingCard:SetTexture(cardTextureDetails.texture)
    self.callingCard:SetTexturePixelCoordinates(cardTextureDetails.texCoords)
    self.callingCard:SetVisible(true)

    local killerSign = killerInfo.Sign
    local killerSignVisible = killerSign and killerSign ~= ""
    if killerSignVisible then
        self.killerSign:SetText(killerSign)
    end
    self.killerSign:SetVisible(killerSignVisible)
    
    local context = killerInfo.Context
    if context == kDeathSource.Player or context == kDeathSource.Structure then -- We have information about the player who killed us (Structure = Commander)
        self.killerName:SetVisible(true)

        self.skillbadge:SetSteamID64(Shared.ConvertSteamId32To64(killerInfo.SteamId))
        self.skillbadge:SetIsRookie(killerInfo.IsRookie)
        self.skillbadge:SetSkill(killerInfo.Skill)
        self.skillbadge:SetAdagradSum(killerInfo.AdagradSum)
        self.skillbadge:SetIsBot(killerInfo.SteamId == 0)
        self.skillbadge:SetVisible(true)

        -- Right Side
-----------------------     JEEZ WTF
        self.killedWithLabel2:SetText(Locale.ResolveString(string.upper(EnumToString(kDeathMessageIcon, killerInfo.WeaponIconIndex))))
----------------------
        local xOffset = DeathMsgUI_GetTechOffsetX(0)
        local yOffset = DeathMsgUI_GetTechOffsetY(killerInfo.WeaponIconIndex)
        local iconWidth = DeathMsgUI_GetTechWidth(0)
        local iconHeight = DeathMsgUI_GetTechHeight(0)

        self.weaponIcon:SetPosition(self.killedWithLabel2:GetSize().x, 0)
        self.weaponIcon:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + iconWidth, yOffset + iconHeight)

        local showRightSide = killerInfo.WeaponIconIndex ~= kDeathMessageIcon.None
        self.killedWithLabel:SetVisible(showRightSide)
        self.killedWithLabel2:SetVisible(showRightSide)
        self.weaponIcon:SetVisible(showRightSide)


    else -- Hiding skill badge, and right side (StructureNoCommander, DeathTrigger, KilledSelf), but everything else is visible.



        self.killerName:SetVisible(true)
        self.skillbadge:SetVisible(false)

        -- Right Side
        local showRightSide = context == kDeathSource.KilledSelf and killerInfo.WeaponIconIndex ~= kDeathMessageIcon.None
        if showRightSide then

            local xOffset = DeathMsgUI_GetTechOffsetX(0)
            local yOffset = DeathMsgUI_GetTechOffsetY(killerInfo.WeaponIconIndex)
            local iconWidth = DeathMsgUI_GetTechWidth(0)
            local iconHeight = DeathMsgUI_GetTechHeight(0)

            self.killedWithLabel:SetVisible(true)
-----------------------     JEEZ WTF x2
            self.killedWithLabel2:SetText(Locale.ResolveString(string.upper(EnumToString(kDeathMessageIcon, killerInfo.WeaponIconIndex))))
-----------------------
            self.killedWithLabel2:SetVisible(true)
            self.weaponIcon:SetPosition(self.killedWithLabel2:GetSize().x, 0)
            self.weaponIcon:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + iconWidth, yOffset + iconHeight)
            self.weaponIcon:SetVisible(true)

        else

            self.killedWithLabel:SetVisible(false)
            self.killedWithLabel2:SetVisible(false)
            self.weaponIcon:SetVisible(false)

        end

    end

    -- If the player does not have a calling card, move the killer name and it's badge to the center, height-wise
    -- Also make sure calling card is not visible.
    if killerInfo.CallingCard == kCallingCards.None then

        self.callingCard:SetVisible(false)
        self.killerName:SetY((self.background:GetSize().y / 2) - (self.killerName:GetSize().y / 2))
        self.skillbadge:SetY(self.killerName:GetPosition().y + self.killerName:GetSize().y)

    else -- We have a calling card to display, so make sure everything is in the proper place.

        self.callingCard:SetVisible(true) -- Just in case
        self.killerName:SetPosition(0, self.callingCard:GetSize().y + 5)

        local centerBorderSize = 22
        local spaceLeftY = self.background:GetSize().y - centerBorderSize - (self.killerName:GetSize().y + self.killerName:GetPosition().y) - self.skillbadge:GetSize().y
        local paddingY = spaceLeftY / 2
        self.skillbadge:SetY(self.killerName:GetSize().y + self.killerName:GetPosition().y + paddingY - 10)

    end

    return true

end


local baseOnUpdate = GUIDeathScreen2.OnUpdate
function GUIDeathScreen2:OnUpdate()
    baseOnUpdate(self)
    local isDead = PlayerUI_GetIsDead()
    if isDead then
        local isFrame,pixels = GetCallingCardTextureFrameDetails(kShowingCardID,Shared.GetTime() - callingCardStartTime,true)
        if isFrame then
            self.callingCard:SetTexturePixelCoordinates(pixels)
        end
    end
end
