local W=Trailwarden
local sessions={}
local function clock() return W.Safe(GetTime) or W.Now() end
local function finite(v) return W.IsFinite(v) and v>=0 end
local function ema(old,value,weight) return old and old+(value-old)*(weight or .2) or value end
local function providerKey()
    local p=W.ProviderIdentity();return tostring(p.version)..":"..tostring(p.contract)..":"..tostring(p.build)
end
local function learning()
    local p=W.GetProfile()
    if type(p.xpLearning)~="table" then p.xpLearning={} end
    local l=p.xpLearning
    if l.provider~=providerKey() then l.quests={};l.provider=providerKey() end
    if type(l.quests)~="table" then l.quests={} end
    if not finite(l.moveSpeed) or l.moveSpeed<1 or l.moveSpeed>30 then l.moveSpeed=nil end
    if not finite(l.killSeconds) or l.killSeconds<1 or l.killSeconds>180 then l.killSeconds=nil end
    if not finite(l.killXP) or l.killXP>100000 then l.killXP=nil end
    for _,field in ipairs({"killSamples","killTrusted","speedSamples"}) do if not finite(l[field]) then l[field]=0 end end
    return l
end
local function session()
    local key=W.GetCharacterKey();local s=sessions[key]
    if not s then
        s={key=key,lastClock=clock(),elapsed=0,total=0,kills=0,questXP=0,turnins=0,history={{t=0,xp=0}},pendingKills=0,pendingQuest=0,goals={}}
        sessions[key]=s
    end
    return s
end
function W.ResetExperience() sessions[W.GetCharacterKey()]=nil;W.SampleExperience() end
function W.ExperienceTick()
    local s=session();local now=clock();local p=W.GetProfile()
    local dt=math.max(0,now-s.lastClock);s.lastClock=now
    -- Count travel, recovery and ordinary downtime; exclude only explicit pause/AFK.
    if not s.excluded then s.elapsed=s.elapsed+dt end
    s.excluded=p.paused or W.Safe(UnitIsAFK,"player")==true
    local speed=W.Safe(GetUnitSpeed,"player")
    if not s.excluded and finite(speed) and speed>=1 and speed<=30 and not W.Safe(UnitOnTaxi,"player") then
        local l=learning();l.moveSpeed=ema(l.moveSpeed,speed,.08);l.speedSamples=math.min(10000,l.speedSamples+1)
    end
    return s
