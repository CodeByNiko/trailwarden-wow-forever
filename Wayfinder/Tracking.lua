Wayfinder = Wayfinder or {}
local W = Wayfinder

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
    return nil
end

function W.GetCharacterKey()
    local name = UnitName and UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName() or "Realm"
    return tostring(name) .. " - " .. tostring(realm)
end

function W.GetProfile()
    WayfinderDB = WayfinderDB or {}
    WayfinderDB.profiles = WayfinderDB.profiles or {}
    local key = W.GetCharacterKey()
    WayfinderDB.profiles[key] = WayfinderDB.profiles[key] or {
        mode = "Balanced",
        waterTotemStage = 0,
        dismissedWelcome = false,
        collapsed = false,
    }
    return WayfinderDB.profiles[key]
end

function W.ScanCharacter()
    local classToken
    if UnitClass then
        local localized, token = UnitClass("player")
        classToken = token or localized
    end
    local raceName, raceToken
    if UnitRace then raceName, raceToken = UnitRace("player") end
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Unknown"
    local level = UnitLevel and UnitLevel("player") or 1
    local zone = (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or "Unknown"
    local mapID = C_Map and C_Map.GetBestMapForUnit and safeCall(C_Map.GetBestMapForUnit, "player")
    local mapInfo = mapID and C_Map and C_Map.GetMapInfo and safeCall(C_Map.GetMapInfo, mapID)
    if mapInfo and mapInfo.name then zone = mapInfo.name end

    local active, activeByID = {}, {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local count = safeCall(C_QuestLog.GetNumQuestLogEntries) or 0
        for i = 1, count do
            local info = safeCall(C_QuestLog.GetInfo, i)
            if info and not info.isHeader and info.questID and info.questID > 0 then
                local title = info.title or (C_QuestLog.GetTitleForLogIndex and safeCall(C_QuestLog.GetTitleForLogIndex, i)) or "Quest"
                local objectives = {}
                if C_QuestLog.GetQuestObjectives then
                    local rows = safeCall(C_QuestLog.GetQuestObjectives, info.questID) or {}
                    for _, objective in ipairs(rows) do
                        if objective and objective.text then
                            objectives[#objectives + 1] = {
                                text = objective.text,
                                fulfilled = objective.numFulfilled or 0,
                                required = objective.numRequired or 0,
                                finished = objective.finished or false,
                            }
                        end
                    end
                end
                local questZoneMapID, questZoneName
                local waypoint
                if C_QuestLog.GetNextWaypoint then
                    local wpMapID, wpX, wpY = safeCall(C_QuestLog.GetNextWaypoint, info.questID)
                    if wpMapID and wpX and wpY then
                        waypoint = { mapID=wpMapID, x=wpX, y=wpY, normalized=true }
                    end
                end
                if C_TaskQuest and C_TaskQuest.GetQuestZoneID then
                    questZoneMapID = safeCall(C_TaskQuest.GetQuestZoneID, info.questID)
                    if questZoneMapID and C_Map and C_Map.GetMapInfo then
                        local questMapInfo = safeCall(C_Map.GetMapInfo, questZoneMapID)
                        questZoneName = questMapInfo and questMapInfo.name
                    end
                end
                local row = {
                    id = info.questID,
                    title = title,
                    isComplete = info.isComplete or (C_QuestLog.IsComplete and safeCall(C_QuestLog.IsComplete, info.questID)) or false,
                    objectives = objectives,
                    zoneMapID = questZoneMapID,
                    zoneName = questZoneName,
                    waypoint = waypoint,
                }
                active[#active + 1] = row
                activeByID[row.id] = true
            end
        end
    end

    local completed = {}
    if C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs then
        local ids = safeCall(C_QuestLog.GetAllCompletedQuestIDs) or {}
        for _, id in ipairs(ids) do completed[id] = true end
    elseif GetQuestsCompleted then
        local ids = safeCall(GetQuestsCompleted) or {}
        for id, done in pairs(ids) do
            if type(id) == "number" and done then completed[id] = true end
            if type(done) == "number" then completed[done] = true end
        end
    end

    local profile = W.GetProfile()
    W.State = {
        key = W.GetCharacterKey(),
        name = UnitName and UnitName("player") or "Adventurer",
        realm = GetRealmName and GetRealmName() or "",
        className = (UnitClass and UnitClass("player")) or "Unknown",
        classToken = classToken or "UNKNOWN",
        raceName = raceName or "Unknown",
        raceToken = raceToken or "UNKNOWN",
        faction = faction,
        level = level,
        zone = zone,
        mapID = mapID,
        activeQuests = active,
        activeByID = activeByID,
        currentZoneQuests = {},
        zoneQuestMappingAvailable = C_TaskQuest and type(C_TaskQuest.GetQuestZoneID) == "function" or false,
        completed = completed,
        completedCount = (function() local n=0 for _ in pairs(completed) do n=n+1 end return n end)(),
        profile = profile,
    }
    for _, quest in ipairs(active) do
        if (mapID and quest.zoneMapID == mapID) or (quest.zoneName and quest.zoneName == zone) then
            W.State.currentZoneQuests[#W.State.currentZoneQuests + 1] = quest
        end
    end
    return W.State
end

function W.GetRecommendation(state)
    state = state or W.State or W.ScanCharacter()
    local level = state.level or 1
    local zone = state.zone or "Unknown"
    local localQuests = state.currentZoneQuests or {}
    if #localQuests > 0 then
        local ready = 0
        local nextQuest
        for _, quest in ipairs(localQuests) do
            if quest.isComplete then
                ready = ready + 1
                if not nextQuest then nextQuest = quest end
            elseif not nextQuest then
                nextQuest = quest
            end
        end
        local title = nextQuest and (nextQuest.isComplete and ("Turn in: " .. nextQuest.title) or ("Continue: " .. nextQuest.title)) or "Finish active quests in " .. zone
        local reason
        if ready > 0 then
            reason = string.format("%d active quest(s) are mapped to this zone; %d appear ready to turn in. Clear these before adding more travel.", #localQuests, ready)
        else
            reason = string.format("%d active quest(s) are mapped to this zone. Follow the next objective before moving to another hub.", #localQuests)
        end
        local waypoint = nextQuest and nextQuest.waypoint
        return {
            title = title,
            zone = waypoint and C_Map and C_Map.GetMapInfo and ((safeCall(C_Map.GetMapInfo, waypoint.mapID) or {}).name) or zone,
            mapID = waypoint and waypoint.mapID,
            x = waypoint and waypoint.x,
            y = waypoint and waypoint.y,
            normalized = waypoint and waypoint.normalized,
            reason = reason,
            instruction = nextQuest and nextQuest.title or "Use the Quests tab to review objectives. When this zone is clear, choose Duskwood or Wetlands as your next route.",
        }
    end
    local route = W.ZoneRoutes and W.ZoneRoutes[zone]
    if route and level >= (route.minLevel or 1) and level <= (route.maxLevel or 60) then
        return route
    end
    if level >= 18 and level <= 24 then
        return W.DefaultRoute
    end
    if level >= 25 and level <= 30 then
        return {
            title="Choose a level-appropriate nearby hub",
            zone="Duskwood or Wetlands", mapID=1437, x=10.5, y=59.7,
            reason="Both zones have questing for the upper 20s; your current quest log and travel position should decide.",
            instruction="Check your active quest list and choose the hub with the least travel from where you are now.",
        }
    end
    return {
        title="Review quests available around you",
        zone=zone, mapID=state.mapID,
        reason="The first route pack is focused on the 18–24 range and your Dwarf Shaman class journey.",
        instruction="Open the Quests tab to review active objectives. The route catalog will grow as Forever quest data is verified.",
    }
end

function W.GetCurrentWaterStep()
    local profile = W.GetProfile()
    local steps = W.WaterTotemRoute or {}
    local index = (profile.waterTotemStage or 0) + 1
    if index > #steps then return nil, #steps end
    return steps[index], #steps
end
