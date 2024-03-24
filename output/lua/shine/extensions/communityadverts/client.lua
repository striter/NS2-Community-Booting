local Plugin = ...

function Plugin:Initialise()
    return true
end

Shine.HookNetworkMessage( "Shine_Announcement", function( Message )
    local title = Message.identity
    local message = Message.message

    if CNPersistent.announcementIdentity ~= title then
        CNPersistent.announcementIdentity = title
        CNPersistentSave()

        CreateGUIObject("NS2CNLocalizeSelection", GUIMenuPopupSimpleMessage, nil,
            {
                title = title,
                message = message,
                buttonConfig ={ GUIPopupDialog.OkayButton},
            })
    end

end )
