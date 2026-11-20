
local kLocationNameLayer = 4
local kLocationFontName = Fonts.kAgencyFB_Smaller_Bordered

-- Always prefer the bordered atlas: the 345 Noto CJK fallback is smaller and has no outline.
local kUseCJKAtlas = GetFileExists("fontsOverride/AgencyFB_smaller_bordered.fnt")
if kUseCJKAtlas then
    kLocationFontName = PrecacheAsset("fontsOverride/AgencyFB_smaller_bordered.fnt")
end

-- Both atlas pages are built to the same 1 px slack and an 18 px Latin cap, so every label takes one
-- small upscale to sit level with the rest of the map.
local kLocationNameFontScale = 1.15

-- Location names follow the stock map-location opacity option; 0.65 is its default and the fallback.
local kLocationAlphaDefault = 0.65

local function GetLocationAlpha()
    return GetAdvancedOption("locationalpha") or kLocationAlphaDefault
end

-- A second atlas of the same face holds a dilated silhouette of every glyph, so one black copy drawn
-- with it gives the whole ring in a single item. Without that atlas the names fall back to a ring of
-- offset copies, which needs the offset below.
local kOutlineFontPath = "fontsOverride/AgencyFB_smaller_bordered_outline.fnt"
local kLocationOutlineFontName = kLocationFontName
local kUseOutlineAtlas = GetFileExists(kOutlineFontPath)
if kUseOutlineAtlas then
    kLocationOutlineFontName = PrecacheAsset(kOutlineFontPath)
end
-- The ring is switched off: at minimap scale the offset copies read as a heavy drop shadow, so the
-- names are drawn flat until the outline atlas is back in place.
local kOutlineDirections = { }
local kLocationOutlineOffset = 2

local function SetupLocationTextItem(item, fontName, fontScale)

    local scale = GetScaledVector()
    item:SetScale(Vector(scale.x * fontScale, scale.y * fontScale, scale.z))
    item:SetFontIsBold(false)
    item:SetFontName(fontName)
    item:SetAnchor(GUIItem.Middle, GUIItem.Center)
    item:SetTextAlignmentX(GUIItem.Align_Center)
    item:SetTextAlignmentY(GUIItem.Align_Center)
    item:SetLayer(kLocationNameLayer)

end

function GUIMinimap:InitializeLocationNames()

    self:UninitializeLocationNames()
    local locationData = PlayerUI_GetLocationData()

    -- Average the position of same named locations so they don't display
    -- multiple times.
    local multipleLocationsData = { }
    for _, location in ipairs(locationData) do

        -- Filter out the ready room.
        if location.Name ~= "Ready Room" then

            local locationTable = multipleLocationsData[location.Name]
            if locationTable == nil then

                locationTable = {}
                table.insert(multipleLocationsData, location.Name)
                multipleLocationsData[location.Name] = locationTable

            end
            table.insert(locationTable, location.Origin)

        end

    end

    local uniqueLocationsData = { }
    for _, name in ipairs(multipleLocationsData) do

        local origins = multipleLocationsData[name]
        local averageOrigin = Vector(0, 0, 0)
        table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
        table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / #origins })

    end

    for _, location in ipairs(uniqueLocationsData) do

        local posX, posY = self:PlotToMap(location.Origin.x, location.Origin.z)
        local locationName = Locale.ResolveLocation( location.Name)
        local uiScale = GetScaledVector()
        local edgeX = kLocationOutlineOffset * uiScale.x
        local edgeY = kLocationOutlineOffset * uiScale.y

        local fontScale = kLocationNameFontScale

        local locationText = GUIManager:CreateTextItem()
        SetupLocationTextItem(locationText, kLocationFontName, fontScale)
        locationText:SetColor(Color(1.0, 1.0, 1.0, kLocationAlphaDefault))

        locationText:SetText(locationName)
        locationText:SetPosition( Vector(posX, posY, 0) )

        -- The outline atlas already carries the edge, so one black copy in place is enough; otherwise
        -- build the ring out of offset copies of the same face.
        local locationOutlines = { }
        if kUseOutlineAtlas then
            local outlineItem = GUIManager:CreateTextItem()
            SetupLocationTextItem(outlineItem, kLocationOutlineFontName, fontScale)
            outlineItem:SetColor(Color(0, 0, 0, 1))
            outlineItem:SetText(locationName)
            outlineItem:SetPosition( Vector(posX, posY, 0) )
            table.insert(locationOutlines, { item = outlineItem })
        else
            for _, direction in ipairs(kOutlineDirections) do
                local outlineItem = GUIManager:CreateTextItem()
                SetupLocationTextItem(outlineItem, kLocationFontName, fontScale)
                outlineItem:SetColor(Color(0, 0, 0, 1))
                outlineItem:SetText(locationName)
                outlineItem:SetPosition( Vector(posX + direction[1] * edgeX, posY + direction[2] * edgeY, 0) )
                table.insert(locationOutlines, { item = outlineItem, direction = direction })
            end
        end

        for _, outline in ipairs(locationOutlines) do
            self.minimap:AddChild(outline.item)
        end
        self.minimap:AddChild(locationText)

        local locationItem = {text = locationText, outlines = locationOutlines, origin = location.Origin}
        locationItem.text:SetColor( Color(1, 1, 1, GetLocationAlpha()))
        table.insert(self.locationItems, locationItem)

    end

end

local baseUninitializeLocationNames = GUIMinimap.UninitializeLocationNames

function GUIMinimap:UninitializeLocationNames()

    for _, locationItem in ipairs(self.locationItems) do
        if locationItem.outlines then
            for _, outline in ipairs(locationItem.outlines) do
                GUI.DestroyItem(outline.item)
            end
        end
    end

    baseUninitializeLocationNames(self)

end

-- The twin is kept out of self.locationItems so the location-colour broadcasts keep hitting the
-- text only, which means the vanilla visibility and position passes have to be mirrored onto it.
local function SyncLocationOutlines(self)

    local locationItems = self.locationItems
    if not locationItems then
        return
    end

    local uiScale = GetScaledVector()
    local edgeX = kLocationOutlineOffset * uiScale.x
    local edgeY = kLocationOutlineOffset * uiScale.y

    for _, locationItem in ipairs(locationItems) do
        local text = locationItem.text
        local visible = text:GetIsVisible()
        local pos = text:GetPosition()

        for _, outline in ipairs(locationItem.outlines or {}) do
            local direction = outline.direction
            outline.item:SetIsVisible(visible)
            if direction then
                outline.item:SetPosition(Vector(pos.x + direction[1] * edgeX, pos.y + direction[2] * edgeY, 0))
            else
                outline.item:SetPosition(Vector(pos.x, pos.y, 0))
            end
        end
    end

end

local baseSetIsVisible = GUIMinimap.SetIsVisible

function GUIMinimap:SetIsVisible(state)

    baseSetIsVisible(self, state)
    SyncLocationOutlines(self)

end

local baseSetLocationNamesEnabled = GUIMinimap.SetLocationNamesEnabled

function GUIMinimap:SetLocationNamesEnabled(enabled)

    baseSetLocationNamesEnabled(self, enabled)
    SyncLocationOutlines(self)

end

local baseSetScale = GUIMinimap.SetScale

function GUIMinimap:SetScale(scale)

    baseSetScale(self, scale)
    SyncLocationOutlines(self)

end