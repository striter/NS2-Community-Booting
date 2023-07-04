Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GuiMenuCommunityGuideButton" (baseClass)

local kWikiAddress = "https://docs.qq.com/doc/DUFlBR0ZJeFRiRnRi"

GuiMenuCommunityGuideButton.kTextureRegular = PrecacheAsset("ui/menu/guide.dds")
GuiMenuCommunityGuideButton.kTextureHover   = PrecacheAsset("ui/menu/guide_over.dds")

GuiMenuCommunityGuideButton.kShadowScale = Vector(10, 5, 1)

function GuiMenuCommunityGuideButton:OnPressed()
    Client.ShowWebpage(kWikiAddress)
end

function GuiMenuCommunityGuideButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("COMMUNITY_GUI_BUTTON"))
end
