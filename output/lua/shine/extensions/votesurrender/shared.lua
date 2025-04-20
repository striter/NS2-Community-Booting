--[[
	Vote surrender shared.
]]

local Plugin = Shine.Plugin( ... )
Plugin.EnabledGamemodes = Shine.kNS2EnabledGameMode

function Plugin:SetupDataTable()
	self:AddDTVar( "integer", "ConcedeTime", kMinTimeBeforeConcede )
end

return Plugin
