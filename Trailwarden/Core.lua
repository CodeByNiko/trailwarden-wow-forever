local W=Trailwarden
local frame=CreateFrame("Frame");W.EventFrame=frame
local pending=false
local pendingEvents={}
W.WorkCounters={events={},captures=0,navigation=0,safety=0,mapChanges=0,mapDeferrals=0}
local counters=W.WorkCounters
W.CombatActive=false
local function combatFlag(value) return value==true or value==1 end
local function liveCombat() return combatFlag(W.Safe(InCombatLockdown)) or combatFlag(W.Safe(UnitAffectingCombat,"player")) end
function W.IsWorldMapOpen() return WorldMapFrame and combatFlag(W.Safe(WorldMapFrame.IsShown,WorldMapFrame)) or false end
W.MapQuietRemaining=0
function W.NoteMapInteraction()
    if W.PendingPlan then W.MapRefreshPending=true end
    if W.CancelPlanning then W.CancelPlanning() end
    W.MapQuietRemaining=.75;counters.mapChanges=counters.mapChanges+1
end
local hookedMap
local function hookMap()
    if WorldMapFrame and WorldMapFrame~=hookedMap and type(WorldMapFrame.HookScript)=="function" then
        WorldMapFrame:HookScript("OnShow",W.NoteMapInteraction)
        WorldMapFrame:HookScript("OnHide",W.NoteMapInteraction)
        hookedMap=WorldMapFrame
    end
end
function W.IsCombatActive()
    if W.CombatActive then return true end
    return liveCombat()
end
function W.SetCombatUI(active)
    W.CombatActive=active==true
    if W.CombatActive and W.PendingPlan then W.CombatRefreshPending=true end
    if W.CombatActive and W.CancelPlanning then W.CancelPlanning() end
    if W.MainFrame then
        if W.CombatActive then W.MainFrame:Hide()
        else W.MainFrame:SetShown(not W.GetProfile().panelHidden) end
    end
    if W.NavigatorFrame then W.NavigatorFrame:SetShown(not W.GetProfile().navigatorHidden) end
    if W.CombatActive and W.ClearRouteOverlay then W.ClearRouteOverlay();W.OverlayStatus="Map pins hidden during combat" end
end
local function render(name,fn,...)
    if name=="navigation" then counters.navigation=counters.navigation+1 end
    local status,message=W.TimedCall(name,fn,...)
    W.OutputErrors=W.OutputErrors or {}
    if status~="ok" then W.OutputErrors[name]=tostring(message or status) else W.OutputErrors[name]=nil end
    return status=="ok"
end
local function pollSafety()
    local status,changed=W.TimedCall("safety scan",W.PollCombatSafety)
    return status=="ok" and changed
