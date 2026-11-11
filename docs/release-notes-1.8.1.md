# Trailwarden 1.8.1

## Fixed

- Active client waypoints are now part of quest change detection. A waypoint-only change refreshes guidance on the next quest event, even when objective text and counters stay the same.
- Route stabilization now recognizes a changed client waypoint as a new target, so the panel and navigation do not keep using the previous coordinates.

## Verification

- Added regressions for waypoint-only changes and duplicate unchanged quest events.
- Full Lua 5.1 and Lua 5.4 suites and reproducible package validation are required before merging this feature.
