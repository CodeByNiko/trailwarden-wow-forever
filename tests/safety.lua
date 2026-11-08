unpack=unpack or table.unpack;loadstring=loadstring or load;math.atan2=math.atan2 or function(y,x) return math.atan(y,x) end
local now=1000;local level=22;local guid="Player-Safety";local alive=true;local unitLevel=29;local hostile=true;local classification="normal";local targetID;local playerX=.75
function UnitGUID(unit) return unit=="player" and guid or targetID and "Creature-0-0-0-0-"..targetID.."-1" end
function UnitLevel(unit) return unit=="player" and level or unitLevel end
function UnitCanAttack() return hostile end
function UnitClassification() return classification end
function UnitName(unit) return unit=="player" and "Fixture" or "Fetid Corpse" end
function UnitIsDeadOrGhost(unit) return unit=="player" and not alive or false end
function GetServerTime() return now end
function GetTime() return now end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
C_Map={GetBestMapForUnit=function() return 1431 end,GetMapInfo=function() return {mapType=3,name="Duskwood"} end,
 GetPlayerMapPosition=function() return CreateVector2D(playerX,.4) end,
 GetWorldPosFromMapPos=function(_,p) local x,y=p:GetXY();return 0,CreateVector2D(x*6000,y*4000) end}
local npcs={
 [1]={name="Fetid Corpse",minLevel=28,maxLevel=29,rank=0,spawns={[10]={{75,40}}}},
 [2]={name="Appropriate ghoul",minLevel=23,maxLevel=24,rank=0,spawns={[10]={{76,40}}}},
 [3]={name="Unknown Forever mob",minLevel=0,maxLevel=0,rank=0,spawns={[10]={{77,40}}}},
 [4]={name="Friendly vendor",minLevel=60,maxLevel=60,rank=1,spawns={[10]={{74,40}}}},
 [5]={name="Elite ghoul",minLevel=22,maxLevel=23,rank=1,spawns={[10]={{73,40}}}},
 [6]={name="Boss",minLevel=22,maxLevel=22,rank=3,spawns={[10]={{72,40}}}},
}
local items={[100]={name="Ghoul Fang",npcDrops={1,2}},[101]={name="Unknown Fang",npcDrops={3}},[102]={name="Supply",vendors={4}},[103]={name="Unsafe-only Fang",npcDrops={1}}}
local quests={
 [10]={name="The Totem of Infliction",questLevel=25,objectives={[3]={{100}}}},
 [11]={name="Unknown new Forever quest",questLevel=25,objectives={[3]={{101}}}},
 [12]={name="Buy supplies",questLevel=25,objectives={[3]={{102}}}},
 [13]={name="Unsafe-only source",questLevel=25,objectives={[3]={{103}}}},
 [14]={name="Dangerous kill",questLevel=25,objectives={{{1}}}},
 [15]={name="Multi-credit kill",questLevel=25,objectives={[5]={{{1,2},0,0,1}}}},
 [16]={name="Scripted unsafe kill",questLevel=25,extraObjectives={{{[10]={{75,40}}},1,"Defeat the creature",1,{{"monster",1}}}}},
 [17]={name="Delivery",questLevel=25,finishedBy={{4}}},
}
local numeric={questLevel=true,requiredClasses=true,requiredRaces=true,rank=true,minLevel=true,maxLevel=true}
local function db(data) return {Get=function(id,key) local r=data[id];if not r then return nil end if r[key]~=nil then return r[key] end if numeric[key] then return 0 end if key=="objectives" or key=="startedBy" or key=="finishedBy" then return {} end end} end
LibQuestieDB={Npc=db(npcs),Item=db(items),Quest=db(quests),Support={Get=function() return {private={areaIdToUiMapId="return {[10]=1431}"}} end}}
for _,name in ipairs({"Common","Data","Database","Safety","Experience","Planner","Replay"}) do dofile("Wayfinder/"..name..".lua") end
local W=Wayfinder;local profiles={};local passed=0
function W.GetCharacterKey() return guid end
function W.GetProfile() profiles[guid]=profiles[guid] or {locations={},includeGroup=false,maxLevelAbove=2,skipped={},deferredLevels={}};return profiles[guid] end
W.ProviderIdentity=function() return {version="current-Forever",build="fixture",contract=4} end
local function state() return {key=guid,level=level,mapID=1431,zone="Duskwood",now=now,player=W.PlayerPoint(),profile=W.Copy(W.GetProfile()),questLogReady=true,historyReady=true,freeSlots=10,activeByID={}} end
local function check(name,ok) assert(ok,name);passed=passed+1;print("PASS safety / "..name) end
local function active(id,kind)
 return {id=id,title=quests[id].name,level=25,objectivesReady=true,objectives={{type=kind or "item",text=id==10 and "Ghoul Fang: 0/10" or "Target: 0/10",fulfilled=0,required=10,finished=false}},waypoint=W.Point(1431,.75,.4)}
