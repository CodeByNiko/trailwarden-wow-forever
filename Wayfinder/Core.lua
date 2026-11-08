local W=Wayfinder
local frame=CreateFrame("Frame");W.EventFrame=frame
local pending=false
local pendingEvents={}
local function render(name,fn,...)
    local status,message=W.Call(fn,...)
    W.OutputErrors=W.OutputErrors or {}
    if status~="ok" then W.OutputErrors[name]=tostring(message or status) else W.OutputErrors[name]=nil end
    return status=="ok"
end
function W.Refresh(force,trigger)
    local started=debugprofilestop and debugprofilestop()
    W.PlanExecutions=(W.PlanExecutions or 0)+1;W.LastRefreshTime=W.Now()
    local state,route,queue,detail
    local ok,errorText=pcall(function()
        state=W.ReadCharacter()
        route,queue,detail=W.PlanRoute(state,force,{previous=W.Decision and W.Decision.route})
        assert(type(route)=="table" and type(queue)=="table","Invalid planner result")
    end)
    if not ok then
        W.LastError=tostring(errorText)
        state=state or W.Copy(W.State) or {key=W.GetCharacterKey(),name="Adventurer",className="Unknown",raceName="Unknown",zone="Unknown area",level=1,now=W.Now(),activeQuests={},completed={},completedCount=0,freeSlots=0,profile=W.GetProfile(),questLogReady=false,historyReady=false}
        route={kind="wait",key="error",title="Waiting for reliable quest data",instruction="The current update could not be completed. Wayfinder will retry; /wf debug contains the details.",reason=W.LastError,ownerKey=state.key};queue={};detail={candidates={},clearPin=false}
    elseif W.LastError then W.RecoveredError=W.LastError;W.LastError=nil end
    local decision={trigger=trigger or (force and "manual" or "refresh"),id=(W.Decision and W.Decision.id or 0)+1,state=state,route=W.Copy(route),queue=W.Copy(queue),detail=detail or {}}
    -- Publish one completed decision; every visible output consumes this version.
    W.Decision=decision;W.State=decision.state;W.CurrentRoute=decision.route;W.Queue=decision.queue
    W.Unmapped=detail and detail.input and detail.input.meta.deferred or {}
    if detail and detail.clearPin then W.GetProfile().pinned=nil;state.profile.pinned=nil end
    if state.questLogReady then W.LastGoodState=W.Copy(state) end
    render("navigation",W.UpdateNavigation)
    render("waypoint",W.SyncWaypoint,decision.route,force)
    local panelOK=render("panel",W.UpdateUI)
    if not panelOK and W.MainFrame then W.MainFrame:Hide() end
    if panelOK and W.MainFrame and not W.GetProfile().panelHidden then W.MainFrame:Show() end
    render("navigator",W.UpdateNavigator)
    render("replay",W.RecordDecision,decision)
    if started then W.LastPlanMilliseconds=debugprofilestop()-started end
