local W=Wayfinder
W.CombatLevelMargin=2
local revision=0
local units={target=true,mouseover=true}
local alert,alertSignature,alertOwner
local function provider() local p=W.ProviderIdentity();return tostring(p.version)..":"..tostring(p.contract)..":"..tostring(p.build) end
local function validLevel(n) return W.IsFinite(n) and n>0 and n%1==0 and n<1000 end
local function observations()
    local p=W.GetProfile();if type(p.combatObserved)~="table" then p.combatObserved={} end
    return p.combatObserved
end
local function strongerRank(a,b)
    local weight={[0]=0,[4]=0,[1]=1,[2]=2,[3]=3}
    if not W.IsFinite(a) or weight[a]==nil then return b or a end
    if not W.IsFinite(b) or weight[b]==nil then return a end
    return weight[b]>weight[a] and b or a
end
local function observed(id,map)
    local o=observations()[tostring(id)..":"..tostring(map)]
    if type(o)~="table" or o.provider~=provider() or not W.IsFinite(o.seen) or W.Now()-o.seen<0 or W.Now()-o.seen>600 then return nil end
    if o.point then
        if type(o.point)~="table" then return nil end
        local point=W.Point(o.point.mapID,o.point.x,o.point.y);if not point then return nil end
        o=W.Copy(o);o.point=point
    end
    return o
end
function W.CombatRisk(id,state)
    local minimum=W.DBGet("Npc",id,"minLevel");local maximum=W.DBGet("Npc",id,"maxLevel");local rank=W.DBGet("Npc",id,"rank")
    local providerMaximum=validLevel(maximum)
    local o=observed(id,state.mapID)
    if o and validLevel(o.level) then maximum=validLevel(maximum) and math.max(maximum,o.level) or o.level end
    if o and W.IsFinite(o.rank) then rank=strongerRank(rank,o.rank) end
    local risk={entityID=id,maxLevel=validLevel(maximum) and maximum or nil,rank=rank,limit=state.level+W.CombatLevelMargin,source=o and "Provider + live observation" or "Forever provider"}
    if o and o.skull and o.playerLevel==state.level then risk.status="blocked";risk.reason="Skull-level enemy"
    elseif rank==3 then risk.status="blocked";risk.reason="Boss target"
    elseif not state.profile.includeGroup and (rank==1 or rank==2) then risk.status="blocked";risk.reason="Elite target in solo mode"
    elseif not providerMaximum or not validLevel(maximum) or validLevel(minimum) and minimum>maximum or not W.IsFinite(rank) or rank<0 or rank>4 or rank%1~=0 then risk.status="unknown";risk.reason="Combat level/rank data unavailable"
    elseif maximum>risk.limit then risk.status="blocked";risk.reason="Enemy level "..maximum.." exceeds combat limit "..risk.limit;risk.resumeLevel=maximum-W.CombatLevelMargin
    else risk.status="allowed";risk.reason="Known combat level within limit" end
    risk.signature=table.concat({tostring(id),tostring(risk.maxLevel),tostring(rank),risk.status,tostring(risk.limit)},":")
    return risk
