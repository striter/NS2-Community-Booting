
if Server then
    function Gamerules:GetCanJoinPlayingTeam(player)
        if player:GetIsSpectator() then

            local numClients = Server.GetNumClientsTotal()
            local numSpecs = Server.GetNumSpectators()

            local numPlayer = numClients - numSpecs
            local maxPlayers = Server.GetMaxPlayers()
            local numRes = Server.GetReservedSlotLimit()

            --check for empty player slots excluding reserved slots
            --if numPlayer >= maxPlayers then
            --    Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            --    return false
            --end

            --check for empty player slots including reserved slots
            --local userId = player:GetSteamId()
            --local hasReservedSlot = GetHasReservedSlotAccess(userId)
            --if numPlayer >= (maxPlayers - numRes) and not hasReservedSlot then
            --    Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(3), true)
            --    return false
            --end
        end

        return true
    end
--    
--    function Gamerules:GetCanJoinPlayingTeam(player)
--        if player:GetIsSpectator() then
--            return self:JoinPlayingTeamValidation(player)
--        end
--
--        return true
--    end
end 