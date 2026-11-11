"""Optional integration check against an extracted, official QuestieDB Forever ZIP.

Install developer-only dependencies: python3 -m pip install lupa cbor2
Run: python3 tools/check_provider.py /path/to/QuestieDB
No provider data, Python dependencies or downloaded code is shipped in the addon.
The actual provider runs under Lua 5.1; client APIs and objective counts are doubles.
"""
import argparse
import base64
import os
from pathlib import Path
import zlib

import cbor2
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('provider', type=Path)
parser.add_argument('--expected-version', help='Fail if the provider TOC version differs from this pinned release.')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
provider = args.provider.resolve()
lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
globals_ = lua.globals()
namespace = lua.table()
metadata, files = {}, []
for line in (provider / 'QuestieDB_Forever.toc').read_bytes().splitlines():
    if line.startswith(b'## '):
        key, _, value = line[3:].partition(b':')
        metadata[key] = value.strip()
    elif line.strip() and not line.startswith(b'#'):
        files.append(line.decode().replace('\\', '/'))
version = metadata.get(b'Version', b'').decode()
if args.expected_version and version != args.expected_version:
    raise SystemExit(f'Expected QuestieDB {args.expected_version}, found {version or "unknown"}')


def to_lua(value):
    if isinstance(value, dict):
        return lua.table_from({to_lua(k): to_lua(v) for k, v in value.items()})
    if isinstance(value, (list, tuple)):
        return lua.table_from([to_lua(v) for v in value])
    return value.encode() if isinstance(value, str) else value


def decompress(value, _kind):
    for window in (15, -15, 31):
        try:
            return zlib.decompress(value, window)
        except zlib.error:
            pass
    raise ValueError('Unsupported compressed QuestieDB block')


globals_.py_metadata = lambda _addon, key: metadata.get(key)
globals_.py_cbor = lambda value: to_lua(cbor2.loads(value))
globals_.py_base64 = base64.b64decode
globals_.py_decompress = decompress
lua.execute(b'''
GetAddOnMetadata=function(a,k) return py_metadata(a,k) end
C_AddOns={GetAddOnMetadata=GetAddOnMetadata}
C_EncodingUtil={DecodeBase64=function(s) return py_base64(s) end,
 DecompressString=function(s,k) return py_decompress(s,k) end,
 DeserializeCBOR=function(s) return py_cbor(s) end}
GetLocale=function() return "enUS" end
GetBuildInfo=function() return "1.60.1","70245","",16001 end
UnitFactionGroup=function() return "Alliance" end
UnitClassBase=function() return "WARRIOR",1 end
UnitRace=function() return "Night Elf","NightElf",4 end
''')
for name in files:
    path = (provider / name).resolve()
    if not path.is_relative_to(provider):
        raise ValueError('Provider TOC path escapes its addon directory')
    lua.execute(path.read_bytes(), b'QuestieDB', namespace)
assert namespace[b'RequireContract'](3) is True
globals_.actualProvider = namespace
os.chdir(root)
# Exercise all existing client doubles, then start a fresh addon namespace so
# fixture provider caches and character profiles cannot contaminate this check.
lua.execute(b'print=function() end')
lua.execute((root / 'tests/scenarios.lua').read_bytes())
lua.execute(b'''
LibQuestieDB=actualProvider;QuestDB=LibQuestieDB.Quest;NpcDB=LibQuestieDB.Npc
ItemDB=LibQuestieDB.Item;ObjectDB=LibQuestieDB.Object
QuestieLoader=nil;Trailwarden=nil;TrailwardenDB=nil;C_Timer=nil
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
for _,name in ipairs({"Common","Data","Tracking","Database","Safety","Experience","Planner","UI","Travel","Navigator","RouteOverlay","Replay","Core"}) do dofile("Trailwarden/"..name..".lua") end
local refresh=Trailwarden.Refresh;Trailwarden.Refresh=nil;Trailwarden.BuildQuestCatalog();Trailwarden.Refresh=refresh
assert(Trailwarden.CatalogReady,Trailwarden.CatalogError)
assert(Trailwarden.CatalogCount==#LibQuestieDB.Quest.GetAllIds())
Trailwarden.Refresh(true,"provider-smoke")
assert(not Trailwarden.LastError,Trailwarden.LastError)
assert(not Trailwarden.ForecastError,Trailwarden.ForecastError)
local accepted
for _,c in ipairs(Trailwarden.Decision.detail.candidates) do
 if c.questID==456 and c.kind=="objective" then accepted=c;break end
end
assert(accepted and accepted.combatRisk.status=="allowed","Accepted quest requires a verified source")
Trailwarden.PinStep(accepted)
assert(Trailwarden.CurrentRoute.questID==456 and Trailwarden.CurrentRoute.kind=="objective")
assert(not Trailwarden.LastError and not Trailwarden.ForecastError)
''')
print('QuestieDB', version, '/ contract', namespace[b'contractVersion'])
print('Complete catalog:', globals_.Trailwarden[b'CatalogCount'], 'quests; accepted objective and forecasts passed')
print('Provider reads are real; client APIs, position and objective counts are synthetic.')
