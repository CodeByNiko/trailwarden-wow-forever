local W=Trailwarden
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
    W.LastAttemptTime=W.Now()
    render("experience",W.SampleExperience)
    local state,route,queue,detail;local captured=false
    local ok,errorText=pcall(function()
        state=W.ReadCharacter();captured=true
        local previous=W.Decision
        local noisy=trigger=="QUEST_LOG_UPDATE" or trigger=="maintenance" or trigger=="XP_REVIEW"
        if not force and noisy and previous and previous.state.key==state.key and previous.state.signature==state.signature and W.Now()-(W.LastRefreshTime or 0)<60 and not W.LastError then return end
        W.PlanExecutions=(W.PlanExecutions or 0)+1;W.LastRefreshTime=W.Now()
        route,queue,detail=W.PlanRoute(state,force,{previous=previous and previous.route,commitment=previous and previous.commitment,previousMapID=previous and previous.state.mapID,releasePlan=trigger=="manual-replan"})
        assert(type(route)=="table" and type(queue)=="table","Invalid planner result")
    end)
    if ok and not route then return end
    if not ok then
        route=nil;queue=nil;detail=nil
        W.LastError=tostring(errorText)
        state=state or W.Copy(W.State) or {key=W.GetCharacterKey(),name="Adventurer",className="Unknown",raceName="Unknown",zone="Unknown area",level=1,now=W.Now(),activeQuests={},completed={},completedCount=0,freeSlots=0,profile=W.GetProfile(),questLogReady=false,historyReady=false}
        -- Preserve only a step revalidated against the fresh live quest log.
        local prior=W.Decision and W.Decision.route
        local q=captured and state.questLogReady and prior and state.activeByID and state.activeByID[prior.questID]
        if q and not q.failed and not (state.combatSafety and state.combatSafety.alert) and not state.dead and not state.profile.paused and prior.ownerKey==state.key then
            local status,steps=W.Call(W.ActiveSteps,q,state)
            if status=="ok" then for _,step in ipairs(steps) do if step.key==prior.key then route=step;route.ownerKey=state.key;break end end end
        end
        if route then queue={};detail={clearPin=false,candidates={},commitment=W.Decision.commitment,recovering=true}
        else route={kind="wait",key="error",title="Waiting for reliable quest data",instruction="The current update could not be completed. Trailwarden will retry; /tw debug contains the details.",reason=W.LastError,ownerKey=state.key};queue={};detail={candidates={},clearPin=false} end
    elseif W.LastError then W.RecoveredError=W.LastError;W.LastError=nil end
    local decision={trigger=trigger or (force and "manual" or "refresh"),id=(W.Decision and W.Decision.id or 0)+1,state=state,route=W.Copy(route),queue=W.Copy(queue),detail=detail or {},commitment=detail and detail.commitment}
    -- Publish one completed decision; every visible output consumes this version.
    W.Decision=decision;W.State=decision.state;W.CurrentRoute=decision.route;W.Queue=decision.queue
    W.Unmapped=detail and detail.input and detail.input.meta.deferred or {}
    if detail and detail.endGrind then W.EndGrindBreak() end
    if detail and detail.clearPin then W.GetProfile().pinned=nil;state.profile.pinned=nil end
    if state.questLogReady then W.LastGoodState=W.Copy(state) end
    render("navigation",W.UpdateNavigation)
    W.NavigationPanelRefresh=nil -- The complete panel render below consumes any transition.
    render("waypoint",W.SyncWaypoint,decision.route,force)
    local panelOK=render("panel",W.UpdateUI)
    if not panelOK and W.MainFrame then W.MainFrame:Hide() end
    if panelOK and W.MainFrame and not W.GetProfile().panelHidden then W.MainFrame:Show() end
    render("navigator",W.UpdateNavigator)
    render("route overlay",W.UpdateRouteOverlay)
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
    if C_Timer then C_Timer.After(.5,update) else update() end
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_COMPLETE","QUEST_DETAIL","QUEST_GREETING","GOSSIP_SHOW","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_ALIVE","PLAYER_UNGHOST","BAG_UPDATE_DELAYED","UPDATE_FACTION","SKILL_LINES_CHANGED","QUEST_QUERY_COMPLETE","PLAYER_XP_UPDATE","CHAT_MSG_COMBAT_XP_GAIN","PLAYER_FLAGS_CHANGED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event,...)
    W.LastEvent=event
    if event=="PLAYER_LOGIN" then
        W.ResetExperience();W.Safe(W.PollCombatSafety);W.CreateUI();W.CreateNavigator();W.Refresh(true)
        if C_Timer then C_Timer.After(.5,function() W.BuildQuestCatalog() end) else W.BuildQuestCatalog() end
        print("|cff5dd4d6Trailwarden "..W.Version.."|r / Your character's route is ready. |cffffc366/tw|r opens the guide; |cffffc366/tw help|r lists controls.")
        return
    end
    local args={...}
    if event=="ADDON_LOADED" then
        if args[1]=="OpenMap" then if W.State then render("navigation",W.UpdateNavigation);render("route overlay",W.UpdateRouteOverlay) end end
        return
    end
    render("XP event",W.ExperienceEvent,event,unpack(args))
    if event=="PLAYER_TARGET_CHANGED" or event=="UPDATE_MOUSEOVER_UNIT" or event=="NAME_PLATE_UNIT_ADDED" or event=="NAME_PLATE_UNIT_REMOVED" then
        W.TrackCombatUnit(event,args[1]);local changed=W.Safe(W.PollCombatSafety)
        if changed then W.Refresh(false,"combat-safety") end
        return
    end
    local ok,message=pcall(function()
        if event=="QUEST_TURNED_IN" then W.RememberTurnIn(args[1]);W.ObserveQuest(args[1],nil,"turnin")
        elseif event=="GOSSIP_SHOW" or event=="QUEST_GREETING" then W.ObserveGossip()
        elseif event=="QUEST_DETAIL" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"pickup")
        elseif event=="QUEST_COMPLETE" then W.ObserveQuest(W.Safe(GetQuestID),W.Safe(GetTitleText),"turnin") end
    end)
    if not ok then W.EventError=tostring(message) end
    -- XP measurements are frequent; they do not invalidate the route after each kill.
    if event=="PLAYER_XP_UPDATE" or event=="CHAT_MSG_COMBAT_XP_GAIN" or event=="PLAYER_FLAGS_CHANGED" then
        if W.Now()-(W.LastRefreshTime or 0)>=60 and not W.Safe(InCombatLockdown) then schedule(false,"XP_REVIEW") end
    else schedule(false,event) end
