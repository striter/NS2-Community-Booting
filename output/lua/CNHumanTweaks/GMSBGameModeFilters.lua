-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua/menu2/NavBar/Screens/ServerBrowser/GMSBGameModeFilters.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Widget that displays a list of game modes available to display in the server browser (eg
--    "ns2", "combat", etc.), including an "ALL" button.
--
--  Properties:
--      ModeList        Array of gamemode name strings.  The order in the array will determine the
--                      order of presentation.
--      SelectedModes   UnorderedSet of gamemodes that are currently selected.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =======================

Script.Load("lua/GUI/GUIObject.lua")
Script.Load("lua/menu2/MenuStyles.lua")
Script.Load("lua/GUI/layouts/GUIListLayout.lua")
Script.Load("lua/UnorderedSet.lua")
Script.Load("lua/menu2/NavBar/Screens/ServerBrowser/GMSBTextButton.lua")

---@class GMSBGameModeFilters : GUIObject
class "GMSBGameModeFilters" (GUIObject)

local kAllSeparation = 46
local kListSpacing = 10
local kAllEnabledOptionName = "server-browser/game-mode-filter-all"
local kMaxWidth = 1200 -- not including "ALL"

-- Surely its bugging

-- When a player "graduates" from bootcamp (becomes not-a-rookie), we wipe their server browser
-- filter settings, and make the default to just show everything, allowing them to see the modded
-- servers for perhaps the first time.  In order to "wipe" their settings, we just switch over to
-- using differently-named settings.
local kHasBeenNonRookieYetOptionPath = "server-browser/game-mode-filter-has-been-non-rookie-yet"
local function GetIsClientARookie()
    return not Client.GetOptionBoolean(kHasBeenNonRookieYetOptionPath, false)
end

local function GetGameModeFilterPath(gameMode)
    if GetIsClientARookie() then
        return (string.format("server-browser/game-modes-rookie/%s", gameMode))
    else
        return (string.format("server-browser/game-modes/%s", gameMode))
    end
end

GMSBGameModeFilters:AddCompositeClassProperty("AllEnabled", "allButton", "Glowing")
GMSBGameModeFilters:AddClassProperty("ModeList", {})
GMSBGameModeFilters:AddClassProperty("SelectedModes", UnorderedSet(), true)

local function DeselectAllInList(self, list)
    local selectedModes = self:GetSelectedModes()
    for i=1, #list do
        selectedModes:RemoveElement(list[i])
        Client.SetOptionBoolean(GetGameModeFilterPath(list[i]), false)
    end
    self:SetSelectedModes(selectedModes)
end

local function SelectAllInList(self, list)
    local selectedModes = self:GetSelectedModes()
    for i=1, #list do
        selectedModes:Add(list[i])
        Client.SetOptionBoolean(GetGameModeFilterPath(list[i]), true)
    end
    self:SetSelectedModes(selectedModes)
end

local function SelectSingleMode(self, mode)
    local selectedModes = self:GetSelectedModes()
    if selectedModes:Add(mode) then
        self:SetSelectedModes(selectedModes)
        Client.SetOptionBoolean(GetGameModeFilterPath(mode), true)
    end
end

local function DeselectSingleMode(self, mode)
    local selectedModes = self:GetSelectedModes()
    if selectedModes:RemoveElement(mode) then
        self:SetSelectedModes(selectedModes)
        Client.SetOptionBoolean(GetGameModeFilterPath(mode), false)
    end
end

local function GetAllSelected(self, list)
    local selectedModes = self:GetSelectedModes()
    for i=1, #list do
        if not selectedModes:Contains(list[i]) then
            return false
        end
    end
    return true
end

local function UpdateSelectedModesForList(self, list)
    if GetAllSelected(self, list) then
        DeselectAllInList(self, list)
    else
        SelectAllInList(self, list)
    end
end

local function OnAllButtonPressed(self)
    UpdateSelectedModesForList(self, self:GetModeList())
end

local function OnFilterPressed(self, filter)
    UpdateSelectedModesForList(self, filter.representedModes)
end

local function FilterUpdateColor(filter)
    if filter.mouseOver then
        filter:ClearPropertyAnimations("Color")
        filter:SetColor(1, 1, 1, 1)
    else
        if GetAllSelected(filter.owner, filter.representedModes) then
            filter:AnimateProperty("Color", MenuStyle.kHighlight, MenuAnimations.Fade)
        else
            filter:AnimateProperty("Color", MenuStyle.kLightGrey, MenuAnimations.Fade)
        end
    end
