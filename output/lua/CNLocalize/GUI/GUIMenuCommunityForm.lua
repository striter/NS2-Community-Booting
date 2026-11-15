Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GuiMenuCommunityFormButton" (baseClass)

local kFormAddress = "https://docs.qq.com/form/page/DUFZGQ2hUV3RsQnlD"

GuiMenuCommunityFormButton.kTextureRegular = PrecacheAsset("ui/menu/form.dds")
GuiMenuCommunityFormButton.kTextureHover   = PrecacheAsset("ui/menu/form_over.dds")

GuiMenuCommunityFormButton.kShadowScale = Vector(10, 5, 1)

function GuiMenuCommunityFormButton:OnPressed()
    Client.ShowWebpage(kFormAddress)
end

function GuiMenuCommunityFormButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("COMMUNITY_FORM_BUTTON"))
end
