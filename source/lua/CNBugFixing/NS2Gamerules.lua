--Remove annoying bots-help-bots

function NS2Gamerules:OnClientDisconnect(client)

    local player = client:GetControllingPlayer()

    if player then

        -- When a player disconnects remove them from their team
        local teamNumber = player:GetTeamNumber()

        --Log player for the round report
        if teamNumber == kTeam1Index or teamNumber == kTeam2Index then
            self.playerRanking:SetExitTime( player, teamNumber )
        end
        self.playerRanking:LogPlayer(player)

        local team = self:GetTeam(teamNumber)
        if team then
            team:RemovePlayer(player)
        end

        player:RemoveSpectators(nil)

        local clientUserId = client:GetUserId()
        if not self.clientpres[clientUserId] then self.clientpres[clientUserId] = {} end
        self.clientpres[clientUserId][teamNumber] = player:GetResources()

        if not client:GetIsVirtual() then       --------------------------------------Don't work on nonvirtual
            self.botTeamController:UpdateBots()
        end
    end

    Gamerules.OnClientDisconnect(self, client)  --??? TD-TODO review for potential "auto" pause, and revising rules, etc.
end

function NS2Gamerules:JoinTeam(player, newTeamNumber, force)

    local client = Server.GetOwner(player)
    if not client then return end

    -- reset players camera distance, so for example if a player is respawning from an infantry portal, they won't
    -- be stuck in 3rd person view.
    player:SetCameraDistance(0)

    if newTeamNumber ~= kSpectatorIndex and not self:GetCanJoinPlayingTeam(player) then
        return false
    end

    if not force and not self:GetCanJoinTeamNumber(player, newTeamNumber) then
        return false
    end

    local success = false
    local newPlayer

    local oldPlayerWasSpectating = client and client:GetSpectatingPlayer()
    local oldPlayerWasCommander = client and player:isa("Commander")
    local oldTeamNumber = player:GetTeamNumber()

    -- Join new team
    if oldTeamNumber ~= newTeamNumber or force then

        if not Shared.GetCheatsEnabled() and self:GetGameStarted() and newTeamNumber ~= kTeamReadyRoom then
            player.spawnBlockTime = Shared.GetTime() + kSuicideDelay
        end

        local team = self:GetTeam(newTeamNumber)
        local oldTeam = self:GetTeam(oldTeamNumber)

        -- Remove the player from the old queue if they happen to be in one
        if oldTeam then
            oldTeam:RemovePlayerFromRespawnQueue(player)
        end

        -- Spawn immediately if going to ready room, game hasn't started, cheats on, or game started recently
        if newTeamNumber == kTeamReadyRoom or self:GetCanSpawnImmediately() or force then

            success, newPlayer = team:ReplaceRespawnPlayer(player, nil, nil)

            local teamTechPoint = team.GetInitialTechPoint and team:GetInitialTechPoint()
            if teamTechPoint then
                newPlayer:OnInitialSpawn(teamTechPoint:GetOrigin())
            end

        else

            -- Destroy the existing player and create a spectator in their place.
            newPlayer = player:Replace(team:GetSpectatorMapName(), newTeamNumber)

            -- Queue up the spectator for respawn.
            team:PutPlayerInRespawnQueue(newPlayer)

            success = true

        end

        local clientUserId = client:GetUserId()
        --Save old pres 
        if oldTeam == self.team1 or oldTeam == self.team2 then
            if not self.clientpres[clientUserId] then self.clientpres[clientUserId] = {} end
            self.clientpres[clientUserId][oldTeamNumber] = player:GetResources()
        end

        -- Update frozen state of player based on the game state and player team.
        if team == self.team1 or team == self.team2 then

            local devMode = Shared.GetDevMode()
            local inCountdown = self:GetGameState() == kGameState.Countdown
            if not devMode and inCountdown then
                newPlayer.frozen = true
            end

            local pres = self.clientpres[clientUserId] and self.clientpres[clientUserId][newTeamNumber]
            newPlayer:SetResources( pres or ConditionalValue(team == self.team1, kMarineInitialIndivRes, kAlienInitialIndivRes) )

        else

            -- Ready room or spectator players should never be frozen
            newPlayer.frozen = false

        end


        newPlayer:TriggerEffects("join_team")

        if success then

            local newPlayerClient = Server.GetOwner(newPlayer)
            if oldPlayerWasSpectating then
                newPlayerClient:SetSpectatingPlayer(nil)
            end

            if newPlayer.OnJoinTeam then
                newPlayer:OnJoinTeam()
            end

            if newTeamNumber == kTeam1Index or newTeamNumber == kTeam2Index then
                self.playerRanking:SetEntranceTime( newPlayer, newTeamNumber )
            elseif oldTeamNumber == kTeam1Index or oldTeamNumber == kTeam2Index then
                self.playerRanking:SetExitTime( newPlayer, oldTeamNumber )
                if oldPlayerWasCommander then
                    self.playerRanking:SetCommanderExitTime( player, oldTeamNumber )
                end
            end

            if newTeamNumber == kSpectatorIndex then
                newPlayer:SetSpectatorMode(kSpectatorMode.Overhead)
                newPlayer:SetIsSpectator(true)
            else
                --remove player from spectator list
                if newPlayer:GetIsSpectator() then
                    newPlayer:SetIsSpectator(false)
                end
            end

            Server.SendNetworkMessage(newPlayerClient, "SetClientTeamNumber", { teamNumber = newPlayer:GetTeamNumber() }, true)

            if not client:GetIsVirtual() then       --------------------------------------Don't work on nonvirtual
                self.botTeamController:UpdateBots()
            end
        end

        return success, newPlayer

    end

    -- Return old player
    return success, player

end