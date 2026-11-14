-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/CNCommunityRank/GUIHoverScoreboard.lua
--
-- Hover tooltip of the scoreboard: the pooled row layout, the placement rules and the tooltip lifecycle behind the
-- SkillIcon hover. GUIScoreboard only asks for the tooltip to be created, refreshed and hidden.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Tooltip with a leading icon column, used for the SkillIcon hover.
local kIconTooltipPadding = 8
local kIconTooltipIconSpacing = 4
local kIconTooltipIconGap = 3
local kIconTooltipRowSpacing = 1
local kIconTooltipLabelGap = 6
local kIconTooltipSeparatorSpacing = 6
local kIconTooltipSeparatorThickness = 1
local kIconTooltipSeparatorColor = Color(1, 1, 1, 0.20)
-- Group titles are drawn a touch brighter than the separator rule that underlines them.
local kIconTooltipTitleColor = Color(0.62, 0.80, 0.95, 1)
local kIconTooltipTitleSpacing = 3
local kIconTooltipMaxTextWidth = 460
local kIconTooltipMaxRows = 20
local kIconTooltipMaxIcons = 2
-- The signature header lists every badge a player picked, so that strip gets a pool of its own.
local kIconTooltipMaxBadges = 10
-- Badges follow the icons: 20% smaller than the tier emblem on the player name row, which keeps full size.
local kIconTooltipBadgeSize = 16 * 0.8
-- The featured badge rides on the player name header, a notch larger than the strip on the signature header.
local kIconTooltipNameBadgeScale = 1.3
-- Icons taller than this only contribute part of their height to the row height, so the rows with the
-- big faction icons stay tight instead of spacing out on the transparent padding of the atlas cells.
local kIconTooltipTallIconHeight = 34
local kIconTooltipTallIconFactor = 0.70
local kIconTooltipDefaultIconSize = Vector(20, 20, 0)

local function GetIconTooltipRowIcons(row)
    if row.icons then
        return row.icons
    end
    if row.texture then
        return { row }
    end
end

