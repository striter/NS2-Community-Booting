
if not kInGame then return end

local menu =
{
	categoryName = "CNVoiceOver",
	entryConfig =
	{
		name = "CNVoiceOver",
		class = GUIMenuCategoryDisplayBoxEntry,
		params = { label = Locale.ResolveString("CNVO_TITLE"), },
	},
	contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
	{
		layoutName = "cnvoConfig",
		contents = {
			{
				name = kCNVoiceOverConfig.VolumePath,
				class = OP_Number,
				params = {
					optionPath = kCNVoiceOverConfig.VolumePath,
					optionType = "float",
					default = kCNVoiceOverConfig.VolumeDefault,
					minValue = 0,
					maxValue = 1,
					useResetButton = true,
					decimalPlaces = 2,
					immediateUpdate = function()
						for k,v in pairs(GetEntities("SoundEffect")) do
							v:UpdateVoiceOverVolume()
						end
					end
				},
				properties = { { "Label",Locale.ResolveString("CNVO_VOLUME")}, },
			},
			{
				name = "cnvoOpenWebConfig",
				class = GUIMenuButton,
				properties = { { "Label", Locale.ResolveString("CNVO_WEB") } },
				postInit = {
					function( self )
						self:HookEvent( self, "OnPressed", function()
							if Shine then
								Shine:OpenWebpage("https://docs.qq.com/doc/DUHZFaHNQdExQSlZs",Locale.ResolveString("CNVO_TITLE"))
							end
						end )
					end
				}
			},
		},
	}
}
table.insert(gModsCategories, menu)