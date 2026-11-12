# Trailwarden 1.8.4

## Changed

- PvP, raid, dungeon and group classification now uses three states. If Questie's optional policy module is missing or incomplete, new database pickups are held as unknown rather than treated as ordinary safe quests.
- The route panel and `/tw debug` explain that Questie is needed to classify new pickups. Already accepted quests remain routable, and existing combat-level/elite checks stay active.

## Verification

- Added checks for the QuestieDB-only unknown state and Questie-present group policy.
- Full Lua 5.1 and Lua 5.4 suites and package validation are required before merging this feature.
