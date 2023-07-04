
Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/GUI/wrappers/FXState.lua")

Script.Load("lua/menu2/GUIMenuGraphic.lua")
Script.Load("lua/menu2/MenuStyles.lua")

Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBTopButtonGroupBackground.lua")

---@class GUIMenuNewsFeedPullout : GUIButton
---@field public GetFXState function @From FXState wrapper
---@field public UpdateFXStateOverride function @From FXState wrapper
---@field public AddFXReceiver function @From FXState wrapper
---@field public RemoveFXReceiver function @From FXState wrapper
local baseClass = GUIButton
baseClass = GetFXStateWrappedClass(baseClass)
class "GUIMenuNewsFeedPullout" (baseClass)

GUIMenuNewsFeedPullout:AddClassProperty("UpsideDown", false)

local kArrowTexture = PrecacheAsset("ui/newMenu/pulloutArrow.dds")

local function UpdateBackgroundPoints(self)

    local isUpsideDown = self:GetUpsideDown()
    local size = self:GetSize()
    local points

    if not isUpsideDown then
        points =
        {
            Vector(0, 0, 0),
            Vector(size.y, size.y, 0),
            Vector(size.x - size.y, size.y, 0),
            Vector(size.x, 0, 0),
        }
    else
        points =
        {
            Vector(size.y, 0, 0),
            Vector(0, size.y, 0),
            Vector(size.x, size.y, 0),
            Vector(size.x - size.y, 0, 0),
        }
    end

    self.back:SetPoints(points)

end

function GUIMenuNewsFeedPullout:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    baseClass.Initialize(self, params, errorDepth)
    
    self.arrowHolder = CreateGUIObject("arrowHolder", GetFXStateWrappedClass(GUIObject), self)
    self.arrowHolder:SetCropMax(1, 1)
    self.arrowHolder:AlignCenter()
    
    self.arrowUp = CreateGUIObject("arrowUp", GetFXStateWrappedClass(GUIObject), self.arrowHolder)
    self.arrowUpGraphic = CreateGUIObject("arrowUp", GUIMenuGraphic, self.arrowUp)
    self.arrowUpGraphic:SetTexture(kArrowTexture)
    self.arrowUpGraphic:SetSizeFromTexture()
    self.arrowUpGraphic:SetAngle(math.pi * 0.5)
    self.arrowUpGraphic:SetRotationOffset(0.5, 0.5)
    self.arrowUpGraphic:AlignCenter()
    -- Transpose size since it's rotated by 90 degrees.
    self.arrowUp:SetSize(self.arrowUpGraphic:GetSize().y, self.arrowUpGraphic:GetSize().x)
    
    self.arrowDown = CreateGUIObject("arrowDown", GetFXStateWrappedClass(GUIObject), self.arrowHolder)
    self.arrowDownGraphic = CreateGUIObject("arrowDown", GUIMenuGraphic, self.arrowDown)
    self.arrowDownGraphic:SetTexture(kArrowTexture)
    self.arrowDownGraphic:SetSizeFromTexture()
    self.arrowDownGraphic:SetAngle(math.pi * -0.5)
    self.arrowDownGraphic:SetRotationOffset(0.5, 0.5)
    self.arrowDownGraphic:AlignCenter()
    -- Transpose size since it's rotated by 90 degrees.
    self.arrowDown:SetSize(self.arrowDownGraphic:GetSize().y, self.arrowDownGraphic:GetSize().x)
    self.arrowDown:SetAnchor(0, -1)
    
    self.arrowHolder:SetSize(self.arrowUp:GetSize())

    self.back = CreateGUIObject("back", GMSBTopButtonGroupBackground, self)
    self.back:SetLayer(-1)
    self.back:SetOpacity(0.9)
    self:HookEvent(self, "OnSizeChanged", UpdateBackgroundPoints)
    self:HookEvent(self, "OnUpsideDownChanged", UpdateBackgroundPoints)
    UpdateBackgroundPoints(self)
    
    self.label = CreateGUIObject("newsLabelLeft", GUIMenuText, self,
    {
        text = gCommunityGuideTable.mainPulloutTitle,
        font = MenuStyle.kOptionFont,
        anchor = Vector(0.25, 0.5, 0),
        hotSpot = Vector(0.5, 0.5, 0),
    })

    self.label2 = CreateGUIObject("newsLabelRight", GUIMenuText, self,
    {
        text = gCommunityGuideTable.subPulloutTitle,
        font = MenuStyle.kOptionFont,
        anchor = Vector(0.75, 0.5, 0),
        hotSpot = Vector(0.5, 0.5, 0),
    })

end

local function AnimateArrowAnchors(self, anchor)
    self.arrowUp:AnimateProperty("Anchor", Vector(0, anchor, 0), MenuAnimations.FlyIn)
    self.arrowDown:AnimateProperty("Anchor", Vector(0, anchor-1, 0), MenuAnimations.FlyIn)
end

function GUIMenuNewsFeedPullout:PointUp()
    AnimateArrowAnchors(self, 0)
end

function GUIMenuNewsFeedPullout:PointDown()
    AnimateArrowAnchors(self, 1)
end
