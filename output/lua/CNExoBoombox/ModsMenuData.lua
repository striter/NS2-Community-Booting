
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

-- Track list sizing
local kTrackRowSpacing = 6
local kVisibleTrackRows = 8
local kTrackButtonScale = 1
local kTrackRowTextPadding = 13
local kTrackRowVerticalPadding = 5
local kTrackScrollBarWidth = 14
local kTrackScrollBarPadding = 3
local kTrackPaneRightGutter = 40
local kTrackNameMaxChars = 44
local kFallbackRowHeight = 78
local kTrackFontFamily = "BBTrack"
local kTrackFontActualSize = 33
local kTrackFont = { family = kTrackFontFamily, size = 58 }
local kCategoryFont = { family = kTrackFontFamily, size = 84 }
local kCategoryInnerPadding = Vector(28, 18, 0)
local kCategoryBoxPadding = Vector(8, 6, 0)
local kTitleFont = { family = kTrackFontFamily, size = 72 }
local kStopIconFont = { family = kTrackFontFamily, size = 160 }
local kSkipIconFont = { family = kTrackFontFamily, size = 120 }
local kStopIconScale = 0.32
local kStopIconWidth = 64
local kStopIconSpacing = 12
local kLocalVolumeWidth = 392
local kLocalVolumeHeight = 64
local kLocalVolumeIconWidth = 56
local kLocalVolumeSliderScale = 0.8
local kLocalVolumeGroupGap = (kStopIconWidth + kStopIconSpacing) * 2
local kTrackHoverColor = Color(1, 1, 1, 1)
local g_BBTrackFontReady = nil
local g_BBTrackFontFile = nil
local g_BBTrackTextWidth = nil
local g_BBTrackRowWidth = nil

-- Shared widget references for cross-widget refresh
local g_BBUIRefs = {
	localHeader = nil,
	stopBtn = nil,
	catBtns = {},
}

local g_BBTrackPane = nil
local g_BBPagePane = nil
local g_BBTrackList = nil
local g_BBTrackBtns = {}
local g_BBShownCategory = nil
local g_BBMarkedIndex = nil
local RenderTrackList
local RefreshBBUI

local function GetTracks(category)
	local all = BoomBoxMixin and BoomBoxMixin.kTracks or GetBoomBoxTracks()
	return all[category]
end

-- Single-member family whose font sheet covers latin, CJK and kana
local function EnsureTrackFont()
	if g_BBTrackFontReady then
		return
	end
	RegisterFontFamily(kTrackFontFamily, {
		{ font = PrecacheAsset("fontsOverride/AgencyFB_medium.fnt"), size = kTrackFontActualSize },
	})
	g_BBTrackFontReady = true
end

local function ApplyCompactSize(button, size)
	local inner = size + kCategoryInnerPadding * 2
	button.innerBox:SetSize(inner)
	button.innerBoxGloss:SetSize(Vector(inner.x * 2, inner.y * 0.5, 1))
	local outer = inner + kCategoryBoxPadding * 2
	button.outerBox:SetSize(outer)
	button.outerBoxGloss:SetSize(Vector(outer.x * 2, outer.y * 0.5, 1))
	button:SetSize(outer)
end

-- Shrink the built-in button padding so large text does not sit in a huge frame
local function CompactButton(button)
	button:HookEvent(button.text, "OnSizeChanged", function(_, size)
		ApplyCompactSize(button, size)
	end)
	ApplyCompactSize(button, button.text:GetSize())
end

-- Icon-only control button, no background boxes
local function MakeIconButton(name, label, font, onPressed, onInit)
	return {
		name = name,
		class = GUIMenuButton,
		properties = { { "Label", label } },
		postInit = {
			function(self)
				self.outerBox:SetVisible(false)
				self.innerBox:SetVisible(false)
				self.glowyText:SetVisible(false)
				self:SetScale(kStopIconScale, kStopIconScale)
				self.text:SetFont(font)
				if onInit then
					onInit(self)
				end
				self:HookEvent(self, "OnFXStateChanged", function(btn, state)
					btn.text:ClearPropertyAnimations("Color")
					btn.text:SetColor(state == "hover" and kTrackHoverColor or MenuStyle.kOptionHeadingColor)
				end)
				self:HookEvent(self, "OnPressed", onPressed)
			end
		}
	}