-- Creates the pooled rows, the badge strip and the background once per scoreboard. Every item starts hidden, so a
-- refresh only has to switch on the items its rows actually use.
function GUIScoreboard:CreateIconTooltip()

    self.iconTooltipBackground = GUIManager:CreateGraphicItem()
    self.iconTooltipBackground:SetLayer(kGUILayerOptionsTooltips)
    self.iconTooltipBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.iconTooltipBackground:SetColor(Color(0, 0, 0, 0.85))
    self.iconTooltipBackground:SetIsVisible(false)

    self.iconTooltipRows = {}
    for i = 1, kIconTooltipMaxRows do
        local rowIcons = {}
        for j = 1, kIconTooltipMaxIcons do
            local rowIcon = GUIManager:CreateGraphicItem()
            rowIcon:SetLayer(kGUILayerOptionsTooltips)
            rowIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
            rowIcon:SetColor(GUIScoreboard.kWhiteColor)
            rowIcon:SetIsVisible(false)
            self.iconTooltipBackground:AddChild(rowIcon)
            table.insert(rowIcons, rowIcon)
        end

        local rowText = GUIManager:CreateTextItem()
        rowText:SetLayer(kGUILayerOptionsTooltips)
        rowText:SetFontName(GUIScoreboard.kPlayerStatsFontName)
        rowText:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
        GUIMakeFontScale(rowText)
        rowText:SetAnchor(GUIItem.Left, GUIItem.Top)
        rowText:SetTextAlignmentX(GUIItem.Align_Min)
        rowText:SetTextAlignmentY(GUIItem.Align_Min)
        rowText:SetColor(Color(1, 1, 1, 1))
        rowText:SetIsVisible(false)
        self.iconTooltipBackground:AddChild(rowText)

        local rowValue = GUIManager:CreateTextItem()
        rowValue:SetLayer(kGUILayerOptionsTooltips)
        rowValue:SetFontName(GUIScoreboard.kPlayerStatsFontName)
        rowValue:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
        GUIMakeFontScale(rowValue)
        rowValue:SetAnchor(GUIItem.Left, GUIItem.Top)
        rowValue:SetTextAlignmentX(GUIItem.Align_Min)
        rowValue:SetTextAlignmentY(GUIItem.Align_Min)
        rowValue:SetColor(Color(1, 1, 1, 1))
        rowValue:SetIsVisible(false)
        self.iconTooltipBackground:AddChild(rowValue)

        local rowText2 = GUIManager:CreateTextItem()
        rowText2:SetLayer(kGUILayerOptionsTooltips)
        rowText2:SetFontName(GUIScoreboard.kPlayerStatsFontName)
        rowText2:SetScale(Vector(1, 1, 1) * GUIScoreboard.kScalingFactor)
        GUIMakeFontScale(rowText2)
        rowText2:SetAnchor(GUIItem.Left, GUIItem.Top)
        rowText2:SetTextAlignmentX(GUIItem.Align_Min)
        rowText2:SetTextAlignmentY(GUIItem.Align_Min)
        rowText2:SetColor(Color(1, 1, 1, 1))
        rowText2:SetIsVisible(false)
        self.iconTooltipBackground:AddChild(rowText2)

        local rowLine = GUIManager:CreateGraphicItem()
        rowLine:SetLayer(kGUILayerOptionsTooltips)
        rowLine:SetAnchor(GUIItem.Left, GUIItem.Top)
        rowLine:SetColor(kIconTooltipSeparatorColor)
        rowLine:SetIsVisible(false)
        self.iconTooltipBackground:AddChild(rowLine)

        local rowTextScale = Vector(rowText:GetScale())
        local rowText2Scale = Vector(rowText2:GetScale())

        table.insert(self.iconTooltipRows, { Icons = rowIcons, Text = rowText, Value = rowValue, Text2 = rowText2, Line = rowLine,
            TextScale = rowTextScale, Text2Scale = rowText2Scale })
    end
    -- Badge textures are standalone images instead of atlas cells, so these items only ever receive SetTexture
    -- and never pixel coordinates.
    self.iconTooltipBadges = {}
    for i = 1, kIconTooltipMaxBadges do
        local badgeIcon = GUIManager:CreateGraphicItem()
        badgeIcon:SetLayer(kGUILayerOptionsTooltips)
        badgeIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
        badgeIcon:SetColor(GUIScoreboard.kWhiteColor)
        badgeIcon:SetIsVisible(false)
        self.iconTooltipBackground:AddChild(badgeIcon)
        table.insert(self.iconTooltipBadges, badgeIcon)
    end
    self.iconTooltipNameBadge = GUIManager:CreateGraphicItem()
    self.iconTooltipNameBadge:SetLayer(kGUILayerOptionsTooltips)
    self.iconTooltipNameBadge:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.iconTooltipNameBadge:SetColor(GUIScoreboard.kWhiteColor)
    self.iconTooltipNameBadge:SetIsVisible(false)
    self.iconTooltipBackground:AddChild(self.iconTooltipNameBadge)
    self.iconTooltipShown = false

end

function GUIScoreboard:DestroyIconTooltip()

    GUI.DestroyItem(self.iconTooltipBackground)
    self.iconTooltipBackground = nil
    self.iconTooltipRows = nil
    self.iconTooltipBadges = nil
    self.iconTooltipNameBadge = nil

end

-- Drops the tooltip when the scoreboard closes or a hover menu takes the cursor.
function GUIScoreboard:HideIconTooltip()

    self.iconTooltipBackground:SetIsVisible(false)

end

-- Every scoreboard update clears the flag first and hides the tooltip afterwards unless a hover refreshed it.
function GUIScoreboard:BeginIconTooltipFrame()

    self.iconTooltipShown = false

end

function GUIScoreboard:EndIconTooltipFrame()

    if not self.iconTooltipShown then
        self:HideIconTooltip()
    end

end

