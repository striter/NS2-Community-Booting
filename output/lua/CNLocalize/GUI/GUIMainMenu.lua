Script.Load("lua/CNLocalize/GUI/GUIMenuCommunityForm.lua")
Script.Load("lua/CNLocalize/GUI/GUIMenuCommunityQQ.lua")

function GUIMainMenu:CreateLinksButtons()

    CreateGUIObject("formButton", GuiMenuCommunityFormButton, self.linkButtonsHolder)
    CreateGUIObject("qqButton", GuiMenuCommunityQQButton, self.linkButtonsHolder)

end