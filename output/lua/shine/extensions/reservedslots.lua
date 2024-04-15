--[[
	Reserved slots.

	The huzzah UWE gave us a proper connection event edition.
]]

local Shine = Shine

local Floor = math.floor
local GetNumClientsTotal = Server.GetNumClientsTotal
local GetNumPlayersTotal = Server.GetNumPlayersTotal
local GetMaxPlayers = Server.GetMaxPlayers
local GetMaxSpectators = Server.GetMaxSpectators
local Max = math.max
local Min = math.min
local tonumber = tonumber

local Plugin = Shine.Plugin( ... )
Plugin.Version = "2.2"

Plugin.HasConfig = true
Plugin.ConfigName = "ReservedSlots.json"

Plugin.SlotType = table.AsEnum{
	"PLAYABLE", "ALL"
}

Plugin.DefaultConfig = {
	-- How many slots?
	Slots = 2,
	-- Should a player with reserved access use up a slot straight away?
	TakeSlotInstantly = true,
	-- Which type(s) of slot should be reserved?
	SlotType = Plugin.SlotType.PLAYABLE,

	DynamicSlot = {
		Count = 0,
		SlotDelta = 2,
	},
	SkillByPassRange = {-1,-1},
}

Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

do
	local Validator = Shine.Validator()
	Validator:AddFieldRule( "SlotType", Validator.InEnum( Plugin.SlotType, Plugin.SlotType.PLAYABLE ) )
	Validator:AddFieldRule( "DynamicSlot",  Validator.IsType( "table", Plugin.DefaultConfig.DynamicSlot  ))
	Validator:AddFieldRule( "SkillByPassRange",  Validator.IsType( "table", Plugin.DefaultConfig.SkillByPassRange  ))
	Plugin.ConfigValidator = Validator
end
local LocalRankPath = "config://shine/temp/history_rank.json"

function Plugin:Initialise()
	self.Config.Slots = Max( Floor( tonumber( self.Config.Slots ) or 0 ), 0 )
	self:SetReservedSlotCount( self:GetFreeReservedSlots() )

	self:CreateCommands()
	self.Enabled = true

	local File, Err = Shine.LoadJSONFile(LocalRankPath)
	self.HistoryRank = File or {}

	return true
end

function Plugin:OnCommunityDBReceived(rawTable)
	for k,v in pairs(rawTable) do
		local lastSeenSkill = v.lastSeenSkill
		if lastSeenSkill then
			self.HistoryRank[tostring(k)] = tonumber(v.lastSeenSkill)
		end
	end

	local Success, Err = Shine.SaveJSONFile( self.HistoryRank, LocalRankPath)
	if not Success then
		Shared.Message( "Error saving history rank file: "..Err )
	end
end

function Plugin:OnFirstThink()
	self:SetReservedSlotCount( self:GetFreeReservedSlots() )
end

function Plugin:CreateCommands()
	local function SetSlotCount(Client, _slotCount, _dynamicSlotCount)
		self.Config.Slots = _slotCount
		self.Config.DynamicSlot.Count = _dynamicSlotCount
		self:SetReservedSlotCount( self:GetFreeReservedSlots() )
		self:SaveConfig()
		Shine:AdminPrint( Client, "%s set reserved slot count to %i", true,
				Shine.GetClientInfo( Client ), _slotCount)
	end
	self:BindCommand( "sh_setresslots", "resslots", SetSlotCount )
		:AddParam{ Type = "number", Min = 0, Round = true, Error = "Please specify the number of slots to set.", Help = "静态预留位" }
		:AddParam{ Type = "number", Min = 0, Round = true,Default = 0 ,Help = "动态预留位"}
		:Help( "设置服务器的预留位 ,普通位为可玩总数-预留位 - 动态预留位,动态预留位随着服务器内人数自动调整直至归零) 例!resslots 10 16" )
end

function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam )
	if OldTeam == kSpectatorIndex or NewTeam == kSpectatorIndex then
		-- Update reserved slot count whenever spectators are added or removed.
		self:SetReservedSlotCount( self:GetFreeReservedSlots() )
	end
end

do
	local function IsSpectator( Client ) return Client:GetIsSpectator() end

	function Plugin:GetNumOccupiedReservedSlots()
		local Clients, Count = Shine:GetClientsWithAccess( "sh_reservedslot" )
		if self.Config.SlotType == self.SlotType.ALL then
			-- When reserving all slots, the slot type a
			-- reserved player is in doesn't matter.
			return Count
		end

		local NumInSpectate = Shine.Stream( Clients )
								   :Filter( IsSpectator )
								   :GetCount()
		-- For reserved player slots, only count those not in spectator slots.
		return Count - Min( NumInSpectate, self:GetMaxSpectatorSlots() )
	end
end

function Plugin:GetFreeReservedSlots()
	-- If considering all slots, then the reserved slot count is offset by the
	-- number of spectator slots to produce the number of reserved playable slots.
	local Offset = self.Config.SlotType == self.SlotType.ALL
			and self:GetMaxSpectatorSlots() or 0

	local slotCount = self.Config.Slots

	local dynamicSlotCount = self.Config.DynamicSlot.Count
	if dynamicSlotCount > 0 then

		local clientsTotal = Server.GetNumClientsTotal()
		local minPlayerCount = GetMaxPlayers() + GetMaxSpectators() - slotCount - dynamicSlotCount
		local delta = clientsTotal - minPlayerCount
		local slotReduction = math.Clamp(delta + self.Config.DynamicSlot.SlotDelta,0,dynamicSlotCount)
		dynamicSlotCount = dynamicSlotCount - slotReduction
		slotCount = slotCount + dynamicSlotCount
	end

	if not self.Config.TakeSlotInstantly then
		return Max( slotCount - Offset, 0 )
	end

	local Count = self:GetNumOccupiedReservedSlots()
	return Max( slotCount - Count - Offset, 0 )
