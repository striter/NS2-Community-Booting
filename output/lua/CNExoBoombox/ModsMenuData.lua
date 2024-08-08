
if not kInGame then return end

local function GetContent()

	local contents = {}
	for k,v in pairs(gBoomBoxDefine) do
		local key = Locale.ResolveString(v.titleKey)
		local title = string.format(Locale.ResolveString("BOOMBOX_VOLUME"),key)--,Locale.ResolveString(key)))
		local path = v.configPath
		table.insert(contents,{
			name = path,
			class = OP_Number,
			params = {
				optionPath = path,
				optionType = "float",
				default = kBoomBoxDefaultValue,
				minValue = 0,
				maxValue = 1,
				useResetButton = true,
				decimalPlaces = 2,
				immediateUpdate = function()
					for k,v in pairs(GetEntities("SoundEffect")) do
						v:UpdateBoomBoxVolume()
					end
				end
			},
			properties = {
				{ "Label",title},
			},
		})
	end
	return contents
end

local menu =
{
	categoryName = "BoomBox",
	entryConfig =
	{
		name = "BoomBox",
		class = GUIMenuCategoryDisplayBoxEntry,
		params =
		{
			label = Locale.ResolveString("BOOMBOX_TITLE"),
		},
	},
	contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
	{
		layoutName = "boomboxOptions",
		contents = GetContent(),
	}
}
table.insert(gModsCategories, menu)