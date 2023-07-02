Script.Load("lua/CNBooting/GUI/GUIMenuCommunityGuide.lua")
--Script.Load("lua/CNBooting/GUI/GUIMenuCommunityGroup.lua")

function GUIMainMenuInGame:CreateLinksButtons()

    CreateGUIObject("guideButton", GuiMenuCommunityGuideButton, self.linkButtonsHolder)
    --CreateGUIObject("groupButton", GuiMenuCommunityGroupButton, self.linkButtonsHolder)

end