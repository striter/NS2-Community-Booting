-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/menu2/PlayerScreen/Customize/GUIMenuCustomizeScreen.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
--    Main player cosmetics window for viewing and selecting specific cosmetics. This also 
--    sets up and manages a separate RenderCamera and bound-texture render target. In addition,
--    this is also the initiator and orchestrator for a pseudo RenderScene managed by the
--    CustomizeScene object.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


Script.Load("lua/GUI/GUIUtils.lua")

Script.Load("lua/GUI/GUIText.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")

Script.Load("lua/menu2/MenuStyles.lua")

Script.Load("lua/menu2/GUIMenuScreen.lua")
Script.Load("lua/menu2/GUIMenuBasicBox.lua")

Script.Load("lua/menu2/widgets/GUIMenuSimpleTextButton.lua")

Script.Load("lua/menu2/widgets/GUIMenuCustomizeTabButton.lua")
Script.Load("lua/menu2/widgets/GUIMenuTabbedListButtonsWidget.lua")

Script.Load("lua/menu2/PlayerScreen/Customize/GUIMenuCustomizeWorldButton.lua")
Script.Load("lua/menu2/widgets/GUIMenuShapedButton.lua")

--Render Scene management and data
Script.Load("lua/NS2Utility.lua") --required for variant stuff
Script.Load("lua/menu2/PlayerScreen/Customize/CustomizeSceneData.lua")
Script.Load("lua/menu2/PlayerScreen/Customize/CustomizeScene.lua")

Script.Load("lua/menu2/popup/GUIMenuPopupDoNotShowAgainMessage.lua")


local robotVariantLabels =
{
    kMarineVariantsData[kMarineVariants.bigmac].displayName,
    kMarineVariantsData[kMarineVariants.bigmac02].displayName,
    kMarineVariantsData[kMarineVariants.bigmac03].displayName,
    kMarineVariantsData[kMarineVariants.bigmac04].displayName,
    kMarineVariantsData[kMarineVariants.bigmac05].displayName,
    kMarineVariantsData[kMarineVariants.bigmac06].displayName,
    kMarineVariantsData[kMarineVariants.chromabmac].displayName,

    kMarineVariantsData[kMarineVariants.militarymac].displayName,
    kMarineVariantsData[kMarineVariants.militarymac02].displayName,
    kMarineVariantsData[kMarineVariants.militarymac03].displayName,
    kMarineVariantsData[kMarineVariants.militarymac04].displayName,
    kMarineVariantsData[kMarineVariants.militarymac05].displayName,
    kMarineVariantsData[kMarineVariants.militarymac06].displayName,
    kMarineVariantsData[kMarineVariants.chromamilbmac].displayName,
}



local kScreenWidth = 1920
local kScreenHeight = 1080
local kScreenBottomDistance = 0

local kDisplayPositionX = 0
local kDisplayPositionY = 240

local kInnerBgSideSpacing = 6
local kInnerBgTopSpacing = 6
local kInnerBgBottomSpacing = 6
local kInnerBgBorderWidth = 1

local kMarinesViewColor = HexToColor("4DB1FF")
local kAliensViewColor = HexToColor("FFCA3A")

local kCinematicShader = PrecacheAsset("shaders/GUI/menu/opaque.surface_shader")

local kMarineSubMenuHeight = 85
local kMarineSubMenuButtonLabelFont = ReadOnly{family = "Microgramma", size = 22}
local kMarineSubMenuButtonLabelLrgFont = ReadOnly{family = "Microgramma", size = 27}
local kMarineSubMenuButtonFont = ReadOnly{family = "MicrogrammaBold", size = 22}
local kMarineSubMenuButtonLrgFont = ReadOnly{family = "MicrogrammaBold", size = 27}

local kAlienSubMenuHeight = 85
local kAlienSubMenuButtonLabelFont = ReadOnly{family = "Agency", size = 38}
local kAlienSubMenuButtonFont = ReadOnly{family = "AgencyBold", size = 38}

local kMarineSubMenuWeaponLabelFont = ReadOnly{family = "Microgramma", size = 24}

local kViewInstructionsFont = ReadOnly{family = "Agency", size = 46}
local kSteamOverlayWarningFont = ReadOnly{family = "MicrogrammaBold", size = 36}

local kMainWorldButtonsLayer = 4
local kItemViewButtonsLayer = 5
local kGlobalBuyButtonLayer = 10
local kGlobalBackButtonLayer = 20

local kSteamOverlayWarningTimeout = 4


local gCustomizeScreen
function GetCustomizeScreen()
    if gCustomizeScreen then
        return gCustomizeScreen
    end
    error("gCustomizeScreen not set!")
end

local function UpdateWorldButtonsSize(self, scene)

    if self.worldWeaponsButton then
        self.worldWeaponsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineWeapons )
                )
        )
    end

    if self.worldArmorsButton then
        self.worldArmorsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineArmors )
                )
        )
    end

    if self.worldExosuitsButton then
        self.worldExosuitsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineExos )
                )
        )
    end

    if self.worldMarineStructsButton then
        self.worldMarineStructsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineStructures )
                )
        )
    end

    if self.worldAlienStructsButton then
        self.worldAlienStructsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienStructures )
                )
        )
    end

    if self.worldLifeformsButton then
        self.worldLifeformsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienLifeforms )
                )
        )
    end

    if self.worldAlienTunnelButton then
        self.worldAlienTunnelButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienTunnels )
                )
        )
    end

end

local function UpdateMarineArmorsButtonsSize( self, scene )

    if self.worldMarineArmorButton then
        self.worldMarineArmorButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Armors )
                )
        )
    end

    if self.worldMarineGenderButton then
        self.worldMarineGenderButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Gender )
                )
        )
        local genderBtnPos = self.worldMarineGenderButton:GetPosition()
        local genderBtnSize = self.worldMarineGenderButton:GetSize()
        local generLblPos = Vector( (genderBtnPos.x + genderBtnSize.x * 0.5) - self.genderChangeLabel:GetSize().x * 0.5, genderBtnPos.y + genderBtnSize.y * 0.4, 0 )
        self.genderChangeLabel:SetPosition( generLblPos )
    end

    if self.worldMarineVoiceButton then
        self.worldMarineVoiceButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Voices )
                )
        )
    end
end

local function UpdateMarineExosuitsButtonsSize(self, scene)

    if self.worldExoMinigunsButton then
        self.worldExoMinigunsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Minigun )
                )
        )
    end

    if self.worldExoRailgunsButton then
        self.worldExoRailgunsButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Railgun )
                )
        )
    end

end

local function UpdateMarineStructuresButtonsSize(self, scene)

    if self.worldCommandStationButton then
        self.worldCommandStationButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.CommandStation )
                )
        )
    end

    if self.worldExtractorButton then
        self.worldExtractorButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Extractor )
                )
        )
    end

    if self.worldMacButton then
        self.worldMacButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MAC )
                )
        )
    end

    if self.worldArcButton then
        self.worldArcButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.ARC )
                )
        )
    end

end

local function UpdateMarinePatchesButtonsSize(self, scene)

    if self.worldPatchButton then

        local curMarineType = Client.GetOptionString("sexType", "Male")
        local marineVariantName = scene:GetCustomizableObjectVariantName( "MarineRight" )
        if table.icontains(robotVariantLabels, marineVariantName) then
            curMarineType = "bigmac"
        end

        local buttonPointsLabel
        if curMarineType == "Male" then
            buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchMale
        elseif curMarineType == "Female" then
            buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchFemale
        elseif curMarineType == "bigmac" then
            buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchBigmac
        end

        self.worldPatchButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( buttonPointsLabel )
                )
        )
    end

end

local function UpdateMarineWeaponsButtonsSize(self, scene)

    if self.worldRifleButton then
        self.worldRifleButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Rifle )
                )
        )
    end

    if self.worldPistolButton then
        self.worldPistolButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Pistol )
                )
        )
    end

    if self.worldWelderButton then
        self.worldWelderButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Welder )
                )
        )
    end

    if self.worldAxeButton then
        self.worldAxeButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Axe )
                )
        )
    end

    if self.worldShotgunButton then
        self.worldShotgunButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Shotgun )
                )
        )
    end

    if self.worldGrenadeLauncherButton then
        self.worldGrenadeLauncherButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.GrenadeLauncher )
                )
        )
    end

    if self.worldFlamethrowerButton then
        self.worldFlamethrowerButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Flamethrower )
                )
        )
    end

    if self.worldHmgButton then
        self.worldHmgButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.HeavyMachineGun )
                )
        )
    end
end

local function UpdateAlienTunnelButtonSize(self, scene)

    if self.worldTunnelButton then
        self.worldTunnelButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Tunnel )
                )
        )
    end

end

local function UpdateAlienStructuresButtonSize(self, scene)

    if self.worldEggButton then
        self.worldEggButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Egg )
                )
        )
    end

    if self.worldHarvesterButton then
        self.worldHarvesterButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Harvester )
                )
        )
    end

    if self.worldHiveButton then
        self.worldHiveButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Hive )
                )
        )
    end

    if self.worldCystButton then
        self.worldCystButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Cyst )
                )
        )
    end

    if self.worldDrifterButton then
        self.worldDrifterButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Drifter )
                )
        )
    end

end

local function UpdateAlienLifeformsButtonSize(self, scene)

    if self.worldSkulkButton then
        self.worldSkulkButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Skulk )
                )
        )
    end

    if self.worldGorgeButton then
        self.worldGorgeButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Gorge )
                )
        )
    end

    if self.worldLerkButton then
        self.worldLerkButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Lerk )
                )
        )
    end

    if self.worldFadeButton then
        self.worldFadeButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Fade )
                )
        )
    end

    if self.worldOnosButton then
        self.worldOnosButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Onos )
                )
        )
    end

    if self.worldClogButton then
        self.worldClogButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Clog )
                )
        )
    end

    if self.worldHydraButton then
        self.worldHydraButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Hydra )
                )
        )
    end

    if self.worldBabblerButton then
        self.worldBabblerButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Babblers )
                )
        )
    end

    if self.worldBabblerEggButton then
        self.worldBabblerEggButton:SetPoints(
                scene:GetScenePointsToScreenPointList(
                        GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.BileMine )
                )
        )
    end
end

local function UpdateInnerBackgroundSize(self, parentSize)
    local mod = Vector(kInnerBgSideSpacing * 2, (kInnerBgBottomSpacing + kInnerBgTopSpacing), 0)

    self.background:SetSize(parentSize - mod)

    if self.renderTexture then
        local viewSize = Vector( parentSize.x - (kInnerBgSideSpacing * 2), parentSize.y - (kInnerBgTopSpacing * 2), 0)
        self.renderTexture:SetSize(viewSize)
        self:UpdateExclusionStencilSize()

        local scene = GetCustomizeScene()

        scene:UpdateViewSize( viewSize )

        self:UpdateActiveViewWorldButtons(scene)

    end

end


---@class GUIMenuCustomizeScreen : GUIMenuScreen
class "GUIMenuCustomizeScreen" (GUIMenuScreen)


function GUIMenuCustomizeScreen:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1

    PushParamChange(params, "screenName", "Customize")
    GUIMenuScreen.Initialize(self, params, errorDepth)
    PopParamChange(params, "screenName")

    gCustomizeScreen = self

    self:GetRootItem():SetDebugName("customizeScreen")

    self:ListenForCursorInteractions() -- prevent click-through

    self.background = CreateGUIObject("background", GUIMenuBasicBox, self)
    self.background:SetLayer(-2)
    self.background:SetPosition( kInnerBgSideSpacing * 0.5, kInnerBgTopSpacing )
    self.background:SetStrokeWidth( kInnerBgBorderWidth )
    self.background:SetStrokeColor( MenuStyle.kTooltipText )
    self:HookEvent(self, "OnSizeChanged", UpdateInnerBackgroundSize)

    self:SetCropMin(0,0)
    self:SetCropMax(1,1)

    self.customizeActive = false

    local viewSize = Vector( kScreenWidth - (kInnerBgSideSpacing * 2) - kInnerBgBorderWidth - 1, kScreenHeight - (kInnerBgTopSpacing * 2) - kInnerBgBorderWidth, 0)

    self.renderTexture = CreateGUIObject("renderTexture", GUIObject, self)
    self.renderTexture:SetLayer(-1)
    self.renderTexture:SetPosition( kInnerBgSideSpacing * 0.5 + kInnerBgBorderWidth, kInnerBgTopSpacing - kInnerBgBorderWidth )
    self.renderTexture:SetSize( viewSize )
    self.renderTexture:SetColor( Color(1, 1, 1, 1) )
    self.renderTexture:SetShader( kCinematicShader )
    self.renderTexture:SetTexture( CustomizeScene.kRenderTarget )

    local scene = GetCustomizeScene()
    scene:Initialize( viewSize )    --note: will be resized when self is
    --Supplied callback is triggered whenever the camera has moved within activation-distance of a given View position
    scene:SetViewLabelGUICallback( self.OnViewLabelActivation )

    self:SetSize( Vector(kScreenWidth, kScreenHeight, 0) )  --force default size now

    self.activeTargetView = gCustomizeSceneData.kDefaultViewLabel  --TODO Read from client options
    self.previousTargetView = self.activeTargetView

    --Note: ALL child GUIObjects MUST be initialized AFTER CustomizeScene is created _and_ initialized!
    self:InitializeNavElements()

    self.viewsWorldButtons = {}
    self:InitWorldNavigationElements()

    self.timeTargetViewChange = 0

    --Hook Main Menu event to toggle this screen in order to control exclusion stencil
    self:HookEvent( GetMainMenu(), "OnClosed", function() GetCustomizeScene():SetActive(false) end )
    self:HookEvent( GetMainMenu(), "OnOpened",
            function()
                GetCustomizeScene():SetActive(GetCustomizeScreen().customizeActive)
            end
    )

    --Required in order to update render scene, this can never be false
    self:SetUpdates( true )

    self.activePurchaseItemId = nil
    self.activePurchaseDlcId = nil

    Event.Hook("OnItemsPurchaseStartComplete", self.OnPurchaseStartComplete)

