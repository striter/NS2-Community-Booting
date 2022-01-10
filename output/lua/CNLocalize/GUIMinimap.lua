Script.Load("lua/CNLocalize/CNLocations.lua")
local kLocationNameLayer = 4
local kLocationFontName = Fonts.kAgencyFB_Smaller_Bordered

local function SetupLocationTextItem(item)

    item:SetScale(GetScaledVector())
    item:SetFontIsBold(false)
    item:SetFontName(kLocationFontName)
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

        -- Locations only supported on the big mode.
        local locationText = GUIManager:CreateTextItem()
        SetupLocationTextItem(locationText)
        locationText:SetColor(Color(1.0, 1.0, 1.0, 0.65))
        local locationName=kTranslateLocations[location.Name]
        if not locationName then
            Shared.Message("Untranslated:{" .. location.Name .. "}@Ladjic")
            locationName=location.Name
        end

        locationText:SetText(locationName)
        locationText:SetPosition( Vector(posX, posY, 0) )

        self.minimap:AddChild(locationText)

        local locationItem = {text = locationText, origin = location.Origin}
        locationItem.text:SetColor( Color(1, 1, 1, GetAdvancedOption("locationalpha")))
        table.insert(self.locationItems, locationItem)

    end

end