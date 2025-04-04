
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
	local function AdminScalePlayer( _client, _target, scale )
        local player = _target:GetControllingPlayer()
        if not player or not player.SetScale then return end
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


    local kFlipPrefixColor = { 235, 152, 78 }
    local function FlipCoin(_client)
        local value = math.random()
        local player = _client:GetControllingPlayer()
        Shine:NotifyDualColour( nil, kFlipPrefixColor[1], kFlipPrefixColor[2], kFlipPrefixColor[3],"[提示]",255, 255, 255,
                string.format("%s投出了一枚硬币,结果为-%s", player:GetName(),value < 0.5 and "正面" or "反面"))

        Shine.SendNetworkMessage(nil, "Shine_PopupWarning", {Message = _message},true)
    end
    self:BindCommand("sh_flip","flip",FlipCoin)
            :Help( "抛出一枚硬币,并告知所有人结果." )


    local function LoginCommander(commandStructure, client)
        local player = client and client:GetControllingPlayer()

        if commandStructure and player and commandStructure:GetIsBuilt() then

            -- make up for not manually moving to CS and using it
            commandStructure.occupied = not client:GetIsVirtual()

            player:SetOrigin(commandStructure:GetDefaultEntryOrigin())

            commandStructure:LoginPlayer( player, true )
        else
            if player then
                Log("%s| Failed to Login commander[%s - %s(%s)] on ResetGame", self:GetClassName(), player:GetClassName(), player:GetId(),
                        client:GetIsVirtual() and "BOT" or "HUMAN"
                )
            end
        end
    end

    self:BindCommand( "sh_commforce", "commforce", function(_client,_target)
        if _target:GetIsVirtual() then
            Shine:NotifyError(_client,"无法对机器人使用该指令.")
            return
        end

        local player = _target:GetControllingPlayer()
        local teamNumber = player:GetTeamNumber()
        if teamNumber == kSpectatorIndex or teamNumber == kTeamReadyRoom then
            Shine:NotifyError(_client,"无法对非战局内玩家食用该指令.")
            return
        end

        local workingCommandStructure
        local commandStructures = GetEntitiesForTeam("CommandStructure", teamNumber)
        for _, commandStructure in ipairs(commandStructures) do
            if commandStructure.occupied then
                workingCommandStructure = commandStructure
                break
            end
        end

        if not workingCommandStructure then
            workingCommandStructure = GetEntitiesForTeam("CommandStructure", teamNumber)[1]
        end

        if not workingCommandStructure then
            Shine:NotifyError(_client,"无法找到队伍内的活跃指挥站.")
            return
        end

        local targetCommander = GetCommanderForTeam(teamNumber)
        if targetCommander and targetCommander.Eject then
            targetCommander:Eject()
        end


        if workingCommandStructure then
            LoginCommander(workingCommandStructure,_target)
        end
    end )
        :AddParam{ Type = "client" }
        :Help( "强制该玩家成为队伍指挥,并将已有指挥踢出.")
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
end