end

function GUIMenuCustomizeScreen:InitializeNavElements()

    self.mainMarineTopBar = {}
    self.mainAlienBottomBar = {}

    local marineBarStyle =
    {
        font = MenuStyle.kCustomizeViewBarMarineButtonFont,
        fontGlow = MenuStyle.kCustomizeViewBarMarineButtonFont,
        fontColor = MenuStyle.kOptionHeadingColor,
        fontGlowStyle = MenuStyle.kMainBarButtonGlow
    }

    --TODO Add localization to Buttons
    --TODO: These lists of buttons need "end-caps" images (optional)
    self.mainMarineTopBar = CreateGUIObject("marineMainTopBar", GUIMenuTabbedListButtonsWidget, self,
            {
                position = Vector( 0, kInnerBgSideSpacing, 0 ),
                align = "top"
            })
    self.mainMarineTopBar:AddButton( "weaponsButton", Locale.ResolveString("CUSTOMIZE_WEAPONS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.Armory) end, marineBarStyle )
    self.mainMarineTopBar:AddButton( "armorsButton", Locale.ResolveString("CUSTOMIZE_ARMORS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.Marines) end, marineBarStyle )
    self.mainMarineTopBar:AddButton( "patchesButton", Locale.ResolveString("CUSTOMIZE_PATCHES"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.ShoulderPatches) end, marineBarStyle )
    self.mainMarineTopBar:AddButton( "exosButton", Locale.ResolveString("CUSTOMIZE_EXOSUITS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.ExoBay) end, marineBarStyle )
    self.mainMarineTopBar:AddButton( "structuresButton", Locale.ResolveString("CUSTOMIZE_TEAMMISCS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.MarineStructures) end, marineBarStyle )
    self.mainMarineTopBar:AlignTop()
    self.mainMarineTopBar:SetVisible(true)

    local alienBarStyle =
    {
        font = MenuStyle.kCustomizeViewBarAlienButtonFont,
        fontGlow = MenuStyle.kCustomizeViewBarAlienButtonFont,
        fontColor = MenuStyle.kOptionHeadingColor,
        fontGlowStyle = MenuStyle.kCustomizeBarButtonAlienGlow
    }

    --TODO: These lists of buttons need "end-caps" images (optional)
    --TODO Add localization to Buttons
    self.mainAlienBottomBar = CreateGUIObject("mainAlienBottomBar", GUIMenuTabbedListButtonsWidget, self, { align = "bottom" })
    self.mainAlienBottomBar:AddButton( "lifeforms", Locale.ResolveString("CUSTOMIZE_LIFEFORMS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.AlienLifeforms) end, alienBarStyle )
    self.mainAlienBottomBar:AddButton( "alienStructsButton", Locale.ResolveString("CUSTOMIZE_TEAMMISCS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.AlienStructures) end, alienBarStyle )
    self.mainAlienBottomBar:AddButton( "alienTunnelsButton", Locale.ResolveString("CUSTOMIZE_TUNNELS"), function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.AlienTunnels) end, alienBarStyle )
    self.mainAlienBottomBar:SetY( -2 )
    self.mainAlienBottomBar:AlignBottom()
    self.mainAlienBottomBar:SetVisible(false)

    self.aliensViewButton = CreateGUIObject("goAliensViewButtn", GUIMenuCustomizeTabButton, self,
            {
                label = Locale.ResolveString("NAME_TEAM_2"), --TODO localize? (requires new string) ...how in the hell was THIS string not localized?!
                font = MenuStyle.kCustomizeViewAliensButtonFont,
                fontColor = MenuStyle.kCustomizeAlienButtonColor,
                fontGlow = MenuStyle.kCustomizeViewAliensButtonFont,
                fontGlowStyle = MenuStyle.kCustomizeBarButtonAlienGlow,
                --position = Vector( 0, -kInnerBgSideSpacing, 0 ),
            })
    self.aliensViewButton:HookEvent(self.aliensViewButton, "OnPressed", function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.DefaultAlienView) end)
    self.aliensViewButton:SetVisible(true)
    self.aliensViewButton:AlignBottom()

    self.marinesViewButton = CreateGUIObject("goMarinesViewButtn", GUIMenuCustomizeTabButton, self,
            {
                label = Locale.ResolveString("NAME_TEAM_1"), --TODO localize? (requires new string)
                font = MenuStyle.kCustomizeViewMarinesButtonFont,
                fontColor = MenuStyle.kCustomizeMarinesViewFontColor,
                fontGlow = MenuStyle.kCustomizeViewMarinesButtonFont,
                fontGlowStyle = MenuStyle.kMainBarButtonGlow,
                position = Vector( 0, kInnerBgSideSpacing, 0 ),
            })
    self.marinesViewButton:HookEvent(self.marinesViewButton, "OnPressed", function() self.SetDesiredActiveView(self, gCustomizeSceneData.kViewLabels.DefaultMarineView) end)
    self.marinesViewButton:SetVisible(false) --only visible in Alien-centric views 
    self.marinesViewButton:AlignTop()

    --Generalized Back button that's only active on "sub-view" (i.e. Non-Default view)
    self.globalBackButton = CreateGUIObject("globalBackButton", GUIMenuCustomizeTabButton, self,
            {
                label = Locale.ResolveString("BACK"),
                font = MenuStyle.kCustomizeViewMarinesButtonFont,
                fontColor = MenuStyle.kWhite,
                fontGlow = MenuStyle.kCustomizeViewMarinesButtonFont,
                fontGlowStyle = MenuStyle.kCustomizeButtonGlow,
                position = Vector( -6, -6, 0 ),
            })
    self.globalBackButton:SetVisible(false)
    self.globalBackButton:AlignBottomRight()
    self.globalBackButton:SetLayer( kGlobalBackButtonLayer )
    self.globalBackButton:HookEvent(self.globalBackButton, "OnPressed",
            function()
                local curTeamIdx = GetViewTeamIndex(self.activeTargetView)
                local teamDefaultView =
                curTeamIdx == kTeam1Index and gCustomizeSceneData.kViewLabels.DefaultMarineView
                        or gCustomizeSceneData.kViewLabels.DefaultAlienView
                self.SetDesiredActiveView(self, teamDefaultView)
            end
    )

    self.globalBuyItemButton = CreateGUIObject("globalBuyButton", GUIMenuCustomizeTabButton, self,
            {
                label = Locale.ResolveString("BUY"), --.. " [ItemName] - [ItemPrice]",
                align = "bottom",
                font = MenuStyle.kCustomizeViewBuyButtonFont,
                fontColor = MenuStyle.kWhite, --?? Team centric color?
                fontGlow = MenuStyle.kCustomizeViewBuyButtonFont,
                fontGlowStyle = MenuStyle.kCustomizeButtonGlow, --TODO Update glow 
                position = Vector( 0, -160, 0 ),
            })
    self.globalBuyItemButton:SetVisible( false )
    self.globalBuyItemButton:SetLayer( kGlobalBackButtonLayer )
    self.globalBuyItemButton:SetTooltip("")

    self.globalSteamOverlayNotification = CreateGUIObject("globalSteamOverlayText", GUIText, self, { font = kSteamOverlayWarningFont, })
    self.globalSteamOverlayNotification:AlignBottom()
    self.globalSteamOverlayNotification:SetY( -165 )
    self.globalSteamOverlayNotification:SetText("Steam Overlay must be Enabled to make purchases") --TODO Localize
    self.globalSteamOverlayNotification:SetDropShadowEnabled( true )
    self.globalSteamOverlayNotification:SetVisible( false )
    self.globalSteamOverlayNotification:SetLayer( kGlobalBackButtonLayer )

end

function GUIMenuCustomizeScreen:CreateGameRestartPopupMessage()

    local popup = CreateGUIObject("popup", GUIMenuPopupDoNotShowAgainMessage, nil,
            {
                title = Locale.ResolveString("ALERT"),
                message = Locale.ResolveString("DLC_PURCHASE_GAME_RESTART_MSG"),
                neverAgainOptionName = "never_show_game_restart",
                buttonConfig =
                {
                    GUIMenuPopupDialog.OkayButton,
                },
            })

end

function GUIMenuCustomizeScreen:SaveNewItemSelectionOption(itemId)
    assert(itemId)
    assert(itemId > 0) --TODO Replace with "IsValidItemID" (and is purchasable?)
    GetCustomizeScene():UpdateNewItemPurchased(itemId)
end

function GUIMenuCustomizeScreen:SetActivePurchasePendingItems( purchaseItemId, purchaseDlcId )
    assert(purchaseDlcId or purchaseItemId)

    if purchaseItemId then
        self.activePurchaseItemId = purchaseItemId
    end

    if purchaseDlcId then
        self.activePurchaseDlcId = purchaseDlcId
    end

    self.previousAvailableItems = GetCustomizeScene():GetAllAvailableCosmetics()
end

--Called via bound Event hook, only triggers when Steam Overlay state changes and is enabled.
--This is here for future proofing future changes, and not utilized fully.
function GUIMenuCustomizeScreen:OnSteamOverlayActivationChange( isActive )
    if isActive then
        --For purchasing, always ignore when overlay is opened
        return
    end

    if self.activePurchaseDlcId then
        --Need to validate new items are infact retianed
        local isDlcPurchase = not self.activePurchaseItemId and self.activePurchaseDlcId
        --For this context, we only care about DLCs. Typical Items and/or Bundles are handled elsewhere
        if isDlcPurchase then
            --DLC purchases require a full client restart
            Client.UpdateInventory()
            local notShowAgain = Client.GetOptionBoolean("never_show_game_restart", false)
            if not notShowAgain then
                self:CreateGameRestartPopupMessage()
            end
            self:UpdateBuyButton(-1)
        end
    else
        self.previousAvailableItems = nil
        self.activePurchaseItemId = nil
        self.activePurchaseDlcId = nil
    end
end

function GUIMenuCustomizeScreen:UpdateBuyButtonForSingleItem(itemId, itemData)
    assert(itemId)
    assert(itemData)

    local newLabel = Locale.ResolveString("BUY") .. " " .. itemData[2] --.. " " .. GetFormattedPrice(itemData[5], Client.GetCurrencyCode())

    self.globalBuyItemButton:SetLabel(newLabel)
    self.globalBuyItemButton:SetTooltip("")
    self.globalBuyItemButton:SetVisible(true)
    self.globalBuyItemButton:UnHookEvent(self.globalBuyItemButton, "OnPressed")
    self.globalBuyItemButton:HookEvent(self.globalBuyItemButton, "OnPressed",
            function()
                GetCustomizeScreen():SetActivePurchasePendingItems( itemId, nil )
                Client.BeginItemPurchase( { itemId } )
            end
    )
end

function GUIMenuCustomizeScreen:UpdateBuyButtonForItemBundle(itemId, itemData)
    assert(itemId)
    assert(itemData)

    local bundleData = {}
    if not Client.GetItemDetails(GetItemBundleId(itemId), bundleData) then
        Log("Failed to retrieve Item[%s] Bundle data", itemId)
        return
    end

    local bundleLabel = Locale.ResolveString("BUY") .. " " .. bundleData[2]

    self.globalBuyItemButton:SetLabel( bundleLabel )
    self.globalBuyItemButton:SetTooltip("")
    --self.globalBuyItemButton:SetTooltip( GetFormattedDlcToolTipText(dlcId) )      TODO Add All Item Names in Bundles
    self.globalBuyItemButton:SetVisible(true)
    self.globalBuyItemButton:UnHookEvent(self.globalBuyItemButton, "OnPressed")
    self.globalBuyItemButton:HookEvent(self.globalBuyItemButton, "OnPressed",
            function()
                GetCustomizeScreen():SetActivePurchasePendingItems( bundleData[1], nil )
                Client.BeginItemPurchase( { bundleData[1] } )
            end
    )
end

--Note: DLC Price is intentionally NOT included, and Steam does not provide API (Web or SDK) to fetch it
function GUIMenuCustomizeScreen:UpdateBuyButtonForDlcItem(itemId, itemData)
    assert(itemId)
    assert(itemData)

    local dlcId = GetItemDlcAppId( itemId )
    assert(type(dlcId) == "number" and dlcId > 0)
    local dlcName = GetFormattedDlcName( dlcId )
    assert(dlcName)

    local dlcLabel = Locale.ResolveString("BUY") .. "  " .. dlcName

    self.globalBuyItemButton:SetTooltip( GetFormattedDlcToolTipText(dlcId) )

    self.globalBuyItemButton:SetLabel( dlcLabel )
    self.globalBuyItemButton:SetVisible(true)
    self.globalBuyItemButton:UnHookEvent(self.globalBuyItemButton, "OnPressed")
    self.globalBuyItemButton:HookEvent(self.globalBuyItemButton, "OnPressed",
            function(self)
                if GetIsDlcBmacBundle(dlcId) then
                    --One-off handling of BMAC required in order to display Bundle page(s) correctly
                    Client.ShowWebpage( GetDlcStorePageUrl(dlcId) )
                else
                    Client.ActivateOverlayToDlcStore( dlcId )
                end
                GetCustomizeScreen():SetActivePurchasePendingItems( nil, dlcId )
            end
    )

end

function GUIMenuCustomizeScreen:UpdateBuyButtonForThunderdomeUnlock(itemId, itemData)   --TD-FIXME Needs to be updated on CustomizeScene RE-active
    local btnLabel = Locale.ResolveString("BUY_THUNDERDOME_UNLOCK")

    self.globalBuyItemButton:SetLabel( btnLabel )
    self.globalBuyItemButton:SetTooltip("")
    self.globalBuyItemButton:SetVisible(true)
    self.globalBuyItemButton:UnHookEvent(self.globalBuyItemButton, "OnPressed")
    self.globalBuyItemButton:HookEvent(self.globalBuyItemButton, "OnPressed",
            function()
                PlayMenuSound("ButtonClick")
                GetScreenManager():DisplayScreen("MissionScreen")   --TD-TODO Need to trigger "scroll to" of the specific unlock
            end
    )
end

function GUIMenuCustomizeScreen:UpdateBuyButton(itemId, forceRecheck)
    assert(itemId)
    local _self = self

    local ownsItemState = function()
        _self.globalBuyItemButton:UnHookEvent(self.globalBuyItemButton, "OnPressed") --for safety sake
        _self.globalBuyItemButton:SetVisible(false) --just hide/prevent interactions on failure
        _self.globalBuyItemButton:SetTooltip("")
    end

    -- -1 indicates "should hide", return immediately when not showing purchasable item (e.g. prevent accidental mouse-over to wipe button state)
    if (itemId == -1 or itemId == 0 or GetOwnsItem(itemId) or forceRecheck) then
        ownsItemState()
        return
    end

    --Note: Currently below won't ever be triggered when overlay is disabled, due to buyable items not being added to available pool
    if not Client.GetIsSteamOverlayEnabled() then
        --Purchasing features in steam won't work if Overlay is disabled
        self.globalSteamOverlayNotification:SetVisible(true)
        --XX Delay via cb, then trigger a hide cb?
        self.globalSteamOverlayNotification:AddTimedCallback( function(_sobSelf) _sobSelf:SetVisible(false) end, kSteamOverlayWarningTimeout, false )
        ownsItemState()
        return
    end

    local HandleMultipleItemId = function(forItemId)
        --This check is first to capture itemId table type (prevent script errors)
        if type(forItemId) == "table" then
            for i = 1, #forItemId do
                if not GetOwnsItem(forItemId[i]) and GetIsItemPurchasable(forItemId[i]) then  --FIXME This is ONLY for Onos, and should use Shadow Bundle instead...
                    return forItemId[i]
                end
            end
        end
        return forItemId
    end
    itemId = HandleMultipleItemId( itemId )

    local isBundledItem = GetIsItemBundleItem(itemId)
    local isDlcItemOnly = GetIsItemDlcOnly(itemId)
    local isThunderdomeUnlocked = GetIsItemThunderdomeUnlock(itemId)

    local itemData = {}
    if not Client.GetItemDetails(itemId, itemData) then
        error("Failed to fetch Item Data for ItemID: %s", itemId)
        ownsItemState()
        return
    end
    assert(itemData and #itemData > 0)

    if isThunderdomeUnlocked then
        self:UpdateBuyButtonForThunderdomeUnlock( itemId, itemData )
    elseif itemData[9] and isDlcItemOnly then
        self:UpdateBuyButtonForDlcItem( itemId, itemData )
    elseif itemData[6] == false and isBundledItem then
        self:UpdateBuyButtonForItemBundle(itemId, itemData)
    else
        self:UpdateBuyButtonForSingleItem(itemId, itemData)
    end

end


function GUIMenuCustomizeScreen:InitWorldNavigationElements()

    local scene = GetCustomizeScene()

    --Marine Default View world buttons
    self.worldWeaponsButton = CreateGUIObject( "worldWeaponsButton", GUIMenuCustomizeWorldButton, self )
    --self.worldWeaponsButton:SetColor( Color(1, 0.5, 1, 0.325) )
    self.worldWeaponsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineWeapons )
            )
    )
    self.worldWeaponsButton:SetLayer( kMainWorldButtonsLayer )
    local viewArmory = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.Armory )
    end
    self.worldWeaponsButton:SetPressedCallback( viewArmory )
    local toggleHighlightArmory = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.Armory )
    end
    self.worldWeaponsButton:SetMouseEnterCallback( toggleHighlightArmory )
    self.worldWeaponsButton:SetMouseExitCallback( toggleHighlightArmory )


    self.worldArmorsButton = CreateGUIObject( "worldArmorsButton", GUIMenuCustomizeWorldButton, self )
    --self.worldArmorsButton:SetColor( Color(1, 1, 1, 0.3) )
    self.worldArmorsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineArmors )
            )
    )
    self.worldArmorsButton:SetLayer( kMainWorldButtonsLayer )
    local viewMarines = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.Marines )
    end
    self.worldArmorsButton:SetPressedCallback( viewMarines )
    local toggleHighlightMarines = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.Marines )
    end
    self.worldArmorsButton:SetMouseEnterCallback( toggleHighlightMarines )
    self.worldArmorsButton:SetMouseExitCallback( toggleHighlightMarines )


    self.worldExosuitsButton = CreateGUIObject( "worldExosuitsButton", GUIMenuCustomizeWorldButton, self )
    --self.worldExosuitsButton:SetColor( Color(0, 1, 1, 0.2) )
    self.worldExosuitsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineExos )
            )
    )
    self.worldExosuitsButton:SetLayer( kMainWorldButtonsLayer )
    local viewExos = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.ExoBay )
    end
    self.worldExosuitsButton:SetPressedCallback( viewExos )
    local toggleHighlightExos = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.ExoBay )
    end
    self.worldExosuitsButton:SetMouseEnterCallback( toggleHighlightExos )
    self.worldExosuitsButton:SetMouseExitCallback( toggleHighlightExos )


    self.worldMarineStructsButton = CreateGUIObject( "worldMarineStructsButton", GUIMenuCustomizeWorldButton, self )
    self.worldMarineStructsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MarineStructures )
            )
    )
    --self.worldMarineStructsButton:SetColor( Color(0, 1, 0, 0.15) )
    self.worldMarineStructsButton:SetLayer( kMainWorldButtonsLayer )
    local viewMarineStructs = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.MarineStructures )
    end
    self.worldMarineStructsButton:SetPressedCallback( viewMarineStructs )
    local toggleHighlightMarineStructs = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.MarineStructures )
    end
    self.worldMarineStructsButton:SetMouseEnterCallback( toggleHighlightMarineStructs )
    self.worldMarineStructsButton:SetMouseExitCallback( toggleHighlightMarineStructs )

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.DefaultMarineView] =
    {
        self.worldWeaponsButton, self.worldArmorsButton, self.worldExosuitsButton, self.worldMarineStructsButton,
    }


    --Alien Default View World buttons

    self.worldAlienStructsButton = CreateGUIObject( "worldAlienStructsButton", GUIMenuCustomizeWorldButton, self )
    self.worldAlienStructsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienStructures )
            )
    )
    --self.worldAlienStructsButton:SetColor( Color(1, 0, 0.5, 0.2) )
    self.worldAlienStructsButton:SetLayer( kMainWorldButtonsLayer )
    self.worldAlienStructsButton:SetVisible(false)
    local viewAlienStructs = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.AlienStructures )
    end
    local toggleHighlightAlienStructs = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.AlienStructures )
    end
    self.worldAlienStructsButton:SetPressedCallback( viewAlienStructs )
    self.worldAlienStructsButton:SetMouseEnterCallback( toggleHighlightAlienStructs )
    self.worldAlienStructsButton:SetMouseExitCallback( toggleHighlightAlienStructs )


    self.worldLifeformsButton = CreateGUIObject( "worldLifeformsButton", GUIMenuCustomizeWorldButton, self )
    self.worldLifeformsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienLifeforms )
            )
    )
    --self.worldLifeformsButton:SetColor( Color(0.9, 1, 0.2, 0.2) )
    self.worldLifeformsButton:SetLayer( kMainWorldButtonsLayer )
    self.worldLifeformsButton:SetVisible(false)
    local viewAlienLifeforms = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.AlienLifeforms )
    end
    local toggleHighlightLifeforms = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.AlienLifeforms )
    end
    self.worldLifeformsButton:SetPressedCallback( viewAlienLifeforms )
    self.worldLifeformsButton:SetMouseEnterCallback( toggleHighlightLifeforms )
    self.worldLifeformsButton:SetMouseExitCallback( toggleHighlightLifeforms )


    self.worldAlienTunnelButton = CreateGUIObject( "worldAlienTunnelButton", GUIMenuCustomizeWorldButton, self )
    self.worldAlienTunnelButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.AlienTunnels )
            )
    )
    --self.worldAlienTunnelButton:SetColor( Color(1, 0, 0, 0.4) )
    self.worldAlienTunnelButton:SetLayer( kMainWorldButtonsLayer )
    self.worldAlienTunnelButton:SetVisible(false)
    local viewAlienTunnels = function()
        GetCustomizeScreen():SetDesiredActiveView( gCustomizeSceneData.kViewLabels.AlienTunnels )
    end
    local toggleHighlightTunnels = function()
        GetCustomizeScene():ToggleViewHighlight( gCustomizeSceneData.kViewLabels.AlienTunnels )
    end
    self.worldAlienTunnelButton:SetPressedCallback( viewAlienTunnels )
    self.worldAlienTunnelButton:SetMouseEnterCallback( toggleHighlightTunnels )
    self.worldAlienTunnelButton:SetMouseExitCallback( toggleHighlightTunnels )


    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.DefaultAlienView] =
    {
        self.worldAlienStructsButton, self.worldLifeformsButton, self.worldAlienTunnelButton
    }


    self:InitMarineWeaponElements(scene)
    self:InitMarineArmorElements(scene)
    self:InitMarinePatchElements(scene)
    self:InitMarineExoElements(scene)
    self:InitMarineStructureElements(scene)

    self:InitAlienLifeformElements(scene)
    self:InitAlienStructuresElements(scene)
    self:InitAlienTunnelElements(scene)

    --[[
    --This is the common (GUI aligned, not world/view releative) button that handles mouse-dragging, etc for Zooming on Scene Objects (i.e. rendering in ViewZone, not Default)
    self.worldGlobalObjectZoomButton = CreateGUIObject("worldGlobalObjectZoomButton", GUIMenuCustomizeWorldButton, self)
    self.worldGlobalObjectZoomButton:AlignCenter()
    self.worldGlobalObjectZoomButton:SetSize( Vector( 2600, 1350, 0 ) ) --match primary parent size, minus some padding?
    self.worldGlobalObjectZoomButton:SetY( -50 )
    self.worldGlobalObjectZoomButton:SetLayer( kItemViewButtonsLayer ) --higher order?
    self.worldGlobalObjectZoomButton:SetVisible(false)
    --self.worldGlobalObjectZoomButton:SetColor( Color(1, 0, 0.1, 0.425) )
    
    self.worldGlobalZoomInstructions = CreateGUIObject("worldGlobalZoomInstructions", GUIText, self, { font = kViewInstructionsFont, })
    self.worldGlobalZoomInstructions:AlignBottom()
    self.worldGlobalZoomInstructions:SetY( -50 )
    self.worldGlobalZoomInstructions:SetText("Left-click and drag to rotate, Right-click to zoom-out") --TODO Localize
    self.worldGlobalZoomInstructions:SetDropShadowEnabled(true)
    self.worldGlobalZoomInstructions:SetVisible(false)

    local CloseZoom = function(self)
        GetCustomizeScreen():HideModelZoomElements( self:GetSceneObjectLabel() )
    end
    self.worldGlobalObjectZoomButton:SetMouseRightClickCallback(CloseZoom)
    --TODO Setup mouse-drag cb
        Should just feed a vector direction and length to CustomizeScene, but only when moved far enough (min-dist)
    --]]

