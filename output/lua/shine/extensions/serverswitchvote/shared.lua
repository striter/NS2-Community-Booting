--[[
	Server switch shared part.
]]

local Plugin = Shine.Plugin( ... )

function Plugin:SetupDataTable()
	self:AddNetworkMessage( "AddServerList", {
		ID = "integer(0 to 64)",
		Name = "string (64)",
		Address = "string (64)",
		Amount = "integer(0 to 64)",
	}, "Client" )
end

return Plugin