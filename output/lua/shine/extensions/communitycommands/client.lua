local Plugin = ...

function Plugin:Initialise()
    Shine.Hook.Add( "PlayerKeyPress","LocalizeSelection", function()
        Shine.Hook.Remove( "PlayerKeyPress", "LocalizeSelection" )
        
        if not CNPersistent then return end
        
        if CNPersistent.forceLocalize == nil then       --Select Localization

            local playerName = GetNickName()
            CreateGUIObject("NS2CNLocalizeSelection", GUIMenuPopupSimpleMessage, nil,
                    {
                        title = "物竞天择2中文社区 - NS2CN",
                        message = string.format("你好 <%s>!\n欢迎加入[物竞天择2中文社区]服务器!\n看起来你是第一次加入社区服务器.\n请选择你的语言偏好.\nHello <%s>!\nWelcome to [NS2CN] Community Server!\nIts your first time join our Server.\nPlease select your language.",playerName,playerName),
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
                                    Locale.SetLocalize(true)
                                    popup:Close()
                                    ChatUI_AddSystemMessage("不要忘记看一看位于主菜单底部的<社区指南>!")
                                end,
                            },
                            {
                                name = "English",
                                params =
                                {
                                    label = "I prefer English",
                                },
                                callback = function(popup)
                                    Locale.SetLocalize(false)
                                    popup:Close()
                                    ChatUI_AddSystemMessage("Rejoin/Reconnect required to get menu re-translate.\nThen you can check our <Community Guide> located at Main Menu Bottom!")
                                end,
                            }
                        },

                    })
            return
        end

    end )
end

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