end

function GUIMenuCustomizeScreen:InitAlienStructuresElements(scene)

    local hiveStr = Locale.ResolveString("HIVE")
    local harvyStr = Locale.ResolveString("HARVESTER")
    local eggStr = Locale.ResolveString("EGG")
    local cystStr = Locale.ResolveString("CYST")
    local drifterStr = Locale.ResolveString("DRIFTER")

    local initHiveLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Hive" ) .. " " .. hiveStr
    local initHarvyLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Harvester" ) .. " " .. harvyStr
    local initEggLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Egg" ) .. " " .. eggStr
    local initCystLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Cyst" ) .. " " .. cystStr
    local initDrifterLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Drifter" ) .. " " .. drifterStr

    self.worldHiveButton = CreateGUIObject( "worldHiveButton", GUIMenuCustomizeWorldButton, self )
    self.worldHiveButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Hive )
            )
    )
    --self.worldHiveButton:SetColor( Color(1, 0, 0.5, 0.2) )
    self.worldHiveButton:SetLayer( kMainWorldButtonsLayer )
    self.worldHiveButton:SetVisible(false)
    self.worldHiveButton:SetTooltip(initHiveLbl)


    self.worldHarvesterButton = CreateGUIObject( "worldHarvesterButton", GUIMenuCustomizeWorldButton, self )
    self.worldHarvesterButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Harvester )
            )
    )
    --self.worldHarvesterButton:SetColor( Color(1, 0, 0, 0.3) )
    self.worldHarvesterButton:SetLayer( kMainWorldButtonsLayer )
    self.worldHarvesterButton:SetVisible(false)
    self.worldHarvesterButton:SetTooltip(initHarvyLbl)

    self.worldEggButton = CreateGUIObject( "worldEggButton", GUIMenuCustomizeWorldButton, self )
    self.worldEggButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Egg )
            )
    )
    --self.worldEggButton:SetColor( Color(0.2, 1, 0.2, 0.2) )
    self.worldEggButton:SetLayer( kMainWorldButtonsLayer )
    self.worldEggButton:SetVisible(false)
    self.worldEggButton:SetTooltip(initEggLbl)

    self.alienStructsIntructions = CreateGUIObject("alienStructsIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.alienStructsIntructions:AlignBottom()
    self.alienStructsIntructions:SetY( -90 )
    self.alienStructsIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.alienStructsIntructions:SetDropShadowEnabled(true)
    self.alienStructsIntructions:SetVisible(false)

    self.worldCystButton = CreateGUIObject( "worldCystButton", GUIMenuCustomizeWorldButton, self )
    self.worldCystButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Cyst )
            )
    )
    --self.worldCystButton:SetColor( Color(1, 1, 0, 0.5) )
    self.worldCystButton:SetLayer( kMainWorldButtonsLayer )
    self.worldCystButton:SetVisible(false)
    self.worldCystButton:SetTooltip(initCystLbl)

    self.worldDrifterButton = CreateGUIObject( "worldDrifterButton", GUIMenuCustomizeWorldButton, self )
    self.worldDrifterButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Drifter )
            )
    )
    --self.worldDrifterButton:SetColor( Color(0.7, 0, 0.12, 0.5) )
    self.worldDrifterButton:SetLayer( kMainWorldButtonsLayer )
    self.worldDrifterButton:SetVisible(false)
    self.worldDrifterButton:SetTooltip(initDrifterLbl)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.AlienStructures] =
    {
        self.worldHiveButton,
        self.worldHarvesterButton,
        self.worldEggButton,
        self.worldCystButton,
        self.worldDrifterButton,

        self.alienStructsIntructions
    }

    local _self = self

    local CycleCosmeticHivePrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Hive, -1 )
        self:SetTooltip( label .. " " .. hiveStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticHiveNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Hive, 1 )
        self:SetTooltip( label .. " " .. hiveStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticHarvesterPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Harvester, -1 )
        self:SetTooltip( label .. " " .. harvyStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticHarvesterNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Harvester, 1 )
        self:SetTooltip( label .. " " .. harvyStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticEggPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Egg, -1 )
        self:SetTooltip( label .. " " .. eggStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticEggNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Egg, 1 )
        self:SetTooltip( label .. " " .. eggStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldHiveButton:SetMouseRightClickCallback( CycleCosmeticHivePrev )
    self.worldHiveButton:SetPressedCallback( CycleCosmeticHiveNext )

    self.worldHarvesterButton:SetMouseRightClickCallback( CycleCosmeticHarvesterPrev )
    self.worldHarvesterButton:SetPressedCallback( CycleCosmeticHarvesterNext )

    self.worldEggButton:SetMouseRightClickCallback( CycleCosmeticEggPrev )
    self.worldEggButton:SetPressedCallback( CycleCosmeticEggNext )

    local CycleCystCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Cyst, -1 )
        self:SetTooltip( label .. " " .. cystStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCystCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Cyst, 1 )
        self:SetTooltip( label .. " " .. cystStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end
    self.worldCystButton:SetMouseRightClickCallback( CycleCystCosmeticPrev )
    self.worldCystButton:SetPressedCallback( CycleCystCosmeticNext )

    local CycleDrifterCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Drifter, -1 )
        self:SetTooltip( label .. " " .. drifterStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleDrifterCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Drifter, 1 )
        self:SetTooltip( label .. " " .. drifterStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end
    self.worldDrifterButton:SetMouseRightClickCallback( CycleDrifterCosmeticPrev )
    self.worldDrifterButton:SetPressedCallback( CycleDrifterCosmeticNext )

end

function GUIMenuCustomizeScreen:InitAlienTunnelElements(scene)

    local tunnelStr = Locale.ResolveString("TUNNEL_ENTRANCE") --TODO no string-key for just "Tunnels"
    local initTunnelLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Tunnel" ) .. " " .. tunnelStr

    self.worldTunnelButton = CreateGUIObject( "worldTunnelButton", GUIMenuCustomizeWorldButton, self )
    self.worldTunnelButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Tunnel )
            )
    )
    --self.worldTunnelButton:SetColor( Color(1, 0, 0.5, 0.2) )
    self.worldTunnelButton:SetLayer( kMainWorldButtonsLayer )
    self.worldTunnelButton:SetVisible(false)
    self.worldTunnelButton:SetTooltip(initTunnelLbl)

    self.tunnelsIntructions = CreateGUIObject("tunnelsIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.tunnelsIntructions:AlignBottom()
    self.tunnelsIntructions:SetY( -90 )
    self.tunnelsIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.tunnelsIntructions:SetDropShadowEnabled(true)
    self.tunnelsIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.AlienTunnels] =
    {
        self.worldTunnelButton, self.tunnelsIntructions
    }

    local _self = self
    local CycleCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Tunnel, -1 )
        self:SetTooltip( label .. " " .. tunnelStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Tunnel, 1 )
        self:SetTooltip( label .. " " .. tunnelStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldTunnelButton:SetMouseRightClickCallback( CycleCosmeticPrev )
    self.worldTunnelButton:SetPressedCallback( CycleCosmeticNext )

end

function GUIMenuCustomizeScreen:InitAlienLifeformElements(scene)

    local skulkStr = Locale.ResolveString("SKULK")
    local gorgeStr = Locale.ResolveString("GORGE")
    local lerkStr = Locale.ResolveString("LERK")
    local fadeStr = Locale.ResolveString("FADE")
    local onosStr = Locale.ResolveString("ONOS")

    local clogStr = Locale.ResolveString("CLOG")
    local hydraStr = Locale.ResolveString("HYDRA")
    local babblerStr = Locale.ResolveString("BABBLER")
    local babblerEggStr = Locale.ResolveString("BABBLER_MINE")

    local initSkulkLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Skulk" ) .. " " .. skulkStr
    local initGorgeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Gorge" ) .. " " .. gorgeStr
    local initLerkLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Lerk" ) .. " " .. lerkStr
    local initFadeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Fade" ) .. " " .. fadeStr
    local initOnosLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Onos" ) .. " " .. onosStr

    local initClogLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Clog" ) .. " " .. clogStr
    local initHydraLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Hydra" ) .. " " .. hydraStr
    local initBabblerLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Babbler" ) .. " " .. babblerStr
    local initBabblerEggLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "BabblerEgg" ) .. " " .. babblerEggStr

    self.worldSkulkButton = CreateGUIObject( "worldSkulkButton", GUIMenuCustomizeWorldButton, self )
    self.worldSkulkButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Skulk )
            )
    )
    --self.worldSkulkButton:SetColor( Color(0.2, 0.2, 0.2, 0.3) )
    self.worldSkulkButton:SetLayer( kMainWorldButtonsLayer )
    self.worldSkulkButton:SetVisible(false)
    self.worldSkulkButton:SetTooltip(initSkulkLbl)

    self.worldGorgeButton = CreateGUIObject( "worldGorgeButton", GUIMenuCustomizeWorldButton, self )
    self.worldGorgeButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Gorge )
            )
    )
    --self.worldGorgeButton:SetColor( Color(0.2, 1, 0, 0.25) )
    self.worldGorgeButton:SetLayer( kMainWorldButtonsLayer )
    self.worldGorgeButton:SetVisible(false)
    self.worldGorgeButton:SetTooltip(initGorgeLbl)

    self.worldLerkButton = CreateGUIObject( "worldLerkButton", GUIMenuCustomizeWorldButton, self )
    self.worldLerkButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Lerk )
            )
    )
    --self.worldLerkButton:SetColor( Color(1, 0, 0.2, 0.25) )
    self.worldLerkButton:SetLayer( kMainWorldButtonsLayer )
    self.worldLerkButton:SetVisible(false)
    self.worldLerkButton:SetTooltip(initLerkLbl)

    self.worldFadeButton = CreateGUIObject( "worldFadeButton", GUIMenuCustomizeWorldButton, self )
    self.worldFadeButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Fade )
            )
    )
    --self.worldFadeButton:SetColor( Color(1, 0, 0.5, 0.2) )
    self.worldFadeButton:SetLayer( kMainWorldButtonsLayer )
    self.worldFadeButton:SetVisible(false)
    self.worldFadeButton:SetTooltip(initFadeLbl)

    self.worldOnosButton = CreateGUIObject( "worldOnosButton", GUIMenuCustomizeWorldButton, self )
    self.worldOnosButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Onos )
            )
    )
    --self.worldOnosButton:SetColor( Color(0.5, 0, 1, 0.2) )
    self.worldOnosButton:SetLayer( kMainWorldButtonsLayer )
    self.worldOnosButton:SetVisible(false)
    self.worldOnosButton:SetTooltip(initOnosLbl)

    self.worldClogButton = CreateGUIObject( "worldClogButton", GUIMenuCustomizeWorldButton, self )
    self.worldClogButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Clog )
            )
    )
    --self.worldClogButton:SetColor( Color(0.2, 1, 1, 0.325) )
    self.worldClogButton:SetLayer( kMainWorldButtonsLayer )
    self.worldClogButton:SetVisible(false)
    self.worldClogButton:SetTooltip(initClogLbl)

    self.worldHydraButton = CreateGUIObject( "worldHydraButton", GUIMenuCustomizeWorldButton, self )
    self.worldHydraButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Hydra )
            )
    )
    --self.worldHydraButton:SetColor( Color(1, 0, 1, 0.2) )
    self.worldHydraButton:SetLayer( kMainWorldButtonsLayer )
    self.worldHydraButton:SetVisible(false)
    self.worldHydraButton:SetTooltip(initHydraLbl)

    self.worldBabblerButton = CreateGUIObject( "worldBabblerButton", GUIMenuCustomizeWorldButton, self )
    self.worldBabblerButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Babblers )
            )
    )
    --self.worldBabblerButton:SetColor( Color(1, 0, 0, 0.2) )
    self.worldBabblerButton:SetLayer( kMainWorldButtonsLayer )
    self.worldBabblerButton:SetVisible(false)
    self.worldBabblerButton:SetTooltip(initBabblerLbl)

    self.worldBabblerEggButton = CreateGUIObject( "worldBabblerEggButton", GUIMenuCustomizeWorldButton, self )
    self.worldBabblerEggButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.BileMine )
            )
    )
    --self.worldBabblerEggButton:SetColor( Color(1, 0.75, 0.2, 0.35) )
    self.worldBabblerEggButton:SetLayer( kMainWorldButtonsLayer )
    self.worldBabblerEggButton:SetVisible(false)
    self.worldBabblerEggButton:SetTooltip(initBabblerEggLbl)

    self.lifeformsIntructions = CreateGUIObject("lifeformsIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.lifeformsIntructions:AlignBottom()
    self.lifeformsIntructions:SetY( -90 )
    self.lifeformsIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.lifeformsIntructions:SetDropShadowEnabled(true)
    self.lifeformsIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.AlienLifeforms] =
    {
        self.worldSkulkButton,
        self.worldGorgeButton,
        self.worldLerkButton,
        self.worldFadeButton,
        self.worldOnosButton,

        self.worldClogButton,
        self.worldHydraButton,
        self.worldBabblerButton,
        self.worldBabblerEggButton,

        self.lifeformsIntructions
    }

    local _self = self

    local CycleCosmeticSkulkPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Skulk, -1 )
        self:SetTooltip(label .. " " .. skulkStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticSkulkNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Skulk, 1 )
        self:SetTooltip(label .. " " .. skulkStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticGorgePrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Gorge, -1 )
        self:SetTooltip(label .. " " .. gorgeStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticGorgeNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Gorge, 1 )
        self:SetTooltip(label .. " " .. gorgeStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticLerkPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Lerk, -1 )
        self:SetTooltip(label .. " " .. lerkStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticLerkNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Lerk, 1 )
        self:SetTooltip(label .. " " .. lerkStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticFadePrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Fade, -1 )
        self:SetTooltip(label .. " " .. fadeStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticFadeNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Fade, 1 )
        self:SetTooltip(label .. " " .. fadeStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticOnosPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Onos, -1 )
        self:SetTooltip(label .. " " .. onosStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticOnosNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Onos, 1 )
        self:SetTooltip(label .. " " .. onosStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticClogPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Clog, -1 )
        self:SetTooltip(label .. " " .. clogStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticClogNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Clog, 1 )
        self:SetTooltip(label .. " " .. clogStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticHydraPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Hydra, -1 )
        self:SetTooltip(label .. " " .. hydraStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticHydraNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Hydra, 1 )
        self:SetTooltip(label .. " " .. hydraStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticBabblerPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Babbler, -1 )
        self:SetTooltip(label .. " " .. babblerStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticBabblerNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Babbler, 1 )
        self:SetTooltip(label .. " " .. babblerStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticBabblerEggPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.BabblerEgg, -1 )
        self:SetTooltip(label .. " " .. babblerEggStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleCosmeticBabblerEggNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.BabblerEgg, 1 )
        self:SetTooltip(label .. " " .. babblerEggStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldSkulkButton:SetMouseRightClickCallback( CycleCosmeticSkulkPrev )
    self.worldSkulkButton:SetPressedCallback( CycleCosmeticSkulkNext )

    self.worldGorgeButton:SetMouseRightClickCallback( CycleCosmeticGorgePrev )
    self.worldGorgeButton:SetPressedCallback( CycleCosmeticGorgeNext )

    self.worldLerkButton:SetMouseRightClickCallback( CycleCosmeticLerkPrev )
    self.worldLerkButton:SetPressedCallback( CycleCosmeticLerkNext )

    self.worldFadeButton:SetMouseRightClickCallback( CycleCosmeticFadePrev )
    self.worldFadeButton:SetPressedCallback( CycleCosmeticFadeNext )

    self.worldOnosButton:SetMouseRightClickCallback( CycleCosmeticOnosPrev )
    self.worldOnosButton:SetPressedCallback( CycleCosmeticOnosNext )

    self.worldClogButton:SetMouseRightClickCallback( CycleCosmeticClogPrev )
    self.worldClogButton:SetPressedCallback( CycleCosmeticClogNext )

    self.worldHydraButton:SetMouseRightClickCallback( CycleCosmeticHydraPrev )
    self.worldHydraButton:SetPressedCallback( CycleCosmeticHydraNext )

    self.worldBabblerButton:SetMouseRightClickCallback( CycleCosmeticBabblerPrev )
    self.worldBabblerButton:SetPressedCallback( CycleCosmeticBabblerNext )

    self.worldBabblerEggButton:SetMouseRightClickCallback( CycleCosmeticBabblerEggPrev )
    self.worldBabblerEggButton:SetPressedCallback( CycleCosmeticBabblerEggNext )

end



function GUIMenuCustomizeScreen:InitMarineExoElements(scene)

    local exoSuitStr = Locale.ResolveString("EXOSUIT")
    local initExoSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "ExoMiniguns" ) .. " " .. exoSuitStr --rail shares same label

    self.worldExoMinigunsButton = CreateGUIObject( "worldExoMinigunsButton", GUIMenuCustomizeWorldButton, self, { tooltip = "" } )
    self.worldExoMinigunsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Minigun )
            )
    )
    --self.worldExoMinigunsButton:SetColor( Color(0.2, 1, 1, 0.2) )
    self.worldExoMinigunsButton:SetVisible(false)
    self.worldExoMinigunsButton:SetTooltip(initExoSkinLabel)

    self.worldExoRailgunsButton = CreateGUIObject( "worldExoRailgunsButton", GUIMenuCustomizeWorldButton, self, { tooltip = "" } )
    self.worldExoRailgunsButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Railgun )
            )
    )
    --self.worldExoRailgunsButton:SetColor( Color(0.5, 0.2, 1, 0.2) )
    self.worldExoRailgunsButton:SetVisible(false)
    self.worldExoRailgunsButton:SetTooltip(initExoSkinLabel)

    self.exoIntructions = CreateGUIObject("exoIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.exoIntructions:AlignBottom()
    self.exoIntructions:SetY( -50 )
    self.exoIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.exoIntructions:SetDropShadowEnabled(true)
    self.exoIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.ExoBay] =
    {
        self.worldExoMinigunsButton, self.worldExoRailgunsButton, self.exoIntructions
    }

    local _self = self
    local CycleCosmeticPrev = function( self )
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Exo, -1 )
        _self.worldExoRailgunsButton:SetTooltip(label .. " " .. exoSuitStr)
        _self.worldExoMinigunsButton:SetTooltip(label .. " " .. exoSuitStr)
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticNext = function( self )
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Exo, 1 )
        _self.worldExoRailgunsButton:SetTooltip(label .. " " .. exoSuitStr)
        _self.worldExoMinigunsButton:SetTooltip(label .. " " .. exoSuitStr)
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldExoMinigunsButton:SetMouseRightClickCallback( CycleCosmeticPrev )
    self.worldExoMinigunsButton:SetPressedCallback( CycleCosmeticNext )

    self.worldExoRailgunsButton:SetMouseRightClickCallback( CycleCosmeticPrev )
    self.worldExoRailgunsButton:SetPressedCallback( CycleCosmeticNext )

