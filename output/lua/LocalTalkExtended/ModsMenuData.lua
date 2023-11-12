-- define OP_TT_ColorPicker just incase ns2plus hasn't been loaded
Script.Load("lua/menu2/widgets/GUIMenuColorPickerWidget.lua") -- doesn't get loaded by vanilla menu
OP_TT_ColorPicker = OP_TT_ColorPicker or GetMultiWrappedClass(GUIMenuColorPickerWidget, {"Option", "Tooltip"})

local menu =
{
	categoryName = "localTalk",
	entryConfig =
	{
		name = "localTalkModEntry",
		class = GUIMenuCategoryDisplayBoxEntry,
		params =
		{
			label = "区域语音设置",
		},
	},
	contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
	{
		layoutName = "localTalkOptions",
		contents =
		{
			{
				name = "pushToTalkLocal",
				class = OP_Keybind,
				params = {
					optionPath = "input/LocalVoiceChat",
					optionType = "string",
					default = "None",

					bindGroup = "general",
				},
				properties = {
					{ "Label", "按键说话(区域内所有玩家)" },
				},
			},
			{
				name = "pushToTalkLocalTeam",
				class = OP_Keybind,
				params =
				{
					optionPath = "input/LocalVoiceChatTeam",
					optionType = "string",
					default = "None",

					bindGroup = "general",
				},
				properties =
				{
					{"Label", "按键说话(区域内队友)"},
				},
			},
			{
				name = "LocalTalkExtended_color",
				class = OP_TT_ColorPicker,
				params =
				{
					optionPath = "LocalTalkExtended_color",
					optionType = "color",
					default = 0x80FF80,

					tooltip = "使用区域语音(所有人)的玩家颜色.",
				},
				properties =
				{
					{"Label", string.upper("区域语音(所有人)")},
				},
				postInit = function(self)
					self:HookEvent(self, "OnValueChanged", function(this)
						kLocalVoiceFontColor = this:GetValue()
					end)
				end
			},
			{
				name = "LocalTalkExtended_color_team",
				class = OP_TT_ColorPicker,
				params =
				{
					optionPath = "LocalTalkExtended_color_team",
					optionType = "color",
					default = 0xC028C0,

					tooltip =  "使用区域语音(队伍)的玩家颜色",
				},
				properties =
				{
					{"Label", string.upper("区域语音(队伍)")},
				},
				postInit = function(self)
					self:HookEvent(self, "OnValueChanged", function(this)
						kLocalVoiceTeamOnlyFontColor = this:GetValue()
					end)
				end
			},
		},
	}
}
table.insert(gModsCategories, menu)