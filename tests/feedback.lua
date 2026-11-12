Trailwarden={}
local W=Trailwarden
dofile("Trailwarden/Common.lua")
dofile("Trailwarden/Replay.lua")
W.ProviderIdentity=function() return {version="Forever test",contract=4,build="client test"} end
W.Version="1.8.12"
W.CurrentRoute={kind="objective",title="Private quest title",questID=765432,reason="raw private reason",point={mapID=1438,x=.123456,y=.654321},source="Private provider detail"}
W.Decision={detail={candidateCount=3,scoreEvaluations=3,candidates={{kind="objective",questName="Private quest title",questID=765432},{kind="pickup",questName="Other private quest",questID=987654}}}}
W.Queue={{kind="objective",title="Private quest title",questID=765432}}
local export=W.ExportFeedback()
local passed=0
local function check(name,ok) assert(ok,name);passed=passed+1;print("PASS feedback / "..name) end
check("feedback export is valid JSON with release and provider identity",export:find('"addonVersion":"1.8.12"',1,true) and export:find('"contract":4',1,true))
check("feedback export reports route category and reason code",export:find('"routeKind":"objective"',1,true) and export:find('"why":"accepted_quest_objective"',1,true))
check("feedback export aggregates counts without candidate records",export:find('"candidateCount":3',1,true) and not export:find('"candidates"',1,true))
check("feedback export omits character and quest names",not export:find("Raelorn",1,true) and not export:find("Private quest",1,true) and not export:find("Other private",1,true))
check("feedback export omits quest IDs, coordinates and raw free text",not export:find("765432",1,true) and not export:find("987654",1,true) and not export:find("0.123456",1,true) and not export:find("raw private reason",1,true) and not export:find("Private provider detail",1,true))
check("feedback export does not include profile preferences",not export:find("preferences",1,true) and not export:find("includeGroup",1,true) and not export:find("paused",1,true))
print(string.format("%d feedback export checks passed",passed))