-- Places one icon slot inside the vertical band that starts at _slotTop and is _slotHeight tall, and returns its
-- width. Every icon is centred in that band, so all the emblems of a row share one baseline; an icon may carry
-- riseY to be lifted by that many pixels, which makes up for the descender slot under the text glyphs. The slot
-- is hidden when there is no icon.
local function SetTooltipIcon(_iconItem, _icon, _x, _slotTop, _slotHeight, _scale)
    if not _icon then
        _iconItem:SetIsVisible(false)
        return 0
    end
    local iconWidth = (_icon.width or kIconTooltipDefaultIconSize.x) * _scale
    local iconHeight = (_icon.height or kIconTooltipDefaultIconSize.y) * _scale
    _iconItem:SetTexture(_icon.texture)
    _iconItem:SetTexturePixelCoordinates(_icon.x1, _icon.y1, _icon.x2, _icon.y2)
    _iconItem:SetSize(Vector(iconWidth, iconHeight, 0))
    _iconItem:SetColor(_icon.color or GUIScoreboard.kWhiteColor)
    _iconItem:SetPosition(Vector(_x, _slotTop + (_slotHeight - iconHeight) * 0.5 - (_icon.riseY or 0) * _scale, 0))
    _iconItem:SetIsVisible(true)
    return iconWidth
end

local function PlaceTooltipIcons(_rowItem, _icons, _startX, _slotTop, _slotHeight, _scale)
    local iconX = _startX
    for j = 1, kIconTooltipMaxIcons do
        local iconWidth = SetTooltipIcon(_rowItem.Icons[j], _icons and _icons[j], iconX, _slotTop, _slotHeight, _scale)
        if iconWidth > 0 then
            iconX = iconX + iconWidth + kIconTooltipIconGap * _scale
        end
    end
end

