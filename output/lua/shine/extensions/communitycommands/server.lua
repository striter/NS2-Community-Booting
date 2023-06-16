
local Plugin = ...

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

    self:BindCommand("sh_kill","kill",KillSelf,true):Help( "不活了." )
    
    local function StunTarget(_client, _duration)
        local player = _client:GetControllingPlayer()
        if player and HasMixin(player, "Stun") and player:GetCanDie() then
            player:SetStun(_duration)
        end
    end
    self:BindCommand("sh_stun","stun", StunTarget,true):
    AddParam{ Type = "number", Help = "睡觉时间", Round = true, Min = 1, Max = 30, Optional = true, Default = 5 }:
    Help( "开始睡觉(仅陆战队可用).")

    self:BindCommand("sh_stun_set","stun_set",function(_client, _targetClient,_duration) StunTarget(_targetClient,_duration) end,false):
    AddParam{ Type = "client"}:
    AddParam{ Type = "number", Help = "睡觉时间", Round = true, Min = 1, Max = 30, Optional = true, Default = 5 }:
    Help( "强制睡觉(仅陆战队可用)." )
    
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

    self:BindCommand( "sh_scale", "scale", AdminScalePlayer )
    :AddParam{ Type = "client" }
    :AddParam{ Type = "number", Round = false, Min = 0.1, Max = 5, Optional = true, Default = 0.5 }
    :Help( "设置ID对应玩家的大小." )

    local function AdminSetAllScale( _client, scale )
        for client in Shine.IterateClients() do
            local player = client:GetControllingPlayer()
            if not player.SetScale then return end
            player:SetScale(scale)
		end

        Shine:AdminPrint( nil, "%s set all scale to %s", true,  Shine.GetClientInfo( _client ), scale )
	end

    self:BindCommand( "sh_scale_all", "scale_all", AdminSetAllScale )
    :AddParam{ Type = "number", Round = false, Min = 0.1, Max = 5, Optional = true, Default = 0.5 }
    :Help( "设置所有玩家的大小." )

    local function SwitchLocalize(_client)
        Server.SendNetworkMessage(_client, "SwitchLocalize", {},true)
    end
    self:BindCommand("sh_localize","localize",SwitchLocalize,true)
        :Help( "Switch your localize mode,Rejoin required. 需要中文汉化的话请勿用(该操作将切换插件强制汉化状态)" )
    
    local function WarnPopup(_client,_target,_message)
        if not _target or _target:GetIsVirtual() then return end
        Shine.SendNetworkMessage(_target, "Shine_PopupWarning", {Message = _message},true)
    end
    self:BindCommand("sh_warn_popup","warn_popup",WarnPopup)
            :AddParam{ Type = "client" }
            :AddParam{ Type = "string",Optional = true, TakeRestOfLine = true, Default = "不当的言行将会对他人造成严重影响!\n请注意你的行为!" }
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
end