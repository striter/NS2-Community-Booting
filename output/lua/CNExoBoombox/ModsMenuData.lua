
if not kInGame then return end

-- Category order for display
local kCategoryOrder = {
	EBoomBoxTrack.CUSTOM,
	EBoomBoxTrack.OST,
	EBoomBoxTrack.JP,
	EBoomBoxTrack.EN,
	EBoomBoxTrack.CN,
	EBoomBoxTrack.Calm,
}

-- Shared widget references for cross-widget refresh
local g_BBUIRefs = {
	localHeader = nil,  -- GUIMenuText showing section title + now playing + 1/11
	catBtns = {},       -- { [EBoomBoxTrack] = GUIMenuButton }
	playBtn  = nil,     -- GUIMenuButton for play/stop toggle
}

-- Helper: insert a non-interactive section header
local function InsertHeader(contents, labelKey)
	table.insert(contents, {
		name = "bbHeader_" .. labelKey,
		class = GUIMenuText,
		params = { text = Locale.ResolveString(labelKey) },
	})
end

local function GetLocalSectionTitle()
	local base = Locale.ResolveString("BOOMBOX_SECTION_LOCAL")
	local tracks = (BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks())[g_BoomBoxLocalCategory]
	local total = tracks and #tracks or 0
	local catLabel = Locale.ResolveString(gBoomBoxDefine[g_BoomBoxLocalCategory].titleKey)
	local pos
	if g_BoomBoxLocalPlaying and g_BoomBoxLocalPlayingCategory == g_BoomBoxLocalCategory and g_BoomBoxLocalPlayingIndex then
		pos = g_BoomBoxLocalPlayingIndex .. "/" .. total
	else
		pos = "0/" .. total
	end
	if g_BoomBoxLocalPlaying and BoomBoxLocalGetNowPlayingName then
		local name = BoomBoxLocalGetNowPlayingName()
		if name then
			return base .. "  " .. name .. "  [" .. catLabel .. " " .. pos .. "]"
		end
	end
	return base
end

-- Called after every user action to sync all dynamic widgets
local function RefreshBBUI()
	if g_BBUIRefs.localHeader then
		g_BBUIRefs.localHeader:SetText(GetLocalSectionTitle())
	end
	if g_BBUIRefs.playBtn then
		if g_BoomBoxLocalPlaying then
			g_BBUIRefs.playBtn:SetLabel("■  " .. Locale.ResolveString("BOOMBOX_STOP"))
		else
			g_BBUIRefs.playBtn:SetLabel("▶  " .. Locale.ResolveString("BOOMBOX_LOCAL_PLAY"))
		end
	end
	for cat, btn in pairs(g_BBUIRefs.catBtns) do
		local catLabel = Locale.ResolveString(gBoomBoxDefine[cat].titleKey)
		if g_BoomBoxLocalCategory == cat then
			btn:SetLabel("[+] " .. catLabel)
		else
			btn:SetLabel(catLabel)
		end
	end
end