-- Shows a tooltip near the cursor. Each entry of _rows is either a plain line
-- { text = string, textColor = Color, textScale = number, align = "left"/"center"/"right", gap = number,
--   icons = { { texture, x1, y1, x2, y2, width, height, color, riseY }, ... }, iconsAlign = "right",
--   leadingBadge = texture } where gap adds pixels to the row spacing below that line, a leading badge is drawn
-- before the text, a two column line { label = string, value = string, valueColor = Color, icons = { ... },
--   valueIcon = { texture, x1, y1, x2, y2, width, height, color, riseY } } so all labels share one column while every value
-- ends flush against its emblem, both of which pin to the right edge like the icons of an iconsAlign = "right"
-- row, a header line
-- { title = string, rightText = string, rightIcons = { ... }, rightBadges = { texture, ... }, gap = number } that
-- prints a label with an optional note, icons and a strip of standalone badge textures hanging on the right edge
-- and a rule above it, or { separator = true } for a bare rule. Every icon is centred in the height of its line.
-- Lines
-- without icons keep the icon column indent so every line shares one text column, except aligned lines
-- (align = "center"/"right") which are placed across the whole panel and rows with iconsAlign = "right" whose
-- icons pin to the right edge.
function GUIScoreboard:ShowIconTooltip(_rows, _mouseX, _mouseY)

    if #_rows == 0 then
        return
    end

    local scale = GUIScoreboard.kScalingFactor
    local padding = kIconTooltipPadding * scale
    local baseRowSpacing = kIconTooltipRowSpacing * scale
    local iconSpacing = kIconTooltipIconSpacing * scale
    local iconGap = kIconTooltipIconGap * scale
    local labelGap = kIconTooltipLabelGap * scale
    local separatorSpacing = kIconTooltipSeparatorSpacing * scale
    local separatorThickness = math.max(1, kIconTooltipSeparatorThickness * scale)
    local titleSpacing = kIconTooltipTitleSpacing * scale

    local iconColumnWidth = 0
    for _, row in ipairs(_rows) do
        local icons = GetIconTooltipRowIcons(row)
        if icons and row.iconsAlign ~= "right" then
            local width = 0
            for i, icon in ipairs(icons) do
                width = width + (icon.width or kIconTooltipDefaultIconSize.x) * scale + (i > 1 and iconGap or 0)
            end
            iconColumnWidth = math.max(iconColumnWidth, width)
        end
    end
    if iconColumnWidth > 0 then
        iconColumnWidth = iconColumnWidth + iconSpacing
    end

    local labelColumnWidth = 0
    for _, row in ipairs(_rows) do
        if row.value then
            labelColumnWidth = math.max(labelColumnWidth, self.iconTooltipRows[1].Text:GetTextWidth(row.label or "") * scale)
        end
    end
    local valueOffset = iconColumnWidth + (labelColumnWidth > 0 and (labelColumnWidth + labelGap) or 0)

    local valueColumnWidth = 0
    for _, row in ipairs(_rows) do
        if row.value then
            valueColumnWidth = math.max(valueColumnWidth, self.iconTooltipRows[1].Value:GetTextWidth(row.value) * self.iconTooltipRows[1].Value:GetScale().x)
        end
    end

    local y = padding
    local contentWidth = 0
    local alignedTexts = {}
    local alignedIcons = {}
    local alignedValues = {}
    local alignedValueIcons = {}
    local alignedTitleTails = {}
    local alignedTitleBadges = nil
    for _, badgeIcon in ipairs(self.iconTooltipBadges) do
        badgeIcon:SetIsVisible(false)
    end
    self.iconTooltipNameBadge:SetIsVisible(false)
    for i = 1, #self.iconTooltipRows do
        local rowItem = self.iconTooltipRows[i]
        local row = _rows[i]
        -- A row may ask for extra air below itself, so one section can breathe more than another.
        local rowSpacing = baseRowSpacing + ((row and row.gap) or 0) * scale
        rowItem.Text:SetScale(rowItem.TextScale * ((row and row.textScale) or 1))
        rowItem.Text2:SetScale(rowItem.Text2Scale)
        if row and row.separator then
            rowItem.Text:SetIsVisible(false)
            rowItem.Text2:SetIsVisible(false)
            rowItem.Value:SetIsVisible(false)
            for j = 1, kIconTooltipMaxIcons do
                rowItem.Icons[j]:SetIsVisible(false)
            end
            rowItem.Line:SetPosition(Vector(padding, y + separatorSpacing, 0))
            rowItem.Line:SetIsVisible(true)
            y = y + separatorSpacing * 2 + separatorThickness
        elseif row and row.title then
            for j = 1, kIconTooltipMaxIcons do
                rowItem.Icons[j]:SetIsVisible(false)
            end
            rowItem.Text:SetText(row.title)
            rowItem.Text:SetColor(row.textColor or kIconTooltipTitleColor)
            rowItem.Text:SetIsVisible(true)
            local titleWidth = rowItem.Text:GetTextWidth(row.title) * rowItem.Text:GetScale().x
            local titleHeight = rowItem.Text:GetTextHeight(row.title) * rowItem.Text:GetScale().y
            -- The rule opens the section and its title sits at the top left corner of the block below it.
            rowItem.Line:SetPosition(Vector(padding, y, 0))
            rowItem.Line:SetIsVisible(true)
            local titleY = y + separatorThickness + titleSpacing
            rowItem.Text:SetPosition(Vector(padding, titleY, 0))
            local headingWidth = titleWidth
            local headingHeight = titleHeight
            rowItem.Value:SetIsVisible(false)
            local tailIcons = row.rightIcons
            local tailIconsWidth = 0
            local tailIconsHeight = 0
            if tailIcons then
                for j, icon in ipairs(tailIcons) do
                    tailIconsWidth = tailIconsWidth + (icon.width or kIconTooltipDefaultIconSize.x) * scale + (j > 1 and iconGap or 0)
                    tailIconsHeight = math.max(tailIconsHeight, (icon.height or kIconTooltipDefaultIconSize.y) * scale)
                end
            end
            local rightWidth = 0
            local rightHeight = 0
            if row.rightText then
                rowItem.Text2:SetText(row.rightText)
                rowItem.Text2:SetColor(row.rightColor or GUIScoreboard.kWhiteColor)
                rowItem.Text2:SetIsVisible(true)
                rightWidth = rowItem.Text2:GetTextWidth(row.rightText) * rowItem.Text2:GetScale().x
                rightHeight = rowItem.Text2:GetTextHeight(row.rightText) * rowItem.Text2:GetScale().y
            else
                rowItem.Text2:SetIsVisible(false)
            end
            if row.rightText or tailIcons then
                -- The trailing note and its icons hang on the right edge, which needs the final panel width.
                local tailWidth = rightWidth + (tailIconsWidth > 0 and (tailIconsWidth + (rightWidth > 0 and iconGap or 0)) or 0)
                -- The note and its emblems ride the middle of whichever element is tallest on the line, so they stay
                -- centred against each other even when an emblem or an inline markup title is taller than the other.
                local lineHeight = math.max(titleHeight, rightHeight, tailIconsHeight)
                headingHeight = math.max(headingHeight, lineHeight)
                table.insert(alignedTitleTails, { rowItem = rowItem, textItem = row.rightText and rowItem.Text2 or nil,
                    textWidth = rightWidth, textHeight = rightHeight, icons = tailIcons, width = tailWidth, y = titleY, height = lineHeight })
                headingWidth = headingWidth + labelGap + tailWidth
            end
            local badges = row.rightBadges
            if badges and #badges > 0 then
                -- The badge strip also ends on the right edge, so it is placed once the panel width is known.
                local badgeSize = kIconTooltipBadgeSize * scale
                local badgesWidth = #badges * badgeSize + (#badges - 1) * iconGap
                alignedTitleBadges = { textures = badges, width = badgesWidth, y = titleY, height = titleHeight }
                headingWidth = headingWidth + labelGap + badgesWidth
            end
            contentWidth = math.max(contentWidth, headingWidth)
            y = titleY + headingHeight + rowSpacing
        elseif row then
            local icons = GetIconTooltipRowIcons(row)
            local isValueRow = row.value ~= nil
            -- Left aligned headers hug the panel edge; other lines keep the icon column indent.
            local textIndent = (row.align == "left" or (not icons and row.align)) and 0 or iconColumnWidth
            rowItem.Line:SetIsVisible(false)
            rowItem.Text2:SetIsVisible(false)

            local rowTextMaxWidth = math.max(80 * scale, kIconTooltipMaxTextWidth * scale - (icons and valueOffset or 0))
            local rowText = isValueRow and (row.label or "") or (row.text or "")
            -- Right aligned lines are never wrapped, so a short section stays one line and the panel follows the text.
            local wrappedText = row.align == "right" and rowText or WordWrap(rowItem.Text, rowText, 0, rowTextMaxWidth)
            rowItem.Text:SetText(wrappedText)
            rowItem.Text:SetColor(row.textColor or GUIScoreboard.kWhiteColor)
            rowItem.Text:SetIsVisible(true)

            local textWidth = rowItem.Text:GetTextWidth(wrappedText) * rowItem.Text:GetScale().x
            local textHeight = rowItem.Text:GetTextHeight(wrappedText) * rowItem.Text:GetScale().y

            local valueWidth, valueHeight = 0, 0
            if isValueRow then
                rowItem.Value:SetText(row.value)
                rowItem.Value:SetColor(row.valueColor or GUIScoreboard.kWhiteColor)
                rowItem.Value:SetIsVisible(true)
                valueWidth = rowItem.Value:GetTextWidth(row.value) * rowItem.Value:GetScale().x
                valueHeight = rowItem.Value:GetTextHeight(row.value) * rowItem.Value:GetScale().y
            else
                rowItem.Value:SetIsVisible(false)
            end

            local rowHeight = math.max(textHeight, valueHeight)
            if icons then
                for _, icon in ipairs(icons) do
                    local iconHeight = (icon.height or kIconTooltipDefaultIconSize.y) * scale
                    if iconHeight > kIconTooltipTallIconHeight * scale then
                        iconHeight = iconHeight * kIconTooltipTallIconFactor
                    end
                    rowHeight = math.max(rowHeight, iconHeight)
                end
            end
            -- The trailing emblem of a value line is part of the row height too, so the leading icons, the number and
            -- that emblem all centre on the same band.
            if row.valueIcon then
                rowHeight = math.max(rowHeight, (row.valueIcon.height or kIconTooltipDefaultIconSize.y) * scale)
            end

            -- A featured badge sits in front of the text, so everything after it shifts by its width.
            local leadingWidth = 0
            local leadingBadge = row.leadingBadge
            if leadingBadge then
                local nameBadgeSize = kIconTooltipBadgeSize * kIconTooltipNameBadgeScale * scale
                leadingWidth = nameBadgeSize + labelGap
                rowHeight = math.max(rowHeight, nameBadgeSize)
                self.iconTooltipNameBadge:SetTexture(leadingBadge)
                self.iconTooltipNameBadge:SetSize(Vector(nameBadgeSize, nameBadgeSize, 0))
                self.iconTooltipNameBadge:SetPosition(Vector(padding, y + (rowHeight - nameBadgeSize) * 0.5, 0))
                self.iconTooltipNameBadge:SetColor(GUIScoreboard.kWhiteColor)
                self.iconTooltipNameBadge:SetIsVisible(true)
            end

            local iconsWidth = 0
            if icons then
                for j, icon in ipairs(icons) do
                    iconsWidth = iconsWidth + (icon.width or kIconTooltipDefaultIconSize.x) * scale + (j > 1 and iconGap or 0)
                end
            end
            local iconsRight = row.iconsAlign == "right"
            if iconsRight then
                -- Icons pinned to the right edge can only be placed once the panel width is known.
                table.insert(alignedIcons, { rowItem = rowItem, icons = icons, width = iconsWidth, y = y, height = rowHeight })
            else
                PlaceTooltipIcons(rowItem, icons, padding + math.max(0, (iconColumnWidth - iconSpacing - iconsWidth) * 0.5), y, rowHeight, scale)
            end

            local textPosY = y + (rowHeight - textHeight) * 0.5
            if not icons and row.align then
                -- Lines without an icon may be centred or right aligned, which needs the final panel width.
                table.insert(alignedTexts, { item = rowItem.Text, y = textPosY, width = textWidth, align = row.align })
            else
                rowItem.Text:SetPosition(Vector(padding + leadingWidth + textIndent, textPosY, 0))
            end

            if isValueRow then
                contentWidth = math.max(contentWidth, valueOffset + valueColumnWidth)
                -- The emblem of that number pins to the right edge, so the four of them stack into one column
                -- right under the tier emblem of the name row.
                local valueIcon = row.valueIcon
                local valueIconWidth = 0
                if valueIcon then
                    valueIconWidth = (valueIcon.width or kIconTooltipDefaultIconSize.x) * scale
                    table.insert(alignedValueIcons, { item = rowItem.Icons[2], icon = valueIcon, width = valueIconWidth,
                        top = y, height = rowHeight })
                    contentWidth = math.max(contentWidth, valueOffset + valueColumnWidth + iconGap + valueIconWidth)
                end
                -- Every number ends flush against the left edge of its own emblem, which also needs the final width.
                table.insert(alignedValues, { item = rowItem.Value, width = valueWidth, iconWidth = valueIconWidth,
                    centerY = y + (rowHeight - valueHeight) * 0.5 })
            else
                local trailingIcons = iconsRight and (iconsWidth + iconGap) or 0
                contentWidth = math.max(contentWidth, leadingWidth + textIndent + textWidth + trailingIcons)
            end
            y = y + rowHeight + rowSpacing
        else
            rowItem.Text:SetIsVisible(false)
            rowItem.Text2:SetIsVisible(false)
            rowItem.Value:SetIsVisible(false)
            rowItem.Line:SetIsVisible(false)
            for j = 1, kIconTooltipMaxIcons do
                rowItem.Icons[j]:SetIsVisible(false)
            end
        end
    end

    local width = contentWidth + padding * 2
    local height = y - baseRowSpacing + padding

    for _, entry in ipairs(alignedTexts) do
        local offset = 0
        if entry.align == "center" then
            offset = (contentWidth - entry.width) * 0.5
        elseif entry.align == "right" then
            offset = contentWidth - entry.width
        end
        entry.item:SetPosition(Vector(padding + math.max(0, offset), entry.y, 0))
    end

    for _, entry in ipairs(alignedTitleTails) do
        -- Right anchored, so the icons sit left of the note and the whole tail ends on the panel edge.
        local left = padding + math.max(0, contentWidth - entry.width)
        if entry.icons then
            PlaceTooltipIcons(entry.rowItem, entry.icons, left, entry.y, entry.height, scale)
        end
        if entry.textItem then
            entry.textItem:SetPosition(Vector(left + entry.width - entry.textWidth, entry.y + (entry.height - entry.textHeight) * 0.5, 0))
        end
    end

    for _, entry in ipairs(alignedIcons) do
        PlaceTooltipIcons(entry.rowItem, entry.icons, padding + math.max(0, contentWidth - entry.width), entry.y, entry.height, scale)
    end

    for _, entry in ipairs(alignedValues) do
        -- Numbers stop one gap left of their emblem so the numbers and the emblems read as one right aligned block.
        local rightEdge = entry.iconWidth > 0 and (contentWidth - entry.iconWidth - iconGap) or (valueOffset + valueColumnWidth)
        entry.item:SetPosition(Vector(padding + math.max(0, rightEdge - entry.width), entry.centerY, 0))
    end

    for _, entry in ipairs(alignedValueIcons) do
        SetTooltipIcon(entry.item, entry.icon, padding + math.max(0, contentWidth - entry.width), entry.top, entry.height, scale)
    end

    if alignedTitleBadges then
        -- Right anchored strip: the badges grow leftwards from the panel edge next to the title text.
        local badgeSize = kIconTooltipBadgeSize * scale
        local left = padding + math.max(0, contentWidth - alignedTitleBadges.width)
        local badgeY = alignedTitleBadges.y + (alignedTitleBadges.height - badgeSize) * 0.5
        for i, texture in ipairs(alignedTitleBadges.textures) do
            local badgeIcon = self.iconTooltipBadges[i]
            if badgeIcon then
                badgeIcon:SetTexture(texture)
                badgeIcon:SetSize(Vector(badgeSize, badgeSize, 0))
                badgeIcon:SetPosition(Vector(left, badgeY, 0))
                badgeIcon:SetColor(GUIScoreboard.kWhiteColor)
                badgeIcon:SetIsVisible(true)
            end
            left = left + badgeSize + iconGap
        end
    end

    local innerWidth = width - padding * 2
    for i = 1, #self.iconTooltipRows do
        local lineItem = self.iconTooltipRows[i].Line
        if lineItem:GetIsVisible() then
            lineItem:SetSize(Vector(innerWidth, separatorThickness, 0))
        end
    end

    local centerX = _mouseX - GUIScoreboard.screenWidth / 2
    local centerY = _mouseY - GUIScoreboard.screenHeight / 2
    local x = centerX + 18 * scale
    local posY = centerY + 12 * scale
    if x + width > GUIScoreboard.screenWidth / 2 then
        x = centerX - width - 18 * scale
    end
    if posY + height > GUIScoreboard.screenHeight / 2 then
        posY = centerY - height - 12 * scale
    end

    self.iconTooltipBackground:SetSize(Vector(width, height, 0))
    self.iconTooltipBackground:SetPosition(Vector(x, posY, 0))
    self.iconTooltipBackground:SetIsVisible(true)
    self.iconTooltipShown = true

end