end

function GUIMenuCustomizeScreen:InitMarineStructureElements(scene)

    local cmdStationStr = Locale.ResolveString("COMMAND_STATION")
    local extractorStr = Locale.ResolveString("EXTRACTOR")
    local macStr = Locale.ResolveString("MAC")
    local arcStr = Locale.ResolveString("ARC")

    local initExtractorSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Extractor" ) .. " " .. extractorStr
    local initCmdStationSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "CommandStation" ) .. " " .. cmdStationStr

    local initMacSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Mac" ) .. " " .. macStr
    local initArcSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Arc" ) .. " " .. arcStr

    self.worldCommandStationButton = CreateGUIObject( "worldCommandStationButton", GUIMenuCustomizeWorldButton, self )
    self.worldCommandStationButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.CommandStation )
            )
    )
    --self.worldCommandStationButton:SetColor( Color(1, 0.2, 0.81, 0.25) )
    self.worldCommandStationButton:SetVisible(false)
    self.worldCommandStationButton:SetTooltip(initCmdStationSkinLabel)

    self.worldExtractorButton = CreateGUIObject( "worldExtractorButton", GUIMenuCustomizeWorldButton, self )
    self.worldExtractorButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Extractor )
            )
    )
    --self.worldExtractorButton:SetColor( Color(0.9, 0.2, 0.3, 0.2) )
    self.worldExtractorButton:SetTooltip(initExtractorSkinLabel)
    self.worldExtractorButton:SetVisible(false)


    self.worldMacButton = CreateGUIObject( "worldMacButton", GUIMenuCustomizeWorldButton, self )
    self.worldMacButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.MAC )
            )
    )
    --self.worldMacButton:SetColor( Color(0.25, 0.85, 0.1, 0.32) )
    self.worldMacButton:SetTooltip(initMacSkinLabel)
    self.worldMacButton:SetVisible(false)


    self.worldArcButton = CreateGUIObject( "worldArcButton", GUIMenuCustomizeWorldButton, self )
    self.worldArcButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.ARC )
            )
    )
    --self.worldArcButton:SetColor( Color(1, 0, 0, 0.35) )
    self.worldArcButton:SetTooltip(initArcSkinLabel)
    self.worldArcButton:SetVisible(false)


    self.marineStructsIntructions = CreateGUIObject("marineStructsIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.marineStructsIntructions:AlignBottom()
    self.marineStructsIntructions:SetY( -50 )
    self.marineStructsIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.marineStructsIntructions:SetDropShadowEnabled(true)
    self.marineStructsIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.MarineStructures] =
    {
        self.worldCommandStationButton,
        self.worldExtractorButton,
        self.worldMacButton,
        self.worldArcButton,

        self.marineStructsIntructions
    }

    local _self = self

    local CycleCosmeticExtractorPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Extractor, -1 )
        self:SetTooltip( label .. " " .. extractorStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticExtractorNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Extractor, 1 )
        self:SetTooltip( label .. " " .. extractorStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleCosmeticStationPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.CommandStation, -1 )
        self:SetTooltip( label .. " " .. cmdStationStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleCosmeticStationNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.CommandStation, 1 )
        self:SetTooltip( label .. " " .. cmdStationStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldExtractorButton:SetMouseRightClickCallback( CycleCosmeticExtractorPrev )
    self.worldExtractorButton:SetPressedCallback( CycleCosmeticExtractorNext )

    self.worldCommandStationButton:SetMouseRightClickCallback( CycleCosmeticStationPrev )
    self.worldCommandStationButton:SetPressedCallback( CycleCosmeticStationNext )


    local CycleMacCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Mac, -1 )
        self:SetTooltip( label .. " " .. macStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleMacCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Mac, 1 )
        self:SetTooltip( label .. " " .. macStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldMacButton:SetMouseRightClickCallback( CycleMacCosmeticPrev )
    self.worldMacButton:SetPressedCallback( CycleMacCosmeticNext )

    local CycleArcCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Arc, -1 )
        self:SetTooltip( label .. " " .. arcStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end
    local CycleArcCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Arc, 1 )
        self:SetTooltip( label .. " " .. arcStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    self.worldArcButton:SetMouseRightClickCallback( CycleArcCosmeticPrev )
    self.worldArcButton:SetPressedCallback( CycleArcCosmeticNext )

end

function GUIMenuCustomizeScreen:InitMarinePatchElements(scene)

    local patchStr = "Shoulder Patch"  --FIXME Bleh...no string-key for just "Shoulder Patch"
    local initPatchIdx = scene.avaiableCosmeticItems["shoulderPatches"][scene:GetActiveShoulderPatchIndex()]

    local PadNameFormated = function( name )    --TODO duplicate, remove to central local func
        if name == nil then --no patches owned
            name = "None"
        end
        return name == "None" and name or name .. " " .. patchStr
    end

    local initPadLbl = PadNameFormated( kShoulderPadNames[initPatchIdx] )

    local curMarineType = Client.GetOptionString("sexType", "Male")
    local marineVariantName = scene:GetCustomizableObjectVariantName( "MarineRight" )
    if table.icontains(robotVariantLabels, marineVariantName) then
        curMarineType = "bigmac"
    end

    local buttonPointsLabel
    if curMarineType == "Male" then
        buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchMale
    elseif curMarineType == "Female" then
        buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchFemale
    elseif curMarineType == "bigmac" then
        buttonPointsLabel = gCustomizeSceneData.kWorldButtonLabels.ShoulderPatchBigmac
    end

    self.worldPatchButton = CreateGUIObject( "worldPatchButton", GUIMenuCustomizeWorldButton, self )
    self.worldPatchButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( buttonPointsLabel )
            )
    )
    --self.worldPatchButton:SetColor( Color(0.735, 0.285, 0, 0.3) )
    self.worldPatchButton:SetLayer( kMainWorldButtonsLayer )
    self.worldPatchButton:SetVisible(false)
    self.worldPatchButton:SetTooltip(initPadLbl)

    self.patchesIntructions = CreateGUIObject("patchesIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.patchesIntructions:AlignBottom()
    self.patchesIntructions:SetY( -50 )
    self.patchesIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.patchesIntructions:SetDropShadowEnabled(true)
    self.patchesIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.ShoulderPatches] =
    {
        self.worldPatchButton, self.patchesIntructions
    }

    local _self = self

    local CyclePatchNext = function(self)
        local label, ownsVariant = scene:CyclePatches( 1 )
        self:SetTooltip( PadNameFormated(label) )
        _self:UpdateBuyButton( not ownsVariant and scene:GetActiveShoulderPatchItemId() or -1 )
    end

    local CyclePatchPrev = function(self)
        local label, ownsVariant = scene:CyclePatches( -1 )
        self:SetTooltip( PadNameFormated(label) )
        _self:UpdateBuyButton( not ownsVariant and scene:GetActiveShoulderPatchItemId() or -1 )
    end

    self.worldPatchButton:SetMouseRightClickCallback( CyclePatchPrev )
    self.worldPatchButton:SetPressedCallback( CyclePatchNext )

