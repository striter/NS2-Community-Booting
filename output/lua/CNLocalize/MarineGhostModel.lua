
local commandStationScreenPos = Vector(0, 0, 0)
function MarineGhostModel:Update()

    local modelCoords = GhostModel.Update(self)
    
    if modelCoords then
        
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(modelCoords.origin, zAxis)
        self.circleModel:SetCoords(coords)
        
        self.powerIcon:SetIsVisible(true)
        self.obsBeaconLocation:SetIsVisible(true)

        local location = GetLocationForPoint(modelCoords.origin)
        local powerNode = location ~= nil and GetPowerPointForLocation(location:GetName())
        local commandStation = GetNearest(modelCoords.origin, "CommandStation", kTeam1Index, function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)

        if commandStation ~= nil and GetLocationForPoint(commandStation:GetOrigin()) then
            commandStationOrigin = commandStation:GetOrigin()
            beaconToLocationText = Locale.ResolveLocation( GetLocationForPoint(commandStationOrigin):GetName())
        end

        if commandStationOrigin then
            commandStationScreenPos = Client.WorldToScreen(commandStationOrigin)
        end

        local powered = false

        if powerNode then
            local player = Client.GetLocalPlayer()
            local showPowerIndicator = player.currentTechId and player.currentTechId ~= kTechId.None and LookupTechData(player.currentTechId, kTechDataRequiresPower, false)
            local showBeaconIndicator = player.currentTechId and player.currentTechId ~= kTechId.None and LookupTechData(player.currentTechId, kTechDataShowBeaconToLocation, false)

            self.powerIcon:SetIsVisible(showPowerIndicator)
            self.obsBeaconLocation:SetIsVisible(showBeaconIndicator)

            powered = powerNode:GetIsPowering()
            
            local screenPos = Client.WorldToScreen(modelCoords.origin)
            local powerNodeScreenPos = Client.WorldToScreen(powerNode:GetOrigin())
            local iconPos = screenPos + GetNormalizedVectorXY(powerNodeScreenPos - screenPos) * GUIScale(100) - GUIScale(Vector(32, 32, 0))
            local textPos = screenPos + GetNormalizedVectorXY(commandStationScreenPos - screenPos) * GUIScale(100) - GUIScale(Vector(32, 32, 0))
        
            self.powerIcon:SetPosition(iconPos)
            self.obsBeaconLocation:SetPosition(textPos)

            local animation = (1 + math.sin(Shared.GetTime() * 8)) * 0.5
            local useColor = Color()
            
            if powered then
            
                useColor = Color(
                    (1 - kMarineTeamColorFloat.r) * animation + kMarineTeamColorFloat.r,
                    (1 - kMarineTeamColorFloat.g) * animation + kMarineTeamColorFloat.g,
                    (1 - kMarineTeamColorFloat.b) * animation + kMarineTeamColorFloat.b,
                    1
                )
        
            else
                useColor = Color(0.5 + 0.5 * animation, 0, 0, 1)
            end
            
            self.powerIcon:SetColor(useColor)

            if showPowerIndicator then
                local screenPos = Client.WorldToScreen(modelCoords.origin)
                local textPos = self.powerIcon:GetPosition()
                local powerPoint = GetPowerPointForLocation(location:GetName())
                local text = string.format("%s", Locale.ResolveLocation( location:GetName()))
                local builtFraction = powerPoint:GetBuiltFraction()
                local healthFraction = powerPoint:GetHealthScalar()
                if builtFraction < 1 then
                    text = StringReformat(Locale.ResolveString("POWER_BUILT"),
                            { location = Locale.ResolveLocation( location:GetName()),
                              percentage = builtFraction*100 })
                elseif builtFraction > 0 and healthFraction < 1 then
                    text = StringReformat(Locale.ResolveString("POWER_HEALTH"),
                            { location = Locale.ResolveLocation( location:GetName()),
                              percentage = healthFraction*100 })
                end
                self.powerLocationText:SetText(text)
                self.powerLocationText:SetColor(useColor)

                if screenPos.x > textPos.x then
                    self.powerLocationText:SetAnchor(GUIItem.Left, GUIItem.Center)
                    self.powerLocationText:SetTextAlignmentX(GUIItem.Align_Max)
                    self.powerLocationText:SetPosition(GUIScale(Vector(-10, 0, 0)))
                else
                    self.powerLocationText:SetAnchor(GUIItem.Right, GUIItem.Center)
                    self.powerLocationText:SetTextAlignmentX(GUIItem.Align_Min)
                    self.powerLocationText:SetPosition(GUIScale(Vector(10, 0, 0)))
                end
            else
                self.powerLocationText:SetText("")
            end

            if showBeaconIndicator and beaconToLocationText ~= "" then
                local beaconText = StringReformat(Locale.ResolveString("BEACONS_TO"),
                        { location = beaconToLocationText })
                self.obsBeaconLocation:SetText(beaconText)
            else
                self.obsBeaconLocation:SetIsVisible(false)
            end
        else
            self.powerIcon:SetIsVisible(false)
            self.obsBeaconLocation:SetIsVisible(false)
        end

    else
    
        self.powerIcon:SetIsVisible(false)
        self.obsBeaconLocation:SetIsVisible(false)

    end
    
end


