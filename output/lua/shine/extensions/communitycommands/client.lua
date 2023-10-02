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
                                    SetLocalize(true)
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
                                    SetLocalize(false)
                                    popup:Close()
                                    ChatUI_AddSystemMessage("Rejoin/Reconnect required to get menu re-translate.\nThen you can check our <Community Guide> located at Main Menu Bottom!")
                                end,
                            }
                        },

                    })
            return
        end

        --local kNoticeVersion = 1
        --if CNPersistent.noticeVersion ~= kNoticeVersion then
        --    CNPersistent.noticeVersion = kNoticeVersion
        --    CNPersistentSave()
        --    
        --    local title = CNPersistent.forceLocalize and "提示" or "Tips"
        --    local message = CNPersistent.forceLocalize 
        --            and "NS2.0使用了很多额外贴图.\n若近期遇到频繁闪退问题.\n请于[主菜单]->[选项]->[画面]页卡.\n将[GPU显存]调至[Unlimited]." 
        --            or "NS2.0 added tons of custom stuff.\nIf u encounter a lot crashes.\nPlease Try:\n[Main Menu]->[Option]->[Graphics].\nChange [GPU Memory] to [UNLIMITED]"
        --    CreateGUIObject("NS2CNLocalizeSelection", GUIMenuPopupSimpleMessage, nil,
        --        {
        --            title = title,
        --            message = message,
        --            escDisabled = true,
        --            buttonConfig ={ GUIPopupDialog.OkayButton},
        --        })
        --end
        
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
