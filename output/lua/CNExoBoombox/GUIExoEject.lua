--======= Copyright (c) 2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIExoEject.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


local kButtonPos
local kTextOffset

local kFontName = Fonts.kAgencyFB_Small

class 'GUIExoEject' (GUIScript)

local function UpdateItemsGUIScale(self)
    kTextOffset = GUIScale(Vector(0, 20, 0))
end

function GUIExoEject:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)

    self:Uninitialize()
    self:Initialize()
end


local kBackgroundName=PrecacheAsset("ui/boomboxBG.dds")

function GUIExoEject:Initialize()

    UpdateItemsGUIScale(self)
    
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetSize(Vector(300,100, 0))
    self.background:SetTexture(kBackgroundName)
    self.background:SetBlendTechnique( GUIItem.Add )
    self.background:SetAnchor( GUIItem.Left, GUIItem.Bottom)
    self.background:SetPosition(Vector(105,-157,0))

    self.title = GetGUIManager():CreateTextItem()
    self.title:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.title:SetPosition(Vector(255,-132,0))
    self.title:SetTextAlignmentX(GUIItem.Align_Center)
    self.title:SetTextAlignmentY(GUIItem.Align_Max)
    self.title:SetText(Locale.ResolveString("BOOMBOX_TITLE"))
    self.title:SetScale(GetScaledVector())
    self.title:SetFontName(kFontName)
    GUIMakeFontScale(self.title)
    self.title:SetColor(kMarineFontColor)

    self.button1 = GUICreateButtonIcon("Weapon1")
    self.button1:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button1:SetPosition(Vector(110, -120, 0))
    self.text1 = GetGUIManager():CreateTextItem()
    self.text1:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text1:SetTextAlignmentX(GUIItem.Align_Center)
    self.text1:SetTextAlignmentY(GUIItem.Align_Center)
    self.text1:SetText(Locale.ResolveString(gBoomBoxDefine[EBoomBoxTrack.CUSTOM].titleKey))
    self.text1:SetPosition(kTextOffset)
    self.text1:SetScale(GetScaledVector())
    self.text1:SetFontName(kFontName)
    GUIMakeFontScale(self.text1)
    self.text1:SetColor(kMarineFontColor)
    self.button1:AddChild(self.text1)


    self.button2 = GUICreateButtonIcon("Weapon2")
    self.button2:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button2:SetPosition(Vector(162, -120, 0))
    self.text2 = GetGUIManager():CreateTextItem()
    self.text2:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text2:SetTextAlignmentX(GUIItem.Align_Center)
    self.text2:SetTextAlignmentY(GUIItem.Align_Center)
    self.text2:SetText(Locale.ResolveString(gBoomBoxDefine[EBoomBoxTrack.OST].titleKey))
    self.text2:SetPosition(kTextOffset)
    self.text2:SetScale(GetScaledVector())
    self.text2:SetFontName(kFontName)
    GUIMakeFontScale(self.text2)
    self.text2:SetColor(kMarineFontColor)
    self.button2:AddChild(self.text2)


    self.button3 = GUICreateButtonIcon("Weapon3")
    self.button3:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button3:SetPosition(Vector(214, -120, 0))
    self.text3 = GetGUIManager():CreateTextItem()
    self.text3:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text3:SetTextAlignmentX(GUIItem.Align_Center)
    self.text3:SetTextAlignmentY(GUIItem.Align_Center)
    self.text3:SetText(Locale.ResolveString(gBoomBoxDefine[EBoomBoxTrack.JP].titleKey))
    self.text3:SetPosition(kTextOffset)
    self.text3:SetScale(GetScaledVector())
    self.text3:SetFontName(kFontName)
    GUIMakeFontScale(self.text3)
    self.text3:SetColor(kMarineFontColor)
    self.button3:AddChild(self.text3)

    self.button4 = GUICreateButtonIcon("Weapon4")
    self.button4:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button4:SetPosition(Vector(266, -120, 0))
    self.text4 = GetGUIManager():CreateTextItem()
    self.text4:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text4:SetTextAlignmentX(GUIItem.Align_Center)
    self.text4:SetTextAlignmentY(GUIItem.Align_Center)
    self.text4:SetText(Locale.ResolveString(gBoomBoxDefine[EBoomBoxTrack.EN].titleKey))
    self.text4:SetPosition(kTextOffset)
    self.text4:SetScale(GetScaledVector())
    self.text4:SetFontName(kFontName)
    GUIMakeFontScale(self.text4)
    self.text4:SetColor(kMarineFontColor)
    self.button4:AddChild(self.text4)

    self.button5 = GUICreateButtonIcon("Weapon5")
    self.button5:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button5:SetPosition(Vector(318, -120, 0))

    self.text5 = GetGUIManager():CreateTextItem()
    self.text5:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text5:SetTextAlignmentX(GUIItem.Align_Center)
    self.text5:SetTextAlignmentY(GUIItem.Align_Center)
    self.text5:SetText(Locale.ResolveString(gBoomBoxDefine[EBoomBoxTrack.CN].titleKey))
    self.text5:SetPosition(kTextOffset)
    self.text5:SetScale(GetScaledVector())
    self.text5:SetFontName(kFontName)
    GUIMakeFontScale(self.text5)
    self.text5:SetColor(kMarineFontColor)
    self.button5:AddChild(self.text5)
    
    self.button6 = GUICreateButtonIcon("Reload")
    self.button6:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button6:SetPosition(Vector(370, -120, 0))

    self.text6 = GetGUIManager():CreateTextItem()
    self.text6:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text6:SetTextAlignmentX(GUIItem.Align_Center)
    self.text6:SetTextAlignmentY(GUIItem.Align_Center)
    self.text6:SetText(Locale.ResolveString("BOOMBOX_STOP"))
    self.text6:SetPosition(kTextOffset)
    self.text6:SetScale(GetScaledVector())
    self.text6:SetFontName(kFontName)
    GUIMakeFontScale(self.text6)
    self.text6:SetColor(kMarineFontColor)
    self.button6:AddChild(self.text6)
    
    self.button = GUICreateButtonIcon("Drop")
    self.button:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.button:SetPosition( Vector(430, -120, 0))

    self.text = GetGUIManager():CreateTextItem()
    self.text:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.text:SetTextAlignmentX(GUIItem.Align_Center)
    self.text:SetTextAlignmentY(GUIItem.Align_Center)
    self.text:SetText(Locale.ResolveString("EJECT_FROM_EXO"))
    self.text:SetPosition(kTextOffset)
    self.text:SetScale(GetScaledVector())
    self.text:SetFontName(kFontName)
    GUIMakeFontScale(self.text)
    self.text:SetColor(kMarineFontColor)

    self.button:AddChild(self.text)
    self.button:SetIsVisible(false)
end


function GUIExoEject:Uninitialize()

    if self.title then
        GUI.DestroyItem(self.title)
    end

    if self.background then
        GUI.DestroyItem(self.background)
    end

    if self.button then
        GUI.DestroyItem(self.button)
    end

    if self.button1 then
        GUI.DestroyItem(self.button1)
    end
    if self.button2 then
        GUI.DestroyItem(self.button2)
    end

    if self.button3 then
        GUI.DestroyItem(self.button3)
    end

    if self.button4 then
        GUI.DestroyItem(self.button4)
    end

    if self.button5 then
        GUI.DestroyItem(self.button5)
    end

    if self.button6 then
        GUI.DestroyItem(self.button6)
    end
end

function GUIExoEject:Update(deltaTime)

    PROFILE("GUIExoEject:Update")

    local player = Client.GetLocalPlayer()
    if player == nil or not Client.GetIsControllingPlayer() then
        return
    end
    
    self.title:SetText(player:GetBoomBoxTitle())
    self.text6:SetText(player:GetBoomBoxAction())
    self.button:SetIsVisible(player:GetCanEject())
end
