ModLoader.SetupFileHook("lua/InputHandler.lua", "lua/LocalTalkExtended/InputHandler.lua", "post")
ModLoader.SetupFileHook("lua/NetworkMessages.lua", "lua/LocalTalkExtended/NetworkMessages.lua", "post")
ModLoader.SetupFileHook("lua/BindingsDialog.lua", "lua/LocalTalkExtended/BindingsDialog.lua", "post")
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/LocalTalkExtended/ModsMenuData.lua", "post")

ModLoader.SetupFileHook("lua/GUIVoiceChat.lua", "lua/LocalTalkExtended/GUIVoiceChat.lua", "replace")
