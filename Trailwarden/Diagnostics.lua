local W=Trailwarden
function W.TargetExplanation()
    local route=W.CurrentRoute or {};local detail=W.Decision and W.Decision.detail or {}
    local lines={route.reason or route.instruction or "Trailwarden is waiting for reliable quest data."}
    local count=tonumber(detail.candidateCount) or 0
    if count>0 then lines[#lines+1]=count.." eligible step(s) were considered." end
    local shown=0
    for _,candidate in ipairs(detail.candidates or {}) do
        if candidate.key~=route.key and shown<2 then
            local name=candidate.questName or candidate.title
            if type(name)=="string" and name~="" then
                local distance=W.IsFinite(candidate.distance) and (" · "..W.FormatDistance(candidate.distance)) or ""
                lines[#lines+1]="Also eligible: "..name..distance;shown=shown+1
            end
        end
    end
    if shown>0 then lines[#lines+1]="Other eligible steps remain in the planned list." end
    return lines
end
function W.Diagnostics()
    local s=W.State or W.ReadCharacter();local r=W.CurrentRoute or {};local n=W.Navigation or {}
    local lines={"Trailwarden "..W.Version,"Decision: "..tostring(W.Decision and W.Decision.id).." / navigation "..tostring(n.decisionID).." / map "..tostring(W.WaypointDecisionID),
        "Character: "..s.name.." / "..s.raceName.." "..s.className.." / level "..s.level,
        "Zone: "..s.zone.." / map "..tostring(s.mapID),"Quest log ready: "..tostring(s.questLogReady).." / history ready: "..tostring(s.historyReady),
        "Quest log: "..#s.activeQuests.." active / "..s.completedCount.." completed / revision "..tostring(s.revision),
        "Catalog: "..tostring(W.CatalogState).." / "..tostring(W.CatalogCount or 0).." quests / "..tostring(W.DatabaseStatus),"Catalog error: "..tostring(W.CatalogError or "none"),
        "Step: "..tostring(r.key).." / "..tostring(r.title),"Target: "..tostring(r.target).." / "..tostring(r.mapID).." / "..tostring(r.x)..", "..tostring(r.y),
        "Map pins: "..tostring(W.OverlayStatus),"Planner work area: "..tostring(s.workArea and s.workArea.id).." / region "..tostring(s.regionMapID),
        "Access: "..tostring(n.travel and n.travel.mode).." / cave "..tostring(n.travel and n.travel.caveID).." / source "..tostring(n.travel and n.travel.entry and n.travel.entry.accessSource).." / error "..tostring(W.AccessError or "none"),
        "Navigation: "..(n.label or "none").." / distance "..tostring(n.distance),"Last plan: "..string.format("%.2f",W.LastPlanMilliseconds or 0).." ms / event "..tostring(W.LastEvent),
        "Last error: "..tostring(W.LastError or "none"),"Event error: "..tostring(W.EventError or "none"),"Recovered error: "..tostring(W.RecoveredError or "none"),"Map waypoint: "..tostring(W.WaypointStatus),"Local replay: /tw trace (last 20 decisions)","Deferred / unmapped:"}
    for _,issue in ipairs(s.readIssues or {}) do lines[#lines+1]="Read issue: "..issue end
    for _,q in ipairs(W.Unmapped or {}) do lines[#lines+1]=q.id.." / "..q.title.." / "..q.reason end
    local e=W.SafeExperienceStats()
    lines[#lines+1]="XP: "..W.FormatXP(e.totalXP).." / rolling "..W.FormatXP(e.rate).." per hour / next level "..W.FormatETA(e.eta)
    lines[#lines+1]="XP sources: "..e.kills.." rewarded kills / "..e.turnins.." turn-ins / "..e.questXP.." event quest XP"
    lines[#lines+1]="XP pace: "..string.format("%.1f",e.moveSpeed).." yards/sec / "..string.format("%.1f",e.killSeconds).." seconds/kill"
    lines[#lines+1]="XP quest model: "..(r.economy and W.FormatXP(r.economy.xpPerHour) or "unknown").." / "..(r.economy and r.economy.confidence or "unknown")
    if e.calibration then lines[#lines+1]="Last quest XP calibration: "..tostring(e.calibration.questID).." / predicted "..W.FormatXP(e.calibration.expectedXP).." / actual "..W.FormatXP(e.calibration.actualXP).." / error "..string.format("%.1f%%",e.calibration.percentError)..(e.calibration.percentError>=50 and " (large estimate error)" or "") end
    lines[#lines+1]="Region plan: "..tostring(W.Decision and W.Decision.commitment and W.Decision.commitment.mapID)
    lines[#lines+1]="Forecast error: "..tostring(W.ForecastError or "none").." / learning error: "..tostring(W.LearningError or "none")
    lines[#lines+1]="Combat target cap: +"..W.CombatLevelMargin.." / risk revision "..tostring(s.combatSafety and s.combatSafety.revision)
    for issue in pairs(s.policyIssues or {}) do lines[#lines+1]="Quest policy: "..issue end
    lines[#lines+1]="Planning: "..tostring(W.PlanExecutions).." selections / "..tostring(W.ForecastBuilds or 0).." forecasts / "..tostring(W.ForecastCacheHits or 0).." cached forecasts"
    local planDetail=W.Decision and W.Decision.detail or {}
    lines[#lines+1]="Planner budget: "..tostring(planDetail.candidateCount or 0).." candidates / "..tostring(planDetail.scoreEvaluations or 0).." scores / preview shortened="..tostring(planDetail.queuePreviewShortened==true)
    for id,message in pairs(W.TargetErrors or {}) do lines[#lines+1]="Target "..id..": "..message end
    lines[#lines+1]="Active quest objectives:"
    for _,q in ipairs(s.activeQuests) do
        lines[#lines+1]=q.id.." / "..q.title.." / complete="..tostring(q.isComplete).." / objectives ready="..tostring(q.objectivesReady)
        for _,o in ipairs(q.objectives) do lines[#lines+1]="  "..tostring(o.type).." / "..tostring(o.id).." / "..o.text.." / "..tostring(o.fulfilled).."/"..tostring(o.required).." / done="..tostring(o.finished) end
    end
    lines[#lines+1]="Output/data errors:"
    for key,value in pairs(W.OutputErrors or {}) do lines[#lines+1]=key..": "..value end
    for key,value in pairs(W.DataIssues or {}) do lines[#lines+1]=key..": "..value end
    return table.concat(lines,"\n")
end
