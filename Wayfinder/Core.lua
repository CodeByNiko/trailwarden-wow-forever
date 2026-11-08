local W=Wayfinder
local frame=CreateFrame("Frame");W.EventFrame=frame
local pending=false
function W.Refresh(force)
    local started=debugprofilestop and debugprofilestop()
    W.PlanExecutions=(W.PlanExecutions or 0)+1;W.LastRefreshTime=W.Now()
    local state=W.ScanCharacter()
    local ok,route,queue=pcall(W.PlanRoute,state,force)
    if not ok then
        W.LastError=tostring(route)
        route={kind="wait",key="error",title="The route needs attention",instruction="Use /wf debug to copy diagnostics. Your quest progress is preserved.",reason="A planning error prevented this update."};queue={}
    elseif W.LastError then W.RecoveredError=W.LastError;W.LastError=nil
    end
    W.CurrentRoute,W.Queue=route,queue or {}
    W.SyncWaypoint(route,force);W.UpdateUI();W.UpdateNavigator()
    if started then W.LastPlanMilliseconds=debugprofilestop()-started end
end
local function schedule(force)
    if pending then return end
    pending=true
    local function update() pending=false;W.Refresh(force) end
    if C_Timer then C_Timer.After(0.2,update) else update() end
end
function W.Diagnostics()
    local s=W.State or W.ScanCharacter();local r=W.CurrentRoute or {};local n=W.NavigationInfo(r)
    local lines={"Wayfinder "..W.Version,"Character: "..s.name.." / "..s.raceName.." "..s.className.." / level "..s.level,
        "Zone: "..s.zone.." / map "..tostring(s.mapID),"Quest log: "..#s.activeQuests.." active / "..s.completedCount.." completed / history ready: "..tostring(s.historyReady),
        "QuestieDB: "..tostring(LibQuestieDB~=nil).." / contract "..tostring(LibQuestieDB and LibQuestieDB.contractVersion),
        "Catalog: "..tostring(W.CatalogCount or 0).." quests / "..(W.DatabaseStatus or "not started"),
        "Settings: group="..tostring(s.profile.includeGroup).." maxAbove="..s.profile.maxLevelAbove.." mapSync="..tostring(s.profile.mapSync).." paused="..tostring(s.profile.paused),
        "Step: "..tostring(r.key).." / "..tostring(r.title),"Target: "..tostring(r.target).." / "..tostring(r.mapID).." / "..tostring(r.x)..", "..tostring(r.y),
        "Navigation: "..(n.label or "none").." / distance "..tostring(n.distance),"Facing: "..tostring(W.Safe(GetPlayerFacing)),
        "Last plan: "..string.format("%.2f",W.LastPlanMilliseconds or 0).." ms / event "..tostring(W.LastEvent),"Last error: "..tostring(W.LastError or "none"),"Recovered error: "..tostring(W.RecoveredError or "none"),"Plan executions: "..tostring(W.PlanExecutions or 0),"Map waypoint: "..tostring(W.WaypointStatus or "not set"),"Deferred / unmapped:"}
    for _,q in ipairs(W.Unmapped or {}) do lines[#lines+1]=tostring(q.id).." / "..q.title.." / "..q.reason end
    lines[#lines+1]="Active quest IDs:"
    for _,q in ipairs(s.activeQuests) do lines[#lines+1]=q.id.." / "..q.title.." / complete="..tostring(q.isComplete) end
    return table.concat(lines,"\n")
end
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_COMPLETE","QUEST_DETAIL","QUEST_GREETING","GOSSIP_SHOW","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_ALIVE","PLAYER_UNGHOST","BAG_UPDATE_DELAYED","UPDATE_FACTION","SKILL_LINES_CHANGED","QUEST_QUERY_COMPLETE"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event,...)
    W.LastEvent=event
    if event=="PLAYER_LOGIN" then
        W.ScanCharacter();W.CreateUI();W.CreateNavigator();W.Refresh(true)
        local attempts=0
        local function prepare()
            attempts=attempts+1;W.BuildQuestCatalog()
            if not W.BuildingCatalog and not W.CatalogReady and attempts<10 and C_Timer then C_Timer.After(1,prepare) end
        end
        if C_Timer then C_Timer.After(0.5,prepare) else prepare() end
        print("|cff5dd4d6Wayfinder "..W.Version.."|r / Your character's route is ready. |cffffc366/wf|r opens the guide; |cffffc366/wf help|r lists controls.")
        return
    elseif event=="QUEST_TURNED_IN" then
        local id=...;W.RememberTurnIn(id);W.ObserveQuest(id,nil,"turnin")
    elseif event=="GOSSIP_SHOW" or event=="QUEST_GREETING" then W.ObserveGossip()
    elseif event=="QUEST_DETAIL" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"pickup")
    elseif event=="QUEST_COMPLETE" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"turnin") end
    schedule(false)
end)
local navElapsed,planElapsed=0,0
frame:SetScript("OnUpdate",function(_,dt)
    navElapsed=navElapsed+dt;planElapsed=planElapsed+dt
    if navElapsed>=0.1 then navElapsed=0;if W.State then W.UpdateNavigator();W.UpdateLiveUI() end end
    if planElapsed>=2 then
        planElapsed=0
        if W.State then
            local current,previous=W.PlayerPoint(),W.State.player
            local changed=(current and not previous) or (previous and not current)
            if current and previous then changed=current.mapID~=previous.mapID or W.TravelCost(current,previous)>=35 end
            local dead=W.Safe(UnitIsDeadOrGhost,"player")==true
            if changed or dead~=W.State.dead or W.Now()-(W.LastRefreshTime or 0)>=15 or (W.CurrentRoute and W.CurrentRoute.key=="error") then W.Refresh(false) end
        end
    end
end)
SLASH_WAYFINDER1="/wayfinder";SLASH_WAYFINDER2="/wf"
SlashCmdList.WAYFINDER=function(message)
    local cmd=string.lower((message or ""):match("^%s*(.-)%s*$"))
    local p=W.GetProfile()
    if cmd=="" then W.ToggleUI()
    elseif cmd=="arrow" then W.ToggleNavigator()
    elseif cmd=="settings" then W.ToggleSettings()
    elseif cmd=="lock" then p.locked=not p.locked;W.Refresh(true)
    elseif cmd=="refresh" then W.CurrentRoute=nil;p.pinned=nil;W.Refresh(true)
    elseif cmd=="rebuild" then W.BuildQuestCatalog(true)
    elseif cmd=="skip" then W.SkipCurrent()
    elseif cmd=="undo" then W.UndoSkip()
    elseif cmd=="pause" then p.paused=true;W.Refresh(true)
    elseif cmd=="resume" then p.paused=false;p.pinned=nil;W.Refresh(true)
    elseif cmd=="group" then p.includeGroup=not p.includeGroup;W.Refresh(true)
    elseif cmd=="auto" then p.mapSync=not p.mapSync;W.Refresh(true)
    elseif cmd=="reset" then p.panelPoint=nil;p.navigatorPoint=nil;W.ApplyPositions()
    elseif cmd=="debug" then W.ShowDiagnostics()
    else print("|cff5dd4d6Wayfinder|r /wf, arrow, settings, lock, refresh, rebuild, skip, undo, pause, resume, group, auto (map waypoint), reset (positions), debug.") end
end
