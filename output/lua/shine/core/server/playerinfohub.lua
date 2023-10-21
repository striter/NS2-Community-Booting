--[[
	Shine PlayerInfoHub
]]
local Shine = Shine

local StringFormat = string.format
local JsonDecode = json.decode

Shine.PlayerInfoHub = {}
local PlayerInfoHub = Shine.PlayerInfoHub
PlayerInfoHub.SteamData = {}

local Queue = {}
local current = 0
local last = 0
local working = false

local function ProcessQueue()
	PROFILE("PlayerInfoHub:ProcessQueue()")
	working = true
	current = current + 1

	local node = Queue[current]

	local function OnSuccess( Response )
		node[2](Response)

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	local function OnTimeout()
		if node[3] then
			node[3]()
		end

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	Shine.TimedHTTPRequest(node[1], "GET", OnSuccess, OnTimeout, 20)
end

local function AddToHTTPQueue( Address, OnSuccess, OnTimeout)
	last = last + 1
	Queue[last] = {
		Address,
		OnSuccess,
		OnTimeout
	}

	if not working then ProcessQueue() end
end

function PlayerInfoHub:OnConnect( Client )
	PROFILE("PlayerInfoHub:OnConnect()")
	if not Shine:IsValidClient( Client ) then return end

	local SteamId = Client:GetUserId()
	if not SteamId or SteamId <= 0 then return end

	local SteamId64 = StringFormat( "%s%s", 76561, SteamId + 197960265728 )

	local steamData = PlayerInfoHub:GetSteamData(SteamId)

	--[[
	-- Status:
	 - -2 = Fetching
	 - -1 = Timeout
	 ]]
	if steamData.Validated then return end
	steamData.Validated = true
	
	AddToHTTPQueue( StringFormat( "http://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=372C1D52A38C8F6685153E2D87EDE66F&SteamId=%s&appids_filter[0]=4920", SteamId64 ), function( Response )
		local returnVal = JsonDecode( Response )
		returnVal = returnVal and returnVal.response and returnVal.response.games and returnVal.response.games[1]
		if not returnVal then
			steamData.PlayTime = -2
			return
		else
			steamData.PlayTime = returnVal.playtime_forever and returnVal.playtime_forever / 60 or 0
			local player = GetPlayerFromUserId(SteamId)
			if player then
				player:SetSteamData(steamData)
			end
		end
	end,nil )
end

function PlayerInfoHub:SetCommunityData(steamId,data)
	Shared.SendHTTPRequest(string.format("http://127.0.0.1:3000/users/%s",steamId),"POST",{mtd = "DELETE"})		--Try delete previous onee

	data.id = steamId
	Shared.SendHTTPRequest("http://127.0.0.1:3000/users","POST",data		--Pop a new one
			--,function(response)
			--	Print("response: " .. response )
			--end
	)
end

function PlayerInfoHub:GetCommunityData(steamId,onSuccessfulCallBack)
	local queryURL = StringFormat( "http://127.0.0.1:3000/users/%s" ,steamId )
	AddToHTTPQueue( queryURL, function( response,errorCode )
		local returnVal = JsonDecode(response)
		if not returnVal or not returnVal.id then return end
		onSuccessfulCallBack(returnVal) 
	end,nil )
end

Shine.Hook.Add( "ClientConnect", "GetPlayerInfo", function( Client )
	PlayerInfoHub:OnConnect( Client )
end )

function PlayerInfoHub:GetSteamData( SteamId )
	if not self.SteamData[ SteamId ] then
		self.SteamData[ SteamId ] = {Validated = false, PlayTime = -1}
	end
	return self.SteamData[ SteamId ]
end