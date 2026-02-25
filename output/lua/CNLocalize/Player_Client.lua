
-- Draw the current location on the HUD ("Marine Start", "Processing", etc.)

function PlayerUI_GetPingInfo(player, teamInfo, onMiniMap)

    local position = Vector(0,0,0)

    local pingPos = teamInfo:GetPingPosition()

    local location = GetLocationForPoint(pingPos)
    local locationName = location and Locale.ResolveLocation(location:GetName()) or ""

    if not onMiniMap then
        position = GetClampedScreenPosition(pingPos, 40)
    else
        position = pingPos
    end
    local pingTime = teamInfo:GetPingTime()

    local timeSincePing = Shared.GetTime() - pingTime
    local distance = (player:GetEyePos() - pingPos):GetLength()

    return timeSincePing, position, distance, locationName, pingTime

end

function PlayerUI_GetLocationName()

    local locationName = ""

    local player = Client.GetLocalPlayer()

    local playerLocation = GetLocationForPoint(player:GetOrigin())

    if player ~= nil and player:GetIsPlaying() then

        if playerLocation ~= nil then

            locationName = Locale.ResolveLocation(playerLocation.name)

        elseif playerLocation == nil and locationName ~= nil then

            locationName = Locale.ResolveLocation(player:GetLocationName())

        elseif locationName == nil then

            locationName = ""

        end

    end

    return locationName

end

local kEnemyObjectiveRange = 30
function PlayerUI_GetObjectiveInfo()

    local player = Client.GetLocalPlayer()

    if player then

        if player.crossHairHealth and player.crossHairText then

            player.showingObjective = true
            return player.crossHairHealth / 100, player.crossHairText .. " " .. ToString(player.crossHairHealth) .. "%", player.crossHairTeamType

        end

        -- check command structures in range (enemy or friend) and return health % and name
        local objectiveInfoEnts = EntityListToTable( Shared.GetEntitiesWithClassname("ObjectiveInfo") )
        local playersTeam = player:GetTeamNumber()

        local function SortByHealthAndTeam(ent1, ent2)
            return ent1:GetHealthScalar() < ent2:GetHealthScalar() and ent1.teamNumber == playersTeam
        end

        table.sort(objectiveInfoEnts, SortByHealthAndTeam)

        for _, objectiveInfoEnt in ipairs(objectiveInfoEnts) do

            if objectiveInfoEnt:GetIsInCombat() and ( playersTeam == objectiveInfoEnt:GetTeamNumber() or (player:GetOrigin() - objectiveInfoEnt:GetOrigin()):GetLength() < kEnemyObjectiveRange ) then

                local healthFraction = math.max(0.01, objectiveInfoEnt:GetHealthScalar())

                player.showingObjective = true

                local text = StringReformat(Locale.ResolveString("OBJECTIVE_PROGRESS"),
                        { location = Locale.ResolveLocation(objectiveInfoEnt:GetLocationName()),
                          name = GetDisplayNameForTechId(objectiveInfoEnt:GetTechId()),
                          health = math.ceil(healthFraction * 100) })

                return healthFraction, text, objectiveInfoEnt:GetTeamType()

            end

        end

        player.showingObjective = false

    end

end