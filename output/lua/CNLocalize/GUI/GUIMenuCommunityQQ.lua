Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/popup/GUIMenuPopupDialog.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GuiMenuCommunityQQButton" (baseClass)

local kCardTexture = PrecacheAsset("ui/menu/qq_card.dds")
local kCardSize = Vector(1120, 420, 0)

GuiMenuCommunityQQButton.kTextureRegular = PrecacheAsset("ui/menu/qq.dds")
GuiMenuCommunityQQButton.kTextureHover   = PrecacheAsset("ui/menu/qq_over.dds")

GuiMenuCommunityQQButton.kShadowScale = Vector(10, 5, 1)

function GuiMenuCommunityQQButton:OnPressed()

    local popup = CreateGUIObject("communityQQPopup", GUIMenuPopupDialog, nil,
    {
        title = Locale.ResolveString("COMMUNITY_QQ_BUTTON"),
        buttonConfig =
        {
            GUIPopupDialog.OkayButton,
        },
    })

    local card = CreateGUIObject("communityQQCard", GUIObject, popup.contentsHolder)
    card:SetTexture(kCardTexture)
    card:SetSize(kCardSize)
    card:SetColor(1, 1, 1, 1)
    card:AlignCenter()

end

function GuiMenuCommunityQQButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("COMMUNITY_QQ_BUTTON"))
end
