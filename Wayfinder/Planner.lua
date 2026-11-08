Wayfinder = Wayfinder or {}
local W = Wayfinder

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

local function importQuestieModule(name)
    if QuestieLoader and type(QuestieLoader.ImportModule) == "function" then
        return safe(QuestieLoader.ImportModule, QuestieLoader, name)
    end
end

local function getQuestDB()
    if LibQuestieDB and LibQuestieDB.Quest and LibQuestieDB.Quest.Get and LibQuestieDB.Quest.GetAllIds then
        return LibQuestieDB.Quest
    end
    if QuestDB and QuestDB.Get and QuestDB.GetAllIds then return QuestDB end
    return nil
end

local function getNPCDB()
    if LibQuestieDB and LibQuestieDB.Npc then return LibQuestieDB.Npc end
    if NpcDB then return NpcDB end
    return nil
end

local function uiMapForArea(areaID)
    if not areaID or areaID <= 0 then return nil end
    local zoneDB = W.ZoneDB or importQuestieModule("ZoneDB")
    W.ZoneDB = zoneDB
    if zoneDB and zoneDB.GetUiMapIdByAreaId then
        local mapID = safe(zoneDB.GetUiMapIdByAreaId, zoneDB, areaID)
        if mapID then return mapID end
    end
    return nil
end

local function questField(db, id, key)
    return safe(db.Get, id, key)
end

local function mapPoint(mapID, x, y)
    if not mapID or not x or not y or not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return nil end
    local px, py = x, y
    if px > 1 or py > 1 then px, py = px / 100, py / 100 end
    local continentID, worldPosition = safe(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(px, py))
    if not continentID or not worldPosition then return nil end
    local wx, wy
    if worldPosition.GetXY then wx, wy = worldPosition:GetXY() else wx, wy = worldPosition.x, worldPosition.y end
    if not wx or not wy then return nil end
    return { mapID=mapID, x=px, y=py, continent=continentID, wx=wx, wy=wy }
end

local function getPlayerWorldPosition(state)
    if not state.mapID or not C_Map or not C_Map.GetPlayerMapPosition then return nil end
    local pos = safe(C_Map.GetPlayerMapPosition, state.mapID, "player")
    if not pos then return nil end
    local x, y = pos:GetXY()
    return mapPoint(state.mapID, x, y)
end

local function getStarterNPCs(startedBy)
    if type(startedBy) ~= "table" then return {} end
    -- Questie stores starter IDs as { NPC IDs, object IDs, item IDs }.
    if type(startedBy[1]) == "table" then return startedBy[1] end
    return startedBy
end

