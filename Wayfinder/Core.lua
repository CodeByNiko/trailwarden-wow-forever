Wayfinder = Wayfinder or {}
local W = Wayfinder

local events = CreateFrame("Frame")
W.EventFrame = events
local refreshPending = false
local function scheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.35, function()
        refreshPending = false
        W.ScanCharacter()
        if W.RefreshUI then W.RefreshUI() end
    end)
end

events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_ACCEPTED")
events:RegisterEvent("QUEST_REMOVED")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        W.ScanCharacter()
        if W.CreateUI then W.CreateUI() end
        if W.CreateNavigator then W.CreateNavigator() end
        if W.BuildQuestCatalog then W.BuildQuestCatalog() end
        if W.RefreshUI then W.RefreshUI() end
        print("|cff67d4e8Wayfinder|r ready. Your route and navigator are active. Type |cffffd27f/wf|r to show or hide the guide.")
        return
    end
    scheduleRefresh()
end)

SLASH_WAYFINDER1 = "/wayfinder"
SLASH_WAYFINDER2 = "/wf"
SlashCmdList = SlashCmdList or {}
SlashCmdList.WAYFINDER = function(message)
    message = string.lower(message or "")
    if message == "refresh" then
        W.ScanCharacter()
        if W.BuildQuestCatalog then W.BuildQuestCatalog() end
        if W.RefreshUI then W.RefreshUI(true) end
        print("|cff67d4e8Wayfinder|r refreshed your route data.")
    elseif message == "auto" then
        local profile = W.GetProfile()
        profile.autoArrow = not profile.autoArrow
        if W.RefreshUI then W.RefreshUI(true) end
        print("|cff67d4e8Wayfinder|r automatic waypoint arrow " .. (profile.autoArrow and "enabled." or "paused."))
    elseif message == "arrow" then
        if W.ToggleNavigator then W.ToggleNavigator() end
    else
        if W.CreateUI then W.CreateUI() end
        if W.ToggleUI then W.ToggleUI() end
    end
end
