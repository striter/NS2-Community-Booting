
ModLoader.SetupFileHook( "lua/Globals.lua", "lua/CNTiny/Globals.lua", "post")
ModLoader.SetupFileHook( "lua/ReadyRoomPlayer.lua", "lua/CNTiny/ReadyRoomPlayer.lua", "post" )
ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/CNTiny/ServerAdminCommands.lua", "post" )
ModLoader.SetupFileHook( "lua/WallMovementMixin.lua", "lua/CNTiny/WallMovementMixin.lua", "post" )
ModLoader.SetupFileHook( "lua/CrouchMoveMixin.lua", "lua/CNTiny/CrouchMoveMixin.lua", "post" )

ModLoader.SetupFileHook( "lua/Spectator.lua", "lua/CNTiny/Spectator.lua", "replace")
ModLoader.SetupFileHook( "lua/Player.lua", "lua/CNTiny/Player.lua", "post" )
ModLoader.SetupFileHook( "lua/Marine.lua", "lua/CNTiny/Marine.lua", "post" )
ModLoader.SetupFileHook( "lua/Prowler/Prowler.lua", "lua/CNTiny/Prowler.lua", "post" )