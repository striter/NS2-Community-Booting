--[[
	Shine admin server-side startup.
	Loads stuff.
]]

local Scripts = {
	"core/shared/misc.lua",
	"lib/player.lua",
	"lib/timer.lua",
	"lib/datatables.lua",
	"lib/query.lua",
	"core/shared/config.lua",
	"core/shared/logging.lua",
	"core/server/permissions.lua",
	"core/shared/commands.lua",
	"core/server/commands.lua",
	"core/server/logging.lua",
	"core/shared/system_notifications.lua",
	"core/server/config.lua",
	"core/shared/chat.lua",
	"core/server/chat.lua",
	"core/shared/webpage.lua",
	"lib/screentext/sh_screentext.lua",
	"lib/screentext/sv_screentext.lua",
	"core/shared/adminmenu.lua",
	"core/server/playerinfohub.lua",
	"core/shared/votemenu.lua",
	"core/server/votemenu.lua",
	"core/shared/autocomplete.lua"
}

Server.AddRestrictedFileHashes( "lua/shine/lib/gui/*.lua" )

local tmpDate = os.date("*t", Shared.GetSystemTime())
kCurrentYear = tmpDate.year
kCurrentMonth = tmpDate.month
kCurrentDay = tmpDate.day
kCurrentHour = tmpDate.hour
kCurrentHourFloat = kCurrentHour + tmpDate.min / 60

Shine.BaseGamemode = "ns2"
Shine.kRankGameMode = { "ns2", "NS2.0", "Siege+++"  }
Shine.kSeedingGameMode = {"Defense2.0","Combat"}

Shine.LoadScripts( Scripts )

Shine:Print( "Shine started up successfully." )
Shine:SaveLog()
