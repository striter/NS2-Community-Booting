
local kBackgroundTexture = PrecacheAsset("ui/deathscreen/background.dds")

local kCallingCardSize = Vector(274, 274, 0)
local kBigFontName = Fonts.kAgencyFB_Large
local kMediumFontName = Fonts.kAgencyFB_Medium
local kSmallFontName = Fonts.kAgencyFB_Small

local kCenterSectionWidth = 310
local kSectionPadding = 35 -- Padding between text and center section
local kBackgroundDesiredShowTime = 2 -- Desired seconds to show the black background
local kContentsDesiredShowTime = 5 -- How long to show the calling card, name, etc
local kBackgroundFadeInDelay = 0.45 -- When the black background starts fading in, compared to the contents
local kSubtextColor = HexToColor("8aa5ad")

local function UpdateResolutionScaling(self, newX, newY)

    local mockupRes = Vector(1920, 1080, 0)
    local screenRes = Vector(newX, newY, 0)
    local scale = screenRes / mockupRes
    scale = math.min(scale.x, scale.y)

    self:SetSize(newX, newY)
    self.background:SetScale(scale, scale)

end

function GUIDeathScreen2:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    GUIObject.Initialize(self, params, errorDepth)

    self.contentsObjs = {}

    self:SetSize(Client.GetScreenWidth(), Client.GetScreenHeight())
    self:SetLayer(kGUILayerDeathScreen) -- GUI rendering is depth-first...
    self:SetColor(0,0,0,1)
    self:SetOpacity(0)

    self.background = CreateGUIObject("background", GUIObject, self)
    self.background:AlignCenter()
    self.background:SetTexture(kBackgroundTexture)
    self.background:SetSizeFromTexture()
    self.background:SetColor(1,1,1)
    table.insert(self.contentsObjs, self.background)

    self.callingCard = CreateGUIObject("callingCard", GUIObject, self.background)
    self.callingCard:SetSize(kCallingCardSize)
    self.callingCard:SetColor(1,1,1)
    self.callingCard:AlignTop()
    self.callingCard:SetY(22)
    table.insert(self.contentsObjs, self.callingCard)

    local sideWidth = math.floor((self.background:GetSize().x - (kCenterSectionWidth)) / 2)
    local startLeftFromRight = -sideWidth - kCenterSectionWidth - kSectionPadding
    local startRightFromLeft = sideWidth + kCenterSectionWidth + kSectionPadding

    self.killedByLabel = CreateGUIObject("killedByLabel", GUIText, self.background)
    self.killedByLabel:AlignRight()
    self.killedByLabel:SetFontName(kBigFontName)
    self.killedByLabel:SetText(Locale.ResolveString("DEATHSCREEN_LEFTLABEL_TOP"))
    self.killedByLabel:SetPosition(startLeftFromRight, -20)
    self.killedByLabel:SetColor(HexToColor("ff5757"))
    table.insert(self.contentsObjs, self.killedByLabel)

    self.killedByLabelPrefix = CreateGUIObject("killedByLabel", GUIText, self.background)
    self.killedByLabelPrefix:AlignRight()
    self.killedByLabelPrefix:SetFontName(kBigFontName)
    self.killedByLabelPrefix:SetText(string.format("%s%s", Locale.ResolveString("DEATHSCREEN_LEFTLABEL_TOP_PREFIX"), " "))
    self.killedByLabelPrefix:SetPosition(startLeftFromRight - self.killedByLabel:GetSize().x, -20)
    self.killedByLabelPrefix:SetColor(1,1,1)
    table.insert(self.contentsObjs, self.killedByLabelPrefix)

    self.killedByLabel2 = CreateGUIObject("killedByLabel2", GUIText, self.background)
    self.killedByLabel2:AlignRight()
    self.killedByLabel2:SetFontName(kMediumFontName)
    self.killedByLabel2:SetText(Locale.ResolveString("DEATHSCREEN_LEFTLABEL_BOTTOM"))
    self.killedByLabel2:SetPosition(startLeftFromRight, 20)
    self.killedByLabel2:SetColor(kSubtextColor)
    table.insert(self.contentsObjs, self.killedByLabel2)

    self.killedWithLabel = CreateGUIObject("killedWithLabel", GUIText, self.background)
    self.killedWithLabel:AlignLeft()
    self.killedWithLabel:SetFontName(kSmallFontName)
    self.killedWithLabel:SetText(Locale.ResolveString("DEATHSCREEN_RIGHTLABEL_TOP"))
    self.killedWithLabel:SetPosition(startRightFromLeft, -40)
    self.killedWithLabel:SetColor(kSubtextColor)
    table.insert(self.contentsObjs, self.killedWithLabel)

    self.killedWithLabel2 = CreateGUIObject("killedWithLabel2", GUIText, self.background)
    self.killedWithLabel2:AlignLeft()
    self.killedWithLabel2:SetFontName(kBigFontName)
    self.killedWithLabel2:SetPosition(startRightFromLeft, 0)
    self.killedWithLabel2:SetColor(1,1,1)
    table.insert(self.contentsObjs, self.killedWithLabel2)

    self.killerName = CreateGUIObject("killerName", GUIText, self.background) -- TODO(Salads): Change this to a truncated text? names can get pretty long..
    self.killerName:AlignTop()
    self.killerName:SetFontName(kSmallFontName)
    self.killerName:SetPosition(self.callingCard:GetSize().y + 5, -20)
    self.killerName:SetColor(1,1,1)
    self.killerName:SetPosition(0, self.callingCard:GetSize().y + 5)
    table.insert(self.contentsObjs, self.killerName)

    self.weaponIcon = CreateGUIObject("weaponIcon", GUIObject, self.killedWithLabel2)
    self.weaponIcon:AlignLeft()
    self.weaponIcon:SetTexture(kInventoryIconsTexture)
    self.weaponIcon:SetColor(1,1,1)
    self.weaponIcon:SetSize(DeathMsgUI_GetTechWidth(), DeathMsgUI_GetTechHeight())
    self.weaponIcon:SetPosition(self.killedWithLabel2:GetSize().x, 0)
    table.insert(self.contentsObjs, self.weaponIcon)

    self.skillbadge = CreateGUIObject("skillbadge", GUIMenuSkillTierIcon, self.background)
    self.skillbadge:AlignTop()
    table.insert(self.contentsObjs, self.skillbadge:GetIconObject())
    self:HookEvent(GetGlobalEventDispatcher(), "OnResolutionChanged", UpdateResolutionScaling)
    UpdateResolutionScaling(self, Client.GetScreenWidth(), Client.GetScreenHeight())

    self.lastIsDead = PlayerUI_GetIsDead()
    self.lastIsSpawning = false
    self.hasOpenedMap = false
    self.shouldStopShowingBackground = false
    self.shouldStopShowingContents = false
    self.shouldStopShowing = false
    self.spawningStarted = false

    self:ShowContents(false, true)
    self:ShowBackground(false, true)
    self:SetUpdates(true)

end
