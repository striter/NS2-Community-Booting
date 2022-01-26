Script.Load("lua/CNLocalize/CNStrings.lua")
local baseResolveString = Locale.ResolveString

function CNLocalizeResolve(input)
    if not input then return "" end

    local resolvedString = rawget(kTranslateMessage,input) 
    if resolvedString  then
        return resolvedString
    end

    return baseResolveString(input)
end

Locale.ResolveString = CNLocalizeResolve

Script.Load("lua/CNLocalize/CNLocations.lua")
function CNResolveLocation(input)
    local locationName=kTranslateLocations[input]
    if not locationName then
        Shared.Message("Location:{" .. input .. "} Untranslated")
        locationName=input
    end
    return locationName
end
Locale.ResolveLocation = CNResolveLocation

ModLoader.SetupFileHook("lua/GUIMinimap.lua", "lua/CNLocalize/GUIMinimap.lua", "post")



Script.Load("lua/CNLocalize/ChatFilters.lua")
function CNChatFilter(input)
    return string.gsub(input, "%w+", kChatFilters) 
end
Locale.ChatFilter = CNChatFilter


if Shine then

    --Default Shines
    Script.Load("lua/CNLocalize/ShineStrings.lua")
    function Shine.Locale:GetLocalisedString( Source, Lang, Key )
        
        local finalValue = rawget(kShineTranslations,Key)
        if finalValue then
            return finalValue
        end
        
        local pluginStrings=  kShinePluginsTranslations[Source]
        if pluginStrings then
            finalValue = rawget(pluginStrings,Key)
            if finalValue then
                return finalValue
            end
        end

        Shared.Message("Shine:|"..Source .. "|".. Key .. "|Untranslated")

        local LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Lang )
        if not LanguageStrings or not LanguageStrings[ Key ] then
            LanguageStrings = Shine.Locale:GetLanguageStrings( Source, Shine.Locale.DefaultLanguage )
        end
        return LanguageStrings and LanguageStrings[ Key ] or Key
    end
    
    --Plugin , Undone
    -- local ETSPlugin = Shine.Plugins["enforceteamsizes"]
    -- if ETSPlugin then
    --     Shared.Message("Enforce Team Size Localize Hooked")
    --     local kETSMessage={}
    --     kETSMessage[1]="边境拓荒者部队 玩家已满,请观战等待空位."
    --     kETSMessage[2]="卡拉异形 玩家已满,请观战等待空位."
    --     kETSMessage[3]="观战 已满,请尽快加入对局."

    --     function ETSPlugin:Notify(Player, Message, OldTeam)
    --         Shine:NotifyDualColour( Player, self.Config.MessageNameColor[1], self.Config.MessageNameColor[2],
    --             self.Config.MessageNameColor[3], "[人数限制]", 255, 255, 255,
    --         Message, true, Shine:GetTeamName(OldTeam, true) )
    --     end

    --     function ETSPlugin:JoinTeam( Gamerules, Player, NewTeam, _, ShineForce )
    --         if self.Config.IgnoreBots and Player:GetIsVirtual() then return end
        
    --         local TeamIndex = string.format("Team%s", NewTeam)
    --         if ShineForce or NewTeam == kTeamReadyRoom or not self.Config.Teams[TeamIndex] then return end
        
    --         --Check if team is above MaxPlayers
    --         if self:GetNumPlayers(Gamerules:GetTeam(NewTeam)) >= self.Config.Teams[TeamIndex].MaxPlayers then
    --             --Inform player
    --             self:Notify(Player, kETSMessage[NewTeam], NewTeam)
    --             return false
    --         end
    --     end
    -- end

    --Chat Filter
    local Plugin = Shine.Plugins["improvedchat"]
    local ChatAPI = require "shine/core/shared/chat/chat_api"

    local ColourElement = require "shine/lib/gui/richtext/elements/colour"
    local ImageElement = require "shine/lib/gui/richtext/elements/image"
    local SpacerElement = require "shine/lib/gui/richtext/elements/spacer"
    local TextElement = require "shine/lib/gui/richtext/elements/text"
    
    local Hook = Shine.Hook
    local SGUI = Shine.GUI
    local Units = SGUI.Layout.Units
    
    local Ceil = math.ceil
    local IsType = Shine.IsType
    local OSDate = os.date
    local RoundTo = math.RoundTo
    local StringFormat = string.format
    local StringFind = string.find
    local TableRemove = table.remove
    local TableRemoveByValue = table.RemoveByValue
    local IntToColour = ColorIntToColor

    local function GetTeamPrefix( Data )
        if Data.LocationID > 0 then
            local Location = Shared.GetString( Data.LocationID )
            if StringFind( Location, "[^%s]" ) then
                return StringFormat( "(队伍, %s) ", Locale.ResolveLocation(Location) )
            end
        end
    
        return "(队伍) "
    end

    -- Overrides the default chat behaviour, adding chat tags and turning the contents into rich text.
    function Plugin:OnChatMessageReceived( Data )
        local Player = Client.GetLocalPlayer()
        if not Player then return true end

        if not Client.GetIsRunningServer() then
            local Prefix = "Chat All"
            if Data.TeamOnly then
                Prefix = StringFormat( "Chat Team %d", Data.TeamNumber )
            end

            Shared.Message( StringFormat( "%s %s - %s: %s", OSDate( "[%H:%M:%S]" ), Prefix, Data.Name, Data.Message ) )
        end

        if Data.SteamID ~= 0 and ChatUI_GetSteamIdTextMuted( Data.SteamID ) then
            return true
        end

        -- Server sends -1 for ClientID if there is no client attached to the message.
        local Entry = Data.ClientID ~= -1 and Shine.GetScoreboardEntryByClientID( Data.ClientID )
        local IsCommander = Entry and Entry.IsCommander and IsVisibleToLocalPlayer( Player, Entry.EntityTeamNumber )
        local IsRookie = Entry and Entry.IsRookie

        local Contents = {}

        local ChatTag = self.ChatTags[ Data.SteamID ]
        if ChatTag and ( not Data.TeamOnly or self.dt.DisplayChatTagsInTeamChat ) then
            if ChatTag.Image then
                Contents[ #Contents + 1 ] = ImageElement( {
                    Texture = ChatTag.Image,
                    AutoSize = DEFAULT_IMAGE_SIZE,
                    AspectRatio = 1
                } )
            end
            Contents[ #Contents + 1 ] = ColourElement( ChatTag.Colour )
            Contents[ #Contents + 1 ] = TextElement( ( ChatTag.Image and " " or "" )..ChatTag.Text.." " )
        end

        if IsCommander then
            Contents[ #Contents + 1 ] = ColourElement( IntToColour( kCommanderColor ) )
            Contents[ #Contents + 1 ] = TextElement( "[指挥] " )
        end

        if IsRookie then
            Contents[ #Contents + 1 ] = ColourElement( IntToColour( kNewPlayerColor ) )
            Contents[ #Contents + 1 ] = TextElement( Locale.ResolveString( "新兵" ).." " )
        end

        local Prefix = "(全局) "
        if Data.TeamOnly then
            Prefix = GetTeamPrefix( Data )
        end

        Prefix = StringFormat( "%s%s: ", Prefix, Data.Name )

        Contents[ #Contents + 1 ] = ColourElement( IntToColour( GetColorForTeamNumber( Data.TeamNumber ) ) )
        Contents[ #Contents + 1 ] = TextElement( Prefix )

        Contents[ #Contents + 1 ] = ColourElement( kChatTextColor[ Data.TeamType ] )
        Contents[ #Contents + 1 ] = TextElement( Locale.ChatFilter( Data.Message ) )

        Hook.Call( "OnChatMessageParsed", Data, Contents )

        return self:AddRichTextMessage( {
            Source = {
                Type = ChatAPI.SourceTypeName.PLAYER,
                ID = Data.SteamID,
                Details = Data
            },
            Message = Contents
        } )
    end

end
