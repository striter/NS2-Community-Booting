Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/popup/GUIMenuPopupIconMessage.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GuiMenuCommunityQQButton" (baseClass)

local kIconTexture = PrecacheAsset("ui/menu/qq_qr.dds")

GuiMenuCommunityQQButton.kTextureRegular = PrecacheAsset("ui/menu/qq.dds")
GuiMenuCommunityQQButton.kTextureHover   = PrecacheAsset("ui/menu/qq_over.dds")

GuiMenuCommunityQQButton.kShadowScale = Vector(10, 5, 1)

function GuiMenuCommunityQQButton:OnPressed()
    CreateGUIObject("communityQQPopup", GUIMenuPopupIconMessage, nil,
    {
        title = Locale.ResolveString("COMMUNITY_QQ_BUTTON"),
        message = Locale.ResolveString("COMMUNITY_QQ_MESSAGE"),
        icon = kIconTexture,
        buttonConfig =
        {
            GUIPopupDialog.OkayButton,
        },
    })
end

function GuiMenuCommunityQQButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("COMMUNITY_QQ_BUTTON"))
end