end
function W.CombatPoints(id,state,blocked)
    local risk=W.CombatRisk(id,state)
    if risk.status~="allowed" then if blocked then blocked[#blocked+1]=risk end;return {} end
    local points={}
    for _,point in ipairs(W.EntityPoints("Npc",id)) do
        local copy=W.Copy(point);copy.combatRisk=W.Copy(risk);points[#points+1]=copy
    end
    return points
end
function W.TrackCombatUnit(event,unit)
    if event=="NAME_PLATE_UNIT_ADDED" and type(unit)=="string" then units[unit]=true
    elseif event=="NAME_PLATE_UNIT_REMOVED" and type(unit)=="string" then units[unit]=nil end
end
local classifications={normal=0,elite=1,rareelite=2,worldboss=3,rare=4,minus=0,trivial=0}
function W.PollCombatSafety()
    local before=revision;local state={level=W.Safe(UnitLevel,"player") or 1,mapID=C_Map and W.Safe(C_Map.GetBestMapForUnit,"player"),profile=W.GetProfile()}
    local point=W.PlayerPoint();local nextAlert
    local store=observations()
    for unit in pairs(units) do
        local guid=W.Safe(UnitGUID,unit)
        local id=type(guid)=="string" and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-") or guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
        local level=W.Safe(UnitLevel,unit);local classification=W.Safe(UnitClassification,unit);local rank=classifications[classification]
        local attackable=W.Safe(UnitCanAttack,"player",unit)==true
        if id and point and (validLevel(level) or level==-1) and attackable and W.Safe(UnitIsVisible,unit)~=false then
            local key=tostring(id)..":"..tostring(state.mapID);local old=store[key]
            local skull=level==-1
            if type(old)~="table" or old.provider~=provider() or not W.IsFinite(old.seen) or W.Now()-old.seen>600 then old=nil end
            local recordedLevel=old and validLevel(old.level) and validLevel(level) and math.max(old.level,level) or level
            local recordedRank=old and strongerRank(old.rank,rank) or rank
            local recordedSkull=skull or old and old.skull==true and old.playerLevel==state.level or false
            local priorPoint=old and type(old.point)=="table" and W.Point(old.point.mapID,old.point.x,old.point.y)
            if not old or old.level~=recordedLevel or old.rank~=recordedRank or old.skull~=recordedSkull or not priorPoint or (W.Distance(priorPoint,point) or 1000)>100 then revision=revision+1 end
            store[key]={level=recordedLevel,skull=recordedSkull,rank=recordedRank,playerLevel=state.level,point=W.Copy(point),seen=W.Now(),provider=provider()}
            if not W.Safe(UnitIsDeadOrGhost,unit) and (skull or level>state.level+W.CombatLevelMargin or rank==3 or not state.profile.includeGroup and (rank==1 or rank==2)) then
                local name=W.Safe(UnitName,unit) or "Hostile enemy"
                local candidate={name=name,entityID=id,level=validLevel(level) and level or nil,skull=skull,seen=W.Now(),point=W.Copy(point),reason=skull and "Skull-level enemy visible" or "Hostile combat target exceeds automatic combat limits"}
                if not nextAlert or (candidate.level or 999)>(nextAlert.level or 999) then nextAlert=candidate end
            end
        end
    end
    local keys={};for key,o in pairs(store) do
        if type(o)~="table" or not W.IsFinite(o.seen) or W.Now()-o.seen>600 or o.provider~=provider() then store[key]=nil else keys[#keys+1]=key end
    end
    if #keys>200 then table.sort(keys,function(a,b) return store[a].seen<store[b].seen end);for i=1,#keys-200 do store[keys[i]]=nil end end
    local signature=nextAlert and (W.GetCharacterKey()..":"..nextAlert.entityID..":"..tostring(nextAlert.level)) or "none"
    local changed=signature~=alertSignature or revision~=before
    alert=nextAlert;alertSignature=signature;alertOwner=W.GetCharacterKey()
    return changed
end
function W.CombatSafetySnapshot(state)
    local current=alertOwner==state.key and alert and W.Now()-alert.seen<=3 and alert.point and W.Distance(state.player,alert.point) and W.Distance(state.player,alert.point)<=150 and W.Copy(alert) or nil
    local known,unsafe=false,false
    for key,raw in pairs(observations()) do
        local o=type(raw)=="table" and raw
        local point=o and type(o.point)=="table" and W.Point(o.point.mapID,o.point.x,o.point.y)
        if o and o.provider==provider() and W.IsFinite(o.seen) and W.Now()-o.seen>=0 and W.Now()-o.seen<=180 and point and W.Distance(state.player,point) and W.Distance(state.player,point)<=300 then
            local id=type(key)=="string" and tonumber(key:match("^(%d+):"))
            local risk=id and W.CombatRisk(id,state)
            if risk and risk.status=="allowed" then known=true else unsafe=true end
            if validLevel(o.level) and o.level>state.level+W.CombatLevelMargin then unsafe=true end
            if not W.IsFinite(o.rank) or o.skull and o.playerLevel==state.level or o.rank==3 or not state.profile.includeGroup and (o.rank==1 or o.rank==2) then unsafe=true end
        end
    end
    return {revision=revision,alert=current,grindAllowed=known and not unsafe,limit=state.level+W.CombatLevelMargin}
end