end


local worldWepBtnToItem =
{
    ["worldRifleButton"] = gCustomizeSceneData.kSceneObjectReferences.Rifle,
    ["worldPistolButton"] = gCustomizeSceneData.kSceneObjectReferences.Pistol,
    ["worldShotgunButton"] = gCustomizeSceneData.kSceneObjectReferences.Shotgun,
    ["worldWelderButton"] = gCustomizeSceneData.kSceneObjectReferences.Welder,
    ["worldAxeButton"] = gCustomizeSceneData.kSceneObjectReferences.Axe,
    ["worldGrenadeLauncherButton"] = gCustomizeSceneData.kSceneObjectReferences.GrenadeLauncher,
    ["worldFlamethrowerButton"] = gCustomizeSceneData.kSceneObjectReferences.Flamethrower,
    ["worldHmgButton"] = gCustomizeSceneData.kSceneObjectReferences.HeavyMachineGun,
}

function GUIMenuCustomizeScreen:InitMarineWeaponElements(scene)

    local rifleLabel = Locale.ResolveString("RIFLE")
    local pistolLabel = Locale.ResolveString("PISTOL")
    local welderLabel = Locale.ResolveString("WELDER")
    local axeLabel = Locale.ResolveString("AXE")
    local sgLabel = Locale.ResolveString("SHOTGUN")
    local nadeLabel = Locale.ResolveString("GRENADE_LAUNCHER")
    local ftLabel = Locale.ResolveString("FLAMETHROWER")
    local hmgLabel = Locale.ResolveString("HEAVY_MACHINE_GUN")

    local initRifleLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Rifle" ) .. " " .. rifleLabel
    local initPistolLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Pistol" ) .. " " .. pistolLabel
    local initWelderLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Welder" ) .. " " .. welderLabel
    local initAxeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Axe" ) .. " " .. axeLabel
    local initShotgunLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Shotgun" ) .. " " .. sgLabel
    local initNadeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "GrenadeLauncher" ) .. " " .. nadeLabel
    local initFtLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Flamethrower" ) .. " " .. ftLabel
    local initHmgLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "HeavyMachineGun" ) .. " " .. hmgLabel

    self.worldRifleButton = CreateGUIObject( "worldRifleButton", GUIMenuCustomizeWorldButton, self )
    self.worldRifleButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Rifle )
            )
    )
    --self.worldRifleButton:SetColor( Color(1, 1, 1, 0.285) )
    self.worldRifleButton:SetVisible(false)
    self.worldRifleButton:SetTooltip(initRifleLbl)

    self.worldPistolButton = CreateGUIObject( "worldPistolButton", GUIMenuCustomizeWorldButton, self )
    self.worldPistolButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Pistol )
            )
    )
    --self.worldPistolButton:SetColor( Color(1, 1, 0, 0.285) )
    self.worldPistolButton:SetVisible(false)
    self.worldPistolButton:SetTooltip(initPistolLbl)

    self.worldWelderButton = CreateGUIObject( "worldWelderButton", GUIMenuCustomizeWorldButton, self )
    self.worldWelderButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Welder )
            )
    )
    --self.worldWelderButton:SetColor( Color(0, 1, 1, 0.3) )
    self.worldWelderButton:SetVisible(false)
    self.worldWelderButton:SetTooltip(initWelderLbl)

    self.worldAxeButton = CreateGUIObject( "worldAxeButton", GUIMenuCustomizeWorldButton, self )
    self.worldAxeButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Axe )     --TODO Revise points for easier selection
            )
    )
    --self.worldAxeButton:SetColor( Color(0, 1, 1, 0.3) )
    self.worldAxeButton:SetVisible(false)
    self.worldAxeButton:SetTooltip(initAxeLbl)

    self.worldShotgunButton = CreateGUIObject( "worldShotgunButton", GUIMenuCustomizeWorldButton, self )
    self.worldShotgunButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Shotgun )
            )
    )
    --self.worldShotgunButton:SetColor( Color(1, 0, 1, 0.285) )
    self.worldShotgunButton:SetVisible(false)
    self.worldShotgunButton:SetTooltip(initShotgunLbl)

    self.worldGrenadeLauncherButton = CreateGUIObject( "worldGrenadeLauncherButton", GUIMenuCustomizeWorldButton, self )
    self.worldGrenadeLauncherButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.GrenadeLauncher )
            )
    )
    --self.worldGrenadeLauncherButton:SetColor( Color(1, 0, 0.5, 0.3) )
    self.worldGrenadeLauncherButton:SetVisible(false)
    self.worldGrenadeLauncherButton:SetTooltip(initNadeLbl)

    self.worldFlamethrowerButton = CreateGUIObject( "worldFlamethrowerButton", GUIMenuCustomizeWorldButton, self )
    self.worldFlamethrowerButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Flamethrower )
            )
    )
    --self.worldFlamethrowerButton:SetColor( Color(0, 0.65, 1, 0.3) )
    self.worldFlamethrowerButton:SetVisible(false)
    self.worldFlamethrowerButton:SetTooltip(initFtLbl)

    self.worldHmgButton = CreateGUIObject( "worldHmgButton", GUIMenuCustomizeWorldButton, self )
    self.worldHmgButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.HeavyMachineGun )
            )
    )
    --self.worldHmgButton:SetColor( Color(0.4, 0, 1, 0.3) )
    self.worldHmgButton:SetVisible(false)
    self.worldHmgButton:SetTooltip(initHmgLbl)

    self.weaponsIntructions = CreateGUIObject("weaponsIntructions", GUIText, self, { font = kViewInstructionsFont, })
    self.weaponsIntructions:AlignBottom()
    self.weaponsIntructions:SetY( -50 )
    self.weaponsIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO Localize
    self.weaponsIntructions:SetDropShadowEnabled(true)
    self.weaponsIntructions:SetVisible(false)

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.Armory] =
    {
        self.worldRifleButton, self.worldPistolButton, self.worldShotgunButton,
        self.worldWelderButton, self.worldAxeButton, self.worldGrenadeLauncherButton,
        self.worldFlamethrowerButton, self.worldHmgButton,
        self.weaponsIntructions
    }

    local FormatWeaponLabel = function( weaponBtn, itemLabel )
        if weaponBtn == "worldRifleButton" then
            return itemLabel .. " " .. rifleLabel
        elseif weaponBtn == "worldPistolButton" then
            return itemLabel .. " " .. pistolLabel
        elseif weaponBtn == "worldWelderButton" then
            return itemLabel .. " " .. welderLabel
        elseif weaponBtn == "worldAxeButton" then
            return itemLabel .. " " .. axeLabel
        elseif weaponBtn == "worldShotgunButton" then
            return itemLabel .. " " .. sgLabel
        elseif weaponBtn == "worldGrenadeLauncherButton" then
            return itemLabel .. " " .. nadeLabel
        elseif weaponBtn == "worldFlamethrowerButton" then
            return itemLabel .. " " .. ftLabel
        elseif weaponBtn == "worldHmgButton" then
            return itemLabel .. " " .. hmgLabel
        end
    end

    local GetWeaponSceneObjectName = function( weaponBtn )
        if weaponBtn == "worldRifleButton" then
            return "Rifle"
        elseif weaponBtn == "worldPistolButton" then
            return "Pistol"
        elseif weaponBtn == "worldWelderButton" then
            return "Welder"
        elseif weaponBtn == "worldAxeButton" then
            return "Axe"
        elseif weaponBtn == "worldShotgunButton" then
            return "Shotgun"
        elseif weaponBtn == "worldGrenadeLauncherButton" then
            return "GrenadeLauncher"
        elseif weaponBtn == "worldFlamethrowerButton" then
            return "Flamethrower"
        elseif weaponBtn == "worldHmgButton" then
            return "HeavyMachineGun"
        end
    end

    local _self = self
    local CycleWeaponCosmeticNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( worldWepBtnToItem[self.name], 1 )
        self:SetTooltip( FormatWeaponLabel( self.name, label ) )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleWeaponCosmeticPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( worldWepBtnToItem[self.name], -1 )
        self:SetTooltip( FormatWeaponLabel( self.name, label ) )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    self.worldRifleButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldRifleButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldPistolButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldPistolButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldShotgunButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldShotgunButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldWelderButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldWelderButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldAxeButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldAxeButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldGrenadeLauncherButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldGrenadeLauncherButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldFlamethrowerButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldFlamethrowerButton:SetPressedCallback( CycleWeaponCosmeticNext )

    self.worldHmgButton:SetMouseRightClickCallback( CycleWeaponCosmeticPrev )
    self.worldHmgButton:SetPressedCallback( CycleWeaponCosmeticNext )

    --TODO Add Object View-Zone "zooming" feature (needs to be modal, to toggle mouse-tracking [rotator] UI element(s) )

