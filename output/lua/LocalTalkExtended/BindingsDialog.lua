local defaults = debug.getupvaluex(GetDefaultInputValue, "defaults")
table.insert(defaults, {"LocalVoiceChat", "None"})
table.insert(defaults, {"LocalVoiceChatTeam", "None"})

local bindings = BindingsUI_GetBindingsData()
for i, v in ipairs {
	"LocalVoiceChat",     "input", "Proximity Communication (can be heard by enemy)",     "None",
	"LocalVoiceChatTeam", "input", "Proximity Communication (can be heard by team only)", "None",
} do
	table.insert(bindings, i, v)
end
