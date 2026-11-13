"""Optional integration check against an extracted, official QuestieDB Forever ZIP.

Install developer-only dependencies: python3 -m pip install lupa cbor2
Run: python3 tools/check_provider.py /path/to/QuestieDB
No provider source, Python dependencies or downloaded code is shipped in the addon.
The addon includes a reproducible, version-bound factual quest/zone ID index.
The actual provider runs under Lua 5.1; client APIs and objective counts are doubles.
"""
import argparse
import os
from pathlib import Path


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('provider', type=Path)
parser.add_argument('--expected-version', help='Fail if the provider TOC version differs from this pinned release.')
parser.add_argument('--build', default='70245')
parser.add_argument('--numeric-build', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
provider = args.provider.resolve()
from provider_runtime import load_provider
lua,namespace,version=load_provider(provider,args.expected_version,args.build)
globals_=lua.globals()
globals_.actualProvider = namespace
os.chdir(root)
# Exercise all existing client doubles, then start a fresh addon namespace so
# fixture provider caches and character profiles cannot contaminate this check.
lua.execute(b'print=function() end')
lua.execute((root / 'tests/scenarios.lua').read_bytes())
if args.numeric_build:
    globals_.numeric_test_build=int(args.build)
    lua.execute(b'GetBuildInfo=function() return "1.60.1",numeric_test_build end')
lua.execute(b'''
LibQuestieDB=actualProvider;QuestDB=LibQuestieDB.Quest;NpcDB=LibQuestieDB.Npc
ItemDB=LibQuestieDB.Item;ObjectDB=LibQuestieDB.Object
hooksecurefunc=function(owner,key,callback)
 local original=owner[key];owner[key]=function(...) local a,b,c,d=original(...);callback(...);return a,b,c,d end
end
QuestieLoader=nil;Trailwarden=nil;TrailwardenDB=nil;C_Timer=nil;SlashCmdList={}
UnitGUID=function(unit) if unit=="player" then return "Player-Provider-Smoke" end end
UnitName=function() return "Provider test" end
UnitClass=function() return "Warrior","WARRIOR",1 end
UnitRace=function() return "Night Elf","NightElf",4 end
UnitLevel=function() return 7 end
UnitIsDeadOrGhost=function() return false end
UnitXP=function() return 100 end;UnitXPMax=function() return 1000 end
C_Map.GetBestMapForUnit=function() return 1438 end
C_Map.GetPlayerMapPosition=function() return CreateVector2D(.58,.45) end
-- Unavailable map metadata must not make an instance sentinel abort the catalog.
C_Map.GetMapInfo=function(id) if id==1438 then return {mapType=3,name="Teldrassil"} end end
local objectiveRows={}
for _,entry in ipairs(LibQuestieDB.Quest.Get(456,"objectives")[1] or {}) do
 objectiveRows[#objectiveRows+1]={type="monster",text=LibQuestieDB.Npc.Get(entry[1],"name"),numRequired=5,numFulfilled=0,finished=false}
end
C_QuestLog.GetNumQuestLogEntries=function() return 1,1 end
C_QuestLog.GetInfo=function() return {questID=456,title=LibQuestieDB.Quest.Get(456,"name"),level=2} end
C_QuestLog.GetQuestObjectives=function() return objectiveRows end
C_QuestLog.IsComplete=function() return false end
C_QuestLog.GetAllCompletedQuestIDs=function() return {} end
C_QuestLog.GetNextWaypoint=function() end
for _,name in ipairs({"Common","Locale","Data","CatalogIndex","CatalogIndex1015","Provider","Tracking","Database","Safety","Experience","Planner","UI","Travel","Navigator","RouteOverlay","Replay","Diagnostics","Scheduler","Core","Commands"}) do dofile("Trailwarden/"..name..".lua") end
collectgarbage("collect");local baseMemory=collectgarbage("count");local started=os.clock()
local refresh=Trailwarden.Refresh;Trailwarden.Refresh=nil;Trailwarden.BuildQuestCatalog();Trailwarden.Refresh=refresh
catalogColdMS=(os.clock()-started)*1000
collectgarbage("collect");catalogRetainedKB=collectgarbage("count")-baseMemory
assert(Trailwarden.CatalogReady,Trailwarden.CatalogError)
local named=0
for _,id in ipairs(LibQuestieDB.Quest.GetAllIds()) do if type(LibQuestieDB.Quest.Get(id,"name"))=="string" then named=named+1 end end
assert(Trailwarden.CatalogCount==named,"Catalog did not retain every named quest")
assert(Trailwarden.CatalogIndexStatus=="verified offline zone index",Trailwarden.CatalogIndexStatus)
assert(not Trailwarden.ProviderReads["Npc.spawns"] and not Trailwarden.ProviderReads["Object.spawns"],"Global spawn queries during indexed startup")
Trailwarden.Refresh(true,"provider-smoke")
assert(not Trailwarden.LastError,Trailwarden.LastError)
assert(not Trailwarden.ForecastError,Trailwarden.ForecastError)
assert(type(Trailwarden.Diagnostics)=="function","Diagnostics module was not loaded into the fresh addon namespace")
assert(type(Trailwarden.TargetExplanation)=="function","Target explanation module was not loaded into the fresh addon namespace")
assert(type(SlashCmdList.TRAILWARDEN)=="function","Slash commands were not registered in the fresh addon namespace")
assert(Trailwarden.Diagnostics():find("Trailwarden",1,true),"Fresh-namespace diagnostics did not render")
local commandOK,commandError=pcall(SlashCmdList.TRAILWARDEN,"debug")
assert(commandOK,"Fresh-namespace debug command failed: "..tostring(commandError))
assert(Trailwarden.DiagnosticsFrame and Trailwarden.DiagnosticsFrame.edit:GetText():find("Trailwarden",1,true),"Debug command did not render fresh-namespace diagnostics")
assert(next(Trailwarden.OutputErrors or {})==nil,"Output errors after initial refresh: "..Trailwarden.Diagnostics())
local accepted
for _,c in ipairs(Trailwarden.Decision.detail.candidates) do
 if c.questID==456 and c.kind=="objective" then accepted=c;break end
end
assert(accepted and accepted.combatRisk.status=="allowed","Accepted quest requires a verified source")
Trailwarden.PinStep(accepted)
assert(Trailwarden.CurrentRoute.questID==456 and Trailwarden.CurrentRoute.kind=="objective")
assert(not Trailwarden.LastError and not Trailwarden.ForecastError)
assert(next(Trailwarden.OutputErrors or {})==nil,"Output errors after pinning the provider objective: "..Trailwarden.Diagnostics())
''')
lua.execute(b'''
local W=Trailwarden
local first=LibQuestieDB.Quest.Get(456,"objectives")[1][1][1]
local a=LibQuestieDB.Npc.Get(first,"spawns");local b=LibQuestieDB.Npc.Get(first,"spawns")
assert(a~=b,"Real provider did not return independent tables")
W.BeginDataCapture();local before=W.ProviderReads["Npc.spawns"] or 0
local one=W.DBRead("Npc",first,"spawns");local two=W.DBRead("Npc",first,"spawns")
assert(one==two and W.ProviderReads["Npc.spawns"]==before+1,"Repeated real reads not coalesced")
W.EndDataCapture();W.BeginDataCapture();local three=W.DBRead("Npc",first,"spawns");W.EndDataCapture();assert(three~=one)
collectgarbage("collect");local base=collectgarbage("count");collectgarbage("stop");local started=os.clock()
for i=1,10 do W.Refresh(true,"real-provider-warm") end
warmMS=(os.clock()-started)*1000;warmAllocatedKB=collectgarbage("count")-base
collectgarbage("restart");collectgarbage("collect");warmRetainedKB=collectgarbage("count")-base
assert(not W.LastError and not W.ForecastError)
assert(W.EntityCacheEntries<=128 and W.EntityCachePoints<=4096 and (W.ReplayEntries or 0)<=12000)
local captured=W.WorkCounters.captures;local plans=W.PlanExecutions
WorldMapFrame={IsShown=function() return true end}
for i=1,100 do W.Refresh(false,"QUEST_LOG_UPDATE");W.EventFrame.scripts.OnEvent(W.EventFrame,"UPDATE_MOUSEOVER_UNIT") end
assert(W.WorkCounters.captures==captured and W.PlanExecutions==plans,"Map storm escaped gates with real provider")
WorldMapFrame=nil
''')
print('Actual provider cold catalog: %.2f ms / %.1f KiB retained' % (globals_.catalogColdMS,globals_.catalogRetainedKB))
print('Actual provider 10 warm plans: %.2f ms / %.1f KiB allocated / %.1f KiB retained' % (globals_.warmMS,globals_.warmAllocatedKB,globals_.warmRetainedKB))
print('QuestieDB', version, '/ contract', namespace[b'contractVersion'])
print('Complete catalog:', globals_.Trailwarden[b'CatalogCount'], 'quests; accepted objective and forecasts passed')
print('Provider reads are real; client APIs, position and objective counts are synthetic.')