end

local kMaleMarineVoiceSamples =
{
    [1] = { "CustomizeMaleVoice1", "CustomizeMaleVoice2", "CustomizeMaleVoice3", "CustomizeMaleVoice4" },
    [2] = { "CustomizeMaleVoice5", "CustomizeMaleVoice9" },
    [3] = { "CustomizeMaleVoice6", "CustomizeMaleVoice7", "CustomizeMaleVoice8", }
}

local kFemaleMarineVoiceSamples =
{
    [1] = { "CustomizeFemaleVoice1", "CustomizeFemaleVoice2", "CustomizeFemaleVoice3", "CustomizeFemaleVoice4" },
    [2] = { "CustomizeFemaleVoice5", "CustomizeFemaleVoice8" },
    [3] = { "CustomizeFemaleVoice6", "CustomizeFemaleVoice7", }
}

local kBmacFriendVoiceSamples =
{
    [1] = { "CustomizeBmacFriendVoice1", "CustomizeBmacFriendVoice2", "CustomizeBmacFriendVoice3", "CustomizeBmacFriendVoice4" },
    [2] = { "CustomizeBmacFriendVoice5", "CustomizeBmacFriendVoice9" },
    [3] = { "CustomizeBmacFriendVoice6", "CustomizeBmacFriendVoice7", "CustomizeBmacFriendVoice8", }
}

local kBmacCombatVoiceSamples =
{
    [1] = { "CustomizeBmacCombatVoice1", "CustomizeBmacCombatVoice2", "CustomizeBmacCombatVoice3", "CustomizeBmacCombatVoice4" },
    [2] = { "CustomizeBmacCombatVoice5", "CustomizeBmacCombatVoice9" },
    [3] = { "CustomizeBmacCombatVoice6", "CustomizeBmacCombatVoice7", "CustomizeBmacCombatVoice8", }
}

