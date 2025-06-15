local function Vote(self,prefer)
    self.votedYes = prefer
    self.timeLastVoted = Shared.GetTime()
    SendVoteChoice(prefer)
end


local function UpdateSizeOfUI(self, screenWidth, screenHeight)
    local titleFontName = Fonts.kAgencyFB_Small
    self.tipsText:SetFontName(titleFontName)
    self.tipsText:SetScale(GetScaledVector())
    self.tipsText:SetPosition(GUIScale(Vector(4, 14, 0)))
end

local kNoTextColor = Color(0.6, 0, 0, 1)
local baseOnInitialize = GUIVoteMenu.Initialize
function GUIVoteMenu:Initialize()
    baseOnInitialize(self)

    self.tipsText = GUIManager:CreateTextItem()
    self.tipsText:SetColor(kNoTextColor)
    self.tipsText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.tipsText:SetTextAlignmentX(GUIItem.Align_Min)
    self.tipsText:SetTextAlignmentY(GUIItem.Align_Min)
    self.tipsText:SetText("提示")
    self.noBackground:AddChild(self.tipsText)

    UpdateSizeOfUI(self, Client.GetScreenWidth(), Client.GetScreenHeight())
end


local baseOnUninitialize = GUIVoteMenu.Uninitialize
function GUIVoteMenu:Uninitialize()
    baseOnUninitialize(self)
    GUI.DestroyItem(self.tipsText)
    self.tipsText = nil
end

function GUIVoteMenu:SendKeyEvent(key, down)

    --if down and self.votedYes == nil and voteId ~= self.lastVotedId and voteId > 0 then

    local currentVoteId = GetCurrentVoteId()

    if currentVoteId <= 0 then return false end

    --if self.votedYes == nil and GetOnlyAcceptedResults() then
    --    local team = Client.GetLocalPlayer():GetTeamNumber()
    --    if team ~= kTeam1Index and team ~=kTeam2Index then
    --        Vote(self,true)
    --        return false
    --    end
    --end

    if down then
        if self.timeLastVoted and Shared.GetTime() - self.timeLastVoted < 0.5 then
            return false
        end

        if GetIsBinding(key, "VoteYes") then
            Vote(self,true)
            return true
        elseif GetIsBinding(key, "VoteNo") then
            Vote(self,false)
            return true
        end
    end

    return false
end

local baseUpdate = GUIVoteMenu.Update
function GUIVoteMenu:Update(deltaTime)

    PROFILE("GUIVoteMenu:Update")
    baseUpdate(self,deltaTime)

    if self.visible and GetCurrentVoteQuery() ~= nil then
        local data = GetActiveVoteData()
        local tipsText = nil
        if data.onlyAccepted then
            if self.yesText and self.noText then

                if data.failReward ~= nil and data.failReward > 0 then
                    local yes, no, required = GetVoteResults()
                    local failReward = math.ceil(data.failReward * 10) / 10
                    self.yesText:SetText(string.format(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_FAIL_REWARD_YES"),  GetPrettyInputName("VoteYes"),failReward ))
                    self.noText:SetText(string.format(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_FAIL_REWARD_NO"), GetPrettyInputName("VoteNo") ))
                    if not self.votedYes then
                        self.yesCount:SetText(string.format(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_FAIL_REWARD_REQUIREMENT"), required))
                    end
                    tipsText = Locale.ResolveString("VOTE_AFFECT_ACCEPTED_FAIL_REWARD_TIPS")
                else
                    self.yesText:SetText(StringReformat(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_YES"), { key = GetPrettyInputName("VoteYes") }))
                    self.noText:SetText(StringReformat(Locale.ResolveString("VOTE_AFFECT_ACCEPTED_NO"), { key = GetPrettyInputName("VoteNo") }))
                end
            end
            
        end
        self.noCount:SetIsVisible(not data.onlyAccepted)
        self.tipsText:SetIsVisible(tipsText ~= nil)
        if tipsText then
            self.tipsText:SetText(tipsText)
        end
    end
end