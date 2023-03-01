
if Server then
    function Gamerules:JoinPlayingTeamValidation(player)

        local numClients = Server.GetNumClientsTotal()
        local numSpecs = Server.GetNumSpectators()

        local numPlayer = numClients - numSpecs
        local maxPlayers = Server.GetMaxPlayers()
        ----
        local activePlayers = maxPlayers
        if Shine then
            local ETPlugin = Shine.Plugins["enforceteamsizes"]
            if ETPlugin and ETPlugin.Enabled then
                activePlayers = ETPlugin:GetMaxPlayers(self)
            end
        end
        ----

        local numRes = Server.GetReservedSlotLimit()

        Shared.Message(tostring(numPlayer) .. " " .. tostring(activePlayers))

        --check for empty player slots excluding reserved slots
        if numPlayer >= activePlayers then
            Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            return false
        end

        --check for empty player slots including reserved slots
        local userId = player:GetSteamId()
        local hasReservedSlot = GetHasReservedSlotAccess(userId)
        if numPlayer >= (maxPlayers - numRes) and not hasReservedSlot then
            Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            return false
        end
        return true
    end
    
    function Gamerules:GetCanJoinPlayingTeam(player)
        if player:GetIsSpectator() then
            return self:JoinPlayingTeamValidation(player)
        end

        return true
    end
end 