local function GetContent()

	local contents = {}

	-- ── Section: 音量校正 ──
	InsertHeader(contents, "BOOMBOX_SECTION_VOLUME")
	for _, v in ipairs(kCategoryOrder) do
		local def = gBoomBoxDefine[v]
		local key = Locale.ResolveString(def.titleKey)
		local title = string.format(Locale.ResolveString("BOOMBOX_VOLUME"), key)
		table.insert(contents, {
			name = def.configPath,
			class = OP_Number,
			params = {
				optionPath = def.configPath,
				optionType = "float",
				default = kBoomBoxDefaultValue,
				minValue = 0,
				maxValue = 1,
				useResetButton = true,
				decimalPlaces = 2,
				immediateUpdate = function()
					for _, se in pairs(GetEntities("SoundEffect")) do
						se:UpdateBoomBoxVolume()
					end
				end
			},
			properties = { { "Label", title } },
		})
	end

	-- ── Section: 本地播放器 (标题同时显示正在播放曲目) ──
	table.insert(contents, {
		name = "bbHeader_BOOMBOX_SECTION_LOCAL",
		class = GUIMenuText,
		params = { text = GetLocalSectionTitle() },
		postInit = {
			function(self)
				g_BBUIRefs.localHeader = self
			end
		}
	})

	-- Local volume
	table.insert(contents, {
		name = "boomboxLocalVolume",
		class = OP_Number,
		params = {
			optionPath = "BB_Local_Volume",
			optionType = "float",
			default = 0.5,
			minValue = 0.1,
			maxValue = 1,
			useResetButton = true,
			decimalPlaces = 2,
			immediateUpdate = function()
				g_BoomBoxLocalVolume = Client.GetOptionFloat("BB_Local_Volume", 0.5)
				if BoomBoxLocalApplyVolume then BoomBoxLocalApplyVolume() end
			end
		},
		properties = { { "Label", Locale.ResolveString("BOOMBOX_LOCAL_VOLUME") } },
	})

	-- Category selector row (horizontal)
	local catChildren = {}
	for _, cat in ipairs(kCategoryOrder) do
		local catDef = gBoomBoxDefine[cat]
		local catLabel = Locale.ResolveString(catDef.titleKey)
		table.insert(catChildren, {
			name = "boomboxCat_" .. catDef.key,
			class = GUIMenuButton,
			properties = { { "Label", catLabel } },
			postInit = {
				function(self)
					g_BBUIRefs.catBtns[cat] = self
					self:SetScale(0.7, 0.7)
					local catLbl = Locale.ResolveString(gBoomBoxDefine[cat].titleKey)
					if g_BoomBoxLocalCategory == cat then
						self:SetLabel("[+] " .. catLbl)
					end
					self:HookEvent(self, "OnPressed", function()
						g_BoomBoxLocalCategory = cat
						if BoomBoxLocalPlay then BoomBoxLocalPlay(cat, 1) end
						RefreshBBUI()
					end)
				end
			}
		})
	end
	table.insert(contents, {
		name = "boomboxCatRow",
		class = GUIListLayout,
		params = {
			orientation = "horizontal",
			spacing = 8,
			frontPadding = 0,
			backPadding = 0,
		},
		postInit = {
			function(self)
				local parent = self:GetParent()
				if parent then
					self:SetSize(parent:GetSize().x, self:GetSize().y)
					self:HookEvent(parent, "OnSizeChanged", function(_, size)
						self:SetSize(size.x, self:GetSize().y)
					end)
				end
			end
		},
		children = catChildren,
	})

	-- Playback controls row: ◀ Prev | ▶/■ Play/Stop | ▶▶ Next — horizontal
	local playLabel = g_BoomBoxLocalPlaying
		and ("■  " .. Locale.ResolveString("BOOMBOX_STOP"))
		or  ("▶  " .. Locale.ResolveString("BOOMBOX_LOCAL_PLAY"))
	table.insert(contents, {
		name = "boomboxControlRow",
		class = GUIListLayout,
		params = {
			orientation = "horizontal",
			spacing = 8,
			frontPadding = 0,
			backPadding = 0,
		},
		postInit = {
			function(self)
				local parent = self:GetParent()
				if parent then
					self:SetSize(parent:GetSize().x, self:GetSize().y)
					self:HookEvent(parent, "OnSizeChanged", function(_, size)
						self:SetSize(size.x, self:GetSize().y)
					end)
				end
			end
		},
		children = {
			{
				name = "boomboxPrev",
				class = GUIMenuButton,
				properties = { { "Label", "◀  " .. Locale.ResolveString("BOOMBOX_LOCAL_PREV") } },
				postInit = {
					function(self)
						self:SetScale(0.7, 0.7)
						self:HookEvent(self, "OnPressed", function()
							BoomBoxLocalPrev()
							RefreshBBUI()
						end)
					end
				}
			},
			{
				name = "boomboxPlayStop",
				class = GUIMenuButton,
				properties = { { "Label", playLabel } },
				postInit = {
					function(self)
						self:SetScale(0.7, 0.7)
						g_BBUIRefs.playBtn = self
						if g_BoomBoxLocalPlaying then
							self:SetLabel("■  " .. Locale.ResolveString("BOOMBOX_STOP"))
						end
						self:HookEvent(self, "OnPressed", function()
							if g_BoomBoxLocalPlaying then
								BoomBoxLocalStop()
							else
								BoomBoxLocalPlayCurrent()
							end
							RefreshBBUI()
						end)
					end
				}
			},
			{
				name = "boomboxNext",
				class = GUIMenuButton,
				properties = { { "Label", "▶▶  " .. Locale.ResolveString("BOOMBOX_LOCAL_NEXT") } },
				postInit = {
					function(self)
						self:SetScale(0.7, 0.7)
						self:HookEvent(self, "OnPressed", function()
							BoomBoxLocalNext()
							RefreshBBUI()
						end)
					end
				}
			},
			{
				name = "boomboxRandom",
				class = GUIMenuButton,
				properties = { { "Label", "?  " .. Locale.ResolveString("BOOMBOX_LOCAL_RANDOM") } },
				postInit = {
					function(self)
						self:SetScale(0.7, 0.7)
						self:HookEvent(self, "OnPressed", function()
							BoomBoxLocalRandom()
							RefreshBBUI()
						end)
					end
				}
			},
		},
	})

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
