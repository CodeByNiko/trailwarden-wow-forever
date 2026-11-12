local W=Trailwarden
SLASH_TRAILWARDEN1="/trailwarden";SLASH_TRAILWARDEN2="/tw"
SlashCmdList.TRAILWARDEN=function(message)
    local cmd=string.lower((message or ""):match("^%s*(.-)%s*$"));local p=W.GetProfile()
    local scale=cmd:match("^scale%s+(%d+)$");local arrowScale=cmd:match("^arrowscale%s+(%d+)$")
    if scale or arrowScale then W.SetDisplayScale(scale and "uiScale" or "navigatorScale",tonumber(scale or arrowScale)/100);return end
    local language=cmd:match("^language%s+(%a+)$")
    if language then
        language=string.lower(language)
        if language=="auto" or language=="en" or language=="da" then
            p.language=language;W.ActionLabels={escort=W.L("action_escort"),grind=W.L("action_grind"),pickup=W.L("action_pickup"),objective=W.L("action_objective"),turnin=W.L("action_turnin"),deliver=W.L("action_deliver"),item=W.L("action_item"),travel=W.L("action_travel"),wait=W.L("action_wait")}
            print("|cff5dd4d6Trailwarden|r "..W.L("language_changed"));W.Refresh(true);W.ClearRouteOverlay();W.UpdateRouteOverlay()
        else print("|cff5dd4d6Trailwarden|r "..W.L("language_usage")) end
        return
    end
    if cmd=="" then W.ToggleUI()
    elseif cmd=="arrow" then W.ToggleNavigator()
    elseif cmd=="routepins" then p.routeOverlay=not p.routeOverlay;W.ClearRouteOverlay();W.UpdateRouteOverlay()
    elseif cmd=="settings" then W.ToggleSettings()
    elseif cmd=="lock" then p.locked=not p.locked;W.Refresh(true)
    elseif cmd=="refresh" then p.pinned=nil;W.Refresh(true,"manual-replan")
    elseif cmd=="rebuild" then W.BuildQuestCatalog(true)
    elseif cmd=="skip" then W.SkipCurrent()
    elseif cmd=="later" then W.DeferCurrent()
    elseif cmd=="undo" then W.UndoSkip()
    elseif cmd=="pause" then p.paused=true;W.Refresh(true)
    elseif cmd=="resume" then p.paused=false;p.pinned=nil;W.Refresh(true)
    elseif cmd=="group" then p.includeGroup=not p.includeGroup;W.Refresh(true)
    elseif cmd=="auto" then p.mapSync=not p.mapSync;W.Refresh(true)
    elseif cmd=="reset" then p.panelPoint=nil;p.navigatorPoint=nil;W.ApplyPositions()
    elseif cmd=="perf" then W.ShowDiagnostics(W.PerformanceSummary())
    elseif cmd=="perfreset" then W.PerformanceSummary(true);print("Trailwarden performance counters reset.")
    elseif cmd=="debug" then W.ShowDiagnostics()
    elseif cmd=="feedback" then W.ShowDiagnostics(W.ExportFeedback())
    elseif cmd=="xpreset" then W.ResetExperience();W.Refresh(true)
    elseif cmd=="xp" then p.xpRouting=not p.xpRouting;W.Refresh(true)
    elseif cmd=="trace" then W.ShowDiagnostics(W.ExportReplay())
    else print("|cff5dd4d6Trailwarden|r /tw, arrow, routepins, settings, language auto|en|da, lock, refresh, rebuild, skip, later, undo, pause, resume, group, auto (map waypoint), reset (positions), debug, feedback (reviewable summary), trace (local replay), xp (routing), xpreset (session), scale 60-130, arrowscale 60-150.") end
end

