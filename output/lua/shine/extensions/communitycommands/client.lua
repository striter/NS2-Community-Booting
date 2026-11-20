local Plugin = ...

Shine.HookNetworkMessage( "Shine_PopupWarning", function( Message )
    CreateGUIObject("PopupWarning", GUIMenuPopupSimpleMessage, nil,
            {
                title = Locale.ResolveString("WARNING"),
                message = Message.Message,
                buttonConfig =
                {
                    GUIPopupDialog.OkayButton,
                },
            })
end )
