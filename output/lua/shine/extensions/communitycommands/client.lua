local Plugin = ...

function Plugin:Initialise()
    Shine.Hook.Add( "PlayerKeyPress","LocalizeSelection", function()
        Shine.Hook.Remove( "PlayerKeyPress", "LocalizeSelection" )
        
        if not CNPersistent then return end
        if CNPersistent.forceLocalization ~= nil then return end
        local playerName = GetNickName()
        CreateGUIObject("NS2CNLocalizeSelection", GUIMenuPopupSimpleMessage, nil,
                {
                    title = "物竞天择2中文社区 - NS2CN",
                    message = string.format("你好 <%s>!\n欢迎加入[物竞天择2中文社区]服务器!\n看起来你是第一次加入社区服务器.\n请选择你的语言偏好.\nHello <%s>!\nWelcome to [NS2CN] Community Server!\nIts your first time join our Server.\nPlease select your language.\nTips: Rejoin required to get menu re-translate",playerName,playerName),
                    escDisabled = true,
                    buttonConfig =
                    {
                        {
                            name = "Chinese",
                            params =
                            {
                                label = "中文用户点我",
                            },
                            callback = function(popup)
                                SetLocalize(true)
                                popup:Close()
                            end,
                        },
                        {
                            name = "English",
                            params =
                            {
                                label = "I prefer English",
                            },
                            callback = function(popup)
                                SetLocalize(false)
                                popup:Close()
                            end,
                        }
                    },
                    
                })
    end )
end

Shine.HookNetworkMessage( "Shine_PopupWarning", function( Message )
    CreateGUIObject("PopupWarning", GUIMenuPopupSimpleMessage, nil,
            {
                title = Locale.ResolveString("WARNING"),
                message = Message.Message,
                escDisabled = true,
                buttonConfig =
                {
                    GUIPopupDialog.OkayButton,
                },
            })
end )