end
local function schedule(force,event)
    if event then pendingEvents[event]=true end
    if pending then return end;pending=true
    local function update()
        pending=false;local events={};for name in pairs(pendingEvents) do events[#events+1]=name end;table.sort(events);pendingEvents={}
        W.Refresh(force,table.concat(events,","))
    end
    if C_Timer then C_Timer.After(.2,update) else update() end
end
function W.Diagnostics()
    local s=W.State or W.ReadCharacter();local r=W.CurrentRoute or {};local n=W.Navigation or {}
    local lines={"Wayfinder "..W.Version,"Decision: "..tostring(W.Decision and W.Decision.id).." / navigation "..tostring(n.decisionID).." / map "..tostring(W.WaypointDecisionID),
        "Character: "..s.name.." / "..s.raceName.." "..s.className.." / level "..s.level,
        "Zone: "..s.zone.." / map "..tostring(s.mapID),"Quest log ready: "..tostring(s.questLogReady).." / history ready: "..tostring(s.historyReady),
        "Quest log: "..#s.activeQuests.." active / "..s.completedCount.." completed / revision "..tostring(s.revision),
        "Catalog: "..tostring(W.CatalogState).." / "..tostring(W.CatalogCount or 0).." quests / "..tostring(W.DatabaseStatus),"Catalog error: "..tostring(W.CatalogError or "none"),
        "Step: "..tostring(r.key).." / "..tostring(r.title),"Target: "..tostring(r.target).." / "..tostring(r.mapID).." / "..tostring(r.x)..", "..tostring(r.y),
        "Navigation: "..(n.label or "none").." / distance "..tostring(n.distance),"Last plan: "..string.format("%.2f",W.LastPlanMilliseconds or 0).." ms / event "..tostring(W.LastEvent),
        "Last error: "..tostring(W.LastError or "none"),"Event error: "..tostring(W.EventError or "none"),"Recovered error: "..tostring(W.RecoveredError or "none"),"Map waypoint: "..tostring(W.WaypointStatus),"Local replay: /wf trace (last 20 decisions)","Deferred / unmapped:"}
    for _,issue in ipairs(s.readIssues or {}) do lines[#lines+1]="Read issue: "..issue end
    for _,q in ipairs(W.Unmapped or {}) do lines[#lines+1]=q.id.." / "..q.title.." / "..q.reason end
    lines[#lines+1]="Active quest objectives:"
    for _,q in ipairs(s.activeQuests) do
        lines[#lines+1]=q.id.." / "..q.title.." / complete="..tostring(q.isComplete).." / objectives ready="..tostring(q.objectivesReady)
        for _,o in ipairs(q.objectives) do lines[#lines+1]="  "..tostring(o.type).." / "..tostring(o.id).." / "..o.text.." / "..tostring(o.fulfilled).."/"..tostring(o.required).." / done="..tostring(o.finished) end
    end
    lines[#lines+1]="Output/data errors:"
    for key,value in pairs(W.OutputErrors or {}) do lines[#lines+1]=key..": "..value end
    for key,value in pairs(W.DataIssues or {}) do lines[#lines+1]=key..": "..value end
    return table.concat(lines,"\n")
end
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_COMPLETE","QUEST_DETAIL","QUEST_GREETING","GOSSIP_SHOW","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_ALIVE","PLAYER_UNGHOST","BAG_UPDATE_DELAYED","UPDATE_FACTION","SKILL_LINES_CHANGED","QUEST_QUERY_COMPLETE"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event,...)
    W.LastEvent=event
    if event=="PLAYER_LOGIN" then
        W.CreateUI();W.CreateNavigator();W.Refresh(true)
        if C_Timer then C_Timer.After(.5,function() W.BuildQuestCatalog() end) else W.BuildQuestCatalog() end
        print("|cff5dd4d6Wayfinder "..W.Version.."|r / Your character's route is ready. |cffffc366/wf|r opens the guide; |cffffc366/wf help|r lists controls.")
        return
    end
    local args={...}
    local ok,message=pcall(function()
        if event=="QUEST_TURNED_IN" then W.RememberTurnIn(args[1]);W.ObserveQuest(args[1],nil,"turnin")
        elseif event=="GOSSIP_SHOW" or event=="QUEST_GREETING" then W.ObserveGossip()
        elseif event=="QUEST_DETAIL" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"pickup")
        elseif event=="QUEST_COMPLETE" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"turnin") end
    end)
    if not ok then W.EventError=tostring(message) end
    schedule(false,event)
end)
local navElapsed,planElapsed=0,0
frame:SetScript("OnUpdate",function(_,dt)
    navElapsed=navElapsed+dt;planElapsed=planElapsed+dt
    if navElapsed>=.1 then navElapsed=0;if W.State then render("navigation",W.UpdateNavigation);render("navigator",W.UpdateNavigator);render("live panel",W.UpdateLiveUI) end end
    if planElapsed>=2 then
        planElapsed=0
        if W.State then
            local current,previous=W.PlayerPoint(),W.State.player
            local changed=(current and not previous) or (previous and not current)
            if current and previous then changed=current.mapID~=previous.mapID or W.TravelCost(current,previous)>=35 end
            local dead=W.Safe(UnitIsDeadOrGhost,"player")==true
            if changed or dead~=W.State.dead or W.Now()-(W.LastRefreshTime or 0)>=15 or (W.CurrentRoute and W.CurrentRoute.key=="error") then W.Refresh(false,changed and "movement" or dead~=W.State.dead and "life-state" or "maintenance") end
        end
    end
end)
SLASH_WAYFINDER1="/wayfinder";SLASH_WAYFINDER2="/wf"
SlashCmdList.WAYFINDER=function(message)
    local cmd=string.lower((message or ""):match("^%s*(.-)%s*$"));local p=W.GetProfile()
    if cmd=="" then W.ToggleUI()
    elseif cmd=="arrow" then W.ToggleNavigator()
    elseif cmd=="settings" then W.ToggleSettings()
    elseif cmd=="lock" then p.locked=not p.locked;W.Refresh(true)
    elseif cmd=="refresh" then p.pinned=nil;W.Refresh(true)
    elseif cmd=="rebuild" then W.BuildQuestCatalog(true)
    elseif cmd=="skip" then W.SkipCurrent()
    elseif cmd=="undo" then W.UndoSkip()
    elseif cmd=="pause" then p.paused=true;W.Refresh(true)
    elseif cmd=="resume" then p.paused=false;p.pinned=nil;W.Refresh(true)
    elseif cmd=="group" then p.includeGroup=not p.includeGroup;W.Refresh(true)
    elseif cmd=="auto" then p.mapSync=not p.mapSync;W.Refresh(true)
    elseif cmd=="reset" then p.panelPoint=nil;p.navigatorPoint=nil;W.ApplyPositions()
    elseif cmd=="debug" then W.ShowDiagnostics()
    elseif cmd=="trace" then W.ShowDiagnostics(W.ExportReplay())
    else print("|cff5dd4d6Wayfinder|r /wf, arrow, settings, lock, refresh, rebuild, skip, undo, pause, resume, group, auto (map waypoint), reset (positions), debug, trace.") end
end
