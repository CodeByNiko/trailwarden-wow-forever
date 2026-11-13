"""Generate compact factual quest/zone IDs using the public provider API, offline."""
import argparse
from pathlib import Path
from provider_runtime import load_provider
p=argparse.ArgumentParser();p.add_argument('provider',type=Path);p.add_argument('--expected-version',required=True);p.add_argument('--archive-sha',required=True);p.add_argument('--output',type=Path,default=Path('Trailwarden/CatalogIndex.lua'));p.add_argument('--check',action='store_true');p.add_argument('--build',default='70245');p.add_argument('--symbol',default='ProviderCatalogIndex');a=p.parse_args()
lua,provider,version=load_provider(a.provider,a.expected_version,a.build)
g=lua.globals();g.LibQuestieDB=provider
lua.execute(b'''C_Map={GetMapInfo=function() return {mapType=3} end}
for _,name in ipairs({"Common","Data","Database"}) do dofile("Trailwarden/"..name..".lua") end
local W=Trailwarden
local entities={Npc={},Object={}}
for _,kind in ipairs({"Npc","Object"}) do
 local db=LibQuestieDB[kind];local read=db.Get
 local spawn=db.spawns;if spawn then db.spawns=function(id) entities[kind][id]=true;return spawn(id) end end
 db.Get=function(id,field) if field=="spawns" then entities[kind][id]=true end;return read(id,field) end
end
W.BuildQuestCatalog(true)
assert(W.CatalogReady,W.CatalogError)
index={schema=1,version=W.ProviderIdentity().version,contract=LibQuestieDB.contractVersion,mode=LibQuestieDB.mode,flavor=LibQuestieDB.flavor.name,build=W.ProviderIdentity().build,ids={},maps={},items={},entities={Npc={},Object={}}}
for i,id in ipairs(LibQuestieDB.Quest.GetAllIds()) do index.ids[i]=id end
for map,records in pairs(W.CatalogByMap) do local ids={};for _,r in ipairs(records) do ids[#ids+1]=r.id end;table.sort(ids);index.maps[map]=ids end
for _,entry in ipairs(W.ItemQuests) do index.items[entry.record.id]=entry.items end
for kind,values in pairs(entities) do for id in pairs(values) do index.entities[kind][#index.entities[kind]+1]=id end;table.sort(index.entities[kind]) end''')
def literal(v):
    if v is None:return 'nil'
    if isinstance(v,bool):return 'true' if v else 'false'
    if isinstance(v,bytes):return '"'+v.decode().replace('\\','\\\\').replace('"','\\"')+'"'
    if isinstance(v,(int,float)):return str(v)
    pairs=sorted(v.items(),key=lambda x:(isinstance(x[0],bytes),x[0]))
    return '{'+','.join('['+literal(k)+']='+literal(value) for k,value in pairs)+'}'
content='-- Generated factual IDs via tools/generate_catalog_index.py; no provider code or coordinates.\n-- QuestieDB '+version+' Forever ZIP SHA-256: '+a.archive_sha+'\nlocal identity=Trailwarden.ProviderIdentity()\nif identity.version=="'+version+'" and identity.build=="'+a.build+'" then\nTrailwarden.'+a.symbol+'='+literal(g.index)+'\nend\n'
if a.check:
    if not a.output.exists() or a.output.read_text()!=content:raise SystemExit('Generated catalog index differs')
    print('Catalog index is reproducible and matches the actual provider')
else:a.output.write_text(content);print(a.output,len(content),'bytes')
