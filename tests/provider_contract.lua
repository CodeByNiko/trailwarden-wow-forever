-- Interface fixtures based on the public QuestieDB API, not a bundled quest database.
-- Reference: Questie/QuestieDB 5c14272d61ad2c8d08526b15d633322fc561588e docs/api.md.
unpack=unpack or table.unpack;loadstring=loadstring or load
local passed=0
local function check(name,value) assert(value,name);passed=passed+1;print("PASS contract / "..name) end
TrailwardenDB=nil
local epoch=1000;local failLevel=false;local nilLevel=false;local calls={};local timers={}
local tableFields={startedBy=true,finishedBy=true,objectives=true,objectivesText=true,triggerEnd=true,preQuestGroup=true,preQuestSingle=true,childQuests=true,inGroupWith=true,exclusiveTo=true,requiredSkill=true,requiredMinRep=true,requiredMaxRep=true,requiredSourceItems=true,reputationReward=true,breadcrumbs=true,extraObjectives=true,requiredRanks=true}
local ids={1,2,3}
local unknownStarter=false
LibQuestieDB={contractVersion=4,RequireContract=function(v) return v<=4 end,Enum={raceMaskById={[4]=8}},
 Quest={GetAllIds=function() return ids end,Get=function(id,key)
    assert(type(id)=="number" and type(key)=="string","Entity.Get must be dot-called")
    calls[#calls+1]={id,key}
    if id<1 or id>3 then return nil end
    if id==2 and key=="questLevel" and failLevel then error("transient provider failure") end
    if id==3 and key=="questLevel" and nilLevel then return nil end
    if key=="name" then return "Contract quest "..id end
    if key=="startedBy" then return {{unknownStarter and id==2 and 102 or 100}} end
    if key=="finishedBy" or key=="objectives" then return {} end
    if tableFields[key] then return nil end
    if key=="questLevel" then return 7 end
    return 0
 end},
 Npc={Get=function(id,key) if id~=100 and id~=101 and id~=102 then return nil end if key=="name" then return "Contract giver" elseif key=="spawns" then return {[10]=id==102 and {{-1,-1}} or id==101 and {{-1,-1},{.5,.25}} or {{.5,.25}}} end return 0 end},
 Support={Get=function(name) assert(name=="ZoneDB");return {private={areaIdToUiMapId="return { [10]=9999 }",areaIdToUiMapIdOverride="return { [10]=1438 }"}} end}}
function UnitGUID(unit) return unit=="player" and "Player-Contract" or "Creature-0-0-0-0-100-1" end
function UnitName(unit) return unit=="player" and "Contract" or "Contract giver" end
function UnitClass() return "Warrior","WARRIOR",1 end
function UnitRace() return "Night Elf","NightElf",4 end
function UnitLevel() return 7 end
function GetRealmName() return "Fixture" end
function UnitFactionGroup() return "Alliance" end
function GetServerTime() return epoch end
function GetAddOnMetadata(_,key) return key=="Version" and "contract-fixture" or nil end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
C_Map={GetBestMapForUnit=function() return 1438 end,GetPlayerMapPosition=function() return CreateVector2D(.4,.6) end,GetMapInfo=function() return {name="Teldrassil",mapType=3} end}
C_QuestLog={GetNumQuestLogEntries=function() return 0 end,GetAllCompletedQuestIDs=function() return {} end}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
for _,name in ipairs({"Common","Locale","Data","Tracking","Database"}) do dofile("Trailwarden/"..name..".lua") end
local W=Trailwarden
check("entity getter called with documented dot signature",W.DBGet("Quest",1,"name")=="Contract quest 1")
check("numeric nil fields on known quests are zero",W.Q(1,"requiredLevel")==0)
check("structured empty objectives remain a table",type(W.Q(1,"objectives"))=="table" and W.Count((W.Q(1,"objectives")))==0)
check("optional table fields remain nil",W.Q(1,"preQuestSingle")==nil)
check("unknown entity fields remain nil",W.Q(999,"questLevel")==nil and W.Q(999,"name")==nil)
check("provider support strings and overrides are consumed",W.MapForArea(10)==1438)
local points=W.EntityPoints("Npc",100)
check("provider coordinates are percentages even below one",#points==1 and points[1].x==.005 and points[1].y==.0025)
local mixed,mixedStatus=W.EntityPoints("Npc",101)
check("unknown-position sentinels retain other valid spawn points",mixedStatus=="ok" and #mixed==1 and mixed[1].x==.005)
local unmapped,unmappedStatus=W.EntityPoints("Npc",102)
check("sentinel-only entities are unmapped rather than invalid",#unmapped==0 and unmappedStatus=="empty")
failLevel=true;local value,status=W.Q(2,"questLevel");check("API failure is distinguishable from a nil field",value==nil and status=="error")
failLevel=false;check("transient field errors are not cached as absence",W.Q(2,"questLevel")==7)
nilLevel=true;value,status=W.Q(3,"questLevel");check("contract violation remains unknown",value==nil and status=="invalid")
nilLevel=false;check("corrected provider field can recover",W.Q(3,"questLevel")==7)
local s=W.ReadCharacter();check("documented race-mask contract is used",s.raceMask==8 and s.classMask==1)
W.ObserveQuest(1,"Contract quest 1","pickup");s=W.ReadCharacter();local observed=W.ObservedPoint(1,"pickup",s)
check("live observation includes identity time units and provenance",observed and observed.x==.4 and observed.confidence=="interaction-area" and observed.entityID==100)
epoch=1301;s=W.ReadCharacter();check("observation freshness has an explicit boundary",W.ObservedPoint(1,"pickup",s)==nil)
unknownStarter=true
W.BuildQuestCatalog();while #timers>0 do table.remove(timers,1)() end
check("one unmapped starter cannot disable the entire quest catalog",W.CatalogReady and W.CatalogCount==3 and W.CatalogError==nil)
local published=W.CatalogByMap;local supportAPI=LibQuestieDB.Support.Get
LibQuestieDB.Support.Get=function() return nil end;W.BuildQuestCatalog(true)
check("temporarily missing map support retains published data",not W.BuildingCatalog and W.CatalogByMap==published and W.CatalogError~=nil)
LibQuestieDB.Support.Get=supportAPI
while #timers>0 do table.remove(timers,1)() end
check("map support recovery is not poisoned by empty caches",W.CatalogReady and W.CatalogError==nil and W.CatalogByMap~=published)
check("enumeration list remains provider-owned and unchanged",#ids==3 and ids[1]==1 and ids[3]==3 and W.CatalogCount==3)
-- Client contract: Gethe/wow-ui-source forever, QuestLogDocumentation.lua
-- f0da0a9171aa736c8a64d2b3a8ae70195f5d2afb. Objectives have no objectiveID.
C_QuestLog.GetNumQuestLogEntries=function() return 2,1 end
C_QuestLog.GetInfo=function(i) if i==1 then return {isHeader=true,title="Teldrassil"} end return {questID=1,title="Contract quest",level=7} end
C_QuestLog.GetQuestObjectives=function() return {{text="Defeat target: 1/3",type="monster",objectiveType=0,numFulfilled=1,numRequired=3,finished=false}} end
C_QuestLog.IsComplete=function() return false end
C_QuestLog.ReadyForTurnIn=function() return nil end
s=W.ReadCharacter()
check("Forever shown-entry and total-quest counts are distinct",s.questLogReady and #s.activeQuests==1)
check("Forever objective rows need no invented objective ID",s.activeQuests[1].objectivesReady and s.activeQuests[1].objectives[1].id==nil and s.activeQuests[1].objectives[1].objectiveType==0)
C_QuestLog.GetNumQuestLogEntries=function() return 1,1 end
s=W.ReadCharacter();check("collapsed or partial log cannot declare absence",not s.questLogReady and #s.activeQuests==0)
C_QuestLog.GetNumQuestLogEntries=function() return 2,1 end
C_QuestLog.GetQuestObjectives=function() return nil end
s=W.ReadCharacter();check("nullable objectives remain unknown",s.questLogReady and not s.activeQuests[1].objectivesReady)
print(passed.." provider and client contract checks passed")