end

local function TruncateUtf8(text, maxChars)
	local count = 0
	local i = 1
	while i <= #text do
		count = count + 1
		if count > maxChars then
			return string.sub(text, 1, i - 1) .. ".."
		end
		local byte = string.byte(text, i)
		if byte >= 240 then
			i = i + 4
		elseif byte >= 224 then
			i = i + 3
		elseif byte >= 192 then
			i = i + 2
		else
			i = i + 1
		end
	end
	return text
end

local function GetTrackLabel(index, track, marked)
	return string.format("%s%2d. %s", marked and "> " or "  ", index, TruncateUtf8(track.name, kTrackNameMaxChars))
end

-- Walk up from a widget until the scroll pane of the page that holds it
local function GetPageScrollPane(widget)
	local current = widget
	for _ = 1, 8 do
		local parent = current:GetParent()
		if not parent then
			return nil
		end
		if parent.GetVerticalBar and parent:GetVerticalBar() then
			return parent
		end
		current = parent
	end
	return nil
end

local function GetTrackRowHeight()
	local button = g_BBTrackBtns[1]
	if button then
		local height = button:GetSize().y * button:GetScale().y
		if height > 0 then
			return height
		end
	end
	return kFallbackRowHeight
end

local function GetTrackViewRows()
	return math.min(kVisibleTrackRows, math.max(1, #g_BBTrackBtns))
end

local function GetTrackViewHeight()
	local rows = GetTrackViewRows()
	local rowHeight = GetTrackRowHeight()
	local button = g_BBTrackBtns[rows]
	if button then
		local height = button:GetPosition().y + rowHeight
		if height > 0 then
			return height
		end
	end
	return rowHeight * rows + kTrackRowSpacing * math.max(0, rows - 1)
end

-- Rows span the page width so the list reads like a player; the bar hugs the right edge
local function GetRowWidth()
	local pageWidth = g_BBPagePane and g_BBPagePane:GetSize().x or 0
	if pageWidth > kTrackPaneRightGutter + kTrackScrollBarWidth + kTrackRowTextPadding * 2 then
		return pageWidth - kTrackPaneRightGutter - kTrackScrollBarWidth
	end
	if g_BBTrackTextWidth then
		return g_BBTrackTextWidth + kTrackRowTextPadding * 2
	end
	return 0
end

local function ApplyRowWidth()
	local width = GetRowWidth()
	if width <= 0 or width == g_BBTrackRowWidth then
		return
	end
	g_BBTrackRowWidth = width
	for index = 1, #g_BBTrackBtns do
		local button = g_BBTrackBtns[index]
		button:SetSize(width, button.text:GetSize().y + kTrackRowVerticalPadding * 2)
	end
end

-- Keep the pane scroll range in sync with the list, independent of layout events
local function SyncTrackPane()
	if not (g_BBTrackPane and g_BBTrackList) then
		return
	end
	ApplyRowWidth()
	local rowWidth = g_BBTrackRowWidth
	if not rowWidth or rowWidth <= 0 then
		return
	end
	local paneWidth = rowWidth + kTrackScrollBarWidth
	g_BBTrackPane:SetSize(paneWidth, g_BBTrackPane:GetSize().y)
	g_BBTrackPane:SetPaneSize(paneWidth, g_BBTrackList:GetSize().y)
end

local function UpdateTrackPaneHeight()
	if not g_BBTrackPane then
		return
	end
	g_BBTrackPane:SetSize(g_BBTrackPane:GetSize().x, GetTrackViewHeight())
	SyncTrackPane()
end

local function GetRowTextColor(marked, hovered)
	if hovered then
		return kTrackHoverColor
	end
	return marked and MenuStyle.kPopupTitleColor or MenuStyle.kOptionHeadingColor
end

local function UpdatePlayingMarker()
	local tracks = GetTracks(g_BBShownCategory)
	local index = nil
	if g_BoomBoxLocalPlaying and g_BoomBoxLocalPlayingCategory == g_BBShownCategory then
		index = g_BoomBoxLocalPlayingIndex
	end
	if index and not (tracks and tracks[index]) then
		index = nil
	end
	if index == g_BBMarkedIndex then
		return
	end
	local oldButton = g_BBMarkedIndex and g_BBTrackBtns[g_BBMarkedIndex]
	if oldButton and tracks and tracks[g_BBMarkedIndex] then
		oldButton:SetLabel(GetTrackLabel(g_BBMarkedIndex, tracks[g_BBMarkedIndex], false))
		oldButton.text:ClearPropertyAnimations("Color")
		oldButton.text:SetColor(GetRowTextColor(false, oldButton:GetMouseOver()))
	end
	g_BBMarkedIndex = index
	local button = index and g_BBTrackBtns[index]
	if button then
		button:SetLabel(GetTrackLabel(index, tracks[index], true))
		button.text:ClearPropertyAnimations("Color")
		button.text:SetColor(GetRowTextColor(true, button:GetMouseOver()))
	end
end

local function ScrollToTrack(index)
	local button = g_BBTrackBtns[index]
	if not (g_BBTrackPane and button) then
		return
	end
	local viewHeight = g_BBTrackPane:GetSize().y
	local maxScroll = math.max(0, g_BBTrackPane:GetPaneSize().y - viewHeight)
	local target = Clamp(button:GetPosition().y - (viewHeight - GetTrackRowHeight()) * 0.5, 0, maxScroll)
	g_BBTrackPane:SetPanePosition(0, -target)
	local bar = g_BBTrackPane:GetVerticalBar()
	if bar then
		bar:SetValue(target, true)
	end
end

local function LockTrackText(guiText)
	guiText:SetFont(kTrackFont)
	guiText:HookEvent(guiText, "OnInternalFontChanged", function(textObj, newFontFile)
		if not g_BBTrackFontFile then
			g_BBTrackFontFile = newFontFile
		end
		textObj.text:SetFontName(g_BBTrackFontFile)
	end)
	local textObj = guiText:GetTextObject()
	if not g_BBTrackFontFile then
		g_BBTrackFontFile = textObj:GetFontName()
	end
	if g_BBTrackFontFile then
		textObj:SetFontName(g_BBTrackFontFile)
	end
end

local function RebuildTrackList()
	EnsureTrackFont()
	local category = g_BoomBoxLocalCategory
	local tracks = GetTracks(category) or {}
	g_BBTrackList:SetAutoArrange(false)
	for i = #g_BBTrackBtns, 1, -1 do
		g_BBTrackBtns[i]:Destroy()
		g_BBTrackBtns[i] = nil
	end
	g_BBShownCategory = category
	g_BBMarkedIndex = nil
	for index = 1, #tracks do
		local button = CreateGUIObject("bbTrack" .. index, GUIMenuButton, g_BBTrackList, { label = GetTrackLabel(index, tracks[index], false) })
		button.outerBox:SetVisible(false)
		button.innerBox:SetVisible(false)
		button:SetScale(kTrackButtonScale, kTrackButtonScale)
		LockTrackText(button.text)
		button.glowyText:SetVisible(false)
		button.text:AlignLeft()
		button.text:SetPosition(kTrackRowTextPadding, 0)
		button:HookEvent(button.text, "OnSizeChanged", function(self, size)
			self:SetSize(g_BBTrackRowWidth or (size.x + kTrackRowTextPadding * 2), size.y + kTrackRowVerticalPadding * 2)
		end)
		local textSize = button.text:GetSize()
		if textSize.y > 0 then
			button:SetSize(g_BBTrackRowWidth or (textSize.x + kTrackRowTextPadding * 2), textSize.y + kTrackRowVerticalPadding * 2)
		end
		button:HookEvent(button, "OnFXStateChanged", function(self, state)
			self.text:ClearPropertyAnimations("Color")
			self.text:SetColor(state == "disabled" and MenuStyle.kDarkGrey or GetRowTextColor(g_BBMarkedIndex == index, state == "hover"))
		end)
		button:HookEvent(button, "OnPressed", function()
			if g_BoomBoxLocalPlaying and g_BoomBoxLocalPlayingCategory == category and g_BoomBoxLocalPlayingIndex == index then
				BoomBoxLocalStop()
				RefreshBBUI()
			else
				BoomBoxLocalPlay(category, index)
				RefreshBBUI(true)
			end
		end)
		g_BBTrackBtns[index] = button
	end
	local textWidth = g_BBTrackTextWidth or 0
	for index = 1, #tracks do
		local button = g_BBTrackBtns[index]
		textWidth = math.max(textWidth,
			button.text:CalculateTextSize(GetTrackLabel(index, tracks[index], false)).x,
			button.text:CalculateTextSize(GetTrackLabel(index, tracks[index], true)).x)
	end
	g_BBTrackTextWidth = textWidth
	g_BBTrackRowWidth = 0
	ApplyRowWidth()
	if not g_BBTrackRowWidth or g_BBTrackRowWidth <= 0 then
		g_BBTrackRowWidth = textWidth + kTrackRowTextPadding * 2
	end
	for index = 1, #tracks do
		local button = g_BBTrackBtns[index]
		button:SetSize(g_BBTrackRowWidth, button.text:GetSize().y + kTrackRowVerticalPadding * 2)
	end
	g_BBTrackList:ArrangeNow()
	g_BBTrackList:SetAutoArrange(true)
	g_BBTrackPane:SetPanePosition(0, 0)
	UpdatePlayingMarker()
	UpdateTrackPaneHeight()
	local bar = g_BBTrackPane:GetVerticalBar()
	if bar then
		bar:SetValue(0, true)
	end
end

function RenderTrackList()
	if not (g_BBTrackList and g_BBTrackPane) then
		return
	end
	if g_BBShownCategory ~= g_BoomBoxLocalCategory then
		RebuildTrackList()
	else
		UpdatePlayingMarker()
	end
end

-- Helper: insert a non-interactive section header
local function InsertHeader(contents, labelKey)
	table.insert(contents, {
		name = "bbHeader_" .. labelKey,
		class = GUIMenuText,
		params = { text = Locale.ResolveString(labelKey) },
		postInit = {
			function(self)
				self:SetFont(kTitleFont)
			end
		},
	})
end

local function GetLocalSectionTitle()
	return Locale.ResolveString("BOOMBOX_SECTION_LOCAL")
end

-- Scroll the track list to the track that is currently playing
local function FollowPlayingTrack()
	if not (g_BoomBoxLocalPlaying and g_BoomBoxLocalPlayingCategory == g_BoomBoxLocalCategory and g_BoomBoxLocalPlayingIndex) then
		return
	end
	ScrollToTrack(g_BoomBoxLocalPlayingIndex)
end

-- Called after every user action to sync all dynamic widgets
function RefreshBBUI(followPlaying)
	RenderTrackList()
	if followPlaying then
		FollowPlayingTrack()
	end
	if g_BBUIRefs.localHeader then
		g_BBUIRefs.localHeader:SetText(GetLocalSectionTitle())
	end
	if g_BBUIRefs.stopBtn then
		g_BBUIRefs.stopBtn:SetLabel(g_BoomBoxLocalPlaying and "■" or "▶")
	end
	for cat, btn in pairs(g_BBUIRefs.catBtns) do
		local catLabel = Locale.ResolveString(gBoomBoxDefine[cat].titleKey)
		local selected = g_BoomBoxLocalCategory == cat
		btn:SetLabel(selected and ("[+] " .. catLabel) or catLabel)
		btn.text:ClearPropertyAnimations("Color")
		btn.text:SetColor(btn:GetMouseOver() and kTrackHoverColor or (selected and MenuStyle.kPopupTitleColor or MenuStyle.kOptionHeadingColor))
	end
end

local function GetContent()

	EnsureTrackFont()

	local contents = {}

	-- Section: volume correction
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

	-- Section: local player (heading also shows the now playing track)
	table.insert(contents, {
		name = "bbHeader_BOOMBOX_SECTION_LOCAL",
		class = GUIMenuText,
		params = { text = GetLocalSectionTitle() },
		postInit = {
			function(self)
				self:SetFont(kTitleFont)
				g_BBUIRefs.localHeader = self
			end
		}
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
					self.text:SetFont(kCategoryFont)
					self.glowyText:SetVisible(false)
					CompactButton(self)
					self:HookEvent(self, "OnFXStateChanged", function(btn, state)
						btn.text:ClearPropertyAnimations("Color")
						if state == "hover" then
							btn.text:SetColor(kTrackHoverColor)
						elseif g_BoomBoxLocalCategory == cat then
							btn.text:SetColor(MenuStyle.kPopupTitleColor)
						else
							btn.text:SetColor(MenuStyle.kOptionHeadingColor)
						end
					end)
					local catLbl = Locale.ResolveString(gBoomBoxDefine[cat].titleKey)
					if g_BoomBoxLocalCategory == cat then
						self:SetLabel("[+] " .. catLbl)
						self.text:SetColor(MenuStyle.kPopupTitleColor)
					end
					self:HookEvent(self, "OnPressed", function()
						g_BoomBoxLocalCategory = cat
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
			spacing = 6,
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

	-- Track list: nested scroll pane, keeps the page layout intact
	table.insert(contents, {
		name = "boomboxTrackPane",
		class = GUIMenuScrollPane,
		params = {
			horizontalScrollBarEnabled = false,
		},
		postInit = {
			function(self)
				g_BBTrackPane = self
				self.GetScrollBarThickness = function()
					return kTrackScrollBarWidth
				end
				local bar = self:GetVerticalBar()
				if bar then
					bar.minusButton:SetVisible(false)
					bar.plusButton:SetVisible(false)
					bar:SetOutsidePadding(kTrackScrollBarPadding)
				end
				g_BBPagePane = GetPageScrollPane(self)
				if g_BBPagePane then
					self:HookEvent(g_BBPagePane, "OnSizeChanged", function()
						UpdateTrackPaneHeight()
					end)
				end
				self:AddTimedCallback(function()
					self:SetSize(self:GetSize().x, self:GetSize().y + 1)
					UpdateTrackPaneHeight()
				end, 0)
			end
		},
		children = {
			{
				name = "boomboxTrackList",
				class = GUIListLayout,
				params = {
					orientation = "vertical",
					spacing = kTrackRowSpacing,
					frontPadding = 0,
					backPadding = 0,
				},
				postInit = {
					function(self)
						g_BBTrackList = self
						g_BBTrackBtns = {}
						g_BBShownCategory = nil
						g_BBMarkedIndex = nil
						self:HookEvent(self, "OnSizeChanged", SyncTrackPane)
						RenderTrackList()
					end
				},
			},
		},
	})

	-- Local volume row, random + transport controls on the left
	table.insert(contents, {
		name = "boomboxVolumeRow",
		class = GUIListLayout,
		params = {
			orientation = "horizontal",
			spacing = 0,
			frontPadding = 0,
			backPadding = 0,
		},
		postInit = {
			function(self)
				self._Arrange = function(layout, items)
					local slot = kStopIconWidth + kStopIconSpacing
					local iconSize = kStopIconWidth / kStopIconScale
					local iconCount = #items - 1
					for index = 1, iconCount do
						local icon = GetOwningGUIObject(items[index]) or items[index]
						icon:SetAnchor(0, 0)
						icon:SetHotSpot(0, 0)
						icon:SetPosition((index - 1) * slot, 0)
						icon:SetSize(iconSize, iconSize)
					end
					local volume = GetOwningGUIObject(items[#items]) or items[#items]
					volume:SetAnchor(0, 0)
					volume:SetHotSpot(0, 0)
					volume:SetPosition(iconCount * slot + kLocalVolumeGroupGap, 0)
					local volumeWidth = kLocalVolumeWidth + kLocalVolumeIconWidth
					volume:SetSize(volumeWidth, kLocalVolumeHeight)
					layout:SetSize(iconCount * slot + kLocalVolumeGroupGap + volumeWidth, kLocalVolumeHeight)
				end
			end
		},
		children = {
			MakeIconButton("bbLocalRandom", "⇄", kStopIconFont, function()
				BoomBoxLocalRandom()
				RefreshBBUI(true)
			end),
			MakeIconButton("bbLocalPrev", "◀◀", kSkipIconFont, function()
				BoomBoxLocalPrev()
				RefreshBBUI(true)
			end),
			MakeIconButton("bbLocalStop", g_BoomBoxLocalPlaying and "■" or "▶", kStopIconFont, function()
				BoomBoxLocalToggle()
				RefreshBBUI()
			end, function(btn)
				g_BBUIRefs.stopBtn = btn
			end),
			MakeIconButton("bbLocalNext", "▶▶", kSkipIconFont, function()
				BoomBoxLocalNext()
				RefreshBBUI(true)
			end),
			{
				name = "boomboxLocalVolume",
				class = OP_Number,
				params = {
					optionPath = "BB_Local_Volume",
					optionType = "float",
					default = 0.5,
					minValue = 0,
					maxValue = 1,
					useResetButton = true,
					decimalPlaces = 2,
					immediateUpdate = function()
						g_BoomBoxLocalVolume = Client.GetOptionFloat("BB_Local_Volume", 0.5)
						if BoomBoxLocalApplyVolume then BoomBoxLocalApplyVolume() end
					end
				},
				properties = { { "Label", Locale.ResolveString("BOOMBOX_LOCAL_VOLUME") } },
				postInit = {
					function(self)
						if self.back then
							self.back:SetVisible(false)
						end
						if self.resetButton then
							self.resetButton:SetVisible(false)
						end
						if self.leftSideHolder then
							self.leftSideHolder:SetVisible(false)
						end
						local icon = CreateGUIObject("boomboxLocalVolumeIcon", GUIMenuText, self, { text = "♫" })
						icon:SetFont(kStopIconFont)
						icon:SetScale(kStopIconScale, kStopIconScale)
						icon:SetColor(MenuStyle.kOptionHeadingColor)
						icon:AlignLeft()
						icon:SetPosition(0, 0)
						local function FillSlider()
							local slider = self.slider
							if not slider then
								return
							end
							local size = self:GetSize()
							local sliderHeight = size.y * kLocalVolumeSliderScale
							slider:SetAnchor(0, 0)
							slider:SetHotSpot(0, 0)
							slider:SetPosition(kLocalVolumeIconWidth, (size.y - sliderHeight) * 0.5)
							slider:SetSize(size.x - kLocalVolumeIconWidth, sliderHeight)
						end
						self:HookEvent(self, "OnSizeChanged", FillSlider)
						if self.label then
							self:HookEvent(self.label, "OnTextSizeChanged", FillSlider)
						end
						if self.entry and self.entry.displayText then
							self:HookEvent(self.entry.displayText, "OnInternalFontChanged", FillSlider)
							self:HookEvent(self.entry.displayText, "OnInternalFontScaleChanged", FillSlider)
						end
						FillSlider()
						self:AddTimedCallback(FillSlider, 0)
					end
				},
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