end)
local navElapsed,planElapsed,xpElapsed=0,0,0
frame:SetScript("OnUpdate",function(_,dt)
    navElapsed=navElapsed+dt;planElapsed=planElapsed+dt;xpElapsed=xpElapsed+dt
    if xpElapsed>=1 then
        xpElapsed=0;render("experience",W.SampleExperience)
        if W.State then render("route overlay",W.UpdateRouteOverlay) end
        if W.Safe(W.PollCombatSafety) then W.Refresh(false,"combat-safety") end
    end
    if navElapsed>=.1 then
        navElapsed=0
        if W.State then
            render("navigation",W.UpdateNavigation);render("navigator",W.UpdateNavigator)
            if W.NavigationPanelRefresh then
                W.NavigationPanelRefresh=nil;render("navigation transition panel",W.UpdateUI)
            else render("live panel",W.UpdateLiveUI) end
        end
    end
    if planElapsed>=2 then
        planElapsed=0
        if W.State then
            local current,previous=W.PlayerPoint(),W.State.player
            local area=W.Safe(W.ReadWorkArea,current)
            local areaChanged=(area and area.id)~=(W.State.workArea and W.State.workArea.id)
            local changed=areaChanged or (current and not previous) or (previous and not current)
            if current and previous then changed=changed or current.mapID~=previous.mapID or W.TravelCost(current,previous)>=120 and W.Now()-(W.LastRefreshTime or 0)>=10 end
            local dead=W.Safe(UnitIsDeadOrGhost,"player")==true
            if changed or dead~=W.State.dead or W.Now()-(W.LastRefreshTime or 0)>=60 or (W.CurrentRoute and W.CurrentRoute.key=="error") then W.Refresh(false,changed and "movement" or dead~=W.State.dead and "life-state" or "maintenance") end
        end
    end
end)