end

--[[
	Set the number of reserved slots for the server browser/NS2 code.
]]
function Plugin:SetReservedSlotCount( NumSlots )
	Server.SetReservedSlotLimit( NumSlots )
end

function Plugin:GetRealPlayerCount()
	-- This includes the connecting player for whatever reason...
	return GetNumPlayersTotal() - 1
end

function Plugin:GetRealClientCount()
	return GetNumClientsTotal() - 1
end

function Plugin:GetMaxPlayers()
	return GetMaxPlayers()
end

function Plugin:GetMaxSpectatorSlots()
	return GetMaxSpectators()
end

local function RangeValid(range)
	return range[1] >= 0 or range[2] >= 0
end

local function InRange(range,value)
	if range[1] > 0 and range[2] > 0 then
		return range[1] <= value and value <= range[2]
	end

	if range[1] < 0 and range[2] > 0 then
		return value <= range[2]
	end

	if range[1] > 0 and range[2] < 0 then
		return range[1] <= value
	end

	return true
end

local function RangeString(range)
	if range[1] > 0 and range[2] > 0 then
		return string.format("[%s-%s]",range[1],range[2])
	end

	if range[1] < 0 and range[2] > 0 then
		return string.format("[<=%s]",range[2])
	end

	if range[1] > 0 and range[2] < 0 then
		return string.format("[>=%s]",range[1])
	end

	return "无限制"
end

function Plugin:HasReservedSlotAccess( Client )
	if RangeValid(self.Config.SkillByPassRange) and InRange(self.Config.SkillByPassRange, self.HistoryRank[tostring(Client)] or 0) then
		return true
	end

	return Shine:HasAccess( Client, "sh_reservedslot" )
end

function Plugin:ClientConnect( Client )
	self:SetReservedSlotCount( self:GetFreeReservedSlots() )
end

--[[
	Update the number of free slots if a client who had reserved slot access
	disconnects, and we take slots instantly.
]]
function Plugin:ClientDisconnect( Client )
	self:SetReservedSlotCount( self:GetFreeReservedSlots() )
end

Plugin.ConnectionHandlers = {
	-- Consumes playable slots only. Spectator slots are handled entirely by the default handler.
	[ Plugin.SlotType.PLAYABLE ] = function( self, ID )
		local NumPlayers = self:GetRealPlayerCount()
		local MaxPlayers = self:GetMaxPlayers()

		local Slots = self.Config.Slots

		-- Deduct reserved slot users from the number of reserved slots empty.
		if self.Config.TakeSlotInstantly then
			Slots = self:GetFreeReservedSlots()
			self:SetReservedSlotCount( Slots )
		end

		-- Allow if there's less players than public slots.
		if NumPlayers < MaxPlayers - Slots then
			return true
		end

		-- Allow if they have reserved access and we're not full.
		if NumPlayers < MaxPlayers and self:HasReservedSlotAccess( ID ) then
			return true
		end

		-- Here either they have reserved slot access but the server is full,
		-- or they don't have reserved slot access and there's no free public slots.
		-- Thus, fall through to the default NS2 behaviour which handles spectator slots.
	end,
	-- Consumes all slots, spectator slots will be blocked if they are reserved.
	[ Plugin.SlotType.ALL ] = function( self, ID )
		local NumClients = self:GetRealClientCount()
		local MaxClients = self:GetMaxPlayers() + self:GetMaxSpectatorSlots()

		local Slots = self.Config.Slots

		-- Deduct reserved slot users from the number of reserved slots empty.
		if self.Config.TakeSlotInstantly then
			self:SetReservedSlotCount( self:GetFreeReservedSlots() )
			-- The reserved slot count only applies to playable slots, this includes
			-- spectator slots.
			Slots = Max( Slots - self:GetNumOccupiedReservedSlots(), 0 )
		end

		-- If only spectator slots are free, then the default handler needs to run
		-- to assign them to a spectator slot properly.
		local ALLOWED
		local ShouldFallThrough = self:GetRealPlayerCount() >= self:GetMaxPlayers()
		if not ShouldFallThrough then
			ALLOWED = true
		end

		-- Allow if all slots have not yet been filled.
		if NumClients < MaxClients - Slots then
			return ALLOWED
		end

		-- Allow if they have reserved access and we're not full.
		local HasSlots = NumClients < MaxClients
		if HasSlots and self:HasReservedSlotAccess( ID ) then
			return ALLOWED
		end

		-- Deny entirely if the server is completely full or they have no
		-- reserved slot access and only reserved slots are left.

		local denyReason = HasSlots and "请获取预留位.\nSlot is reserved." or "服务器已满.\nServer full."
		if RangeValid(self.Config.SkillByPassRange) then
			local rangeString = RangeString(self.Config.SkillByPassRange)
			denyReason = string.format("%s分段可获本服预留位.\nSlot reserved for specific skill players.",rangeString)
		end

		return false, denyReason
	end
}

--[[
	Checks the given NS2ID to see if it has reserved slot access.

	If they do, or if the server has enough free non-reserved slots, they are allowed in.
	If the client will be assigned to a spectator slot, then this will defer to the default
	handler.
]]
function Plugin:CheckConnectionAllowed( ID )
	return self.ConnectionHandlers[ self.Config.SlotType ]( self, tonumber( ID ) )
end


return Plugin