end
local s=state();local risk=W.CombatRisk(1,s)
check("level-25 quest cannot authorize a level-29 mob for level-22 player",risk.status=="blocked" and risk.maxLevel==29 and risk.resumeLevel==27)
check("fixed combat cap is independent of wider quest comfort",(function() s.profile.maxLevelAbove=4;return W.CombatRisk(1,s).status=="blocked" end)())
local steps=W.ActiveSteps(active(10),s)
check("collection chooses farther appropriate source over nearer level-29 source",#steps==1 and steps[1].point.entityID==2 and steps[1].combatRisk.maxLevel==24)
check("appropriate alternative does not mark the whole objective as held",#steps.safetyBlocked==0)
check("NPC point cache is not annotated or mutated by risk filter",W.EntityPoints("Npc",2)[1].combatRisk==nil)
check("unsafe-only drop source cannot use client waypoint as bypass",#W.ActiveSteps(active(13),s)==0)
check("direct kill objective applies enemy-level cap",#W.ActiveSteps(active(14,"monster"),s)==0)
check("kill-credit alternatives retain only appropriate creatures",W.ActiveSteps(active(15,"monster"),s)[1].point.entityID==2)
check("extra-objective spawn coordinates cannot bypass unsafe creature reference",#W.ActiveSteps(active(16,"monster"),s)==0)
local unknown=W.ActiveSteps(active(11),s)
check("new Forever mob with unknown levels is held rather than assumed suitable",#unknown==0 and unknown.safetyBlocked[1].status=="unknown")
check("friendly high-level vendors are not treated as combat targets",W.ActiveSteps(active(12),s)[1].point.entityID==4)
local completed=active(13);completed.isComplete=true;quests[13].finishedBy={{4}}
check("completed turn-in remains usable at high-level friendly NPC",W.ActiveSteps(completed,s)[1].kind=="turnin")
local blocked={};check("solo mode rejects elites even inside level range",#W.CombatPoints(5,s,blocked)==0)
s.profile.includeGroup=true;check("group setting may permit appropriate elite",#W.CombatPoints(5,s,{})>0)
check("group setting does not permit seven-level combat difference",#W.CombatPoints(1,s,{})==0)
check("boss targets are never automatic combat goals",#W.CombatPoints(6,s,{})==0)
level=27;s=state();check("level-up automatically permits previously held level-29 source",W.CombatRisk(1,s).status=="allowed")
level=22;s=state()
-- A live correction must invalidate both navigation continuity and provider assumptions.
targetID=2;unitLevel=29;W.PollCombatSafety();s=state();s.combatSafety=W.CombatSafetySnapshot(s)
check("live higher enemy level overrides lower provider level",W.CombatRisk(2,s).status=="blocked")
check("visible high-level hostile creates navigation stop",s.combatSafety.alert and s.combatSafety.alert.level==29)
local input={state=s,meta={candidates=steps,deferred={},ready=true},previous=steps[1],commitment={ownerKey=guid,mapID=1431},weights=W.Copy(W.RouteWeights)}
local stop=W.SelectRoute(input)
check("safety stop overrides pin XP and regional continuity",stop.key=="danger" and not stop.point)
s.profile.pinned=steps[1].key;check("manual focus cannot bypass visible danger stop",W.SelectRoute(input).key=="danger")
unitLevel=24;W.PollCombatSafety();s=state();check("lower later observation cannot erase known higher enemy range",W.CombatRisk(2,s).status=="blocked")
now=now+601;targetID=nil;W.PollCombatSafety();s=state();check("expired live correction yields to current provider",W.CombatRisk(2,s).status=="allowed")
targetID=2;unitLevel=-1;W.PollCombatSafety();s=state();check("skull-level observation is blocked without inventing an exact level",W.CombatRisk(2,s).status=="blocked" and W.CombatSafetySnapshot(s).alert.skull)
targetID=2;unitLevel=29;hostile=false;W.PollCombatSafety();s=state();check("friendly high-level unit cannot create hostile warning",W.CombatSafetySnapshot(s).alert==nil)
hostile=true;unitLevel=29;W.PollCombatSafety();guid="Player-Other";s=state();check("live danger and observations do not leak between characters",W.CombatSafetySnapshot(s).alert==nil and W.CombatRisk(2,s).status=="allowed")
guid="Player-Safety";now=now+601;targetID=nil;W.PollCombatSafety();s=state()
check("no observed enemy evidence cannot establish grind suitability",not W.CombatSafetySnapshot(s).grindAllowed)
targetID=2;unitLevel=23;classification="normal";W.PollCombatSafety();s=state();check("appropriate live enemy evidence can permit grind comparison",W.CombatSafetySnapshot(s).grindAllowed)
classification="elite";W.PollCombatSafety();s=state();check("live elite correction blocks solo routing",W.CombatRisk(2,s).status=="blocked")
classification="rare";W.PollCombatSafety();s=state();check("rare classification cannot downgrade previous elite observation",W.CombatRisk(2,s).status=="blocked")
-- Pure candidate defense and persisted corrupt evidence.
local bad=W.Copy(steps[1]);bad.combatRisk.status="blocked";s.combatSafety={};s.profile.pinned=bad.key
local reject=W.SelectRoute({state=s,meta={candidates={bad},deferred={},ready=true},weights=W.Copy(W.RouteWeights)})
check("selector rejects explicitly blocked candidate even when pinned",reject.kind=="wait")
W.GetProfile().combatObserved.bad={point={mapID=1431,x="bad",y=.4},level=99,seen=now,provider="current-Forever:4:fixture"}
check("malformed saved observations do not crash or invent threat",pcall(W.CombatSafetySnapshot,state()))
-- A cached or mislabeled allowed flag cannot override the current level cap.
local stale=W.Copy(steps[1]);stale.combatRisk.maxLevel=29;stale.combatRisk.status="allowed";s.profile.pinned=stale.key
check("current combat cap overrides stale allowed candidate metadata",W.SelectRoute({state=s,meta={candidates={stale},deferred={},ready=true},weights=W.Copy(W.RouteWeights)}).kind=="wait")
-- Unknown provider NPCs can use a local live level but not distant spawn inference.
now=now+601;targetID=3;unitLevel=23;classification="normal";npcs[3].spawns[10][2]={90,40};W.PollCombatSafety();s=state()
local localOnly=W.CombatPoints(3,s,{})
check("single live level cannot certify unknown NPC maximum across spawns",#localOnly==0)
-- Held quests remain represented and cannot be resumed through pinning.
local held=W.SelectRoute({state=s,meta={candidates={},deferred={{id=13,title="Unsafe-only source",safety=true,reason="Enemy level 29 exceeds cap",resumeLevel=27}},ready=true},weights=W.Copy(W.RouteWeights)})
local _,heldQueue=W.SelectRoute({state=s,meta={candidates={},deferred={{id=13,title="Unsafe-only source",safety=true,reason="Enemy level 29 exceeds cap",resumeLevel=27}},ready=true},weights=W.Copy(W.RouteWeights)})
check("held objective remains visible with return level",held.kind=="wait" and heldQueue[1].safetyHeld and heldQueue[1].resumeLevel==27)
UnitIsVisible=function() return false end;targetID=1;unitLevel=29;W.PollCombatSafety();s=state()
check("distant invisible selected enemy cannot keep local danger stop stuck",W.CombatSafetySnapshot(s).alert==nil)
UnitIsVisible=nil
local replay=io.open("tests/safety-replay.json","w");replay:write(W.Json({schema=1,origin="synthetic-combat-safety",frames={{event="hostile-level29-visible",input=input,expected={key="danger",queue={},clearPin=false}}}}));replay:close()
print(passed.." combat-safety checks passed")
