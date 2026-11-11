# Trailwarden 1.8.3

## Fixed

- Navigation and access errors now invalidate all Trailwarden-owned navigation outputs for the active decision.
- The panel enters a safe retry state while route outputs are invalid; stale bearings, pins and map waypoints are cleared.
- A later navigation update restores guidance for the same decision without requiring another quest event. Player-owned map waypoints remain protected.

## Verification

- Added injected access-failure and same-decision recovery checks, plus a stale map-overlay decision regression.
- Full Lua 5.1 and Lua 5.4 suites and package validation are required before merging this feature.
