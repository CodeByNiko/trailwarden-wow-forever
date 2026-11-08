# Changelog

## 1.0.0

- Replaced character-specific zone fallbacks with a common live quest planner.
- Added GUID-scoped profiles, retained turn-in history, and migration from 0.3.
- Added race/class/level/chain/exclusivity checks and solo/group comfort settings.
- Added NPC/object pickup and turn-in routing, item-source objectives, kill credit,
  delivery steps, quest events, client-waypoint fallback and quest-starting items.
- Added local pickup batching, area clustering, completion-aware queue updates,
  quest-log capacity handling, focused steps, hysteresis and temporary quest skips.
- Added live gossip observations and snapshot-scoped missing-offer suppression.
- Rebuilt the panel with bounded text regions, four planned steps, tooltips,
  compact mode, character settings, scale and saved panel position.
- Replaced native-navigation dependence with an original draggable arrow texture,
  independent map-derived distances, calibrated map axes and explicit arrival states.
- Added safe handling for missing positions, another continent, death, pause and
  user-owned map waypoints.
- Added diagnostics, scenario verification and reproducible release packaging.

## 0.3.0

- Introduced the custom movable arrow and dynamic pickup queue.
- Imported Questie's ZoneDB through its module loader.

## 0.2.1

- Corrected Forever UI map IDs.

## 0.2.0

- Focused the interface on routing and automatic map waypoints.

## 0.1.0

- Initial installable foundation.
