
local kMarineTextFontName = PrecacheAsset(Fonts.kAgencyFB_Small)
local kAlienTextFontName = kMarineTextFontName --? --PrecacheAsset(Fonts.kKartika_Small)
local kArrowModel = PrecacheAsset("models/misc/waypoint_arrow.model")
local kArrowAlienModel = PrecacheAsset("models/misc/waypoint_arrow_alien.model")

local function InitMarineTexture(self)

    self.arrowModelName = kArrowModel
    self.lightColor = Color(0.2, 0.2, 1, 1)

    self.finalDistanceText:SetFontName(kMarineTextFontName)
    self.finalDistanceText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.finalDistanceText)
    self.finalNameText:SetFontName(kMarineTextFontName)
    self.finalNameText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.finalNameText)
    self.orderIcon:SetColor(kIconColors[kMarineTeamType])
    
    self.waypointDirection:SetColor(Color(1, 1, 1, 1))
    self.marineWaypointLoaded = true

end

local function InitAlienTexture(self)

    self.arrowModelName = kArrowAlienModel
    self.lightColor = Color(1, 0.2, 0.2, 1)

    self.finalDistanceText:SetFontName(kAlienTextFontName)
    self.finalDistanceText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.finalDistanceText)
    self.finalNameText:SetFontName(kAlienTextFontName)
    self.finalNameText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.finalNameText)
    self.orderIcon:SetColor(kIconColors[kAlienTeamType])
    
    self.waypointDirection:SetColor(kAlienTeamColorFloat)
    self.marineWaypointLoaded = false

end

function GUIWaypoints:OnLocalPlayerChanged(newPlayer)

    if newPlayer:GetTeamNumber() == kTeam1Index then
        InitMarineTexture(self)
    elseif newPlayer:GetTeamNumber() == kTeam2Index then
        InitAlienTexture(self)
    end
    
end