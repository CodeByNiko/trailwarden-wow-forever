local W=Wayfinder
local defaults={xpRouting=true,includeGroup=false,maxLevelAbove=2,navigatorHidden=false,mapSync=true,panelHidden=false,collapsed=false,uiScale=.9,navigatorScale=1,queueRows=2,paused=false,locked=false}
local function validID(id) return W.IsFinite(id) and id>0 and id%1==0 end
local function cleanPosition(pos)
    if type(pos)~="table" or type(pos.point)~="string" or type(pos.relativePoint)~="string" or not W.IsFinite(pos.x) or not W.IsFinite(pos.y) then return nil end
    local anchors={TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,CENTER=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    if not anchors[pos.point] or not anchors[pos.relativePoint] then return nil end
    return {point=pos.point,relativePoint=pos.relativePoint,x=pos.x,y=pos.y}
end
local validated=setmetatable({},{__mode="k"})
local function validateContents(p)
    for id,level in pairs(p.deferredLevels) do if not validID(id) or not W.IsFinite(level) or level<=0 then p.deferredLevels[id]=nil end end
    for id,done in pairs(p.completed) do if not validID(id) or done~=true then p.completed[id]=nil end end
    for id,untilTime in pairs(p.skipped) do if type(id)~="string" or not W.IsFinite(untilTime) or untilTime<=W.Now() then p.skipped[id]=nil end end
    for id,o in pairs(p.offers) do if not validID(id) or type(o)~="table" or not W.IsFinite(o.seen) or not W.IsFinite(o.revision) then p.offers[id]=nil end end
    for id,o in pairs(p.locations) do
        if type(id)~="string" or type(o)~="table" or o.units~="normalized" or not validID(o.entityID) or not W.IsFinite(o.seen) or not W.Point(o.mapID,o.x,o.y) then p.locations[id]=nil end
    end
    for id,g in pairs(p.gossip) do if not validID(id) or type(g)~="table" or type(g.offers)~="table" or not W.IsFinite(g.seen) then p.gossip[id]=nil end end
    validated[p]=true
end
function W.GetCharacterKey()
    return W.Safe(UnitGUID,"player") or ((W.Safe(UnitName,"player") or "Unknown").." - "..(W.Safe(GetRealmName) or "Realm"))
end
function W.GetProfile()
    if type(WayfinderDB)~="table" then WayfinderDB={} end
    if type(WayfinderDB.profiles)~="table" then WayfinderDB.profiles={} end
    local key=W.GetCharacterKey()
    local p=WayfinderDB.profiles[key]
    if type(p)~="table" then
        local oldKey=(W.Safe(UnitName,"player") or "Unknown").." - "..(W.Safe(GetRealmName) or "Realm")
        p=type(WayfinderDB.profiles[oldKey])=="table" and W.Copy(WayfinderDB.profiles[oldKey]) or {}
        WayfinderDB.profiles[key]=p
    end
    for k,v in pairs(defaults) do if type(p[k])~=type(v) then p[k]=v end end
    if p.displayVersion~=2 then
        if p.uiScale==1 then p.uiScale=.9 end
        p.displayVersion=2
    end
    if not W.IsFinite(p.uiScale) then p.uiScale=.9 end
    p.uiScale=math.max(.6,math.min(1.3,p.uiScale))
    if not W.IsFinite(p.navigatorScale) then p.navigatorScale=1 end
    p.navigatorScale=math.max(.6,math.min(1.5,p.navigatorScale))
    if p.queueRows~=0 and p.queueRows~=2 and p.queueRows~=4 then p.queueRows=2 end
    if p.maxLevelAbove~=2 and p.maxLevelAbove~=4 then p.maxLevelAbove=2 end
    for _,field in ipairs({"completed","skipped","offers","locations","gossip","deferredLevels"}) do if type(p[field])~="table" then p[field]={} end end
    if not validated[p] then validateContents(p) end
    for key,untilTime in pairs(p.skipped) do if not W.IsFinite(untilTime) or untilTime<=W.Now() then p.skipped[key]=nil end end
    p.panelPoint=cleanPosition(p.panelPoint);p.navigatorPoint=cleanPosition(p.navigatorPoint)
    if p.pinned~=nil and type(p.pinned)~="string" then p.pinned=nil end
    if p.lastSkipped and not p.skipped[p.lastSkipped] then p.lastSkipped=nil end
    if not W.IsFinite(p.progressRevision) then p.progressRevision=0 end
    if not W.IsFinite(p.schema) or p.schema<3 then p.waterTotemStage=nil;p.schema=3 end
    return p
end
function W.RememberTurnIn(id) if validID(id) then W.GetProfile().completed[id]=true end end
local function done(v) return v==true or v==1 end
function W.ReadCharacter()
    local p=W.GetProfile();validateContents(p)
    local className,classToken=W.Safe(UnitClass,"player")
    local raceName,raceToken,raceID=W.Safe(UnitRace,"player")
    local mapID=C_Map and W.Safe(C_Map.GetBestMapForUnit,"player")
    local state={key=W.GetCharacterKey(),name=W.Safe(UnitName,"player") or "Adventurer",className=className or "Unknown",classToken=classToken,raceName=raceName or "Unknown",raceToken=raceToken,raceID=raceID,
        classMask=W.ClassMasks[classToken],raceMask=W.ClassicRaceMasks[raceID],faction=W.Safe(UnitFactionGroup,"player"),level=W.Safe(UnitLevel,"player") or 1,
        mapID=mapID,zone=mapID and W.MapName(mapID) or W.Safe(GetRealZoneText) or "Unknown area",now=W.Now(),provider=W.ProviderIdentity(),
        activeQuests={},activeByID={},player=W.PlayerPoint(),dead=W.Safe(UnitIsDeadOrGhost,"player")==true,readIssues={}}
    if LibQuestieDB and LibQuestieDB.RequireContract and W.Safe(LibQuestieDB.RequireContract,3) then
        state.raceMask=(LibQuestieDB.Enum and LibQuestieDB.Enum.raceMaskById or {})[raceID] or state.raceMask
    end
    local ql=C_QuestLog or {}
    state.capabilities={questLog=type(ql.GetInfo)=="function",objectives=type(ql.GetQuestObjectives)=="function",completedHistory=type(ql.GetAllCompletedQuestIDs)=="function",clientWaypoint=type(ql.GetNextWaypoint)=="function"}
    local historyStatus,completed=W.Call(ql.GetAllCompletedQuestIDs)
    state.historyReady=historyStatus=="ok" and type(completed)=="table"
    if state.historyReady then
        for _,id in ipairs(completed) do if validID(id) then p.completed[id]=true else state.historyReady=false end end
    elseif GetQuestsCompleted then
        local into={};local status,result=W.Call(GetQuestsCompleted,into)
        result=type(result)=="table" and result or into
        if status=="ok" then
            state.historyReady=true
            for id,v in pairs(result) do if validID(id) and v==true then p.completed[id]=true elseif validID(v) then p.completed[v]=true end end
        end
    end
    if not state.historyReady then state.readIssues[#state.readIssues+1]="Completed quest history unavailable" end
    local logStatus,count,totalQuests=W.Call(ql.GetNumQuestLogEntries)
    state.questLogReady=logStatus=="ok" and W.IsFinite(count) and count>=0 and count%1==0
    for i=1,state.questLogReady and count or 0 do
        local status,info=W.Call(ql.GetInfo,i)
        if status~="ok" or type(info)~="table" then state.questLogReady=false
        elseif not info.isHeader and validID(info.questID) then
            local id=info.questID
            local q={id=id,title=info.title or "Quest",level=W.IsFinite(info.level) and info.level or nil,logIndex=i,objectives={},isComplete=done(info.isComplete) or done(W.Safe(ql.IsComplete,id)) or done(W.Safe(ql.ReadyForTurnIn,id)),failed=info.isComplete==-1}
            local objectiveStatus,rows=W.Call(ql.GetQuestObjectives,id)
            q.objectivesReady=objectiveStatus=="ok" and type(rows)=="table"
            for j,o in ipairs(q.objectivesReady and rows or {}) do
                if type(o)~="table" then q.objectivesReady=false
                else
                    if type(o.type)~="string" or o.numFulfilled~=nil and not W.IsFinite(o.numFulfilled) or o.numRequired~=nil and not W.IsFinite(o.numRequired) then q.objectivesReady=false end
                    q.objectives[j]={text=type(o.text)=="string" and o.text or "",type=o.type,objectiveType=o.objectiveType,id=o.objectiveID,fulfilled=o.numFulfilled or 0,required=o.numRequired or 0,finished=done(o.finished)} end
            end
            local m,x,y=W.Safe(ql.GetNextWaypoint,id);q.waypoint=W.Point(m,x,y)
            if q.waypoint then q.waypoint.source="Client waypoint" end
            local fingerprint={tostring(id),tostring(q.isComplete),tostring(q.objectivesReady)}
            for _,o in ipairs(q.objectives) do fingerprint[#fingerprint+1]=table.concat({tostring(o.type),tostring(o.objectiveType),tostring(o.id),tostring(o.fulfilled),tostring(o.required),tostring(o.finished)},":") end
            q.fingerprint=table.concat(fingerprint,"/")
            state.activeQuests[#state.activeQuests+1]=q;state.activeByID[id]=q
        elseif not info.isHeader then state.questLogReady=false end
    end
    -- Forever reports shown entries separately from total quests. A collapsed or
    -- changing log must not make hidden active quests appear absent.
    if totalQuests~=nil and (not W.IsFinite(totalQuests) or totalQuests<0 or totalQuests%1~=0 or totalQuests~=#state.activeQuests) then
        state.questLogReady=false
        state.readIssues[#state.readIssues+1]="Quest log is incomplete; expand quest headers and refresh"
    end
    table.sort(state.activeQuests,function(a,b) return a.id<b.id end)
    state.completed=W.Copy(p.completed);state.completedCount=W.Count(state.completed)
    local progress={state.key,tostring(state.level),tostring(state.classMask),tostring(state.raceMask)}
    local signature={tostring(mapID),tostring(state.level),tostring(state.questLogReady),tostring(state.historyReady)}
    for _,q in ipairs(state.activeQuests) do progress[#progress+1]=tostring(q.id);signature[#signature+1]=q.fingerprint end
    local ids={};for id in pairs(state.completed) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do progress[#progress+1]="c"..id end
    local progressSignature=table.concat(progress,"|")
    if p.progressSignature~=progressSignature then p.progressSignature=progressSignature;p.progressRevision=p.progressRevision+1 end
    state.revision=p.progressRevision;state.signature=table.concat(signature,"|")..":"..progressSignature
    for id,level in pairs(p.deferredLevels) do
        if state.completed[id] or state.activeByID[id] and state.activeByID[id].isComplete or level<=state.level+p.maxLevelAbove or state.questLogReady and not state.activeByID[id] then p.deferredLevels[id]=nil end
    end
    if p.lastDeferred and not p.deferredLevels[p.lastDeferred] then p.lastDeferred=nil end
    state.profile=W.Copy(p)
    local limit=W.Safe(ql.GetMaxNumQuestsCanAccept)
    state.logLimit=W.IsFinite(limit) and limit>0 and limit%1==0 and limit or (W.IsFinite(MAX_QUESTLOG_QUESTS) and MAX_QUESTLOG_QUESTS>0 and MAX_QUESTLOG_QUESTS or 25)
    state.freeSlots=math.max(0,state.logLimit-#state.activeQuests)
    if W.CombatSafetySnapshot then state.combatSafety=W.CombatSafetySnapshot(state) end
    if W.ObserveExperienceProgress then
        local status,message=W.Call(W.ObserveExperienceProgress,state)
        W.LearningError=status~="ok" and tostring(message) or nil
        local xpStatus,xp=W.Call(W.ExperienceStats)
        if xpStatus=="ok" and type(xp)=="table" then state.experience=xp else W.LearningError=tostring(xp) end
    end
    return state
end
function W.ScanCharacter() local state=W.ReadCharacter();W.State=state;return state end
local function npcIdentity()
    local guid=W.Safe(UnitGUID,"npc") or ""
    local kind=guid:match("^(%a+)%-")
    local id=tonumber(guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
    return id,kind=="GameObject" and "Object" or "Npc",guid
end
function W.ObserveQuest(id,title,kind,state)
    if not validID(id) then return end
    local p=W.GetProfile();state=state or W.ReadCharacter()
    local point=W.PlayerPoint();local npc=W.Safe(UnitName,"npc");local entityID,entityKind,guid=npcIdentity()
    if point and npc and entityID then
        p.locations[kind..":"..id]={mapID=point.mapID,x=point.x,y=point.y,units="normalized",name=npc,entityID=entityID,entityKind=entityKind,guid=guid,seen=state.now,provider=W.Copy(state.provider),confidence="interaction-area"}
    end
    if kind=="pickup" then p.offers[id]={title=title,seen=state.now,revision=state.revision} end
end
function W.ObserveGossip()
    local g=C_GossipInfo or {};local status,available=W.Call(g.GetAvailableQuests)
    if status~="ok" or type(available)~="table" then return end
    local state=W.ReadCharacter();local offered={}
    for _,q in ipairs(available) do if type(q)=="table" and validID(q.questID) then W.ObserveQuest(q.questID,q.title,"pickup",state);offered[q.questID]=true end end
    local id=npcIdentity()
    if id then W.GetProfile().gossip[id]={offers=offered,seen=state.now,revision=state.revision} end
    for _,q in ipairs(W.Safe(g.GetActiveQuests) or {}) do if q.isComplete==true or q.isComplete==1 then W.ObserveQuest(q.questID,q.title,"turnin",state) end end
end
function W.SkipCurrent()
    local r=W.CurrentRoute
    if r and r.kind=="grind" then W.EndGrindBreak();W.Refresh(true);return end
    if r and r.key then local p=W.GetProfile();local key=r.questID and ("quest:"..r.questID) or r.key;p.skipped[key]=W.Now()+900;p.lastSkipped=key;p.lastDeferred=nil;p.pinned=nil;W.CurrentRoute=nil;W.Refresh(true) end
end
function W.DeferLevel(r,s)
    if r and s and r.questID and s.activeByID[r.questID] and r.kind~="turnin" and r.level and r.level>s.level+s.profile.maxLevelAbove then return r.level-s.profile.maxLevelAbove end
end
function W.DeferCurrent()
    local r=W.CurrentRoute;local s=W.State
    if not W.DeferLevel(r,s) then return end
    local p=W.GetProfile();p.deferredLevels[r.questID]=r.level;p.lastDeferred=r.questID;p.lastSkipped=nil;p.pinned=nil
    W.Refresh(true,"defer-until-level")
end
function W.UndoSkip()
    local p=W.GetProfile();if p.lastDeferred then p.deferredLevels[p.lastDeferred]=nil;p.lastDeferred=nil end;if p.lastSkipped then p.skipped[p.lastSkipped]=nil;p.lastSkipped=nil end;W.Refresh(true)
end

