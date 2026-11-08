local W=Wayfinder
local function escape(s)
    return '"'..s:gsub('[%z\1-\31\\"]',function(c)
        local known={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
        return known[c] or string.format('\\u%04x',string.byte(c))
    end)..'"'
end
function W.Json(value,seen)
    local kind=type(value)
    if kind=="nil" then return "null" end
    if kind=="boolean" then return value and "true" or "false" end
    if kind=="number" then return W.IsFinite(value) and string.format("%.17g",value) or "null" end
    if kind=="string" then return escape(value) end
    if kind~="table" then return "null" end
    seen=seen or {};if seen[value] then error("Cyclic replay value") end;seen[value]=true
    local array=true;local n=0
    for key in pairs(value) do n=n+1;if type(key)~="number" or key%1~=0 or key<1 then array=false end end
    if n~=#value then array=false end
    local parts={}
    if array then for i=1,#value do parts[#parts+1]=W.Json(value[i],seen) end
    else
        local keys={};for key in pairs(value) do keys[#keys+1]=key end;table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
        for _,key in ipairs(keys) do parts[#parts+1]=escape(tostring(key))..":"..W.Json(value[key],seen) end
    end
    seen[value]=nil
    return (array and "[" or "{")..table.concat(parts,",")..(array and "]" or "}")
end
local function portableInput(input)
    local out=W.Copy(input);local s=out.state
    s.key="character";s.name=nil;s.signature=nil
    s.profile={xpRouting=s.profile.xpRouting,paused=s.profile.paused,pinned=s.profile.pinned,skipped=W.Copy(s.profile.skipped),deferredLevels=W.Copy(s.profile.deferredLevels),includeGroup=s.profile.includeGroup,maxLevelAbove=s.profile.maxLevelAbove}
    if s.player then s.player.ownerKey="character" end
    if out.previous then out.previous.ownerKey="character" end
    if out.commitment then out.commitment.ownerKey="character" end
    for _,candidate in ipairs(out.meta.candidates) do candidate.ownerKey="character" end
    return out
end
function W.RecordDecision(decision)
    if not decision.detail or not decision.detail.input then return end
    if W.ReplayOwner~=decision.state.key then W.ReplayOwner=decision.state.key;W.ReplayFrames={};W.ReplayLastSignature=nil end
    local frames=W.ReplayFrames or {};W.ReplayFrames=frames
    local keys={};for _,step in ipairs(decision.queue) do keys[#keys+1]=step.key end
    local frame={event=decision.trigger or "refresh",capturedAt=decision.state.now,input=portableInput(decision.detail.input),expected={key=decision.route.key,queue=keys,clearPin=decision.detail.clearPin==true}}
    local last=frames[#frames]
    if last and last.expected.key==frame.expected.key and W.ReplayLastSignature==decision.state.signature and (decision.trigger=="movement" or decision.trigger=="maintenance") and (last.event=="movement" or last.event=="maintenance") then frames[#frames]=frame else frames[#frames+1]=frame end
    W.ReplayLastSignature=decision.state.signature
    while #frames>20 do table.remove(frames,1) end
end
function W.ExportReplay(origin)
    return W.Json({schema=1,origin=origin or "live-export",addonVersion=W.Version,provider=W.ProviderIdentity(),frames=W.Copy(W.ReplayFrames or {})})
end

