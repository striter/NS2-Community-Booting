--[[
	Shine ExtraIps Plugin
]]
local StringFormat = string.format

local Plugin = Shine.Plugin( ... )
Plugin.Version = "1.1"
Plugin.NS2Only = true

Plugin.HasConfig = true
Plugin.ConfigName = "ExtraIps.json"
Plugin.DefaultConfig =
{
    MinPlayers = { 12 , 16 , 20 }
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.EnabledGamemodes = Shine.kNS2EnabledGameMode

function Plugin:Initialise()
    self.spawnedInfantryPortal = 0

    return true
end

function Plugin:OnFirstThink()
    Shine.Hook.SetupClassHook( "MarineTeam", "SpawnInitialStructures", "OnSpawnInitialStructures", "PassivePost")
    Shine.Hook.SetupClassHook( "MarineTeam", "AddPlayer", "OnAddPlayer", "PassivePost")
end

function Plugin:SpawnInfantryPortal(Team, TechPoint, IPIndex)
    if IPIndex <= self.spawnedInfantryPortal then return end
    Team:SpawnInfantryPortal(TechPoint, true)
    self.spawnedInfantryPortal = self.spawnedInfantryPortal + 1
end

function Plugin:GetTechPoint(Team)
    -- check that the initial tech point is still controlled by the marines
    local techPoint = Team.startTechPoint
    local techPointOrigin = techPoint:GetOrigin()

    local commandStations = GetEntitiesForTeam("CommandStation", Team:GetTeamNumber())
    local numCommandStations = #commandStations

    -- abort if marines don't have any command stations at the moment
    if numCommandStations == 0 then return end

    local inRange = false
    local rangeSquared = kInfantryPortalAttachRange * kInfantryPortalAttachRange

    for i = 1, numCommandStations do
        local commandStation = commandStations[i]
        if (commandStation:GetOrigin() - techPointOrigin):GetLengthSquaredXZ() <= rangeSquared then
            inRange = true
            break
        end
    end

    if not inRange then
        techPoint = commandStations[1]
    end

    return techPoint
end

function Plugin:OnAddPlayer(Team)
    if not Team.spawnedInfantryPortal or Team.spawnedInfantryPortal < 1 then return end

    local MinPlayers = self.Config.MinPlayers
    local PlayerCount = Team:GetNumPlayers()
    local TechPoint = self:GetTechPoint(Team)

    for i = 1, #MinPlayers do
        if PlayerCount >= MinPlayers[i] then
            self:SpawnInfantryPortal(Team, TechPoint, i)
        end
    end
end

function Plugin:OnSpawnInitialStructures( Team, TechPoint)
    self.spawnedInfantryPortal = 0

    local MinPlayers = self.Config.MinPlayers
    local PlayerCount = Team:GetNumPlayers()

    for i = 1, #MinPlayers do
        if PlayerCount >= MinPlayers[i] then
            self:SpawnInfantryPortal(Team, TechPoint, i)
        end
    end
end

return Plugin