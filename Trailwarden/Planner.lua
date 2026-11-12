local W=Trailwarden
local labels={pickup="Accept: ",turnin="Turn in: ",objective="Quest: ",escort="Escort: ",deliver="Speak about: ",item="Start: "}
local function makeStep(kind,q,point,target,suffix,source,objectiveText)
    local name=q.title or q.name or W.Q(q.id,"name") or ("Quest "..q.id)
    local instruction
    if kind=="pickup" then instruction="Speak with "..target.." and accept this quest. The next step appears when it enters your quest log."
    elseif kind=="turnin" then instruction="Return to "..target.." and turn in this completed quest. Follow-up quests are considered after turn-in."
    elseif kind=="deliver" then instruction="Speak with "..target.." to continue this delivery or conversation quest."
    elseif kind=="item" then instruction="Use "..target.." in your bags to begin this quest."
    else instruction=objectiveText or ("Work around "..target.." until the quest objective updates.") end
    return {kind=kind,key=W.StepKey(kind,q.id,suffix),questID=q.id,questName=name,title=(labels[kind] or "")..name,point=point,
        mapID=point and point.mapID,x=point and point.x,y=point and point.y,target=target,instruction=instruction,source=source or "QuestieDB",level=q.level or W.Q(q.id,"questLevel"),fingerprint=q.fingerprint,combatRisk=point and point.combatRisk,classQuest=(W.Q(q.id,"requiredClasses") or 0)>0,targetRevision=(point and point.source or source or "database")..":"..tostring(point and point.observedAt or W.PublishedCatalogGeneration or 0)..":"..tostring(point and point.combatRisk and point.combatRisk.signature or "noncombat")..((source or point and point.source)=="Client waypoint" and (":"..tostring(q.waypoint and q.waypoint.mapID or "")..":"..tostring(q.waypoint and q.waypoint.x or "")..":"..tostring(q.waypoint and q.waypoint.y or "")) or "")}
