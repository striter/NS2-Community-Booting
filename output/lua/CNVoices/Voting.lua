--Server Switch
RegisterVoteType("VoteDisease", {})

if Client then

    local function SetupAdditionalVotes(voteMenu)

        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_DISEASE"), nil, function(msg)
            AttemptToStartVote("VoteDisease", {})
        end)

        AddVoteStartListener("VoteDisease", function(msg)
            return Locale.ResolveString("VOTE_DISEASE_QUERY" .. tostring(math.random(1, 10)))
        end)
    end
    AddVoteSetupCallback(SetupAdditionalVotes)

end

if Server then
    SetVoteSuccessfulCallback("VoteDisease", 3, function(msg)
        -- Shared.Message(msg.name .. " " .. msg.ip)
        Server.SendNetworkMessage("RandomDisease", {  }, true)
    end)
end