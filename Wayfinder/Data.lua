Wayfinder = Wayfinder or {}
local W = Wayfinder

W.DataVersion = 1
W.RouteModes = { "Balanced", "Fast leveling", "Explore Forever" }

-- Zone recommendations are deliberately broad in this first installable build.
-- Quest-level steps will expand as in-game records are gathered and verified.
W.ZoneRoutes = {
    ["Redridge Mountains"] = {
        minLevel = 20, maxLevel = 24,
        title = "Continue in Duskwood",
        zone = "Duskwood",
        mapID = 1431, x = 73.6, y = 46.8,
        reason = "A natural next hub from Redridge, with a broad level 18–30 quest range.",
        instruction = "From Three Corners, follow the road south to Darkshire. Finish any worthwhile Redridge quests already in your log before you leave.",
    },
    ["Duskwood"] = {
        minLevel = 20, maxLevel = 26,
        title = "Keep working through Duskwood",
        zone = "Duskwood",
        mapID = 1431, x = 73.6, y = 46.8,
        reason = "Duskwood has a strong set of Alliance quests for the low-to-mid 20s.",
        instruction = "Use Darkshire as your hub. Pick up nearby quests together and turn them in in batches to limit backtracking.",
    },
    ["Wetlands"] = {
        minLevel = 20, maxLevel = 29,
        title = "Quest around Menethil Harbor",
        zone = "Wetlands",
        mapID = 1437, x = 10.5, y = 59.7,
        reason = "Wetlands suits the 20–30 bracket and overlaps with the Dwarf Shaman Water Totem journey.",
        instruction = "Use Menethil Harbor as your hub. The Excavation Site is a new Forever dungeon; its quests are optional if you find a group.",
    },
    ["Loch Modan"] = {
        minLevel = 20, maxLevel = 24,
        title = "Continue toward Duskwood",
        zone = "Duskwood",
        mapID = 1431, x = 73.6, y = 46.8,
        reason = "At level 22, Duskwood is a suitable next questing hub. Your Shaman class chain also begins or returns through Loch Modan.",
        instruction = "If Call of Water is active, follow its current quest waypoint. Otherwise travel south through the Wetlands or back through the established Alliance roads.",
    },
    ["Ashenvale"] = {
        minLevel = 20, maxLevel = 29,
        title = "Continue around Astranaar",
        zone = "Ashenvale",
        mapID = 1440, x = 37.0, y = 51.6,
        reason = "Ashenvale offers suitable quests in the 20s and is one stop in the Dwarf Shaman Water Totem journey.",
        instruction = "Astranaar is a convenient hub. Follow your active quests and pick up the flight path while passing through.",
    },
}

W.DefaultRoute = {
    title = "Duskwood is a good next hub",
    zone = "Duskwood",
    mapID = 1431, x = 73.6, y = 46.8,
    reason = "Duskwood has a broad level 18–30 quest range and is a practical follow-up to Redridge.",
    instruction = "Head to Darkshire and gather nearby quests before choosing a direction. If Redridge still has worthwhile quests in your log, finish those first.",
}

-- Dwarf Shaman level-20 Call of Water route. Coordinates are normalized map
-- percentages and should be confirmed in the live Forever client by the player.
W.WaterTotemRoute = {
    { title="Find Norric Lochthane", zone="Loch Modan", mapID=1432, x=41.9, y=19.0,
      detail="Start Call of Water with a Shaman trainer if it is not already in your quest log. Speak with Norric near the loch shore." },
    { title="Visit Hervdana Saegrund", zone="Wetlands", mapID=1437, x=65.7, y=76.4,
      detail="Find Hervdana in the cave behind the waterfall in southern Wetlands and follow her instructions for the first sample." },
    { title="Collect the Redridge water sample", zone="Redridge Mountains", mapID=1433, x=73.7, y=61.6,
      detail="Use the red waterskin at the water location, then return to Hervdana when the quest asks." },
    { title="Collect the Ashenvale water sample", zone="Ashenvale", mapID=1440, x=37.0, y=51.6,
      detail="Fill the blue waterskin in the lake around Astranaar. Return to Hervdana to continue the chain." },
    { title="Return to Norric", zone="Loch Modan", mapID=1432, x=41.9, y=19.0,
      detail="After receiving Water Sapta from Hervdana, return to Norric and follow the next quest instruction." },
    { title="Visit the Forgotten Shrine", zone="Westfall", mapID=1436, x=47.5, y=60.4,
      detail="Use Water Sapta at the shrine when instructed, handle the manifestation encounter, then return to Norric to finish." },
}

W.LevelBands = {
    { min=1, max=9, label="Starting zone" },
    { min=10, max=17, label="Early journey" },
    { min=18, max=24, label="Mid 20s route" },
    { min=25, max=30, label="Late 20s route" },
    { min=31, max=39, label="30s route" },
    { min=40, max=49, label="40s route" },
    { min=50, max=60, label="Endgame journey" },
}