end
local function nearestObjective(points,state)
    if state.workArea and W.MatchCave then
        local localPoints={}
        for _,point in ipairs(points) do
            local cave=W.MatchCave({mapID=point.mapID,point=point})
            if cave and cave.id==state.workArea.id then localPoints[#localPoints+1]=point end
        end
        if #localPoints>0 then return W.NearestPoint(localPoints,state.player,state.mapID) end
    end
    return W.NearestPoint(points,state.player,state.mapID)
end
local function relationPoint(q,field,kind,state)
    local seen=W.ObservedPoint(q.id,kind,state)
    if seen then return seen,"Observed in game" end
    local points=W.RelationPoints(q.id,field)
    return (kind=="pickup" and nearestObjective(points,state) or W.NearestPoint(points,state.player,state.mapID)),"QuestieDB"
end
local typeName={[1]="monster",[2]="object",[3]="item"}
local function matchObjectiveRows(q,group,entries)
    local kind=typeName[group]
    local entityKind=group==1 and "Npc" or group==2 and "Object" or "Item"
    local typed={}
    for _,row in ipairs(q.objectives) do if row.type==kind then typed[#typed+1]=row end end
    local matched,used={},{}
    local function validEntityID(value) return type(value)=="number" and W.IsFinite(value) and value>0 and value%1==0 end
    -- The client's objective ID is useful only inside the matching objective
    -- type. Duplicate IDs on either side are not authoritative.
    for rowIndex,row in ipairs(typed) do
        if validEntityID(row.id) then
            local candidateIndex,candidateCount=nil,0
            for i,candidate in ipairs(entries) do if validEntityID(candidate[1]) and candidate[1]==row.id then candidateIndex=i;candidateCount=candidateCount+1 end end
            local rowCount=0;for _,other in ipairs(typed) do if other.id==row.id then rowCount=rowCount+1 end end
            if candidateCount==1 and rowCount==1 then matched[candidateIndex]=row;used[rowIndex]=true end
        end
    end
    -- Fall back to text only when it identifies one remaining provider entity
    -- unambiguously. Never infer completion from provider/list order.
    local proposals={}
    for rowIndex,row in ipairs(typed) do if not used[rowIndex] and type(row.text)=="string" then
        local winner,length,tied=nil,0,false
        for i,candidate in ipairs(entries) do
            local name=W.DBGet(entityKind,candidate[1],"name")
            if type(name)=="string" and name~="" and string.find(string.lower(row.text),string.lower(name),1,true) then
                if #name>length then winner,length,tied=i,#name,false elseif #name==length then tied=true end
            end
        end
        if winner and not tied then proposals[rowIndex]=winner end
    end end
    local proposalCounts={};for _,candidateIndex in pairs(proposals) do proposalCounts[candidateIndex]=(proposalCounts[candidateIndex] or 0)+1 end
    for rowIndex,candidateIndex in pairs(proposals) do
        if proposalCounts[candidateIndex]==1 and not matched[candidateIndex] then matched[candidateIndex]=typed[rowIndex] end
    end
    -- A sole live row and sole provider entity form a unique pair even when
    -- the client omits objective IDs and localized text omits the entity name.
    if #typed==1 and #entries==1 and not matched[1] then matched[1]=typed[1] end
    return matched
end
local function entityObjectivePoints(kind,id,state,blocked,combat)
    if kind=="Npc" and combat~=false then return W.CombatPoints(id,state,blocked) end
    return W.EntityPoints(kind,id)
end
local function itemPoints(id,state,blocked)
    local out={};local hasSource=false
    for field,kind in pairs({npcDrops="Npc",objectDrops="Object",vendors="Npc"}) do
        for _,entityID in ipairs(W.DBGet("Item",id,field) or {}) do
            hasSource=true
            for _,point in ipairs(entityObjectivePoints(kind,entityID,state,blocked,field=="npcDrops")) do
                local source=W.Copy(point);source.acquisition=field;out[#out+1]=source
            end
        end
    end
    if not hasSource then blocked[#blocked+1]={status="unknown",reason="Item source level data unavailable"} end
    return out
end
local function spawnPoints(spawns)
    local out={}
    for area,coords in pairs(spawns or {}) do
        local m=W.MapForArea(area)
        for _,c in ipairs(coords) do local p=W.PercentPoint(m,c[1],c[2]);if p then out[#out+1]=p end end
    end
    return out
end
-- Activity metadata, not quest IDs: event text marks escorts across old/new content.
local function escortText(id)
    local trigger=W.Q(id,"triggerEnd")
    local text=trigger and trigger[1]
    if type(text)=="string" and string.lower(text):find("escort",1,true) then return text end
end
function W.ActiveSteps(q,state)
    local blocked={}
    local out={safetyBlocked=blocked}
    if q.failed then return out end
    if q.isComplete then
        local p,source=relationPoint(q,"finishedBy","turnin",state)
        p=p or q.waypoint
        if p then out[1]=makeStep("turnin",q,p,p.name or "the quest receiver","",source) end
        return out
    end
    if q.objectivesReady~=true then return out end
    local escort=escortText(q.id)
    if escort then
        local starters=W.Q(q.id,"startedBy") or {};local npcID=starters[1] and starters[1][1]
        local target=npcID and W.DBGet("Npc",npcID,"name") or "the escort NPC"
        local step=makeStep("escort",q,nil,target,"event","QuestieDB",escort)
        step.activity="escort";step.instruction="Stay with "..target.." and protect the escort. Other quest routes wait for completion or failure."
        out[1]=step;return out
    end
    local objectives=W.Q(q.id,"objectives") or {}
    for group=1,3 do
        local entries=objectives[group] or {}
        local liveByEntry=matchObjectiveRows(q,group,entries)
        for i,entry in ipairs(entries) do
            local live=liveByEntry[i];local text=live and live.text
            if not live then
                blocked[#blocked+1]={status="unknown",reason="Live objective could not be matched safely to its provider target"}
            elseif not live.finished then
                local riskStart=#blocked
                local kind=group==1 and "Npc" or "Object"
                local points=group==3 and itemPoints(entry[1],state,blocked) or entityObjectivePoints(kind,entry[1],state,blocked)
                local p=nearestObjective(points,state)
                if p then
                    while #blocked>riskStart do table.remove(blocked) end
                    local target=W.DBGet(group==3 and "Item" or kind,entry[1],"name") or p.name or "the objective area"
                    local detail=text or (group==1 and "Defeat " or group==2 and "Interact with " or "Collect ")..target.."."
                    if group==3 then
                        local action=p.acquisition=="vendors" and "Buy from " or p.acquisition=="objectDrops" and "Search " or "Defeat "
                        detail=(text and (text..". ") or ("Collect "..target..". "))..action..(p.name or "the source").."."
                    end
                    local step=makeStep("objective",q,p,target,typeName[group]..":"..entry[1],"QuestieDB",detail)
                    step.objectiveKind=typeName[group];step.objectiveID=entry[1]
                    step.remaining=live and math.max(0,live.required-live.fulfilled);step.required=live and live.required
                    if live then for index,row in ipairs(q.objectives) do if row==live then step.objectiveIndex=index;break end end end
                    out[#out+1]=step
                end
            end
        end
    end
    -- Kill-credit objectives can credit several creature types.
    for i,entry in ipairs(objectives[5] or {}) do
        local live=entry[4] and entry[4]>0 and q.objectives[entry[4]]
        if not live or not live.finished then
            local riskStart=#blocked
            local points={}
            for _,id in ipairs(entry[1] or {}) do for _,p in ipairs(entityObjectivePoints("Npc",id,state,blocked)) do points[#points+1]=p end end
            local p=nearestObjective(points,state)
            if p then while #blocked>riskStart do table.remove(blocked) end;out[#out+1]=makeStep("objective",q,p,p.name or "the target","credit:"..i,"QuestieDB",live and live.text) end
        end
    end
    local trigger=W.Q(q.id,"triggerEnd")
    if #out==0 and #blocked==0 and trigger and trigger[2] then
        local uncertain=false
        for _,row in ipairs(q.objectives) do if not row.finished and (row.type=="monster" or row.type=="item") then uncertain=true end end
        if uncertain then blocked[#blocked+1]={status="unknown",reason="Quest event has no verified combat source"} end
        local p=not uncertain and nearestObjective(spawnPoints(trigger[2]),state)
        if p then out[#out+1]=makeStep("objective",q,p,"the quest event","event","QuestieDB",trigger[1]) end
    end
    if #out==0 then
        for i,extra in ipairs(W.Q(q.id,"extraObjectives") or {}) do
            local live=extra[4] and extra[4]>0 and q.objectives[extra[4]]
            if not live or not live.finished then
                local riskStart=#blocked
                local combatRefs=false
                for _,ref in ipairs(extra[5] or {}) do if ref[1]=="monster" then combatRefs=true end end
                local points=combatRefs and {} or spawnPoints(extra[1])
                for _,ref in ipairs(extra[5] or {}) do
                    local kind=ref[1]=="monster" and "Npc" or ref[1]=="object" and "Object"
                    if kind then for _,p in ipairs(entityObjectivePoints(kind,ref[2],state,blocked)) do points[#points+1]=p end end
                end
                local p=nearestObjective(points,state)
                if p and live and live.type=="monster" and not p.combatRisk then blocked[#blocked+1]={status="unknown",reason="Extra objective combat levels unverified"};p=nil end
                if p then while #blocked>riskStart do table.remove(blocked) end;out[#out+1]=makeStep("objective",q,p,p.name or "the quest area","extra:"..i,"QuestieDB",extra[3]) end
            end
        end
    end
    if #out==0 and #blocked==0 and q.waypoint then
        local uncertainCombat=false
        for _,row in ipairs(q.objectives) do if not row.finished and (row.type=="monster" or row.type=="item") then uncertainCombat=true end end
        if uncertainCombat then blocked[#blocked+1]={status="unknown",reason="Client waypoint has no verified combat source"}
        else out[1]=makeStep("objective",q,q.waypoint,"the next quest target","client","Client waypoint") end end
    local hasDBObjectives=next(objectives)~=nil or trigger or W.Q(q.id,"extraObjectives")
    if #out==0 and #q.objectives==0 and not hasDBObjectives and W.QuestFieldsHealthy(q.id) then
        local p,source=relationPoint(q,"finishedBy","turnin",state)
        if p then out[1]=makeStep("deliver",q,p,p.name or "the quest receiver","",source) end
    end
    return out
end
local function appendPickups(out,mapID,state,gates)
    local seen={}
    local function add(id,name)
        if seen[id] then return end
        seen[id]=true
        local verdict=W.QuestEligibility(id,state);gates[id]=verdict
        if verdict.status~="eligible" then return end
        local p,source=relationPoint({id=id},"startedBy","pickup",state)
        if p and p.mapID==mapID then
            local step=makeStep("pickup",{id=id,title=name},p,p.name or "the quest giver","",source);step.eligibility=verdict;step.activity=escortText(id) and "escort" or nil;out[#out+1]=step
        end
    end
    for _,record in ipairs((W.CatalogByMap or {})[mapID] or {}) do
        if record.minLevel<=state.level and (record.level==0 or record.level>=state.level-6) and record.level<=state.level+state.profile.maxLevelAbove then add(record.id,record.name) end
    end
    for id,offer in pairs(state.profile.offers) do if offer.revision==state.revision and state.now-offer.seen>=0 and state.now-offer.seen<300 then add(id,offer.title) end end
end
local function itemPickups(out,state)
    for _,e in ipairs(W.ItemQuests or {}) do
        if e.record.minLevel<=state.level and W.IsQuestAvailable(e.record.id,state) then
            for _,id in ipairs(e.items) do
                local count=(C_Item and W.Safe(C_Item.GetItemCount,id)) or W.Safe(GetItemCount,id) or 0
                if count>0 then
                    out[#out+1]=makeStep("item",e.record,nil,W.DBGet("Item",id,"name") or "the quest-starting item","","Inventory")
                    break
                end
            end
        end
    end
end
local forecastCache
local function forecastCandidates(out,state)
    local keys={tostring(state.workArea and state.workArea.id),tostring(state.combatSafety and state.combatSafety.revision),tostring(state.revision),tostring(W.PublishedCatalogGeneration),tostring(state.profile.maxLevelAbove)}
    for _,c in ipairs(out) do keys[#keys+1]=c.key..":"..tostring(c.mapID)..":"..tostring(c.x)..":"..tostring(c.y)..":"..tostring(c.targetRevision)..":"..tostring(c.fingerprint)..":"..tostring(c.remaining)..":"..tostring(c.required)..":"..tostring(state.profile.skipped[c.key] or state.profile.skipped["quest:"..c.questID] or 0)..":"..tostring((state.profile.deferredLevels or {})[c.questID] or 0) end
    table.sort(keys);local stamp=table.concat(keys,"|")
    local cache=forecastCache
    if cache and cache.owner==state.key and cache.stamp==stamp and state.now-cache.at<45 and W.TravelCost(cache.player,state.player)<300 then
        for _,c in ipairs(out) do
            c.economyModel=W.Copy(cache.models[c.key]);c.economy=W.ProjectQuestXP(c.economyModel,state.player,state.experience)
        end
        state.experience.referenceRate=cache.referenceRate
        W.ForecastCacheHits=(W.ForecastCacheHits or 0)+1
        W.RecordFact("Planning",0,"forecastCacheAt",cache.at,"cached")
        return
    end
    W.ForecastBuilds=(W.ForecastBuilds or 0)+1
    local status,message=W.Call(W.PrepareQuestEconomies,out,state)
    W.ForecastError=status~="ok" and tostring(message) or nil
    if status~="ok" then for _,c in ipairs(out) do c.economy=nil;c.economyModel=nil end;return end
    local models={};for _,c in ipairs(out) do models[c.key]=W.Copy(c.economyModel) end
    forecastCache={owner=state.key,stamp=stamp,at=state.now,player=W.Copy(state.player),referenceRate=state.experience.referenceRate,models=models}
end
-- Candidate collection is the only routing layer that reads provider APIs.
function W.CollectCandidates(state)
    local out,deferred,gates={},{},{}
    local transitionStatus
    if state.questLogReady then
        for _,q in ipairs(state.activeQuests) do
            local allowed,why=W.QuestPolicy(q.id,state,true)
            if q.isComplete or (allowed and not q.failed) then
                local status,steps=W.Call(W.ActiveSteps,q,state)
                if status~="ok" or type(steps)~="table" then
                    W.TargetErrors=W.TargetErrors or {};W.TargetErrors[q.id]=tostring(steps)
                    steps={};deferred[#deferred+1]={id=q.id,title=q.title,reason="Target data temporarily unavailable"}
                elseif W.TargetErrors then W.TargetErrors[q.id]=nil end
                for _,c in ipairs(steps) do out[#out+1]=c end
                if #steps==0 and not q.isComplete and state.workFocus and state.workFocus.questID==q.id then
                    out[#out+1]={kind="wait",key="work-review:"..q.id,questID=q.id,questName=q.title,title="Review: "..q.title,level=q.level,reviewWork=true,
                        instruction="Your current quest is unfinished, but its next safe target is unavailable. Review Questie or skip explicitly to leave this work area.",reason="Recent local quest progress; target data needs review.",source="Live quest progress"}
                end
                if steps.safetyBlocked and #steps.safetyBlocked>0 then
                    local risk=steps.safetyBlocked[1]
                    deferred[#deferred+1]={id=q.id,title=q.title,reason=risk.reason,safety=true,resumeLevel=risk.resumeLevel,risks=W.Copy(steps.safetyBlocked)}
                end
                if #steps==0 and status=="ok" and #(steps.safetyBlocked or {})==0 then deferred[#deferred+1]={id=q.id,title=q.title,reason=q.objectivesReady and "No mapped target" or "Objective state unavailable"} end
            else deferred[#deferred+1]={id=q.id,title=q.title,reason=why or "Failed quest"} end
        end
        if state.freeSlots>0 then appendPickups(out,state.regionMapID or state.mapID,state,gates);itemPickups(out,state) end
        local localActions=0
        for _,c in ipairs(out) do if c.mapID==state.mapID or c.kind=="item" then localActions=localActions+1 end end
        if (localActions==0 or state.experience and state.experience.enabled) and state.freeSlots>0 and W.CatalogReady then
            local zoneID=state.regionMapID or state.mapID
            local zone=W.Zones[zoneID];local maps={}
            if zone then for _,id in ipairs(zone.next or {}) do if W.Zones[id] then maps[id]=true else transitionStatus="missing-edge-target" end end
            else transitionStatus="unmapped-zone" end
            if next(maps)==nil then for id,z in pairs(W.Zones) do if zone and z.region==zone.region and z.min<=state.level and z.max>=state.level then maps[id]=true end end end
            if next(maps)==nil and not transitionStatus then transitionStatus="no-supported-neighbor" elseif next(maps)~=nil then transitionStatus=nil end
            local ordered={};for id in pairs(maps) do ordered[#ordered+1]=id end;table.sort(ordered)
            for _,id in ipairs(ordered) do if id~=state.mapID then appendPickups(out,id,state,gates) end end
        end
    end
    for _,c in ipairs(out) do
        c.ownerKey=state.key
        local cave=W.MatchCave and W.MatchCave(c)
        if cave then c.workAreaID=cave.id;c.regionMapID=cave.mapID
        else
            c.regionMapID=W.Safe(W.QuestRegion,c.mapID) or c.mapID
            if state.workArea and c.mapID==state.mapID and c.regionMapID~=c.mapID then c.workAreaID=state.workArea.id end
        end
    end
    if W.PrepareQuestEconomies and state.experience and state.experience.enabled then forecastCandidates(out,state) end
    local policyUnknown=false;for _,gate in pairs(gates) do if gate.status=="unknown" and gate.source=="policy" then policyUnknown=true;break end end
    return {candidates=out,deferred=deferred,gates=gates,policyUnknown=policyUnknown,transitionStatus=transitionStatus,ready=W.CatalogReady==true,databaseStatus=W.DatabaseStatus or "Waiting for quest data",catalogState=W.CatalogState,catalogError=W.CatalogError,catalogGeneration=W.PublishedCatalogGeneration or 0}
end
W.RouteWeights={turninFactor=.8,turninBonus=-450,turninFullRadius=250,turninFadeRadius=1000,pickupFactor=.95,pickupBase=180,nearPickupRadius=350,nearPickupBonus=-420,deliveryFactor=.9,deliveryBase=30,item=-800,objectiveBase=70,clusterRadius=300,clusterBonus=-65,clusterLimit=4,zonePenalty=800,classBonus=-60,fullLogBonus=-500,switchMargin=120,switchRatio=.18,workAreaRadius=450,leaveWorkAreaPenalty=450,leaveAreaMargin=75,xpBias=1000}
local function planningMap(c) return c.regionMapID or c.mapID end
local function clusterCounts(all,w)
    local counts={}
    for _,candidate in ipairs(all) do
        local count,seen=0,{}
        if candidate.point then
            for _,other in ipairs(all) do
                if other.questID~=candidate.questID and other.point and not seen[other.questID] and W.TravelCost(candidate.point,other.point)<w.clusterRadius then
                    count=count+1;seen[other.questID]=true
                end
            end
        end
        counts[candidate.key]=count
    end
    return counts
end
local function score(c,state,all,origin,w,releaseArea,clusters)
    local d=c.kind=="item" and 0 or W.TravelCost(origin,c.point)
    local cluster=clusters and clusters[c.key] or 0
    local action=0
    if c.kind=="turnin" then
        local proximity=math.max(0,math.min(1,(w.turninFadeRadius-d)/(w.turninFadeRadius-w.turninFullRadius)))
        action=d*(w.turninFactor-1)+w.turninBonus*proximity
    elseif c.kind=="pickup" then action=d*(w.pickupFactor-1)+w.pickupBase+(d<w.nearPickupRadius and w.nearPickupBonus or 0)
    elseif c.kind=="deliver" then action=d*(w.deliveryFactor-1)+w.deliveryBase
    elseif c.kind=="item" then action=w.item else action=w.objectiveBase end
    local parts={distance=d,action=action,cluster=math.min(cluster,w.clusterLimit)*w.clusterBonus,zone=c.point and planningMap(c)~=(state.regionMapID or state.mapID) and w.zonePenalty or 0,class=c.classQuest and w.classBonus or 0,capacity=state.freeSlots<3 and c.kind=="turnin" and w.fullLogBonus or 0}
    parts.batching=0
    -- Leaving a work area is a priority boundary, not an XP/distance discount.
    -- It applies to remote objectives too, including objectives of the same quest.
    local blocked=false
    if c.point and not releaseArea then
        for _,other in ipairs(all) do
            local near=other.point and W.TravelCost(origin,other.point)
            if other.kind=="objective" and other.key~=c.key then
                local caveWork=state.workArea and state.workArea.kind=="cave" and other.workAreaID==state.workArea.id
                local nearbyWork=near and near<=w.workAreaRadius and (not state.workArea or state.workArea.kind~="cave" or other.workAreaID==state.workArea.id)
                local leavesCave=caveWork and c.workAreaID~=state.workArea.id
                local leavesArea=nearbyWork and d>w.workAreaRadius
                local startsEscort=c.activity=="escort" and c.kind=="pickup" and (caveWork or nearbyWork)
                local leavesForTown=nearbyWork and (c.kind=="turnin" or c.kind=="pickup" or c.kind=="deliver") and d>math.max(120,near+(w.leaveAreaMargin or 75))
                if leavesCave or leavesArea or leavesForTown or startsEscort then parts.batching=w.leaveWorkAreaPenalty;blocked=true;break end
            elseif other.kind=="pickup" and other.key~=c.key then
                local inArea=state.workArea and other.workAreaID==state.workArea.id
                local opportunity=inArea or near and near<=120 and (not state.workArea or state.workArea.kind~="cave" or other.workAreaID==state.workArea.id)
                local leaving=inArea and c.workAreaID~=state.workArea.id or near and d>w.workAreaRadius
                if opportunity and leaving then parts.batching=w.leaveWorkAreaPenalty;blocked=true;break end
            end
        end
    end
    parts.efficiency=0
    if state.experience and state.experience.enabled and c.economyModel then
        local projected=W.ProjectQuestXP(c.economyModel,origin,state.experience)
        local baseline=parts.distance+parts.action+parts.cluster+parts.zone+parts.class+parts.capacity+parts.batching
        -- Full-cycle XP already includes travel/work. Do not charge distance
        -- a second time; the helper also fails closed for low-confidence models.
        parts.efficiency=W.XPRouteEfficiency(projected,state.experience,baseline,w.xpBias or 1000)
    end
    local value=parts.distance+parts.action+parts.cluster+parts.zone+parts.class+parts.capacity+parts.batching+parts.efficiency
    return value,parts,cluster,blocked
end
local function fallback(input)
    local s,m=input.state,input.meta
    local title,text="Finding your next quest"
    if not s.questLogReady then title="Waiting for your quest log";text="The live quest log is not ready. Trailwarden will retry without guessing your progress."
    elseif not m.ready then text=m.databaseStatus
    elseif m.policyUnknown then title="Quest review needed";text="Questie is optional. Without its quest policy module, Trailwarden holds new database quest pickups whose PvP, raid or group type cannot be confirmed. Install Questie or use it to review new quests; accepted quests remain usable."
    elseif m.transitionStatus=="unmapped-zone" or m.transitionStatus=="no-supported-neighbor" or m.transitionStatus=="missing-edge-target" then title="Local quests exhausted";text="No supported neighboring zone is configured for this area. Existing accepted quests remain available; use the map or Questie to choose another zone, then refresh Trailwarden."
    elseif not s.historyReady then text="Waiting for completed quest history. Active quests remain usable; database pickups wait for confirmation."
    elseif s.freeSlots==0 then text="Your quest log is full. Turn in a quest, or use Questie to review quests you no longer want."
    elseif #m.deferred>0 then text="Some active quests have unavailable targets or are outside your comfort settings. Use Questie or /tw debug for details."
    else text="No eligible mapped step is available. Inspect a quest giver, restore skipped quests or refresh your quest data." end
    local unsafe=0
    for _,q in ipairs(m.deferred) do if q.safety then unsafe=unsafe+1 end end
    if unsafe>0 and s.questLogReady and m.ready then title="Combat objectives held for later";text="Known enemies exceed your combat limit, or their levels are unverified. These quests remain recorded and are reconsidered as your level or data changes. Use Questie for manual review." end
    return {kind="wait",key="wait",title=title,instruction=text,reason="Waiting for confirmed character data.",target=s.zone,ownerKey=s.key}
end
-- Pure selector: plain snapshot in, plain decision out. No game/provider/profile writes.
function W.SelectRoute(input)
    local state=input.state;local w=input.weights or W.RouteWeights
    if state.profile.paused then return {kind="wait",key="paused",title="Route paused",instruction="Resume when you want Trailwarden to plan your next quest step.",reason="Quest progress is still recorded.",ownerKey=state.key},{},{clearPin=false,candidates={}} end
    if state.dead then return {kind="wait",key="dead",title="Return to your character",instruction="Quest navigation resumes after you are alive again.",ownerKey=state.key},{},{clearPin=false,candidates={}} end
    if not state.questLogReady then return fallback(input),{},{clearPin=false,candidates={}} end
    local danger=state.combatSafety and state.combatSafety.alert
    if danger then
        return {kind="wait",key="danger",title="High-risk enemy nearby",target=danger.name,
            instruction="Avoid this enemy and move away from danger. Navigation resumes after the threat is no longer visible.",reason=danger.reason,source="Live hostile observation",ownerKey=state.key},{},{clearPin=false,candidates={},commitment=input.commitment}
    end
    local candidates,levelDeferred={},{};local previous=input.previous
    for _,raw in ipairs(input.meta.candidates) do
        local c=W.Copy(raw)
        local skipped=state.profile.skipped[c.key] or state.profile.skipped["quest:"..c.questID]
        local risk=c.combatRisk
        local combatAllowed=not risk or risk.status=="allowed" and W.IsFinite(risk.maxLevel) and risk.maxLevel<=state.level+(W.CombatLevelMargin or 2) and risk.rank~=3 and (state.profile.includeGroup or risk.rank~=1 and risk.rank~=2)
        if (not skipped or skipped<=state.now) and combatAllowed then
            if previous and previous.ownerKey==state.key and previous.key==c.key and c.kind=="objective" and previous.targetRevision==c.targetRevision and previous.workAreaID==c.workAreaID and previous.mapID==c.mapID and W.TravelCost(state.player,previous.point)<=600 then c.point=W.Copy(previous.point);c.mapID=previous.mapID;c.x=previous.x;c.y=previous.y end
            local level=(state.profile.deferredLevels or {})[c.questID]
            if level and level>state.level+state.profile.maxLevelAbove and c.kind~="turnin" then
                c.levelDeferred=true;c.resumeLevel=math.max(1,level-state.profile.maxLevelAbove)
                c.reason="Deferred until level "..c.resumeLevel.." with your current quest range. Click to resume now."
                levelDeferred[#levelDeferred+1]=c
            else candidates[#candidates+1]=c end
        end
    end
    -- Regional commitment is independent of volatile XP estimates.
    local commitment=input.commitment and input.commitment.ownerKey==state.key and W.Copy(input.commitment) or nil
    local preferred=not input.releasePlan and commitment and commitment.mapID
    local function hasZone(map)
        for _,c in ipairs(candidates) do if planningMap(c)==map then return true end end
    end
    local region=state.regionMapID or state.mapID
    if input.previousMapID and input.previousMapID~=state.mapID and hasZone(region) then preferred=region end
    if preferred and not hasZone(preferred) then preferred=nil end
    if not input.releasePlan and not preferred and hasZone(region) then preferred=region end
    -- Score only actionable candidates: skipped quests must not hold a batch open.
    local clusters=clusterCounts(candidates,w)
    local scoreEvaluations=0
    for _,c in ipairs(candidates) do
        c.score,c.scoreParts,c.cluster,c.batchBlocked=score(c,state,candidates,state.player,w,input.releasePlan,clusters);scoreEvaluations=scoreEvaluations+1
        c.activityRank=c.kind=="escort" and 0 or 1
        local focus=not input.releasePlan and state.workFocus
        c.workFocusRank=c.reviewWork and 0 or focus and c.kind=="objective" and c.questID==focus.questID and c.point and (W.TravelCost(state.player,c.point)<=w.workAreaRadius or state.workArea and c.workAreaID==state.workArea.id) and 0 or 1
        c.zoneRank=preferred and c.mapID and planningMap(c)~=preferred and 1 or 0
        c.distance=W.Distance(state.player,c.point)
        c.reason=c.reviewWork and "Recent local quest progress; next safe target unavailable. Review or skip explicitly." or c.kind=="escort" and "An active escort must finish before ordinary quest routing resumes." or c.batchBlocked and "Finish accepted objectives in the current work area before leaving."
            or c.kind=="turnin" and "Ready to hand in; this may open the next chain step."
            or c.kind=="pickup" and "Gather a nearby quest before leaving this hub."
            or c.kind=="item" and "A quest-starting item is already in your bags."
            or "Continue a quest already in your log."
        if c.cluster>0 then c.reason=c.reason.." "..c.cluster.." other quest step(s) are nearby." end
        if c.economy then c.reason=c.reason.." Quest cycle: ~"..math.floor(c.economy.xpPerHour).." XP/h ("..c.economy.confidence.." confidence)." end
    end
    local function before(a,b)
        if a.activityRank~=b.activityRank then return a.activityRank<b.activityRank end
        if a.batchBlocked~=b.batchBlocked then return not a.batchBlocked end
        if a.workFocusRank~=b.workFocusRank then return a.workFocusRank<b.workFocusRank end
        if a.zoneRank~=b.zoneRank then return a.zoneRank<b.zoneRank end
        if a.score~=b.score then return a.score<b.score end
        return a.key<b.key
    end
    table.sort(candidates,before)
    local best=candidates[1];local pinned=state.profile.pinned;local foundPin=false
    for _,c in ipairs(candidates) do if c.key==pinned then best=c;foundPin=true end end
    if not foundPin and not input.force and previous and previous.ownerKey==state.key and best then
        for _,c in ipairs(candidates) do if c.key==previous.key and c.activityRank==best.activityRank and c.workFocusRank==best.workFocusRank and c.zoneRank==best.zoneRank and (not c.batchBlocked or best.batchBlocked) then
                if c.kind=="objective" or c.score<=best.score+math.max(w.switchMargin,math.abs(best.score)*w.switchRatio) then best=c;break end
            end end
    end
    table.sort(levelDeferred,function(a,b) if a.resumeLevel~=b.resumeLevel then return a.resumeLevel<b.resumeLevel end return a.key<b.key end)
    local uniqueDeferred={};local seenDeferred={}
    for _,c in ipairs(levelDeferred) do if not seenDeferred[c.questID] then uniqueDeferred[#uniqueDeferred+1]=c;seenDeferred[c.questID]=true end end
    local detail={clearPin=pinned~=nil and not foundPin,candidates=candidates,levelDeferred=uniqueDeferred,opportunities={},candidateCount=#candidates,scoreEvaluations=scoreEvaluations,queuePreviewShortened=#candidates>128}
    for _,c in ipairs(candidates) do
        if c.kind=="pickup" and c.point and (state.workArea and c.workAreaID==state.workArea.id or W.TravelCost(state.player,c.point)<=120) then
            detail.opportunities[#detail.opportunities+1]={questID=c.questID,name=c.questName,activity=c.activity,target=c.target}
        end
    end
    if best then
        local map=planningMap(best) or preferred or region
        detail.commitment={ownerKey=state.key,mapID=map,startedAt=commitment and commitment.mapID==map and commitment.startedAt or state.now}
        best.selectedAt=previous and previous.key==best.key and previous.selectedAt or state.now
        best.reason=best.reason.." Finish the current regional batch before changing zones."
    end
    local safetyHeld={}
    for _,q in ipairs(input.meta.deferred) do
        if q.safety then safetyHeld[#safetyHeld+1]={kind="wait",key="safety:"..q.id,questID=q.id,questName=q.title,title="Held: "..q.title,safetyHeld=true,resumeLevel=q.resumeLevel,reason=q.reason,instruction=q.reason,ownerKey=state.key} end
    end
    local function withDeferred(queue)
        if #uniqueDeferred>0 and #queue>=4 then table.remove(queue) end
        for _,c in ipairs(uniqueDeferred) do if #queue>=4 then break end;queue[#queue+1]=c end
        if #safetyHeld>0 and #queue>=4 then table.remove(queue) end
        for _,c in ipairs(safetyHeld) do if #queue>=4 then break end;queue[#queue+1]=c end
        return queue
    end
    if not best then
        local waiting=fallback(input)
        if #uniqueDeferred>0 then waiting.title="Quests saved for later";waiting.instruction="Your deferred quests return automatically within your level range. Click a Later step to resume it now." end
        return waiting,withDeferred({}),detail
    end
    local queue={};local used={[best.key]=true};local from=best.point or state.player
    local queueDepth=detail.queuePreviewShortened and 1 or 4
    for _=1,queueDepth do
        local remaining={};for _,candidate in ipairs(candidates) do if not used[candidate.key] then remaining[#remaining+1]=candidate end end
        local remainingClusters=clusterCounts(remaining,w)
        local nextStep,nextScore,nextBlocked,nextRank
        for _,c in ipairs(remaining) do
                -- Build the remaining list and its cluster counts once per leg.
                local value,_,_,blocked=score(c,state,remaining,from,w,input.releasePlan,remainingClusters);scoreEvaluations=scoreEvaluations+1
                local rank=c.zoneRank
                if not nextStep or nextBlocked and not blocked or blocked==nextBlocked and (rank<nextRank or rank==nextRank and (value<nextScore or value==nextScore and c.key<nextStep.key)) then nextStep,nextScore,nextBlocked,nextRank=c,value,blocked,rank end
        end
        if not nextStep then break end
        queue[#queue+1]=nextStep;used[nextStep.key]=true;from=nextStep.point or from
    end
    detail.scoreEvaluations=scoreEvaluations
    if detail.queuePreviewShortened then best.reason=best.reason.." The next-step preview is shortened to keep planning responsive." end
    if W.ChooseGrindBreak and best.kind~="escort" and not (best.kind=="objective" and (state.workArea or state.workFocus and state.workFocus.questID==best.questID)) then
        local chosen=W.ChooseGrindBreak(best,state,previous,detail)
        if chosen~=best then table.insert(queue,1,best);while #queue>4 do table.remove(queue) end;best=chosen end
    end
    return best,withDeferred(queue),detail
end
function W.PlanRoute(state,force,context)
    context=context or {previous=W.CurrentRoute}
    if state.profile.paused or state.dead then
        local input={state=W.Copy(state),meta={candidates={},deferred={},gates={},ready=W.CatalogReady==true,databaseStatus=W.DatabaseStatus or "Waiting for quest data"},previous=W.Copy(context.previous),commitment=W.Copy(context.commitment),previousMapID=context.previousMapID,releasePlan=context.releasePlan==true,force=force==true,weights=W.Copy(W.RouteWeights)}
        local route,queue,detail=W.SelectRoute(input);detail.input=input;detail.candidateCount=0;detail.scoreEvaluations=0;return route,queue,detail
    end
    if state.combatSafety and state.combatSafety.alert then
        local input={state=W.Copy(state),meta={candidates={},deferred={},ready=W.CatalogReady==true},previous=W.Copy(context.previous),commitment=W.Copy(context.commitment),force=force==true,weights=W.Copy(W.RouteWeights)}
        local route,queue,detail=W.SelectRoute(input);detail.input=input;return route,queue,detail
    end
    W.BeginDataCapture()
    local ok,meta=pcall(W.CollectCandidates,state)
    local facts=W.EndDataCapture()
    if not ok then error(meta) end
    meta.facts=facts
    local input={state=W.Copy(state),meta=meta,previous=W.Copy(context.previous),commitment=W.Copy(context.commitment),previousMapID=context.previousMapID,releasePlan=context.releasePlan==true,force=force==true,weights=W.Copy(W.RouteWeights)}
    local route,queue,detail=W.SelectRoute(input)
    detail.input=input
    return route,queue,detail
end
function W.PinStep(step) if step and not step.safetyHeld then local p=W.GetProfile();if step.levelDeferred then p.deferredLevels[step.questID]=nil end;p.pinned=step.key;W.Refresh(true) end end

