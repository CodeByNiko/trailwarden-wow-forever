# Wayfinder changelog

## 0.3.0
- Added a separate draggable route arrow with destination and live distance.
- Added per-character navigator placement and visibility controls.
- Fixed Questie zone-map integration by importing the ZoneDB module through Questie's loader.
- Added a step queue for nearby quest pickups; the lead instruction changes from travel to accept at the destination and recalculates after quest-log changes.
- Renamed the panel control to Navigator and added `/wf arrow`.

## 0.2.1
- Corrected fallback and Shaman route destinations to Forever's current zone
  UiMapIDs so WoW can resolve the native waypoint.
- Clarified that Blizzard's In Game Navigation display option must be enabled
  for the on-screen arrow to appear; improved waypoint failure feedback.

## 0.2.0
- Reworked the interface into a single route-focused companion with an opaque,
  higher-contrast panel and clearer spacing.
- Removed the duplicate quest tracker and class tab; Questie remains the tracker.
- Added QuestieDB-driven pickup hub suggestions and live active quest waypoint
  prioritization.
- Automatically sets and supertracks the recommended waypoint by default, with
  an in-panel toggle and `/wf auto` command.
- Added route refresh, progress-based updates, and a short nearby hub-stop list.

## 0.1.0
- First installable foundation with route, quest and class tabs.