end
local function factionStamp()
    local rep=C_Reputation
    local modern=type(rep)=="table" and type(rep.GetNumFactions)=="function" and type(rep.GetFactionDataByIndex)=="function"
    local count=modern and W.Safe(rep.GetNumFactions) or W.Safe(GetNumFactions)
    if not W.IsFinite(count) or count<0 then return nil end
    local values={}
    for i=1,count do
        local name,standing,amount,id
        if modern then
            local data=W.Safe(rep.GetFactionDataByIndex,i)
            if type(data)~="table" then return nil end
            if data.isHeader and data.isCollapsed then return nil end
            name,standing,amount,id=data.name,data.reaction,data.currentStanding,data.factionID
        elseif type(GetFactionInfo)=="function" then
            local ok,a,_,c,_,_,f,_,_,header,collapsed,_,_,_,n=pcall(GetFactionInfo,i)
            if not ok or header and collapsed then return nil end
            name,standing,amount,id=a,c,f,n
        end
        if not name then return nil end
        values[#values+1]=table.concat({tostring(id),tostring(name),tostring(standing),tostring(amount)},":")
    end
    return table.concat(values,"|")
end
local function publish(state,route,queue,detail,force,trigger,started)
    local decision={factionStamp=factionStamp(),trigger=trigger or (force and "manual" or "refresh"),id=(W.Decision and W.Decision.id or 0)+1,state=state,route=W.Copy(route),queue=W.Copy(queue),detail=detail or {},commitment=detail and detail.commitment}
    -- Publish one completed decision; every visible output consumes this version.
    W.Decision=decision;W.State=decision.state;W.CurrentRoute=decision.route;W.Queue=decision.queue
    W.Unmapped=detail and detail.input and detail.input.meta.deferred or {}
    if detail and detail.endGrind then W.EndGrindBreak() end
    if detail and detail.clearPin then W.GetProfile().pinned=nil;state.profile.pinned=nil end
    -- Decision already retains the character snapshot; no duplicate graph needed.
    render("navigation",W.UpdateNavigation)
    W.NavigationPanelRefresh=nil -- The complete panel render below consumes any transition.
    render("waypoint",W.SyncWaypoint,decision.route,force)
    local panelOK=true
    if not W.GetProfile().panelHidden then panelOK=render("panel",W.UpdateUI) end
    if not panelOK and W.MainFrame then W.MainFrame:Hide() end
    if panelOK and W.MainFrame then W.MainFrame:SetShown(not W.GetProfile().panelHidden and not W.IsCombatActive()) end
    render("navigator",W.UpdateNavigator)
    render("route overlay",W.UpdateRouteOverlay)
    render("replay",W.RecordDecision,decision)
    if started then W.LastPlanMilliseconds=debugprofilestop()-started end
    W.ActiveRefreshTrigger=nil
end
-- Update counts without rebuilding a valid current objective or disturbing its queue.
local function updateProgress(previous,state)
    local route=previous and previous.route
    local old=previous and previous.state
    if not route or route.kind~="objective" or not route.objectiveIndex or not old or old.key~=state.key or old.level~=state.level or old.mapID~=state.mapID or old.revision~=state.revision then return false end
    if (old.combatSafety and old.combatSafety.revision or 0)~=(state.combatSafety and state.combatSafety.revision or 0) then return false end
    if #old.activeQuests~=#state.activeQuests then return false end
    local changed=false
    for _,q in ipairs(state.activeQuests) do
        local before=old.activeByID[q.id]
        if not before then return false end
        if q.fingerprint~=before.fingerprint then
            if q.id~=route.questID or q.failed or q.isComplete or not q.objectivesReady or #q.objectives~=#before.objectives then return false end
            if (q.waypoint and q.waypoint.mapID)~=(before.waypoint and before.waypoint.mapID) or (q.waypoint and q.waypoint.x)~=(before.waypoint and before.waypoint.x) or (q.waypoint and q.waypoint.y)~=(before.waypoint and before.waypoint.y) then return false end
            for i,row in ipairs(q.objectives) do
                local prior=before.objectives[i]
                if row.type~=prior.type or row.id~=prior.id or row.objectiveType~=prior.objectiveType or row.finished~=prior.finished then return false end
            end
            local row=q.objectives[route.objectiveIndex]
            if not row or row.finished then return false end
            route=W.Copy(route);route.remaining=math.max(0,row.required-row.fulfilled);route.required=row.required;route.fingerprint=q.fingerprint;route.economy=nil;route.economyModel=nil
            if route.objectiveKind~="item" and row.text~="" then route.instruction=row.text end
            changed=true
        end
    end
    if not changed then return false end
    previous.state=state;previous.route=route;W.State=state;W.CurrentRoute=route
    if not W.GetProfile().panelHidden then render("panel",W.UpdateUI) end;return true
end
function W.Refresh(force,trigger)
    if W.CancelPlanning then W.CancelPlanning() end
    if W.IsWorldMapOpen() or W.MapQuietRemaining>0 then counters.mapDeferrals=counters.mapDeferrals+1;W.MapRefreshPending=true;return end
    if W.IsCombatActive() then W.CombatRefreshPending=true;return end
    if trigger=="combat-ended" then W.CombatRefreshPending=nil end
    W.EnsureProvider()
    local started=debugprofilestop and debugprofilestop()
    W.ActiveRefreshTrigger=trigger or (force and "manual" or "refresh")
    W.LastAttemptTime=W.Now()
    render("experience",W.SampleExperience)
    local state,route,queue,detail;local captured=false;local scheduled=false
    local ok,errorText=pcall(function()
        counters.captures=counters.captures+1
        local status,result=W.TimedCall("character capture",W.ReadCharacter)
        if status~="ok" then error(result) end
        state=result;captured=true
        local previous=W.Decision
        local noisy=true;local checkFaction=false
        for event in string.gmatch(trigger or "", "[^,]+") do
            if event=="UPDATE_FACTION" then checkFaction=true
            elseif event~="QUEST_LOG_UPDATE" and event~="maintenance" and event~="XP_REVIEW" and event~="combat-ended" then noisy=false;break end
        end
        if checkFaction then local stamp=factionStamp();if not stamp or not previous or stamp~=previous.factionStamp then noisy=false end end
        if not trigger or trigger=="" then noisy=false end
        if not force and noisy and trigger and trigger:find("QUEST_LOG_UPDATE",1,true) and updateProgress(previous,state) then return end
        if not force and noisy and previous and previous.state.key==state.key and previous.state.signature==state.signature and (previous.state.combatSafety and previous.state.combatSafety.revision or 0)==(state.combatSafety and state.combatSafety.revision or 0) and not W.LastError then return end
        W.PlanExecutions=(W.PlanExecutions or 0)+1;W.LastRefreshTime=W.Now()
        if W.ShouldScheduleSelection and W.ShouldScheduleSelection(force,trigger) then
            local context={previous=previous and previous.route,commitment=previous and previous.commitment,trip=previous and previous.detail and previous.detail.trip,previousMapID=previous and previous.state.mapID,releasePlan=trigger=="manual-replan"}
            scheduled=true
            W.SchedulePlan(state,force,context,function(r,q,d)
                if W.LastError then W.RecoveredError=W.LastError;W.LastError=nil end
                publish(state,r,q,d,force,trigger,started)
            end,function(err) W.LastError=tostring(err);W.Refresh(true,"async-recovery") end)
            W.ActiveRefreshTrigger=nil;return
        end
        local planStatus
        planStatus,route,queue,detail=W.TimedCall("route planner",W.PlanRoute,state,force,{previous=previous and previous.route,commitment=previous and previous.commitment,trip=previous and previous.detail and previous.detail.trip,previousMapID=previous and previous.state.mapID,releasePlan=trigger=="manual-replan"})
        if planStatus~="ok" then error(route) end
        assert(type(route)=="table" and type(queue)=="table","Invalid planner result")
    end)
    if scheduled then return end
    if ok and not route then W.ActiveRefreshTrigger=nil;return end
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
    publish(state,route,queue,detail,force,trigger,started)
end
local function schedule(force,event)
    if W.CancelPlanning then W.CancelPlanning() end
    if W.IsWorldMapOpen() or W.MapQuietRemaining>0 then W.MapRefreshPending=true;return end
    if W.IsCombatActive() then W.CombatRefreshPending=true;return end
    if event then pendingEvents[event]=true end
    if pending then return end;pending=true
    local function update()
        pending=false;local events={};for name in pairs(pendingEvents) do events[#events+1]=name end;table.sort(events);pendingEvents={}
        W.Refresh(force,table.concat(events,","))
    end
    if C_Timer then C_Timer.After(.5,update) else update() end
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_COMPLETE","QUEST_DETAIL","QUEST_GREETING","GOSSIP_SHOW","PLAYER_LEVEL_UP","ZONE_CHANGED_NEW_AREA","ZONE_CHANGED","ZONE_CHANGED_INDOORS","PLAYER_ALIVE","PLAYER_UNGHOST","BAG_UPDATE_DELAYED","UPDATE_FACTION","SKILL_LINES_CHANGED","QUEST_QUERY_COMPLETE","PLAYER_XP_UPDATE","CHAT_MSG_COMBAT_XP_GAIN","PLAYER_FLAGS_CHANGED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED"}) do pcall(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event,...)
    counters.events[event]=(counters.events[event] or 0)+1
    W.LastEvent=event
    if (event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_INDOORS") and W.InvalidateNavigationAccess then W.InvalidateNavigationAccess() end
    if event=="PLAYER_REGEN_DISABLED" then W.SetCombatUI(true);return end
    if event=="PLAYER_REGEN_ENABLED" then
        W.SetCombatUI(false)
        if not W.IsWorldMapOpen() and W.MapQuietRemaining==0 then counters.safety=counters.safety+1;pollSafety() end
        W.Refresh(false,"combat-ended")
        return
    end
    if event=="PLAYER_LOGIN" then
        hookMap()
        W.EnsureProvider();W.SetCombatUI(liveCombat())
        W.ResetExperience();pollSafety();W.CreateUI();W.CreateNavigator();W.Refresh(false,"startup")
        if C_Timer then C_Timer.After(.5,function() W.BuildQuestCatalog() end) else W.BuildQuestCatalog() end
        print("|cff5dd4d6Trailwarden "..W.Version.."|r / Your character's route is ready. |cffffc366/tw|r opens the guide; |cffffc366/tw help|r lists controls.")
        return
    end
    local args={...}
    if event=="ADDON_LOADED" then
        if args[1]=="OpenMap" then if W.State then render("navigation",W.UpdateNavigation);render("route overlay",W.UpdateRouteOverlay) end end
        return
    end
    -- Only these events carry XP, turn-in or AFK timing information.
    -- Target and nameplate events can arrive in bursts and need no XP tick.
    if event=="PLAYER_XP_UPDATE" or event=="CHAT_MSG_COMBAT_XP_GAIN" or event=="PLAYER_FLAGS_CHANGED" or event=="QUEST_TURNED_IN" then
        render("XP event",W.ExperienceEvent,event,unpack(args))
    end
    if event=="PLAYER_TARGET_CHANGED" or event=="UPDATE_MOUSEOVER_UNIT" or event=="NAME_PLATE_UNIT_ADDED" or event=="NAME_PLATE_UNIT_REMOVED" then
        W.TrackCombatUnit(event,args[1])
        -- Nameplate bursts are sampled once by periodic maintenance. Never scan
        -- the entire visible population for every add/remove during a fight.
        if W.IsCombatActive() then W.CombatRefreshPending=true;return end
        if event~="PLAYER_TARGET_CHANGED" or W.IsWorldMapOpen() or W.MapQuietRemaining>0 then return end
        counters.safety=counters.safety+1
        local changed=pollSafety()
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
        if event=="PLAYER_XP_UPDATE" then render("experience",W.SampleExperience);if not W.IsCombatActive() and not W.GetProfile().panelHidden then render("live panel",W.UpdateLiveUI) end end
    else schedule(false,event) end
end)
local navElapsed,planElapsed,xpElapsed,combatElapsed=0,0,0,0
local mapWasOpen=false
local lastNavigationKey,lastCombatNavigationKey
frame:SetScript("OnUpdate",function(_,dt)
    combatElapsed=combatElapsed+dt
    if combatElapsed>=.1 then
        combatElapsed=0
        hookMap()
        local active=liveCombat()
        if active~=W.CombatActive and (type(InCombatLockdown)=="function" or type(UnitAffectingCombat)=="function") then
            W.SetCombatUI(active)
            if not active then
                if not W.IsWorldMapOpen() and W.MapQuietRemaining==0 then counters.safety=counters.safety+1;pollSafety() end
                W.Refresh(false,"combat-ended")
            end
        end
    end
    navElapsed=navElapsed+dt;planElapsed=planElapsed+dt;xpElapsed=xpElapsed+dt
    local mapOpen=W.IsWorldMapOpen()
    local mapChanged=mapWasOpen~=mapOpen
    if mapChanged then W.NoteMapInteraction() end
    mapWasOpen=mapOpen
    if not mapOpen and not mapChanged then W.MapQuietRemaining=math.max(0,W.MapQuietRemaining-dt) end
    if not mapOpen and W.MapQuietRemaining==0 and W.MapRefreshPending then W.MapRefreshPending=nil;schedule(false,"QUEST_LOG_UPDATE") end
    if W.CombatActive then
        planElapsed=0
        if navElapsed>=.1 then
            navElapsed=0
            if not W.GetProfile().navigatorHidden then
                local p=W.PlayerPoint();local key=table.concat({tostring(p and p.mapID),tostring(p and p.x),tostring(p and p.y),tostring(W.Safe(GetPlayerFacing)),tostring(W.Decision and W.Decision.id)},":")
                if key~=lastCombatNavigationKey then lastCombatNavigationKey=key;render("combat navigator",W.UpdateCombatNavigator) end
            end
        end
        if xpElapsed>=1 then xpElapsed=0;render("experience",W.SampleExperience) end
        return
    end
    if mapOpen or W.MapQuietRemaining>0 then
        -- Keep existing map pins stable while the map library is changing its
        -- canvas. Defer quest snapshots and access/waypoint work until closed.
        planElapsed=0
        if xpElapsed>=1 then xpElapsed=0;render("experience",W.SampleExperience) end
        return
    end
    local sampleUpdated=false
    if xpElapsed>=1 then
        xpElapsed=0;sampleUpdated=true;render("experience",W.SampleExperience)
        if W.State then render("route overlay",W.UpdateRouteOverlay) end
        counters.safety=counters.safety+1
        if pollSafety() then W.Refresh(false,"combat-safety") end
    end
    local panelUpdated=false
    if navElapsed>=.1 then
        navElapsed=0
        if W.State then
            local point=W.PlayerPoint();local facing=W.Safe(GetPlayerFacing)
            local key=table.concat({tostring(W.Decision and W.Decision.id),tostring(point and point.mapID),tostring(point and point.x),tostring(point and point.y),tostring(facing),tostring(W.Safe(IsIndoors)),tostring(W.Safe(GetSubZoneText)),tostring(W.NavigationAccessRevision)},":")
            local navigationChanged=key~=lastNavigationKey or W.NavigationError
            if navigationChanged then
                lastNavigationKey=key;render("navigation",W.UpdateNavigation)
                if not W.GetProfile().navigatorHidden then render("navigator",W.UpdateNavigator) end
            end
            if W.NavigationPanelRefresh then
                W.NavigationPanelRefresh=nil;render("navigation transition panel",W.UpdateUI);panelUpdated=true
            elseif not W.GetProfile().panelHidden and navigationChanged then render("live panel",W.UpdateLiveUI);panelUpdated=true end
        end
    end
    if sampleUpdated and W.State and not panelUpdated and not W.GetProfile().panelHidden then render("live panel",W.UpdateLiveUI) end
    if planElapsed>=2 then
        planElapsed=0
        if W.ProviderRebuildNeeded then W.BuildQuestCatalog(true);return end
        if W.State then
            local current,previous=W.PlayerPoint(),W.State.player
            local area=W.Safe(W.ReadWorkArea,current)
            local areaChanged=(area and area.id)~=(W.State.workArea and W.State.workArea.id)
            local changed=areaChanged or (current and not previous) or (previous and not current)
            if current and previous then changed=changed or current.mapID~=previous.mapID or W.TravelCost(current,previous)>=120 and W.Now()-(W.LastRefreshTime or 0)>=10 end
            local dead=W.Safe(UnitIsDeadOrGhost,"player")==true
            if changed or dead~=W.State.dead or (W.CurrentRoute and W.CurrentRoute.key=="error") then W.Refresh(false,changed and "movement" or dead~=W.State.dead and "life-state" or "maintenance") end
        end
    end
end)
