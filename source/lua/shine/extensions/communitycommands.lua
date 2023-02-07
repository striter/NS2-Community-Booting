
local Plugin = Shine.Plugin( ... )

Plugin.HasConfig = true
Plugin.ConfigName = "CommunityCommands.json"
Plugin.DefaultConfig =
{
}


function Plugin:Initialise()
	self:CreateCommands()

	return true
end

function Plugin:CreateCommands()
    --Common commands
    local function KillSelf(_client,scale)
        local player = _client:GetControllingPlayer()
        if player and HasMixin(player, "Live") and player:GetCanDie() then
            player:Kill(player, nil, player:GetOrigin())
        end
    end

    local killCommand = self:BindCommand("sh_kill","kill",KillSelf,true)
    killCommand:Help( "不活了." )

    local function Delocalize(_client)
        Server.SendNetworkMessage(_client, "Delocalize", {},true)
    end
    local delocalizeCommand = self:BindCommand("sh_delocalize","delocalize",Delocalize,true)
    delocalizeCommand:Help( "Get yourself free from brutal injections." )
    
    --Admin comamnds
	local function AdminScalePlayer( _client, _id, scale )
        local target = Shine.GetClientByNS2ID(_id)
        if not target then 
            return 
        end

        local player = target:GetControllingPlayer()
        if not player.SetScale then return end
        player:SetScale(scale)
        Shine:AdminPrint( nil, "%s set %s scale to %s", true,  Shine.GetClientInfo( _client ), Shine.GetClientInfo( target ), scale )
	end

    local setCommand = self:BindCommand( "sh_scale", "scale", AdminScalePlayer )
    setCommand:AddParam{ Type = "steamid" }
    setCommand:AddParam{ Type = "number", Round = false, Min = 0.1, Max = 3, Optional = true, Default = 0.5 }
    setCommand:Help( "设置ID对应玩家的大小." )

    local function AdminSetAllScale( _client, scale )
        for client in Shine.IterateClients() do
            local player = client:GetControllingPlayer()
            if not player.SetScale then return end
            player:SetScale(scale)
		end

        Shine:AdminPrint( nil, "%s set all scale to %s", true,  Shine.GetClientInfo( _client ), scale )
	end

    local setCommand = self:BindCommand( "sh_scale_all", "scale_all", AdminSetAllScale )
    setCommand:AddParam{ Type = "number", Round = false, Min = 0.1, Max = 3, Optional = true, Default = 0.5 }
    setCommand:Help( "设置所有玩家的大小." )

end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
end

return Plugin