function W.BuildQuestCatalog()
    local qdb, ndb = getQuestDB(), getNPCDB()
    W.QuestieDBModule = W.QuestieDBModule or importQuestieModule("QuestieDB")
    if not qdb or not ndb then
        W.QuestCatalog = nil
        W.QuestCatalogStatus = "QuestieDB data is not available"
        if W.RefreshUI then W.RefreshUI() end
        return
    end
    local ids = safe(qdb.GetAllIds) or {}
    local catalog, index = {}, 1
    W.QuestCatalogStatus = "Preparing route data"

    local function buildSlice()
        local last = math.min(index + 29, #ids)
        for i = index, last do
            local questID = ids[i]
            if questID then
                local name = questField(qdb, questID, "name")
                local requiredLevel = questField(qdb, questID, "requiredLevel") or 0
                local questLevel = questField(qdb, questID, "questLevel") or 0
                local zoneOrSort = questField(qdb, questID, "zoneOrSort") or 0
                local startedBy = questField(qdb, questID, "startedBy")
                local npcs = getStarterNPCs(startedBy)
                if name and type(npcs) == "table" and #npcs > 0 then
                    local seen = {}
                    for n = 1, math.min(#npcs, 4) do
                        local npcID = npcs[n]
                        if npcID and not seen[npcID] then
                            seen[npcID] = true
                            local spawns = safe(ndb.Get, npcID, "spawns") or {}
                            local npcName = safe(ndb.Get, npcID, "name")
                            for areaID, coords in pairs(spawns) do
                                local mapID = uiMapForArea(areaID)
                                if mapID and type(coords) == "table" then
                                    for j = 1, math.min(#coords, 3) do
                                        local coord = coords[j]
                                        if coord and coord[1] and coord[2] then
                                            local x, y = coord[1], coord[2]
                                            if x > 1 or y > 1 then x, y = x / 100, y / 100 end
                                            if x >= 0 and y >= 0 and x <= 1 and y <= 1 then
                                                catalog[#catalog + 1] = {
                                                    questID=questID,
                                                    name=name,
                                                    requiredLevel=requiredLevel,
                                                    questLevel=questLevel,
                                                    zoneOrSort=zoneOrSort,
                                                    npcID=npcID,
                                                    npcName=npcName or "Quest giver",
                                                    areaID=areaID,
                                                    point={ mapID=mapID, x=x, y=y },
                                                }
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        index = last + 1
        if index <= #ids then
            C_Timer.After(0.02, buildSlice)
        else
            W.QuestCatalog = catalog
            W.QuestCatalogStatus = "Route data ready"
            if W.RefreshUI then W.RefreshUI() end
        end
    end

    if #ids == 0 then
        W.QuestCatalog = {}
        W.QuestCatalogStatus = "QuestieDB has no quest records"
        if W.RefreshUI then W.RefreshUI() end
    else
        buildSlice()
    end
end

local function isQuestCompleted(state, id)
    if state.completed then return state.completed[id] == true end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return safe(C_QuestLog.IsQuestFlaggedCompleted, id) == true
    end
    return false
end

local function skipQuest(id, state)
    if isQuestCompleted(state, id) then return true end
    local questieDB = W.QuestieDBModule or importQuestieModule("QuestieDB")
    W.QuestieDBModule = questieDB
    if questieDB then
        local checks = { "IsPvPQuest", "IsDungeonQuest", "IsRaidQuest", "IsGroupQuest", "IsRepeatable", "IsActiveEventQuest" }
        for _, method in ipairs(checks) do
            if type(questieDB[method]) == "function" and safe(questieDB[method], id) == true then return true end
        end
        if type(questieDB.IsDoable) == "function" then
            local doable = safe(questieDB.IsDoable, id)
            if doable == false then return true end
        end
    end
    return false
end

local function questLevelFits(entry, level)
    local needed = entry.requiredLevel or 0
    local questLevel = entry.questLevel or 0
    if needed > level then return false end
    if questLevel > 0 and (questLevel < level - 7 or questLevel > level + 5) then return false end
    return true
end

local function distance(a, b)
    if not a or not b or a.continent ~= b.continent then return math.huge end
    local dx, dy = a.wx - b.wx, a.wy - b.wy
    return math.sqrt(dx * dx + dy * dy)
end

local function chooseActiveWaypoint(state)
    local options = {}
    local player = getPlayerWorldPosition(state)
    for _, quest in ipairs(state.activeQuests or {}) do
        if quest.waypoint and not skipQuest(quest.id, state) then
            local p = mapPoint(quest.waypoint.mapID, quest.waypoint.x, quest.waypoint.y)
            if p then
                local nearby = 0
                for _, other in ipairs(state.activeQuests or {}) do
                    if other.id ~= quest.id and other.waypoint and other.waypoint.mapID == quest.waypoint.mapID then
                        local q = mapPoint(other.waypoint.mapID, other.waypoint.x, other.waypoint.y)
                        if q and distance(p, q) < 450 then nearby = nearby + 1 end
                    end
                end
                local d = distance(player, p)
                local isLocal = quest.zoneMapID and quest.zoneMapID == state.mapID
                options[#options + 1] = {
                    kind="active", title=(quest.isComplete and "Turn in: " or "Continue: ") .. quest.title, questID=quest.id,
                    zone=p.mapID and (safe(C_Map.GetMapInfo, p.mapID) or {}).name or state.zone,
                    mapID=p.mapID, x=p.x, y=p.y, normalized=true,
                    reason=quest.isComplete and "Ready to turn in" or "Continue an active quest",
                    detail=quest.isComplete and "Turning this in can unlock the next part of its chain." or "This objective is already in your quest log.",
                    cluster=nearby, distance=d, localZone=isLocal,
                }
            end
        end
    end
    table.sort(options, function(a,b)
        if a.localZone ~= b.localZone then return a.localZone end
        if a.cluster ~= b.cluster then return a.cluster > b.cluster end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return tostring(a.title) < tostring(b.title)
    end)
    return options[1], options
end

local function getMapLabel(mapID)
    local info = mapID and safe(C_Map.GetMapInfo, mapID)
    return info and info.name or "Nearby route"
end

local function choosePickupRoute(state)
    local catalog = W.QuestCatalog
    if not catalog or #catalog == 0 then return nil end
    local player = getPlayerWorldPosition(state)
    local candidates = {}
    for _, entry in ipairs(catalog) do
        if entry.point.mapID == state.mapID and not state.activeByID[entry.questID] and questLevelFits(entry, state.level) and not skipQuest(entry.questID, state) then
            local d = math.huge
            if player then
                local dx, dy = player.x - entry.point.x, player.y - entry.point.y
                d = math.sqrt(dx * dx + dy * dy)
            end
            if d < math.huge then
                entry._distance = d
                candidates[#candidates + 1] = entry
            end
        end
    end
    if #candidates == 0 then return nil end
    -- Use small spatial buckets so a large continent catalog stays inexpensive.
    local buckets, cell = {}, 0.055
    for _, entry in ipairs(candidates) do
        local mapID = entry.point.mapID
        buckets[mapID] = buckets[mapID] or {}
        local gx, gy = math.floor(entry.point.x / cell), math.floor(entry.point.y / cell)
        local key = gx .. ":" .. gy
        buckets[mapID][key] = buckets[mapID][key] or {}
        table.insert(buckets[mapID][key], entry)
    end
    for _, entry in ipairs(candidates) do
        local mapID, px, py = entry.point.mapID, entry.point.x, entry.point.y
        local gx, gy, unique, count = math.floor(px / cell), math.floor(py / cell), {}, 0
        for ox=-1,1 do for oy=-1,1 do
            local rows = buckets[mapID][(gx+ox) .. ":" .. (gy+oy)] or {}
            for _, other in ipairs(rows) do
                local dx, dy = other.point.x-px, other.point.y-py
                if dx*dx + dy*dy <= cell*cell and not unique[other.questID] then
                    unique[other.questID] = true
                    count = count + 1
                end
            end
        end end
        entry._density = count
    end
    table.sort(candidates, function(a,b)
        local aCurrent, bCurrent = a.point.mapID == state.mapID, b.point.mapID == state.mapID
        if aCurrent ~= bCurrent then return aCurrent end
        if a._density ~= b._density then return a._density > b._density end
        if a._distance ~= b._distance then return a._distance < b._distance end
        return tostring(a.name) < tostring(b.name)
    end)
    local best = candidates[1]
    local ordered, included = {}, {}
    local function addStep(entry)
        if #ordered < 3 and not included[entry.questID] then
            included[entry.questID] = true
            ordered[#ordered + 1] = entry
        end
    end
    -- First collect quests from the same nearby quest-giver cluster, then offer
    -- the next nearest hubs in this zone as the following route steps.
    for _, entry in ipairs(candidates) do
        local dx, dy = entry.point.x-best.point.x, entry.point.y-best.point.y
        if entry.point.mapID == best.point.mapID and dx*dx+dy*dy <= 0.025*0.025 then addStep(entry) end
    end
    for _, entry in ipairs(candidates) do addStep(entry) end
    local steps = {}
    for i, entry in ipairs(ordered) do
        steps[i] = {
            title=(i == 1 and "Accept: " or "Then accept: ") .. entry.name,
            npcName=entry.npcName,
            zone=getMapLabel(entry.point.mapID),
            questID=entry.questID,
            mapID=entry.point.mapID, x=entry.point.x, y=entry.point.y, normalized=true,
        }
    end
    return {
        kind="pickup", title="Travel to " .. best.npcName, actionTitle="Accept: " .. best.name, questName=best.name, questID=best.questID,
        zone=getMapLabel(best.point.mapID), mapID=best.point.mapID,
        x=best.point.x, y=best.point.y, normalized=true,
        npcName=best.npcName,
        reason="Arrive and accept this quest. I’ll choose your next nearby step after it enters the quest log.",
        detail="Quest pickup · nearby quests are queued after this one",
        cluster=best._density, routeStops=steps,
    }
end

function W.PlanRoute(state)
    state = state or W.State or W.ScanCharacter()
    local active, activeOptions = chooseActiveWaypoint(state)
    if active then
        active.routeStops = {}
        for i = 1, math.min(3, #activeOptions) do active.routeStops[i] = activeOptions[i] end
        return active
    end
    local pickup = choosePickupRoute(state)
    if pickup then return pickup end
    return W.GetRecommendation(state)
end