end
local function localizedKillXP(message)
    if type(message)~="string" then return nil end
    for name,format in pairs(_G) do
        if type(name)=="string" and name:match("^COMBATLOG_XPGAIN") and type(format)=="string" then
            local parts={"^"};local index,captures,xpIndex=1,0,nil
            while index<=#format do
                local start,finish,position,kind=format:find("%%(%d*%$?)([sd])",index)
                if not start then parts[#parts+1]=format:sub(index):gsub("([^%w])","%%%1");break end
                parts[#parts+1]=format:sub(index,start-1):gsub("([^%w])","%%%1")
                captures=captures+1;parts[#parts+1]=kind=="d" and "(%d+)" or "(.-)"
                if kind=="d" and not xpIndex then xpIndex=captures end
                index=finish+1
            end
            parts[#parts+1]="$"
            if xpIndex then local values={message:match(table.concat(parts))};local value=tonumber(values[xpIndex]);if finite(value) then return value end end
        end
    end
end
function W.ExperienceEvent(event,...)
    local a,b=...;local s=W.ExperienceTick()
    if event=="CHAT_MSG_COMBAT_XP_GAIN" and not s.excluded then
        s.pendingKills=s.pendingKills+1;s.kills=s.kills+1;s.pendingAt=clock()
        local parsed=localizedKillXP(a)
        if parsed then s.pendingParsedXP=(s.pendingParsedXP or 0)+parsed;s.pendingParsedKills=(s.pendingParsedKills or 0)+1 end
        local point=W.PlayerPoint()
        if point then
            local spot=s.spot
            if not spot or not W.Distance(point,spot.point) or W.Distance(point,spot.point)>300 or s.elapsed-(spot.last or 0)>120 then
                spot={point=point,start=s.elapsed,xp=0,trustedXP=0,trustedKills=0,kills=0,last=s.elapsed};s.spot=spot
            end
            spot.kills=spot.kills+1;spot.last=s.elapsed
        end
        if s.lastKill and s.elapsed-s.lastKill>=2 and s.elapsed-s.lastKill<=120 then
            local l=learning();l.killSeconds=ema(l.killSeconds,s.elapsed-s.lastKill)
        end
        s.lastKill=s.elapsed
    elseif event=="QUEST_TURNED_IN" and not s.excluded then
        s.turnins=s.turnins+1
        if finite(b) then s.questXP=s.questXP+b;s.pendingQuest=s.pendingQuest+b;s.pendingAt=clock() end
    end
end
function W.SampleExperience()
    local before=session();local wasExcluded=before.excluded
    local s=W.ExperienceTick();local level=W.Safe(UnitLevel,"player");local xp=W.Safe(UnitXP,"player");local maximum=W.Safe(UnitXPMax,"player")
    if not finite(level) or not finite(xp) or not finite(maximum) then s.available=false;return end
    s.available=true
    local delta=0;local rollover=false
    if s.baseline then
        if level==s.level and xp>=s.xp then delta=xp-s.xp
        elseif level==s.level+1 and s.maximum>0 then
            if not s.levelTransition or s.levelTransition.level~=level then s.levelTransition={level=level,at=clock()};return end
            if clock()-s.levelTransition.at<1 then return end
            delta=s.maximum-s.xp+xp;rollover=true;s.lastRollover=clock();s.levelTransition=nil
        elseif level==s.level and xp<s.xp and s.lastRollover and clock()-s.lastRollover<=2 then delta=xp-s.xp
        elseif level==s.level and xp<s.xp then
            -- XP and level notifications can be delivered in either order.
            -- Keep the old baseline until the delayed level update arrives.
            if not s.rolloverAt then s.rolloverAt=clock() end
            if clock()-s.rolloverAt<2 then return end
            s.rolloverAt=nil
        end
    end
    s.baseline=true;s.level=level;s.xp=xp;s.maximum=maximum
    if delta<0 then s.total=math.max(0,s.total+delta) end
    if delta>0 and not s.excluded and not wasExcluded then
        s.total=s.total+delta
        -- Attribution never adds XP to totals. The XP bar is the sole source.
        if not rollover and s.pendingKills>0 and s.pendingAt and clock()-s.pendingAt<=2 then
            local killXP=math.max(0,delta-s.pendingQuest)
            if killXP>0 then
                local trusted=s.pendingParsedXP and s.pendingParsedXP<=killXP
                local amount=trusted and s.pendingParsedXP or killXP
                local l=learning();l.killXP=ema(l.killXP,amount/s.pendingKills);
                if trusted then l.killTrusted=math.min(10000,l.killTrusted+(s.pendingParsedKills or 0)) end;l.killSamples=math.min(10000,l.killSamples+s.pendingKills)
                if s.spot then
                    s.spot.xp=s.spot.xp+killXP
                    if s.pendingParsedXP and s.pendingParsedXP<=killXP then
                        s.spot.trustedXP=s.spot.trustedXP+s.pendingParsedXP;s.spot.trustedKills=s.spot.trustedKills+(s.pendingParsedKills or 0)
                    end
                end
            end
        end
        s.pendingKills=0;s.pendingQuest=0;s.pendingParsedXP=nil;s.pendingParsedKills=nil;s.rolloverAt=nil
    elseif s.pendingAt and clock()-s.pendingAt>2 then s.pendingKills=0;s.pendingQuest=0;s.pendingParsedXP=nil;s.pendingParsedKills=nil end
    local h=s.history;local last=h[#h]
    if not last or s.elapsed-last.t>=1 or #h==1 and delta>0 then h[#h+1]={t=s.elapsed,xp=s.total} else last.xp=s.total end
    -- Retain the boundary immediately before the rolling 15-minute window.
    while #h>2 and h[2].t<=s.elapsed-900 do table.remove(h,1) end
    while #h>905 do table.remove(h,1) end
end
function W.ExperienceStats()
    local s=session();local l=learning();local first=s.history[1];local span=s.elapsed-first.t
    local rate=span>=60 and math.max(0,s.total-first.xp)*3600/span or nil
    local sessionRate=s.elapsed>=60 and s.total*3600/s.elapsed or nil
    local remaining=s.maximum and math.max(0,s.maximum-(s.xp or 0))
    local g=s.spot;local grind
    if s.available and g and g.trustedKills>=8 and g.trustedXP>0 and s.elapsed-g.start>=120 and s.elapsed-g.last<=60 and s.elapsed-g.start<=900 then
        grind={rate=g.trustedXP*3600/(s.elapsed-g.start),point=W.Copy(g.point),kills=g.kills,seconds=s.elapsed-g.start,valid=true,cooldownUntil=s.grindCooldown or 0}
    end
    return {available=s.available==true,elapsed=s.elapsed,totalXP=s.total,rate=rate,sessionRate=sessionRate,windowSeconds=math.min(span,900),remaining=remaining,eta=rate and rate>0 and remaining and remaining/rate*3600 or nil,
        level=s.level,maximum=s.maximum,kills=s.kills,questXP=s.questXP,turnins=s.turnins,paused=s.excluded==true,inCombat=W.Safe(InCombatLockdown)==true,moveSpeed=l.moveSpeed or 7,killSeconds=l.killSeconds or 35,killXP=l.killXP,killSamples=l.killSamples,killTrusted=l.killTrusted,grind=grind,enabled=W.GetProfile().xpRouting~=false and s.maximum~=0}
end
function W.EndGrindBreak() session().grindCooldown=W.Now()+120 end
local function goalKey(q,o,index) return tostring(q.id)..":"..tostring(o.type)..":"..(o.text or ""):gsub("%d+","#")..":"..index end
function W.ObserveExperienceProgress(state)
    local s=session();local l=learning()
    for _,q in ipairs(state.activeQuests) do
        if q.objectivesReady then
            local row=l.quests[q.id]
            if type(row)~="table" then row={goals={}};l.quests[q.id]=row end
            if type(row.goals)~="table" then row.goals={} end
            row.level=q.level;row.seen=W.Now()
            for i,o in ipairs(q.objectives) do
                if finite(o.required) and finite(o.fulfilled) then
                    local key=goalKey(q,o,i);local previous=s.goals[key]
                    local saved=row.goals[i]
                    if type(saved)~="table" then saved={};row.goals[i]=saved end
                    saved.type=o.type;saved.required=o.required
                    if previous and o.fulfilled>previous.count and s.elapsed>previous.t then
                        local dt=s.elapsed-previous.t;local units=o.fulfilled-previous.count
                        if dt<=600 and not s.excluded then saved.secondsPerUnit=ema(saved.secondsPerUnit,math.max(1,dt/units));saved.samples=(finite(saved.samples) and saved.samples or 0)+1 end
                        s.goals[key]={count=o.fulfilled,t=s.elapsed}
                    elseif not previous or o.fulfilled<previous.count then s.goals[key]={count=o.fulfilled,t=s.elapsed} end
                end
            end
        end
    end
    -- Learning is bounded independently of the full quest history.
    local ids={};for id,row in pairs(l.quests) do if type(row)~="table" or not finite(row.seen) then l.quests[id]=nil else ids[#ids+1]=id end end
    if #ids>200 then table.sort(ids,function(a,b) return l.quests[a].seen<l.quests[b].seen end);for i=1,#ids-200 do l.quests[ids[i]]=nil end end
end
function W.QuestRewardEstimate(id,state)
    local support=LibQuestieDB and LibQuestieDB.Support
    local data=support and W.Safe(support.Get,"QuestXP");local row=type(data)=="table" and type(data.db)=="table" and data.db[id]
    local module=W.Import("QuestXP")
    local status,xp=W.Call(module and module.GetQuestLogRewardXP,module,id)
    if status=="ok" and finite(xp) and xp>0 then
        W.RecordFact("QuestXP",id,"reward",xp,"ok")
        if W.Safe(InCombatLockdown)==true or W.Safe(IsInInstance)==true then return xp,"Questie reward (temporary bonuses uncertain)" end
        return xp,"Questie adjusted reward"
    end
    if type(row)~="table" or not finite(row[1]) or row[1]<=0 or not finite(row[2]) then return nil,"Reward unavailable" end
    local maxLevel=W.Safe(GetMaxPlayerLevel)
    if finite(maxLevel) and state.level>=maxLevel then return 0,"Level cap" end
    -- Provider base reward plus its consumer's documented grey-quest reduction.
    -- Buff/server multipliers are not invented when the consumer is unavailable.
    local scale=math.max(.1,math.min(1,(2*(row[1]-state.level)+20)/10))
    xp=row[2]*scale;W.RecordFact("QuestXP",id,"baseReward",{level=row[1],xp=row[2]},"ok")
    return xp,"Provider base estimate (bonuses unknown)"
end
-- Pure projection, also used by replay. No provider/client reads.
function W.ProjectQuestXP(model,origin,pace)
    if not model or not finite(model.rewardXP) or model.rewardXP<0 or not model.receiver or not origin then return nil end
    pace=pace or {}
    local speed=pace.moveSpeed or 7;if not finite(speed) or speed<1 or speed>40 then return nil end
    local seconds=model.interactionSeconds or 20;if not finite(seconds) or seconds<0 then return nil end;local from=origin;local travel=0;local travelDistance=0;local work=0;local killXP=0
    local function leg(point)
        local d=W.Distance(from,point);if not finite(d) then return false end
        travelDistance=travelDistance+d;travel=travel+d/speed*1.2;from=point;return true
    end
    if model.pickup and not leg(model.pickup) then return nil end
    if model.goals~=nil and type(model.goals)~="table" then return nil end
    local todo=W.Copy(model.goals or {})
    for _,g in ipairs(todo) do
        if not g.point or not finite(g.seconds) or g.seconds<0 or g.killXP~=nil and (not finite(g.killXP) or g.killXP<0) then return nil end
    end
    -- Greedy nearest-neighbour is a useful starting order, but can double back
    -- through a cluster. Two-opt removes crossing detours before XP/h is scored.
    while #todo>0 do
        local nearest,index
        for i,g in ipairs(todo) do local d=W.Distance(from,g.point);if d and (not nearest or d<nearest) then nearest,index=d,i end end
        if not index then return nil end
        local g=table.remove(todo,index);todo[#todo+1]=g;from=g.point
    end
    from=model.pickup or origin
    local improved=true
    while improved and #todo>1 do
        improved=false
        for i=1,#todo-1 do
            local a=i==1 and from or todo[i-1].point
            local b=todo[i].point
            for k=i+1,#todo do
                local c=todo[k].point
                local d=k==#todo and model.receiver or todo[k+1].point
                local ab,cd=W.Distance(a,b),W.Distance(c,d)
                local ac,bd=W.Distance(a,c),W.Distance(b,d)
                if ab and cd and ac and bd and ac+bd+0.01<ab+cd then
                    local left,right=i,k
                    while left<right do todo[left],todo[right]=todo[right],todo[left];left=left+1;right=right-1 end
                    improved=true;break
                end
            end
            if improved then break end
        end
    end
    for _,g in ipairs(todo) do
        if not leg(g.point) then return nil end
        work=work+g.seconds;killXP=killXP+(g.killXP or 0)
    end
    if not leg(model.receiver) then return nil end
    seconds=math.max(20,seconds+travel+work)
    return {xpPerHour=(model.rewardXP+killXP)*3600/seconds,rewardXP=model.rewardXP,killXP=killXP,seconds=seconds,travelSeconds=travel,travelDistance=travelDistance,workSeconds=work,confidence=model.confidence,source=model.source,remainingGoals=#(model.goals or {})}
end
function W.PrepareQuestEconomies(candidates,state)
    local models={}
    local grouped={};local ids={}
    for _,c in ipairs(candidates) do
        local skipped=state.profile.skipped[c.key] or state.profile.skipped["quest:"..c.questID]
        local later=(state.profile.deferredLevels or {})[c.questID]
        if (not skipped or skipped<=state.now) and (not later or later<=state.level+state.profile.maxLevelAbove or c.kind=="turnin") then
            if not grouped[c.questID] then grouped[c.questID]={};ids[#ids+1]=c.questID end
            grouped[c.questID][#grouped[c.questID]+1]=c
        end
    end
    table.sort(ids)
    local l=learning();local pace=state.experience or W.ExperienceStats()
    for _,id in ipairs(ids) do
        local list=grouped[id]
        local reward,source=W.QuestRewardEstimate(id,state);local active=state.activeByID[id];local goals={};local pickup
        local known=true;local learned=l.quests[id];local steps=list
        if type(learned)~="table" or type(learned.goals)~="table" then learned=nil end
        if not active then
            pickup=list[1].point
            local remembered={}
            for _,g in ipairs(learned and learned.goals or {}) do
                if type(g)=="table" and finite(g.required) and g.entityID and (g.type=="monster" or g.type=="item" or g.type=="object") then
                    local kind=g.type=="item" and "Item" or g.type=="monster" and "Npc" or "Object"
                    remembered[#remembered+1]={type=g.type,text=W.DBGet(kind,g.entityID,"name") or "",required=g.required,fulfilled=0,finished=false}
                end
            end
            if learned and #remembered~=#learned.goals then remembered={} end
            steps=W.ActiveSteps({id=id,title=list[1].questName,objectivesReady=true,objectives=remembered,level=list[1].level},state)
            known=#remembered>0
        end
        if reward~=nil then
            local receiver=W.NearestPoint(W.RelationPoints(id,"finishedBy"),state.player,state.mapID)
            local seenLive={}
            for _,c in ipairs(steps) do
                if c.kind=="objective" then
                    local remaining=c.remaining;local unitSeconds;local samples=0
                    local saved=learned and learned.goals
                    if active and saved and c.objectiveIndex and type(saved[c.objectiveIndex])=="table" then saved[c.objectiveIndex].entityID=c.objectiveID end
                    if saved and c.objectiveIndex then local g=saved[c.objectiveIndex];if type(g)=="table" and g.type==c.objectiveKind and finite(g.secondsPerUnit) and finite(g.samples) then unitSeconds=g.secondsPerUnit;samples=g.samples end end
                    if not finite(remaining) then remaining=c.objectiveKind=="monster" and 8 or c.objectiveKind=="item" and 10 or 1;known=false end
                    if c.objectiveIndex then seenLive[c.objectiveIndex]=true end
                    local combat=c.objectiveKind=="monster" or c.objectiveKind=="item" and c.point and c.point.acquisition=="npcDrops"
                    if not unitSeconds or samples<2 then unitSeconds=combat and (pace.killSeconds or 35)*(c.objectiveKind=="item" and 2 or 1) or c.objectiveKind=="object" and 20 or 90;known=false end
                    if combat and (pace.killTrusted or 0)<3 then known=false end
                    local kills=combat and remaining*(c.objectiveKind=="item" and 2 or 1) or 0
                    local sourceKey=c.point and c.point.entityID and (tostring(c.point.entityKind)..":"..c.point.entityID) or c.key
                    goals[#goals+1]={point=c.point,sourceKey=sourceKey,seconds=remaining*unitSeconds,killXP=pace.killXP and kills*pace.killXP or 0}
                elseif c.kind=="deliver" then receiver=c.point end
            end
            if active then
                for i,o in ipairs(active.objectives) do if not o.finished and o.required>o.fulfilled and not seenLive[i] then known=false;reward=nil end end
            end
            if not active and #steps==0 then reward=nil end
            if reward~=nil then
                local model={rewardXP=reward,source=source,receiver=receiver,pickup=pickup,goals=goals,confidence=known and source=="Questie adjusted reward" and "medium" or "low",interactionSeconds=pickup and 40 or 20}
                model.questIDs={id};model.active=active~=nil;models[id]=model
            end
        end
    end
    local rates={}
    for _,id in ipairs(ids) do
        local list=grouped[id]
        local base=models[id]
        if base then
            local combined=W.Copy(base)
            -- Combine accepted work sharing the same work area and hand-in hub.
            -- Each quest reward is banked once; common mob sources share effort.
            for _,otherID in ipairs(ids) do
                local other=models[otherID]
                if other and otherID~=id and other.active and W.Distance(base.receiver,other.receiver) and W.Distance(base.receiver,other.receiver)<=200 then
                    local close=#other.goals==0
                    for _,a in ipairs(base.goals) do for _,b in ipairs(other.goals) do if W.Distance(a.point,b.point) and W.Distance(a.point,b.point)<=300 then close=true end end end
                    if close then
                        combined.rewardXP=combined.rewardXP+other.rewardXP;combined.questIDs[#combined.questIDs+1]=otherID
                        for _,g in ipairs(other.goals) do combined.goals[#combined.goals+1]=W.Copy(g) end
                        if other.confidence~="medium" then combined.confidence="low" end
                    end
                end
            end
            local merged={};local bySource={}
            for _,g in ipairs(combined.goals) do
                local previous=bySource[g.sourceKey]
                if previous and W.Distance(previous.point,g.point) and W.Distance(previous.point,g.point)<=300 then
                    previous.seconds=math.max(previous.seconds,g.seconds);previous.killXP=math.max(previous.killXP,g.killXP)
                else merged[#merged+1]=g;if g.sourceKey then bySource[g.sourceKey]=g end end
            end
            combined.goals=merged;table.sort(combined.questIDs)
            for _,c in ipairs(list) do c.economyModel=combined;c.economy=W.ProjectQuestXP(combined,state.player,pace) end
            local projection=list[1].economy
            if projection and projection.xpPerHour>0 then rates[#rates+1]=projection.xpPerHour end
        end
    end
    if state.experience and #rates>0 then table.sort(rates);state.experience.referenceRate=rates[math.ceil(#rates/2)] end

end
function W.ChooseGrindBreak(best,state,previous,detail)
    local e=state.experience;local g=e and e.grind
    if previous and previous.kind=="grind" and (previous.grindUntil or 0)<=state.now then detail.endGrind=true;return best end
    if not state.combatSafety or not state.combatSafety.grindAllowed then return best end
    if not best or state.profile.pinned or not e or not e.enabled or e.paused or not g or not g.valid then return best end
    if previous and previous.kind=="grind" and e.inCombat and (g.cooldownUntil or 0)<=state.now then
        detail.questAlternative=W.Copy(best);return W.Copy(previous)
    end
    if e.inCombat then return best end
    if not best.economy or best.economy.confidence~="medium" then return best end
    if (g.cooldownUntil or 0)>state.now or not W.Distance(state.player,g.point) or W.Distance(state.player,g.point)>450 then return best end
    if g.rate<=best.economy.xpPerHour*1.25 then return best end
    local untilTime=previous and previous.kind=="grind" and previous.grindUntil or state.now+180
    detail.questAlternative=W.Copy(best)
    return {kind="grind",key="grind:observed",ownerKey=state.key,title="Grind briefly in this area",questName="Short grind break",target=state.zone,point=W.Copy(g.point),mapID=g.point.mapID,x=g.point.x,y=g.point.y,
        instruction="Grind nearby for up to 3 minutes. Your measured kill XP/h currently beats the quest estimate.",reason="Observed kill XP rate exceeds the estimated quest cycle by at least 25%.",source="Your recent kill XP",grindUntil=untilTime,economy={xpPerHour=g.rate,confidence="measured"}}
end
function W.FormatXP(value)
    if not finite(value) then return "--" end
    local digits=string.format("%.0f",value):reverse():gsub("(%d%d%d)","%1,"):reverse()
    return (digits:gsub("^,",""))
end
function W.FormatETA(seconds)
    if not finite(seconds) then return "--" end
    local minutes=math.ceil(seconds/60)
    if minutes<60 then return minutes.."m" end
    return math.floor(minutes/60).."h "..(minutes%60).."m"
end

function W.SafeExperienceStats()
    local status,e=W.Call(W.ExperienceStats)
    if status=="ok" and type(e)=="table" then return e end
    return {available=false,elapsed=0,totalXP=0,windowSeconds=0,kills=0,turnins=0,questXP=0,moveSpeed=7,killSeconds=35}
end