end

local function FilterOnMouseEnter(filter)
    filter.mouseOver = true
    PlayMenuSound("ButtonHover")
    FilterUpdateColor(filter)
end

local function FilterOnMouseExit(filter)
    filter.mouseOver = false
    FilterUpdateColor(filter)
end

local function FilterOnMouseRelease(filter)
    OnFilterPressed(filter.owner, filter)
    if GetAllSelected(filter.owner, filter.representedModes) then
        PlayMenuSound("BeginChoice")
    else
        PlayMenuSound("CancelChoice")
    end
end

local function GetModeDefault(mode)
    if GetIsClientARookie() then
        return mode == "ns2"
    else
        return true
    end
end

local function LoadModeFromOption(self, mode)
    if Client.GetOptionBoolean(GetGameModeFilterPath(mode), GetModeDefault(mode)) then
        SelectSingleMode(self, mode)
    else
        DeselectSingleMode(self, mode)
    end
end

local function OnModeListChanged(self, modeList)
    
    -- Add/update the modes display one mode at a time until either the list is exhausted, or the
    -- maximum length is reached/exceeded.
    
    local modeIdx = 1
    local textObjIdx = 1
    local length = 0
    
    while modeIdx <= #modeList and length <= kMaxWidth do
        
        -- Add new text objects if necessary.
        while #self.filterListObjs < textObjIdx do
            
            local newObj = CreateGUIObject("filterListObj", GUIText, self.filterList)
            newObj:SetFont(MenuStyle.kServerBrowserGameModeFilter)
            newObj:AlignLeft()
            newObj:SetColor(MenuStyle.kLightGrey)
            newObj.owner = self
            
            self.filterListObjs[#self.filterListObjs+1] = newObj
            
            -- Odd-indexed objects are gamemodes, even are dividers.  Setup odds for interaction.
            if #self.filterListObjs % 2 == 1 then
                newObj:HookEvent(newObj, "OnMouseEnter", FilterOnMouseEnter)
                newObj:HookEvent(newObj, "OnMouseExit", FilterOnMouseExit)
                newObj:HookEvent(newObj, "OnMouseRelease", FilterOnMouseRelease)
                newObj:ListenForCursorInteractions()
            else
                newObj:SetText("|")
            end
            
        end
        
        local currentTextObj = self.filterListObjs[textObjIdx]
        local currentMode = modeList[modeIdx]
        
        -- Update the text of the current text object.
        currentTextObj:SetText(currentMode)
        
        -- Update the gamemode(s) that this object represents.
        currentTextObj.representedModes = { currentMode }
        
        -- Load the selection state from options.
        LoadModeFromOption(self, currentMode)
        
        -- Update the filter text color based on selection.
        FilterUpdateColor(currentTextObj)
        
        -- Add length of vertical bar divider plus spacing on either side.
        if textObjIdx > 1 then
            length = length + kListSpacing + self.filterListObjs[textObjIdx-1]:GetSize().x + kListSpacing
        end
        
        -- Add length of mode text.
        length = length + self.filterListObjs[textObjIdx]:GetSize().x
        
        modeIdx = modeIdx + 1
        textObjIdx = textObjIdx + 2
        
    end
    
    if length > kMaxWidth and modeIdx > 1 and textObjIdx > 1 then
        modeIdx = modeIdx - 1
        textObjIdx = textObjIdx - 2
    end
    
    -- While the maximum length is exceeded, back-up by 1 mode, and set the text of the last mode
    -- to "%d OTHERS", grouping all remaining modes into this mode.
    while length > kMaxWidth and modeIdx > 1 and textObjIdx > 1 do
        
        local prevLastObj = self.filterListObjs[textObjIdx]
        local prevLastDivider = self.filterListObjs[textObjIdx-1]
        
        -- Subtract length of previous entry.
        length = length - prevLastObj:GetSize().x
        
        -- Subtract length of divider with its spacing.
        length = length - kListSpacing - prevLastDivider:GetSize().x - kListSpacing
        
        -- Adjust indices to new positions.
        modeIdx = modeIdx - 1
        textObjIdx = textObjIdx - 2
        
        local currentObj = self.filterListObjs[textObjIdx]
        
        -- Subtract length of current entry (text will be changing).
        length = length - currentObj:GetSize().x
        
        -- Change text to the the "%d OTHERS" text.
        local othersCount = #modeList - modeIdx + 1
        currentObj:SetText(StringReformat(
            Locale.ResolveString("SERVERBROWSER_FILTER_GAMEMODE_OTHERS"),
            { amount = othersCount }))
        
        -- Add length of current entry with new text.
        length = length + currentObj:GetSize().x
        
    end
    
    -- Group remaining undisplayed modes into the last text object.
    if modeIdx <= #modeList then
        
        local currentObj = self.filterListObjs[textObjIdx]
        currentObj.representedModes = {}
        for i=modeIdx, #modeList do
            table.insert(currentObj.representedModes, modeList[i])
            
            -- Set state of filter from options.
            LoadModeFromOption(self, modeList[i])
        end
        
        FilterUpdateColor(currentObj)
        
    end
    
    -- Remove leftover text objects.
    for i=#self.filterListObjs, textObjIdx+1, -1 do
        local destroyingObj = self.filterListObjs[i]
        self.filterListObjs[i] = nil
        destroyingObj:Destroy()
    end
    
end

local function UpdateAllEnabled(self)
    self:SetAllEnabled(GetAllSelected(self, self:GetModeList()))
end

local function UpdateSize(self)
    
    local width = self.allButton:GetSize().x + kAllSeparation + self.filterList:GetSize().x
    local height = math.max(self.allButton:GetSize().y, self.filterList:GetSize().y)
    
    self:SetSize(width, height)
    
end

local function OnSelectedModesChanged(self)
    
    local selectedModes = self:GetSelectedModes()
    
    -- Update coloring of all filter list objects to reflect selection status.
    for i=1, #self.filterListObjs, 2 do
        FilterUpdateColor(self.filterListObjs[i])
    end
    
end

local function UpdateHasBeenNonRookieBeforeStatus()

    local recordedValue = GetIsClientARookie()
    local actualValue = GetLocalPlayerProfileData():GetIsRookie()
    
    -- If client is no longer a rookie, but we previously thought they were, make note of it.
    if recordedValue and not actualValue then
        Client.SetOptionBoolean(kHasBeenNonRookieYetOptionPath, true)
    end

end

function GMSBGameModeFilters:SelectAllInList()
    SelectAllInList(self,self:GetModeList())
end

function GMSBGameModeFilters:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    
    GUIObject.Initialize(self, params, errorDepth)
    
    self.filterListObjs = {}
    
    self.allButton = CreateGUIObject("allButton", GMSBTextButton, self)
    self.allButton:AlignLeft()
    self.allButton:SetLabel(Locale.ResolveString("SERVERBROWSER_FILTER_GAMEMODE_ALL"))
    self.allButton:SetGlowing(false)
    self:HookEvent(self.allButton, "OnPressed", OnAllButtonPressed)
    
    local allEnabled = Client.GetOptionBoolean(kAllEnabledOptionName, false)
    self:SetAllEnabled(allEnabled)
    
    self.filterList = CreateGUIObject("filterList", GUIListLayout, self, {orientation = "horizontal"})
    self.filterList:AlignRight()
    self.filterList:SetSpacing(kListSpacing)
    
    self:HookEvent(self, "OnModeListChanged", OnModeListChanged)
    self:HookEvent(self, "OnSelectedModesChanged", OnSelectedModesChanged)
    
    self:HookEvent(self, "OnModeListChanged", UpdateAllEnabled)
    self:HookEvent(self, "OnSelectedModesChanged", UpdateAllEnabled)
    
    self:HookEvent(self.filterList, "OnSizeChanged", UpdateSize)
    self:HookEvent(self.allButton, "OnSizeChanged", UpdateSize)
    UpdateSize(self)
    
    UpdateHasBeenNonRookieBeforeStatus()
    self:HookEvent(GetLocalPlayerProfileData(), "OnLevelChanged", UpdateHasBeenNonRookieBeforeStatus)
    
end

-- DEBUG
Event.Hook("Console_debug_reset_non_rookie_before_status", function()
    Log("Reset 'has-been-non-rookie-before' status.")
    Client.SetOptionBoolean(kHasBeenNonRookieYetOptionPath, false)
end)