--Reference table for each sample length, for setting enable/timeout callback length
--(Note: these are the maximal length of the Sound _Events_, not the individual samples)
local kMarineVoiceSamplesLengths =
{
    ["CustomizeMaleVoice1"] = 1.88,
    ["CustomizeMaleVoice2"] = 1.84,
    ["CustomizeMaleVoice3"] = 2.1,
    ["CustomizeMaleVoice4"] = 1.88,
    ["CustomizeMaleVoice5"] = 4.03,
    ["CustomizeMaleVoice6"] = 1.55,
    ["CustomizeMaleVoice7"] = 1.91,
    ["CustomizeMaleVoice8"] = 1.55,
    ["CustomizeMaleVoice9"] = 1.83,

    ["CustomizeFemaleVoice1"] = 1.8,
    ["CustomizeFemaleVoice2"] = 1.28,
    ["CustomizeFemaleVoice3"] = 2.14,
    ["CustomizeFemaleVoice4"] = 1.41,
    ["CustomizeFemaleVoice5"] = 4.1,
    ["CustomizeFemaleVoice6"] = 1.89,
    ["CustomizeFemaleVoice7"] = 1.54,
    ["CustomizeFemaleVoice8"] = 1.41,

    ["CustomizeBmacFriendVoice1"] = 2.03,
    ["CustomizeBmacFriendVoice2"] = 1.55,
    ["CustomizeBmacFriendVoice3"] = 1.83,
    ["CustomizeBmacFriendVoice4"] = 2.54,
    ["CustomizeBmacFriendVoice5"] = 3.26,
    ["CustomizeBmacFriendVoice6"] = 1.49,
    ["CustomizeBmacFriendVoice7"] = 2.12,
    ["CustomizeBmacFriendVoice8"] = 2.07,
    ["CustomizeBmacFriendVoice9"] = 1.45,

    ["CustomizeBmacCombatVoice1"] = 1.93,
    ["CustomizeBmacCombatVoice2"] = 1.3,
    ["CustomizeBmacCombatVoice3"] = 1.86,
    ["CustomizeBmacCombatVoice4"] = 2.16,
    ["CustomizeBmacCombatVoice5"] = 4.01,
    ["CustomizeBmacCombatVoice6"] = 1.66,
    ["CustomizeBmacCombatVoice7"] = 1.68,
    ["CustomizeBmacCombatVoice8"] = 1.9,
    ["CustomizeBmacCombatVoice9"] = 1.4,
}

local lastPlayedVoiceOver
local function SelectMarineVoiceOwnerSample( samplesTable )
    assert(samplesTable)
    --TODO devise better means to randomize
    local i = math.random(1, #samplesTable)
    local s = math.random( 1, #samplesTable[i] )
    local sample = samplesTable[i][s]
    if sample == lastPlayedVoiceOver then
        sample = SelectMarineVoiceOwnerSample( samplesTable )
    end
    lastPlayedVoiceOver = sample
    return sample
end

local PlayRandomMarineVoiceSample = function( sex, variantId )
    local samplesTable = nil
    local isRobot = table.icontains( kRoboticMarineVariantIds , variantId )

    if sex == "Male" and not isRobot then
        samplesTable = kMaleMarineVoiceSamples
    elseif sex == "Female" and not isRobot then
        samplesTable = kFemaleMarineVoiceSamples
    elseif isRobot then
        if table.icontains( kBigMacVariantIds, variantId ) then
            samplesTable = kBmacFriendVoiceSamples
        else
            samplesTable = kBmacCombatVoiceSamples
        end
    end

    local sample = SelectMarineVoiceOwnerSample(samplesTable)
    assert(sample)

    PlayMenuSound(sample)
    return sample
end

function GUIMenuCustomizeScreen:InitMarineArmorElements(scene)

    local armorStr = Locale.ResolveString("ARMOR")
    local initVariantName = GetCustomizeScene():GetCustomizableObjectVariantName( "MarineRight" )
    local initArmorLabel = initVariantName .. " " .. armorStr

    self.worldMarineArmorButton = CreateGUIObject( "worldMarineArmorButton", GUIMenuCustomizeWorldButton, self )
    self.worldMarineArmorButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Armors )
            )
    )
    --self.worldMarineArmorButton:SetColor( Color(0.2, 1, 1, 0.2) )
    self.worldMarineArmorButton:SetVisible(false)
    self.worldMarineArmorButton:SetTooltip(initArmorLabel)

    self.worldMarineGenderButton = CreateGUIObject( "worldMarineGenderButton", GUIMenuCustomizeWorldButton, self )
    self.worldMarineGenderButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Gender )
            )
    )
    --self.worldMarineGenderButton:SetColor( Color(0.8, 0.4, 0, 0.2) )
    self.worldMarineGenderButton:SetVisible(false)

    local inactiveVoiceBtnColor = Color(0.64, 0.64, 0.72, 0.85)
    local activeVoiceBtnColor = Color(0, 208/255, 1, 1)
    --local disabledVoiceBtnColor = Color(35/255, 35/255, 35/255, 0.25)
    self.worldMarineVoiceButton = CreateGUIObject( "worldMarineVoiceButton", GUIMenuCustomizeWorldButton, self )
    self.worldMarineVoiceButton:SetPoints(
            scene:GetScenePointsToScreenPointList(
                    GetCustomizeWorldButtonPoints( gCustomizeSceneData.kWorldButtonLabels.Gender )
            )
    )
    self.worldMarineVoiceButton:SetColor( activeVoiceBtnColor )
    self.worldMarineVoiceButton:SetVisible(false)
    self.worldMarineVoiceButton.ShowMainMenuOnly = true
    self.worldMarineVoiceButton:SetTexture("ui/speaker.dds")
    self.worldMarineVoiceButton:SetTooltip("Play voice sample") --TODO localize

    self.armorIntructions = CreateGUIObject("armorInstructions", GUIText, self, { font = kViewInstructionsFont, })
    self.armorIntructions:AlignBottom()
    self.armorIntructions:SetY( -50 )
    self.armorIntructions:SetText(Locale.ResolveString("CUSTOMIZE_CYCLE")) --TODO localize
    self.armorIntructions:SetDropShadowEnabled(true)
    self.armorIntructions:SetVisible(false)

    self.genderChangeLabel = CreateGUIObject("genderChangeLabel", GUIText, self,
            {
                font = kViewInstructionsFont,
            })
    self.genderChangeLabel:SetDropShadowEnabled(true)
    self.genderChangeLabel:SetVisible(false)
    local curGend = Client.GetOptionString("sexType", "Male")
    self.genderChangeLabel:SetText( Locale.ResolveString("CUSTOMIZE_CYCLE_SEX")) --TODO Localize

    self.viewsWorldButtons[gCustomizeSceneData.kViewLabels.Marines] =
    {
        self.worldMarineArmorButton, self.worldMarineGenderButton,
        self.armorIntructions, self.genderChangeLabel, self.worldMarineVoiceButton
    }

    local _self = self

    local CycleArmorPrev = function(self)
        local label, ownsVariant, prevVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Marine, -1 )
        local showGender = not table.icontains( robotVariantLabels, label )
        _self.genderChangeLabel:SetVisible(showGender)
        _self.worldMarineGenderButton:SetVisible(showGender)
        _self.worldMarineArmorButton:SetTooltip( label .. " " .. armorStr )
        _self:UpdateBuyButton( not ownsVariant and prevVariantItemId or -1 )
    end

    local CycleArmorNext = function(self)
        local label, ownsVariant, nextVariantItemId = GetCustomizeScene():CycleCosmetic( gCustomizeSceneData.kSceneObjectReferences.Marine, 1 )
        local showGender = not table.icontains( robotVariantLabels, label )
        _self.genderChangeLabel:SetVisible(showGender)
        _self.worldMarineGenderButton:SetVisible(showGender)
        _self.worldMarineArmorButton:SetTooltip( label .. " " .. armorStr )
        _self:UpdateBuyButton( not ownsVariant and nextVariantItemId or -1 )
    end

    local CycleGender = function()
        local newType = GetCustomizeScene():CycleMarineGenderType()
        _self.genderChangeLabel:SetText( Locale.ResolveString("CUSTOMIZE_CYCLE_SEX") ) --TODO Localize
    end

    local PlayExampleVoice = function()
        local sex = GetCustomizeScene():GetMarineGenderType()
        local variant = GetCustomizeScene():GetCustomizableObjectVariantId( "MarineRight" )
        _self.worldMarineVoiceButton:ClearPressedCallback()
        local toPlaySample = PlayRandomMarineVoiceSample( sex, variant )
        local sampleTime = kMarineVoiceSamplesLengths[toPlaySample]
        _self.worldMarineVoiceButton:AddTimedCallback( _self.worldMarineVoiceButton.VoicePlayedCallback, sampleTime, false )
        _self.worldMarineVoiceButton:SetColor(inactiveVoiceBtnColor)
    end

    self.worldMarineVoiceButton.VoicePlayedCallback = function()
        _self.worldMarineVoiceButton:SetEnabled(true)
        _self.worldMarineVoiceButton:SetColor(activeVoiceBtnColor)
        _self.worldMarineVoiceButton:SetTooltip("Play voice sample") --TODO localization
        _self.worldMarineVoiceButton:SetPressedCallback( PlayExampleVoice )
    end

    --TODO Add Middle-click -> zoom handler (to trigger render in view-zone [needs toggle-state])
    self.worldMarineArmorButton:SetMouseRightClickCallback( CycleArmorPrev )
    self.worldMarineArmorButton:SetPressedCallback( CycleArmorNext )
    self.worldMarineGenderButton:SetPressedCallback( CycleGender )

    self.worldMarineVoiceButton:SetPressedCallback( PlayExampleVoice )

end

function GUIMenuCustomizeScreen:UpdateActiveViewWorldButtons(scene)
    assert(scene)

    --Handle Camera perspective changes and changes in World Button points (due to perspective change)
    if self.activeTargetView == gCustomizeSceneData.kViewLabels.DefaultAlienView or self.activeTargetView == gCustomizeSceneData.kViewLabels.DefaultMarineView then
        UpdateWorldButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.Marines then
        UpdateMarineArmorsButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.ExoBay then
        UpdateMarineExosuitsButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.MarineStructures then
        UpdateMarineStructuresButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.ShoulderPatches then
        UpdateMarinePatchesButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.Armory then
        UpdateMarineWeaponsButtonsSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.AlienTunnels then
        UpdateAlienTunnelButtonSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.AlienStructures then
        UpdateAlienStructuresButtonSize(self, scene)

    elseif self.activeTargetView == gCustomizeSceneData.kViewLabels.AlienLifeforms then
        UpdateAlienLifeformsButtonSize(self, scene)

    end
end

function GUIMenuCustomizeScreen:ToggleViewElements()
    assert(self.viewsWorldButtons[self.activeTargetView])

    local scene = GetCustomizeScene()

    self:UpdateActiveViewWorldButtons( scene )

    local worldButtons = self.viewsWorldButtons[self.activeTargetView]
    local isInGame = Client.GetIsConnected()
    for i = 1, #worldButtons do

        local isVis = true

        if self.activeTargetView == gCustomizeSceneData.kViewLabels.Marines then
            local marineVariantName = scene:GetCustomizableObjectVariantName( "MarineRight" )
            local isRobot = table.icontains( robotVariantLabels, marineVariantName )
            if (worldButtons[i].name == "worldMarineGenderButton" or worldButtons[i].name == "genderChangeLabel") and isRobot then
                isVis = false
            end
        end

        if worldButtons[i].ShowMainMenuOnly and isInGame then
            isVis = false
        end

        worldButtons[i]:SetVisible( isVis )
    end

    self:UpdateBuyButton(-1) --auto-hide when view changes

end


function GUIMenuCustomizeScreen:OnViewLabelActivation( activeViewLabel )

    if GetIsViewForTeam(activeViewLabel, kTeam1Index) then
        self.mainMarineTopBar:SetVisible(true)
        self.marinesViewButton:SetVisible(false)

        self.aliensViewButton:SetVisible(true)
        self.mainAlienBottomBar:SetVisible(false)
    elseif GetIsViewForTeam(activeViewLabel, kTeam2Index) then
        self.mainMarineTopBar:SetVisible(false)
        self.marinesViewButton:SetVisible(true)

        self.aliensViewButton:SetVisible(false)
        self.mainAlienBottomBar:SetVisible(true)
    end

    self:ToggleViewElements()

    --Ensure buttons are always present for default views (hackaround)
    if GetIsDefaultView( activeViewLabel ) then
        self.aliensViewButton:SetVisible( GetViewTeamIndex(activeViewLabel) == kTeam1Index )
        self.marinesViewButton:SetVisible( GetViewTeamIndex(activeViewLabel) == kTeam2Index )
        self.globalBackButton:SetVisible(false)
    else
        self.globalBackButton:SetVisible(true)
        self.aliensViewButton:SetVisible(false)
        self.marinesViewButton:SetVisible(false)
    end

end

function GUIMenuCustomizeScreen:HideViewWorldElements() --?? Change to IterDict?
    for k, v in pairs(self.viewsWorldButtons) do
        for i = 1, #v do
            self.viewsWorldButtons[k][i]:SetVisible(false)
        end
    end
end


