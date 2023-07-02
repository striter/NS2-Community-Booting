Script.Load("lua/menu2/GUIMenuExitButton.lua")
Script.Load("lua/menu2/wrappers/Tooltip.lua")

---@class GUIMenuWikiButton : GUIMenuExitButton
local baseClass = GUIMenuExitButton
baseClass = GetTooltipWrappedClass(baseClass)
class "GuiMenuCommunityGroupButton" (baseClass)

local kWikiAddress = "http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=4UYFozF1TTgo8XZ88Ceea1LR-9MLLhLh&authKey=kPpaGuH7%2FnSW80N4zG9DqsffUzwBiF4l5FF4UuSzR%2FbA95SzTIRyBDocb%2FinXIqb&noverify=0&group_code=540422237"

GuiMenuCommunityGroupButton.kTextureRegular = PrecacheAsset("ui/newMenu/wikiButton.dds")
GuiMenuCommunityGroupButton.kTextureHover   = PrecacheAsset("ui/newMenu/wikiButtonOver.dds")

GuiMenuCommunityGroupButton.kShadowScale = Vector(10, 5, 1)

function GuiMenuCommunityGroupButton:OnPressed()
    Client.ShowWebpage(kWikiAddress)
end

function GuiMenuCommunityGroupButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)
    self:SetTooltip(Locale.ResolveString("COMMUNITY_GROUP_BUTTON"))
end
