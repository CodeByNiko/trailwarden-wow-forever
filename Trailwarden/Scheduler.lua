local W=Trailwarden
local serial=0;local active
function W.CancelPlanning()
    serial=serial+1;if W.PendingPlan and W.PendingPlan.capture and W.EndDataCapture then W.EndDataCapture() end;W.PendingPlan=nil
end
local function recordPhase(job,now)
    if not now or not job.phaseStarted then return end
    local elapsed=math.max(0,now-job.phaseStarted);local label="plan stage "..job.phase
    local row=W.WorkTimings[label] or {calls=0,total=0,peak=0};W.WorkTimings[label]=row
    row.calls=row.calls+1;row.total=row.total+elapsed;row.peak=math.max(row.peak,elapsed)
end
function W.PlanningPhase(name)
    if active and active.phase~=name then
        local now=type(debugprofilestop)=='function' and debugprofilestop()
        recordPhase(active,now);active.phase=name;active.phaseStarted=now
    end
end
function W.IsPlanningSlice() return active~=nil end
function W.YieldPlanning()
    if not active then return end
    active.operations=active.operations+1
    if active.operations%4~=0 then return end
    local expired
    if type(debugprofilestop)=='function' then expired=debugprofilestop()-active.started>=2 else expired=active.operations>=512 end
    if expired then coroutine.yield() end
end
local function schedule(input,state,force,context,done,failed)
    W.CancelPlanning()
    local job={serial=serial,generation=W.ProviderGeneration,key=(state or input.state).key,operations=0,phase=state and "candidates" or "selection"}
    job.thread=coroutine.create(function()
        if state then job.capture=true;input=W.PreparePlanInput(state,force,context,true);job.capture=false end
        W.PlanningPhase("selection")
        local route,queue,detail=W.SelectRoute(input);detail.input=input;return route,queue,detail
    end)
    W.PendingPlan=job
    local function step()
        if job.serial~=serial then return end
        if job.generation~=W.ProviderGeneration or W.GetCharacterKey()~=job.key then W.CancelPlanning();return end
        if W.IsCombatActive() or W.IsWorldMapOpen() or (W.MapQuietRemaining or 0)>0 then
            W.CancelPlanning();W.CombatRefreshPending=true;W.MapRefreshPending=true;return
        end
        job.operations=0;job.started=type(debugprofilestop)=='function' and debugprofilestop() or 0
        active=job;job.phaseStarted=type(debugprofilestop)=='function' and debugprofilestop()
        local _,ok,route,queue,detail=W.TimedCall("plan slice",coroutine.resume,job.thread)
        recordPhase(job,type(debugprofilestop)=='function' and debugprofilestop());active=nil
        if job.serial~=serial then return end
        if job.generation~=W.ProviderGeneration then W.CancelPlanning();return end
        if not ok then if job.capture and W.EndDataCapture then W.EndDataCapture() end;W.PendingPlan=nil;failed(route);return end
        if coroutine.status(job.thread)~='dead' then C_Timer.After(.01,step);return end
        W.PendingPlan=nil;detail.input=input;done(route,queue,detail)
    end
    step()
end
function W.ScheduleSelection(input,done,failed) return schedule(input,nil,nil,nil,done,failed) end
function W.SchedulePlan(state,force,context,done,failed) return schedule(nil,state,force,context,done,failed) end
function W.ShouldScheduleSelection(force,trigger)
    if not C_Timer or type(C_Timer.After)~='function' or (force and trigger~='manual-replan') then return false end
    return trigger~='combat-safety' and trigger~='life-state' and trigger~='async-recovery'
end