function GUIMenuCustomizeScreen:ResetAlienLifeformsElements()
    local skulkStr = Locale.ResolveString("SKULK")
    local gorgeStr = Locale.ResolveString("GORGE")
    local lerkStr = Locale.ResolveString("LERK")
    local fadeStr = Locale.ResolveString("FADE")
    local onosStr = Locale.ResolveString("ONOS")

    local clogStr = Locale.ResolveString("CLOG")
    local hydraStr = Locale.ResolveString("HYDRA")
    local babblerStr = Locale.ResolveString("BABBLER")
    local babblerEggStr = Locale.ResolveString("BABBLER_MINE")

    local initSkulkLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Skulk" ) .. " " .. skulkStr
    local initGorgeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Gorge" ) .. " " .. gorgeStr
    local initLerkLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Lerk" ) .. " " .. lerkStr
    local initFadeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Fade" ) .. " " .. fadeStr
    local initOnosLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Onos" ) .. " " .. onosStr

    local initClogLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Clog" ) .. " " .. clogStr
    local initHydraLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Hydra" ) .. " " .. hydraStr
    local initBabblerLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Babbler" ) .. " " .. babblerStr
    local initBabblerEggLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "BabblerEgg" ) .. " " .. babblerEggStr

    self.worldSkulkButton:SetTooltip(initSkulkLbl)
    self.worldGorgeButton:SetTooltip(initGorgeLbl)
    self.worldLerkButton:SetTooltip(initLerkLbl)
    self.worldFadeButton:SetTooltip(initFadeLbl)
    self.worldOnosButton:SetTooltip(initOnosLbl)

    self.worldClogButton:SetTooltip(initClogLbl)
    self.worldHydraButton:SetTooltip(initHydraLbl)
    self.worldBabblerButton:SetTooltip(initBabblerLbl)
    self.worldBabblerEggButton:SetTooltip(initBabblerEggLbl)
end

function GUIMenuCustomizeScreen:ResetAlienStructuresElements()
    local hiveStr = Locale.ResolveString("HIVE")
    local harvyStr = Locale.ResolveString("HARVESTER")
    local eggStr = Locale.ResolveString("EGG")
    local cystStr = Locale.ResolveString("CYST")
    local drifterStr = Locale.ResolveString("DRIFTER")

    local initHiveLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Hive" ) .. " " .. hiveStr
    local initHarvyLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Harvester" ) .. " " .. harvyStr
    local initEggLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Egg" ) .. " " .. eggStr
    local initCystLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Cyst" ) .. " " .. cystStr
    local initDrifterLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Drifter" ) .. " " .. drifterStr

    self.worldHiveButton:SetTooltip(initHiveLbl)
    self.worldHarvesterButton:SetTooltip(initHarvyLbl)
    self.worldEggButton:SetTooltip(initEggLbl)
    self.worldCystButton:SetTooltip(initCystLbl)
    self.worldDrifterButton:SetTooltip(initDrifterLbl)
end

function GUIMenuCustomizeScreen:ResetAlienTunnelsElements()
    local tunnelStr = Locale.ResolveString("TUNNEL_ENTRANCE")
    local initTunnelLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Tunnel" ) .. " " .. tunnelStr
    self.worldTunnelButton:SetTooltip(initTunnelLbl)
end

function GUIMenuCustomizeScreen:ResetMarinePatchesElements()
    local cs = GetCustomizeScene()
    local patchStr = "Shoulder Patch"  --FIXME Bleh...no string-key for just "Shoulder Patch"
    local initPatchIdx = cs.avaiableCosmeticItems["shoulderPatches"][cs:GetActiveShoulderPatchIndex()]
    local PadNameFormated = function( name )    --TODO duplicate, remove to central local func
        if name == nil then --no patches owned
            name = "None"
        end
        return name == "None" and name or name .. " " .. patchStr
    end
    local initPadLbl = PadNameFormated( kShoulderPadNames[initPatchIdx] )
    self.worldPatchButton:SetTooltip(initPadLbl)
end

function GUIMenuCustomizeScreen:ResetMarineWeaponsElements()
    local rifleLabel = Locale.ResolveString("RIFLE")
    local pistolLabel = Locale.ResolveString("PISTOL")
    local welderLabel = Locale.ResolveString("WELDER")
    local axeLabel = Locale.ResolveString("AXE")
    local sgLabel = Locale.ResolveString("SHOTGUN")
    local nadeLabel = Locale.ResolveString("GRENADE_LAUNCHER")
    local ftLabel = Locale.ResolveString("FLAMETHROWER")
    local hmgLabel = Locale.ResolveString("HEAVY_MACHINE_GUN")

    local initRifleLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Rifle" ) .. " " .. rifleLabel
    local initPistolLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Pistol" ) .. " " .. pistolLabel
    local initWelderLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Welder" ) .. " " .. welderLabel
    local initAxeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Axe" ) .. " " .. axeLabel
    local initShotgunLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Shotgun" ) .. " " .. sgLabel
    local initNadeLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "GrenadeLauncher" ) .. " " .. nadeLabel
    local initFtLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "Flamethrower" ) .. " " .. ftLabel
    local initHmgLbl = GetCustomizeScene():GetCustomizableObjectVariantName( "HeavyMachineGun" ) .. " " .. hmgLabel

    self.worldHmgButton:SetTooltip(initHmgLbl)
    self.worldFlamethrowerButton:SetTooltip(initFtLbl)
    self.worldGrenadeLauncherButton:SetTooltip(initNadeLbl)
    self.worldShotgunButton:SetTooltip(initShotgunLbl)
    self.worldAxeButton:SetTooltip(initAxeLbl)
    self.worldWelderButton:SetTooltip(initWelderLbl)
    self.worldPistolButton:SetTooltip(initPistolLbl)
    self.worldRifleButton:SetTooltip(initRifleLbl)
end

function GUIMenuCustomizeScreen:ResetMarineExoElements()
    local exoSuitStr = Locale.ResolveString("EXOSUIT")
    local initExoSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "ExoMiniguns" ) .. " " .. exoSuitStr --rail shares same label
    --TODO Need non=string identifider for above call param
    self.worldExoMinigunsButton:SetTooltip(initExoSkinLabel)
    self.worldExoRailgunsButton:SetTooltip(initExoSkinLabel)
end

function GUIMenuCustomizeScreen:ResetMarineStructuresElements()
    local cmdStationStr = Locale.ResolveString("COMMAND_STATION")
    local extractorStr = Locale.ResolveString("EXTRACTOR")
    local macStr = Locale.ResolveString("MAC")
    local arcStr = Locale.ResolveString("ARC")
    local initExtractorSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Extractor" ) .. " " .. extractorStr
    local initCmdStationSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "CommandStation" ) .. " " .. cmdStationStr
    local initMacSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Mac" ) .. " " .. macStr
    local initArcSkinLabel = GetCustomizeScene():GetCustomizableObjectVariantName( "Arc" ) .. " " .. arcStr
    self.worldCommandStationButton:SetTooltip(initCmdStationSkinLabel)
    self.worldExtractorButton:SetTooltip(initExtractorSkinLabel)
    self.worldMacButton:SetTooltip(initMacSkinLabel)
    self.worldArcButton:SetTooltip(initArcSkinLabel)
end

function GUIMenuCustomizeScreen:ResetMarineArmorElements()
    local armorStr = Locale.ResolveString("ARMOR")
    local initVariantName = GetCustomizeScene():GetCustomizableObjectVariantName( "MarineRight" )
    local initArmorLabel = initVariantName .. " " .. armorStr
    self.worldMarineArmorButton:SetTooltip(initArmorLabel)
end

function GUIMenuCustomizeScreen:ResetActiveVariantsToOwned()
    assert(self.activeTargetView)
    assert(self.previousTargetView)

    --Must be called first, in order for variant data to be in correct state
    local cs = GetCustomizeScene()
    cs:ResetViewVariantsToOwned(self.previousTargetView)

    if GetIsDefaultView(self.previousTargetView) then
        return
    end

    --Marine Views
    if self.previousTargetView == gCustomizeSceneData.kViewLabels.Marines then
        self:ResetMarineArmorElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.ExoBay then
        self:ResetMarineExoElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.MarineStructures then
        self:ResetMarineStructuresElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.ShoulderPatches then
        self:ResetMarinePatchesElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.Armory then
        self:ResetMarineWeaponsElements()

        --Alien Views
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.AlienLifeforms then
        self:ResetAlienLifeformsElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.AlienStructures then
        self:ResetAlienStructuresElements()
    elseif self.previousTargetView == gCustomizeSceneData.kViewLabels.AlienTunnels then
        self:ResetAlienTunnelsElements()
    end


end

local changeViewInterv = 0.2 --delay interval of time + when view-change can occur (dampens button click spam)
function GUIMenuCustomizeScreen:SetDesiredActiveView( viewLabel )
    assert(viewLabel)

    local time = Shared.GetTime()
    local isTeamChanging = GetViewTeamIndex(self.activeTargetView) ~= GetViewTeamIndex(viewLabel)

    if self.activeTargetView == viewLabel and self.timeTargetViewChange + changeViewInterv < time then
        if GetIsViewForTeam(viewLabel, kTeam1Index) then
            viewLabel = gCustomizeSceneData.kViewLabels.DefaultMarineView
        else
            viewLabel = gCustomizeSceneData.kViewLabels.DefaultAlienView
        end
    end

    self.previousTargetView = self.activeTargetView
    self.activeTargetView = viewLabel

    --immediatley hide the team-view change buttons when activating "sub" team-views. It looks better/cleaner
    if not isTeamChanging then
        if GetIsViewForTeam(self.activeTargetView, kTeam1Index) then
            self.aliensViewButton:SetVisible(false)
        elseif GetIsViewForTeam(self.activeTargetView, kTeam2Index) then
            self.marinesViewButton:SetVisible(false)
        end
    end

    self.timeTargetViewChange = Shared.GetTime()

    --Force selected variants to always reset to "nearest owned" (in ownershiplist)
    self:ResetActiveVariantsToOwned()

    self:UpdateBuyButton(-1)
    self:HideViewWorldElements()

    GetCustomizeScene():TransitionToView(viewLabel, isTeamChanging)

end

function GUIMenuCustomizeScreen:RefreshOwnedItems()

    if self and self.customizeActive then
        self:UpdateBuyButton(-1) --force hide on update (e.g. after item purchase)
    end

    GetCustomizeScene():RefreshOwnedItems()
end

function GUIMenuCustomizeScreen:Uninitialize()
    self.renderTexture = nil
    GetCustomizeScene():Destroy()
    GUIMenuScreen.Uninitialize(self)
end

function GUIMenuCustomizeScreen:UpdateExclusionStencilSize()
    local size = GetStaticAbsoluteSize(self.background)
    local pos = GetStaticScreenPosition(self.background)
    Client.SetMainCameraExclusionRect( pos.x, pos.y, pos.x + size.x, pos.y + size.y )
end

function GUIMenuCustomizeScreen:Display(immediate)

    if not GUIMenuScreen.Display(self, immediate) then
        return -- already being displayed!
    end

    self.customizeActive = true

    self:UpdateExclusionStencilSize()

    local scene = GetCustomizeScene()
    scene:ClearTransitions( self.activeTargetView )
    scene:SetActive( self.customizeActive )

    self:OnViewLabelActivation( self.activeTargetView )

end

function GUIMenuCustomizeScreen:Hide()

    if not GUIMenuScreen.Hide(self) then
        return
    end

    self.customizeActive = false

    --Assume a transition _might_ have been active, force complete any, and update GUI as if camera move done
    --resolved GUI state being out of sync with camera-view when re-opening customize screen.
    self:ResetActiveVariantsToOwned()
    local scene = GetCustomizeScene()
    self:OnViewLabelActivation( self.activeTargetView )

    scene:SetActive(self.customizeActive)

end

function GUIMenuCustomizeScreen:OnUpdate(deltaTime, time)
    GetCustomizeScene():OnUpdate(time, deltaTime)
end

function GUIMenuCustomizeScreen:OnPurchaseStartComplete(success)
    --Log("GUIMenuCustomizeScreen:OnPurchaseStartComplete( %s )", success)
    if success then
        self:UpdateBuyButton(-1)
        if self.activePurchaseItemId ~= nil then    --FIXME This will not track "canceled" actions via Steam overlay pop-up...and there's no available callback, shit.
            --TODO Need item tracking of purchase-attempt, and on full-success of process (after atual transaction), set that item as _active_ saved in options for given variant
            self.activePurchaseItemId = nil
        end
    else
        --?? Disable buy button?
        --TODO Provide user with error pop-up, so they don't just spam the button...you know they might...
        ----Can do a "IsSteamAvailable" and/or IsSteamOverlayEnabled checks to tweak the message. Default to "order fail, try later" generic message (localized)
    end
end


Event.Hook("OnSteamOverlayActivated",
        function( isActive )
            GetCustomizeScreen():OnSteamOverlayActivationChange(isActive)
        end
)

