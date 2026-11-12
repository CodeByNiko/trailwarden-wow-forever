Trailwarden={}
local W=Trailwarden
W.Safe=function(fn,...) if type(fn)~="function" then return nil end;local ok,value=pcall(fn,...);return ok and value or nil end
local selected="auto"
W.GetProfile=function() return {language=selected} end
GetLocale=function() return "daDK" end
dofile("Trailwarden/Locale.lua")
local passed=0
local function check(name,ok) assert(ok,name);passed=passed+1;print("PASS localization / "..name) end
check("automatic Danish locale is recognized",W.L("action_escort")=="ESKORTE")
selected="en";check("English selection overrides client locale",W.L("action_escort")=="ESCORT")
selected="da";check("Danish action labels resolve",W.L("action_objective")=="OPGAVE")
check("map cues have distinct non-color glyphs",W.L("marker_entrance")~=W.L("marker_objective"))
local danishAction=W.LocaleCatalogs.daDK.action_escort;W.LocaleCatalogs.daDK.action_escort=nil
check("missing translation falls back to English catalog",W.L("action_escort")=="ESCORT")
W.LocaleCatalogs.daDK.action_escort=danishAction
check("provider and quest names remain caller-owned",W.L("A quest name")=="A quest name")
selected="unsupported";check("unsupported profile value safely falls back to client locale",W.L("action_escort")=="ESKORTE")
print(string.format("%d localization checks passed",passed))
