# Trailwarden 1.8.5

## Changed

- The selector now computes clustering once per candidate set and evaluates each remaining queue set once per leg, removing redundant list construction and repeated pair scans.
- For more than 128 eligible candidates, Trailwarden still scores every candidate for the primary route but shortens the optional queue preview to one step. The selected route remains fully evaluated.
- Paused and dead states bypass provider enumeration and forecast construction.
- `/tw debug` reports candidate and score counts and whether the preview was shortened.

## Verification

- Added a 129-candidate safe-degradation regression and checks that paused/dead planning skips collection.
- Full Lua 5.1 and Lua 5.4 suites and package validation are required before merging this feature.
